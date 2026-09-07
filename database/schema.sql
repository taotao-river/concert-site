-- ============================================================
-- 欧美明星抢票攻略站 · 数据库结构（Supabase / PostgreSQL）
-- 使用方法：复制本文件全部内容到 Supabase SQL Editor 运行
-- ============================================================

-- 开启 UUID 生成（Supabase 默认已开启，保险起见）
create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- 1. 艺人表 artists
-- ------------------------------------------------------------
create table if not exists artists (
  id uuid primary key default gen_random_uuid(),
  name text not null,                -- 显示名（可用中文，如「泰勒·斯威夫特」）
  name_en text,                      -- 原名/英文名（搜索用，如 Taylor Swift）
  slug text unique not null,         -- URL 标识，如 taylor-swift
  type text default 'solo',          -- solo / group
  genre text,                        -- 音乐类型
  country text,                      -- 国家
  songkick_id text,                  -- Songkick 艺人 ID（数据源对齐用）
  spotify_id text,                   -- Spotify 艺人 ID
  official_site text,                -- 官网
  social_links jsonb default '{}',   -- 社媒链接 {x:.., instagram:.., weibo:..}
  description text,                  -- 简介
  is_active boolean default true,    -- 是否在运营
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ------------------------------------------------------------
-- 2. 场馆表 venues
-- ------------------------------------------------------------
create table if not exists venues (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  name_en text,
  city text not null,
  country text not null,
  latitude numeric(9,6),             -- 巡演地图用
  longitude numeric(9,6),
  timezone text,                     -- 如 Asia/Singapore
  capacity integer,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ------------------------------------------------------------
-- 3. 巡演表 tours
-- ------------------------------------------------------------
create table if not exists tours (
  id uuid primary key default gen_random_uuid(),
  name text not null,                -- 巡演名称，如 The Eras Tour
  name_en text,
  slug text,
  artist_id uuid references artists(id) on delete cascade,
  start_date date,
  end_date date,
  status text default 'announced',   -- announced / active / completed / cancelled
  description text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ------------------------------------------------------------
-- 4. 演出场次表 events（核心表）
-- ------------------------------------------------------------
create table if not exists events (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid references artists(id) on delete cascade,
  tour_id uuid references tours(id) on delete set null,
  venue_id uuid references venues(id) on delete set null,
  city text not null,
  country text not null,
  start_time timestamptz not null,   -- 带时区的时间，避免时区错误
  end_time timestamptz,
  timezone text,
  price_min numeric(10,2),           -- 最低价（官方）
  price_max numeric(10,2),           -- 最高价
  currency text default 'USD',
  status text default 'announced',
    -- announced / presale / onsale / soldout / postponed / cancelled / completed
  ticket_url text,                   -- 官方购票链接
  presale_info text,                 -- 预售码渠道等说明
  notes text,
  last_verified_at timestamptz,      -- 信息最后核实时间（信任关键）
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ------------------------------------------------------------
-- 5. 数据来源表 sources
-- ------------------------------------------------------------
create table if not exists sources (
  id uuid primary key default gen_random_uuid(),
  name text not null,                -- 来源名，如 Songkick API
  url text,
  type text,                         -- api / official / affiliate / manual
  is_active boolean default true,
  last_crawled_at timestamptz,
  created_at timestamptz default now()
);

-- ------------------------------------------------------------
-- 6. 演出-来源关联表（一个演出可有多个来源）
-- ------------------------------------------------------------
create table if not exists event_sources (
  event_id uuid references events(id) on delete cascade,
  source_id uuid references sources(id) on delete cascade,
  url text,
  fetched_at timestamptz default now(),
  primary key (event_id, source_id)
);

-- ------------------------------------------------------------
-- 7. 攻略文章表 articles（抢票攻略 / 城市指南）
-- ------------------------------------------------------------
create table if not exists articles (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text unique,
  category text,                     -- ticket_guide / city_guide / tour_info
  artist_id uuid references artists(id) on delete set null,
  city text,
  content text,                      -- 正文（Markdown）
  is_paid boolean default false,     -- 是否订阅版内容
  status text default 'draft',       -- draft / published
  published_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ============================================================
-- 索引（加速搜索、筛选、地图查询）
-- ============================================================
create index if not exists idx_events_artist     on events(artist_id);
create index if not exists idx_events_start_time on events(start_time);
create index if not exists idx_events_city       on events(city);
create index if not exists idx_events_country    on events(country);
create index if not exists idx_events_status     on events(status);
create index if not exists idx_tours_artist      on tours(artist_id);
create index if not exists idx_articles_category on articles(category);
create index if not exists idx_articles_artist   on articles(artist_id);
create index if not exists idx_artists_name      on artists(name);
create index if not exists idx_venues_city       on venues(city);

-- ============================================================
-- 自动更新 updated_at 的触发器
-- ============================================================
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_artists_updated on artists;
create trigger trg_artists_updated before update on artists
  for each row execute function set_updated_at();

drop trigger if exists trg_venues_updated on venues;
create trigger trg_venues_updated before update on venues
  for each row execute function set_updated_at();

drop trigger if exists trg_tours_updated on tours;
create trigger trg_tours_updated before update on tours
  for each row execute function set_updated_at();

drop trigger if exists trg_events_updated on events;
create trigger trg_events_updated before update on events
  for each row execute function set_updated_at();

drop trigger if exists trg_articles_updated on articles;
create trigger trg_articles_updated before update on articles
  for each row execute function set_updated_at();

-- ============================================================
-- 行级安全策略（RLS）
-- 原则：所有人都能读（网站公开），只有登录的管理员能写
-- 如果你暂时只用 Supabase 后台手动录入，可以忽略本节
-- ============================================================

alter table artists enable row level security;
alter table venues enable row level security;
alter table tours enable row level security;
alter table events enable row level security;
alter table sources enable row level security;
alter table event_sources enable row level security;
alter table articles enable row level security;

-- 公开读
create policy "public_read_artists" on artists for select using (true);
create policy "public_read_venues"  on venues  for select using (true);
create policy "public_read_tours"   on tours   for select using (true);
create policy "public_read_events"  on events  for select using (true);
create policy "public_read_sources" on sources for select using (true);
create policy "public_read_event_sources" on event_sources for select using (true);
create policy "public_read_articles" on articles for select using (true);

-- 仅认证用户可写（后续接入登录后使用）
create policy "auth_write_artists" on artists for insert with check (auth.role() = 'authenticated');
create policy "auth_write_venues"  on venues  for insert with check (auth.role() = 'authenticated');
create policy "auth_write_tours"   on tours   for insert with check (auth.role() = 'authenticated');
create policy "auth_write_events"  on events  for insert with check (auth.role() = 'authenticated');
create policy "auth_write_sources" on sources for insert with check (auth.role() = 'authenticated');
create policy "auth_write_event_sources" on event_sources for insert with check (auth.role() = 'authenticated');
create policy "auth_write_articles" on articles for insert with check (auth.role() = 'authenticated');

