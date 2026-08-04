-- ============================================================
-- IMMO-BILE — Clés de chiffrement des documents sensibles (RIB / carte grise)
-- À exécuter dans Supabase > SQL Editor > New query > Run
-- ============================================================
-- Principe : chaque carte grise et chaque RIB est désormais chiffré dans le
-- navigateur AVANT d'être envoyé dans le coffre (Storage). La clé de
-- déchiffrement n'est PAS stockée avec le fichier, ni dans le gros bloc de
-- données partagé de l'application — elle vit ici, dans une table à part,
-- avec ses propres règles d'accès strictes (propriétaire + admin uniquement).
--
-- Résultat : même en cas de fuite du stockage de fichiers (Storage) ou de la
-- table de données principale (app_state) prise isolément, les documents
-- restent illisibles sans accéder AUSSI à cette table-ci.
-- ============================================================

create table if not exists document_keys (
  user_id     uuid not null,
  doc_type    text not null check (doc_type in ('cg','rib')),
  enc_key     text not null, -- clé AES-256 (base64)
  iv          text not null, -- vecteur d'initialisation (base64)
  updated_at  timestamptz default now(),
  primary key (user_id, doc_type)
);

alter table document_keys enable row level security;

-- Lecture : le propriétaire de la clé, ou l'administrateur
create policy "Clés: lecture propriétaire + admin"
on document_keys for select
using (
  user_id = auth.uid()
  or auth.jwt() ->> 'email' = 'k.drouet@pozzo.immo'
);

-- Écriture / mise à jour / suppression : propriétaire uniquement
create policy "Clés: création propriétaire"
on document_keys for insert
with check (user_id = auth.uid());

create policy "Clés: mise à jour propriétaire"
on document_keys for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Clés: suppression propriétaire"
on document_keys for delete
using (user_id = auth.uid());
