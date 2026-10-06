-- Run once in the Supabase SQL editor AFTER the person has signed up.
-- Replace the email, and use 'super_admin' for the first owner account.
insert into public.user_roles (user_id, role)
select id, 'super_admin'::public.app_role
from auth.users
where email = 'you@example.com'
on conflict do nothing;
