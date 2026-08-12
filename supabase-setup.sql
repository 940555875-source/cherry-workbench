-- ============================================================
-- amber的工作台 - Supabase 数据库建表脚本（v3 墓碑机制）
-- 在 Supabase SQL Editor 中执行此脚本的全部内容
-- ============================================================

-- 1. 每日计划表
CREATE TABLE IF NOT EXISTS plans (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  text TEXT NOT NULL DEFAULT '',
  done BOOLEAN NOT NULL DEFAULT FALSE,
  device_id TEXT NOT NULL DEFAULT '',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. 事件提醒表
CREATE TABLE IF NOT EXISTS events (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  time TEXT NOT NULL DEFAULT '',
  title TEXT NOT NULL DEFAULT '',
  desc_text TEXT NOT NULL DEFAULT '',
  device_id TEXT NOT NULL DEFAULT '',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. 打卡习惯表
CREATE TABLE IF NOT EXISTS checkins (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  dates JSONB NOT NULL DEFAULT '[]',
  device_id TEXT NOT NULL DEFAULT '',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. 便签表（单条记录）
CREATE TABLE IF NOT EXISTS notes (
  id TEXT PRIMARY KEY DEFAULT 'default',
  content TEXT NOT NULL DEFAULT '',
  device_id TEXT NOT NULL DEFAULT '',
  deleted_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
INSERT INTO notes (id, content) VALUES ('default', '') ON CONFLICT (id) DO NOTHING;

-- 5. 快捷链接表
CREATE TABLE IF NOT EXISTS links (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  url TEXT NOT NULL DEFAULT '',
  device_id TEXT NOT NULL DEFAULT '',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 自动更新 updated_at 的触发器函数
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为每张表创建触发器
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN SELECT unnest(ARRAY['plans','events','checkins','notes','links']) LOOP
    EXECUTE format('
      DROP TRIGGER IF EXISTS trg_%I_updated_at ON %I;
      CREATE TRIGGER trg_%I_updated_at
        BEFORE UPDATE ON %I
        FOR EACH ROW EXECUTE FUNCTION update_updated_at();
    ', t, t, t, t);
  END LOOP;
END $$;

-- ============================================================
-- 清理超过 30 天的墓碑记录（定时任务）
-- ============================================================
CREATE OR REPLACE FUNCTION cleanup_tombstones()
RETURNS void AS $$
BEGIN
  DELETE FROM plans   WHERE deleted_at IS NOT NULL AND deleted_at < NOW() - INTERVAL '30 days';
  DELETE FROM events  WHERE deleted_at IS NOT NULL AND deleted_at < NOW() - INTERVAL '30 days';
  DELETE FROM checkins WHERE deleted_at IS NOT NULL AND deleted_at < NOW() - INTERVAL '30 days';
  DELETE FROM links   WHERE deleted_at IS NOT NULL AND deleted_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- 如果 Supabase 支持 pg_cron，启用每日清理
-- （如果不支持，跳过这一步不会报错）
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule('cleanup-tombstones', '0 3 * * *', 'SELECT cleanup_tombstones();');
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'pg_cron not available, skipping scheduled cleanup';
END $$;

-- ============================================================
-- 启用 Row Level Security
-- ============================================================
ALTER TABLE plans    ENABLE ROW LEVEL SECURITY;
ALTER TABLE events   ENABLE ROW LEVEL SECURITY;
ALTER TABLE checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes    ENABLE ROW LEVEL SECURITY;
ALTER TABLE links    ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- RLS 策略：允许匿名用户的 CRUD 操作
-- 生产环境建议改用 authenticated + 用户隔离
-- ============================================================
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN SELECT unnest(ARRAY['plans','events','checkins','notes','links']) LOOP
    EXECUTE format('
      DROP POLICY IF EXISTS "Allow anon access on %I" ON %I;
      CREATE POLICY "Allow anon access on %I"
        ON %I FOR ALL TO anon
        USING (true) WITH CHECK (true);
    ', t, t, t, t);
  END LOOP;
END $$;

-- ============================================================
-- 索引
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_plans_date        ON plans(date);
CREATE INDEX IF NOT EXISTS idx_plans_deleted_at  ON plans(deleted_at);
CREATE INDEX IF NOT EXISTS idx_events_date       ON events(date);
CREATE INDEX IF NOT EXISTS idx_events_deleted_at ON events(deleted_at);
CREATE INDEX IF NOT EXISTS idx_checkins_deleted_at ON checkins(deleted_at);
CREATE INDEX IF NOT EXISTS idx_links_deleted_at  ON links(deleted_at);
CREATE INDEX IF NOT EXISTS idx_notes_updated_at  ON notes(updated_at);
