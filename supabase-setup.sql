-- ============================================================
-- cherry的工作台 - Supabase 数据库建表脚本
-- 在 Supabase SQL Editor 中执行此脚本
-- ============================================================

-- 1. 待办事项表
CREATE TABLE IF NOT EXISTS todos (
  id TEXT PRIMARY KEY,
  text TEXT NOT NULL DEFAULT '',
  done BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. 快捷链接表
CREATE TABLE IF NOT EXISTS links (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  url TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. 便签表（单条记录，用 default 作为主键）
CREATE TABLE IF NOT EXISTS notes (
  id TEXT PRIMARY KEY DEFAULT 'default',
  content TEXT NOT NULL DEFAULT '',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 插入默认便签记录
INSERT INTO notes (id, content) VALUES ('default', '')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 启用 Row Level Security
-- ============================================================
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE links ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 创建策略（允许匿名用户的 CRUD 操作）
-- 注意：生产环境建议使用 authenticated 策略
-- ============================================================

-- Todos: 允许匿名读写
CREATE POLICY "Allow anon access on todos"
  ON todos FOR ALL
  TO anon
  USING (true)
  WITH CHECK (true);

-- Links: 允许匿名读写
CREATE POLICY "Allow anon access on links"
  ON links FOR ALL
  TO anon
  USING (true)
  WITH CHECK (true);

-- Notes: 允许匿名读写
CREATE POLICY "Allow anon access on notes"
  ON notes FOR ALL
  TO anon
  USING (true)
  WITH CHECK (true);

-- ============================================================
-- 创建索引
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_todos_created_at ON todos(created_at);
CREATE INDEX IF NOT EXISTS idx_links_created_at ON links(created_at);
CREATE INDEX IF NOT EXISTS idx_notes_updated_at ON notes(updated_at);
