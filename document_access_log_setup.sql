-- ============================================================
-- IMMO-BILE — Journal d'accès aux documents sensibles (RIB / carte grise)
-- À exécuter dans Supabase > SQL Editor > New query > Run
-- ============================================================
-- Chaque consultation réussie d'un RIB ou d'une carte grise est enregistrée :
-- qui a consulté, le document de qui, quel type, à quelle date/heure.
-- Seul l'administrateur peut lire ce journal — personne ne peut le modifier
-- ni le supprimer depuis l'application (traçabilité garantie).
-- ============================================================

create table if not exists document_access_log (
  id               bigint generated always as identity primary key,
  accessed_by      uuid not null,
  accessed_by_name text,
  doc_owner        uuid not null,
  doc_owner_name   text,
  doc_type         text not null check (doc_type in ('cg','rib')),
  accessed_at      timestamptz not null default now()
);

alter table document_access_log enable row level security;

-- N'importe quel utilisateur connecté peut ajouter une ligne, mais UNIQUEMENT
-- pour lui-même en tant qu'"accessed_by" (impossible de falsifier le journal
-- au nom de quelqu'un d'autre).
create policy "Journal: enregistrement de sa propre consultation"
on document_access_log for insert
with check (accessed_by = auth.uid());

-- Seul l'administrateur peut consulter le journal. Aucune policy UPDATE/DELETE
-- n'est créée : le journal est donc en pratique inaltérable depuis l'app.
create policy "Journal: lecture admin uniquement"
on document_access_log for select
using (auth.jwt() ->> 'email' = 'k.drouet@pozzo.immo');

create index if not exists idx_doc_access_log_date on document_access_log(accessed_at desc);
