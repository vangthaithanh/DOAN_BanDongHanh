-- Tao bang post_reports
CREATE TABLE IF NOT EXISTS post_reports (
  id BIGSERIAL PRIMARY KEY,
  post_id BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  reporter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, reporter_id)
);

ALTER TABLE post_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "post_reports_insert" ON post_reports;
CREATE POLICY "post_reports_insert" ON post_reports FOR INSERT
  WITH CHECK (reporter_id = auth.uid());

DROP POLICY IF EXISTS "post_reports_select_own" ON post_reports;
CREATE POLICY "post_reports_select_own" ON post_reports FOR SELECT
  USING (reporter_id = auth.uid());