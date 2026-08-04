-- ============================================================
-- IMMO-BILE — Sécurisation RGPD de l'accès aux données
-- À exécuter dans Supabase > SQL Editor > New query > Run
-- ============================================================
-- ⚠️ Avant d'exécuter ce script :
-- 1. Vérifiez que Authentication > Providers > Email est activé
--    (c'est le cas par défaut sur un nouveau projet Supabase).
-- 2. Décidez si vous activez "Confirm email" (Authentication > 
--    Settings) : si activé, chaque nouveau compte doit cliquer un
--    lien reçu par email avant de pouvoir se connecter. Recommandé
--    en production, peut être désactivé le temps de vos tests.
-- 3. Vérifiez la région de votre projet (Project Settings > 
--    General) : privilégiez une région européenne (ex: Frankfurt)
--    pour la conformité RGPD si ce n'est pas déjà le cas.
-- ============================================================

-- On retire l'ancienne règle qui autorisait absolument tout le monde
-- (y compris sans être connecté) à lire et modifier les données.
DROP POLICY IF EXISTS "Allow all" ON app_state;

-- Nouvelle règle : seule une personne AUTHENTIFIÉE (connectée via
-- Supabase Auth avec un compte email/mot de passe valide) peut lire
-- ou écrire les données. Un visiteur anonyme, ou quelqu'un qui aurait
-- simplement la clé "anon" sans être connecté, ne peut plus rien faire.
CREATE POLICY "Authenticated users only - read" ON app_state
  FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users only - write" ON app_state
  FOR UPDATE
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- (INSERT reste bloqué pour tout le monde : la ligne unique 'main'
-- est déjà créée, personne ne doit pouvoir en créer une autre.)

-- ============================================================
-- Vérification rapide après exécution :
-- SELECT * FROM pg_policies WHERE tablename = 'app_state';
-- Vous devriez voir 2 policies listées ci-dessus, et plus "Allow all".
-- ============================================================
