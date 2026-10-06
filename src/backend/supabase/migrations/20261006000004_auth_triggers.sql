-- =====================================================================
-- 04  Auth triggers: new user -> profile + wallet + default role
-- =====================================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ref text := upper(nullif(new.raw_user_meta_data ->> 'referral_code', ''));
begin
  insert into public.profiles (id, email, first_name, last_name, phone, country, referred_by)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(trim(new.raw_user_meta_data ->> 'first_name'), ''),
    coalesce(trim(new.raw_user_meta_data ->> 'last_name'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'phone'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'country'), ''),
    case when v_ref is null then null
         else (select p.id from public.profiles p where p.referral_code = v_ref) end
  )
  on conflict (id) do nothing;

  insert into public.wallets (user_id) values (new.id) on conflict (user_id) do nothing;
  insert into public.user_roles (user_id, role) values (new.id, 'user') on conflict do nothing;

  insert into public.notifications (user_id, type, title, body)
  values (new.id, 'welcome', 'Welcome to BMFX', 'Your account is ready. Complete identity verification to unlock withdrawals.');

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Keep profiles.email in sync when a user changes their email.
create or replace function public.handle_user_email_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.profiles set email = coalesce(new.email, '') where id = new.id;
  return new;
end;
$$;

drop trigger if exists on_auth_user_email_changed on auth.users;
create trigger on_auth_user_email_changed
  after update of email on auth.users
  for each row
  when (old.email is distinct from new.email)
  execute function public.handle_user_email_change();
