-- Jadikan foto privat: bucket tidak publik, akses hanya ke folder milik sendiri (<uid>/...).
-- JANGAN lupa: foto lama yang tersimpan sebagai URL publik tetap bisa dibaca app
-- karena app mengubahnya menjadi path lalu membuat signed URL.

update storage.buckets set public = false where id = 'pod_images';

drop policy if exists "Siapapun bisa melihat foto" on storage.objects;
drop policy if exists "User bisa kelola foto" on storage.objects;

create policy "pod_images_select_own" on storage.objects
  for select to authenticated
  using (bucket_id = 'pod_images' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "pod_images_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'pod_images' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "pod_images_update_own" on storage.objects
  for update to authenticated
  using (bucket_id = 'pod_images' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'pod_images' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "pod_images_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'pod_images' and (storage.foldername(name))[1] = auth.uid()::text);
