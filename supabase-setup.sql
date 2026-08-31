-- ============================================================
-- amber的工作台 - Supabase 建表脚本（v14.40 根治版）
-- 在 Supabase SQL Editor 中「全选执行」即可。
-- 对齐当前前端数据模型：plans / events / checkins / travels / budget
-- （links 表已废弃，前端已移除，这里一并 DROP）
-- ============================================================

-- ⚠️ 根治关键：先 DROP 掉 schema 过时的旧表，强制 PostgREST 重新加载。
--    travels/budget 目前云端为空表，DROP 无数据损失。
--    本地数据会在下次同步时自动 push 上去。
DROP TABLE IF EXISTS public.travels CASCADE;
DROP TABLE IF EXISTS public.budget  CASCADE;
DROP TABLE IF EXISTS public.links   CASCADE;

-- ============================================================
-- 1. 每日计划表
-- ============================================================
CREATE TABLE IF NOT EXISTS public.plans (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  text TEXT NOT NULL DEFAULT '',
  done BOOLEAN NOT NULL DEFAULT FALSE,
  deadline TEXT,
  category TEXT NOT NULL DEFAULT '',
  note TEXT NOT NULL DEFAULT '',
  device_id TEXT NOT NULL DEFAULT '',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 2. 事件提醒表
-- ============================================================
CREATE TABLE IF NOT EXISTS public.events (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  time TEXT NOT NULL DEFAULT '',
  title TEXT NOT NULL DEFAULT '',
  desc_text TEXT NOT NULL DEFAULT '',
  end_date TEXT,
  end_time TEXT,
  cat TEXT NOT NULL DEFAULT '',
  device_id TEXT NOT NULL DEFAULT '',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 3. 打卡习惯表
-- ============================================================
CREATE TABLE IF NOT EXISTS public.checkins (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  period TEXT NOT NULL DEFAULT 'daily',
  target INTEGER NOT NULL DEFAULT 1,
  dates JSONB NOT NULL DEFAULT '[]',
  device_id TEXT NOT NULL DEFAULT '',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 4. 旅行表（对齐当前前端 travels 数据结构）
-- ============================================================
CREATE TABLE public.travels (
  id TEXT PRIMARY KEY,
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  day INTEGER,
  month_end INTEGER,
  day_end INTEGER,
  destination TEXT NOT NULL DEFAULT '',
  tag TEXT,
  doc_link TEXT,
  cost NUMERIC,
  image TEXT,
  location JSONB,
  sort_key TEXT NOT NULL DEFAULT '',
  done BOOLEAN NOT NULL DEFAULT FALSE,
  device_id TEXT NOT NULL DEFAULT '',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 5. 年度预算表（对齐当前前端 budget 数据结构）
-- ============================================================
CREATE TABLE public.budget (
  id TEXT PRIMARY KEY,
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  "range" TEXT,
  item TEXT NOT NULL DEFAULT '',
  cat TEXT NOT NULL DEFAULT '',
  budget NUMERIC,
  actual NUMERIC,
  note TEXT,
  subs JSONB NOT NULL DEFAULT '[]',
  done BOOLEAN NOT NULL DEFAULT FALSE,
  device_id TEXT NOT NULL DEFAULT '',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 6. 旅行相册表（v14.45 新增，照片关联旅行规划）
-- ============================================================
CREATE TABLE IF NOT EXISTS public.photos (
  id TEXT PRIMARY KEY,
  travel_id TEXT,
  title TEXT NOT NULL DEFAULT '',
  taken_at TEXT,
  image TEXT,
  note TEXT,
  device_id TEXT NOT NULL DEFAULT '',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- RLS：个人使用（anon key），直接禁用，减少变量、避免权限问题
-- ============================================================
ALTER TABLE public.plans    DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.events   DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.checkins DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.travels  DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.budget   DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.photos   DISABLE ROW LEVEL SECURITY;

-- ============================================================
-- 索引
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_plans_date          ON public.plans(date);
CREATE INDEX IF NOT EXISTS idx_events_date         ON public.events(date);
CREATE INDEX IF NOT EXISTS idx_travels_year        ON public.travels(year);
CREATE INDEX IF NOT EXISTS idx_budget_year         ON public.budget(year);
CREATE INDEX IF NOT EXISTS idx_photos_travel       ON public.photos(travel_id);
CREATE INDEX IF NOT EXISTS idx_photos_taken_at     ON public.photos(taken_at);

-- ============================================================
-- ⭐ 强制刷新 PostgREST schema cache（根治死锁的最后一步）
-- ============================================================
NOTIFY pgrst, 'reload schema';
