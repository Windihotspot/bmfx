-- =====================================================================
-- 07  Storage buckets and policies
--
-- Files live under  <bucket>/<user_id>/<filename>
-- so ownership can be checked from the first folder segment.
-- =====================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('kyc-documents',  'kyc-documents',  false, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('deposit-proofs', 'deposit-proofs', false, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('avatars',        'avatars',        true,  2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

-- KYC documents: owner can upload/read their own, admins can read all
create policy "kyc docs: owner upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'kyc-documents' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "kyc docs: owner or admin read" on storage.objects
  for select to authenticated
  using (bucket_id = 'kyc-documents' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

-- Deposit proofs: same pattern
create policy "deposit proofs: owner upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'deposit-proofs' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "deposit proofs: owner or admin read" on storage.objects
  for select to authenticated
  using (bucket_id = 'deposit-proofs' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

-- Avatars: public read (bucket is public), owner writes
create policy "avatars: owner upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatars: owner update" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatars: owner delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
