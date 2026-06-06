-- =============================================
-- RLS PATCH: posts / post_likes / comments
-- Chay trong Supabase SQL Editor
-- =============================================

-- POSTS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "posts_select" ON posts;
CREATE POLICY "posts_select" ON posts FOR SELECT USING (true);

DROP POLICY IF EXISTS "posts_insert" ON posts;
CREATE POLICY "posts_insert" ON posts FOR INSERT
  WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS "posts_update" ON posts;
CREATE POLICY "posts_update" ON posts FOR UPDATE
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS "posts_delete" ON posts;
CREATE POLICY "posts_delete" ON posts FOR DELETE
  USING (profile_id = auth.uid());

-- POST_LIKES
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "post_likes_select" ON post_likes;
CREATE POLICY "post_likes_select" ON post_likes FOR SELECT USING (true);

DROP POLICY IF EXISTS "post_likes_insert" ON post_likes;
CREATE POLICY "post_likes_insert" ON post_likes FOR INSERT
  WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS "post_likes_delete" ON post_likes;
CREATE POLICY "post_likes_delete" ON post_likes FOR DELETE
  USING (profile_id = auth.uid());

-- COMMENTS
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "comments_select" ON comments;
CREATE POLICY "comments_select" ON comments FOR SELECT USING (true);

DROP POLICY IF EXISTS "comments_insert" ON comments;
CREATE POLICY "comments_insert" ON comments FOR INSERT
  WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS "comments_delete" ON comments;
CREATE POLICY "comments_delete" ON comments FOR DELETE
  USING (profile_id = auth.uid());

-- POST_HASHTAGS
ALTER TABLE post_hashtags ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "post_hashtags_select" ON post_hashtags;
CREATE POLICY "post_hashtags_select" ON post_hashtags FOR SELECT USING (true);

DROP POLICY IF EXISTS "post_hashtags_insert" ON post_hashtags;
CREATE POLICY "post_hashtags_insert" ON post_hashtags FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM posts WHERE id = post_id AND profile_id = auth.uid())
);

DROP POLICY IF EXISTS "post_hashtags_delete" ON post_hashtags;
CREATE POLICY "post_hashtags_delete" ON post_hashtags FOR DELETE USING (
  EXISTS (SELECT 1 FROM posts WHERE id = post_id AND profile_id = auth.uid())
);

-- POST_MEDIA
ALTER TABLE post_media ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "post_media_select" ON post_media;
CREATE POLICY "post_media_select" ON post_media FOR SELECT USING (true);

DROP POLICY IF EXISTS "post_media_insert" ON post_media;
CREATE POLICY "post_media_insert" ON post_media FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM posts WHERE id = post_id AND profile_id = auth.uid())
);

-- POST_PLACE_TAGS
ALTER TABLE post_place_tags ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "post_place_tags_select" ON post_place_tags;
CREATE POLICY "post_place_tags_select" ON post_place_tags FOR SELECT USING (true);

DROP POLICY IF EXISTS "post_place_tags_insert" ON post_place_tags;
CREATE POLICY "post_place_tags_insert" ON post_place_tags FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM posts WHERE id = post_id AND profile_id = auth.uid())
);

DROP POLICY IF EXISTS "post_place_tags_delete" ON post_place_tags;
CREATE POLICY "post_place_tags_delete" ON post_place_tags FOR DELETE USING (
  EXISTS (SELECT 1 FROM posts WHERE id = post_id AND profile_id = auth.uid())
);

-- CONVERSATION_MEMBERS
ALTER TABLE conversation_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "conv_members_select" ON conversation_members;
CREATE POLICY "conv_members_select" ON conversation_members FOR SELECT
  USING (profile_id = auth.uid());

DROP POLICY IF EXISTS "conv_members_insert" ON conversation_members;
CREATE POLICY "conv_members_insert" ON conversation_members FOR INSERT
  WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS "conv_members_update" ON conversation_members;
CREATE POLICY "conv_members_update" ON conversation_members FOR UPDATE
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());
