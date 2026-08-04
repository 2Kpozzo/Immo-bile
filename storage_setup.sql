-- ============================================================
-- IMMO-BILE — Coffre-fort documents (RIB & carte grise)
-- À exécuter dans Supabase > SQL Editor > New query > Run
-- ============================================================
-- Principe : les fichiers ne sont plus stockés en base64 dans le
-- bloc de données JSON (app_state), mais dans un vrai espace de
-- stockage privé (Supabase Storage), organisé par dossier :
--   documents/cg/{id-utilisateur}/...   (cartes grises)
--   documents/rib/{id-utilisateur}/...  (RIB)
-- Seul le propriétaire du dossier ET l'administrateur peuvent y
-- accéder — personne d'autre, même connecté, ne peut lire ces
-- fichiers.
-- ============================================================

-- 1. Création du coffre (bucket privé — "public" = false)
insert into storage.buckets (id, name, public)
values ('documents', 'documents', false)
on conflict (id) do nothing;

-- 2. Un utilisateur peut déposer un fichier uniquement dans SON propre dossier
create policy "Documents: upload dans son propre dossier"
on storage.objects for insert
with check (
  bucket_id = 'documents'
  and (storage.foldername(name))[2] = auth.uid()::text
);

-- 3. Lecture : le propriétaire du dossier, OU l'administrateur, peuvent consulter
create policy "Documents: lecture propriétaire + admin"
on storage.objects for select
using (
  bucket_id = 'documents'
  and (
    (storage.foldername(name))[2] = auth.uid()::text
    or auth.jwt() ->> 'email' = 'k.drouet@pozzo.immo'
  )
);

-- 4. Mise à jour (remplacement d'un fichier) : propriétaire uniquement
create policy "Documents: mise à jour propriétaire"
on storage.objects for update
using (
  bucket_id = 'documents'
  and (storage.foldername(name))[2] = auth.uid()::text
)
with check (
  bucket_id = 'documents'
  and (storage.foldername(name))[2] = auth.uid()::text
);

-- 5. Suppression : propriétaire uniquement
create policy "Documents: suppression propriétaire"
on storage.objects for delete
using (
  bucket_id = 'documents'
  and (storage.foldername(name))[2] = auth.uid()::text
);

-- ============================================================
-- ⚠️ Si un jour l'email de l'administrateur change, remplacez
-- 'k.drouet@pozzo.immo' dans la policy n°3 ci-dessus (SQL Editor >
-- rechercher "Documents: lecture propriétaire + admin" > Edit policy).
-- ============================================================
