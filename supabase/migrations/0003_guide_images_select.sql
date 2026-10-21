-- storage: let authors see their own guide images (bug #143)
-- The Storage API's remove() deletes with a WHERE on bucket_id and name plus
-- RETURNING, and Postgres applies SELECT policies to a DELETE that reads
-- columns. 0001 gave storage.objects no SELECT policy, so guide_images_delete
-- never matched a row. Same folder rule as guide_images_delete. The bucket is
-- public, so images load by URL without any policy; scoping this to the
-- author's own "{uid}/" folder keeps other users' folders (and the image names
-- of unpublished drafts) out of list().
create policy guide_images_select on storage.objects for select to authenticated
  using (bucket_id = 'guide-images' and (storage.foldername(name))[1] = auth.uid()::text);
