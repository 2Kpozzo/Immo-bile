CREATE TABLE IF NOT EXISTS app_state (
  id TEXT PRIMARY KEY DEFAULT 'main',
  data JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO app_state (id, data) VALUES ('main', '{}') ON CONFLICT (id) DO NOTHING;

ALTER TABLE app_state ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all" ON app_state FOR ALL USING (true) WITH CHECK (true);
