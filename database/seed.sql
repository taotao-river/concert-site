-- ============================================================
-- 种子数据：以「2026 年真实在巡演」的欧美艺人为准
-- 使用方法：先运行 schema.sql，再运行本文件
-- 数据来源：Ticketmaster / 巡演官方公告（2026-09 检索）
-- 说明：日期为真实巡演信息，场馆精确名称/坐标建议上线前二次核实
-- ============================================================

-- 艺人
--
-- ⚠️ is_active 的含义（CLAUDE.md 第 7 节）：当前是否在巡演。
--    这是首批名单的**否决项**——不在巡演的顶流产生不了任何交易，
--    不应出现在首页和内容排期里。名气不是排序依据。
--    改动 is_active 前必须先核实官网/官方公告，不要凭印象。
insert into artists (name, name_en, slug, type, genre, country, official_site, is_active, description) values
  -- 在巡演：进首批名单
  ('威肯',           'The Weeknd',     'the-weeknd',    'solo', 'r&b/pop',       'Canada',         'https://www.theweeknd.com',        true,  '2026 亚洲终场巡演中（After Hours Til Dawn Tour）· 有亚洲可达场次，优先级最高'),
  ('爱莉安娜·格兰德','Ariana Grande',  'ariana-grande', 'solo', 'pop/r&b',       'United States',  'https://www.arianagrande.com',     true,  '2026 The Eternal Sunshine Tour 巡演中 · 目前仅北美站'),
  ('艾德·希兰',      'Ed Sheeran',     'ed-sheeran',    'solo', 'pop',           'United Kingdom', 'https://www.edsheeran.com',        true,  '2026 LOOP Tour 巡演中 · 目前仅北美站'),
  -- 巡演状态待核实：先置 false，核实后再改
  ('比莉·艾利什',    'Billie Eilish',  'billie-eilish', 'solo', 'pop/alternative','United States', 'https://www.billieeilish.com',     false, '待核实：2026 巡演状态未确认，核实前不进排期'),
  -- 确认无巡演：留在艺人库但不进首批名单
  ('泰勒·斯威夫特',  'Taylor Swift',   'taylor-swift',  'solo', 'pop/country',   'United States',  'https://www.taylorswift.com',      false, 'Eras Tour 已结束，暂无新巡演官宣 · 名气最高但无交易价值'),
  ('阿黛尔',         'Adele',          'adele',         'solo', 'pop/soul',      'United Kingdom', 'https://www.adele.com',            false, '驻唱已结束，暂未官宣新巡演'),
  ('贾斯汀·比伯',    'Justin Bieber',  'justin-bieber', 'solo', 'pop',           'Canada',         'https://www.justinbiebermusic.com', false, '近期无巡演官宣')
on conflict (slug) do nothing;

-- ------------------------------------------------------------
-- 场馆（The Weeknd 亚洲终场站相关，城市级坐标，精确场馆名需二次核实）
-- ------------------------------------------------------------
insert into venues (name, name_en, city, country, latitude, longitude, timezone, capacity) values
  ('新加坡国家体育场', 'National Stadium, Singapore', 'Singapore', 'Singapore', 1.3437, 103.8520, 'Asia/Singapore', 55000),
  ('首尔（场馆待核实）', 'Seoul (venue TBD)', 'Seoul', 'South Korea', 37.5000, 127.0000, 'Asia/Seoul', null),
  ('曼谷（场馆待核实）', 'Bangkok (venue TBD)', 'Bangkok', 'Thailand', 13.7500, 100.5000, 'Asia/Bangkok', null),
  ('香港（场馆待核实）', 'Hong Kong (venue TBD)', 'Hong Kong', 'Hong Kong', 22.3193, 114.1694, 'Asia/Hong_Kong', null),
  ('吉隆坡 TM 体育场', 'TM Stadium National', 'Kuala Lumpur', 'Malaysia', 3.1000, 101.7000, 'Asia/Kuala_Lumpur', null),
  ('东京 西武巨蛋', 'Belluna Dome', 'Tokyo', 'Japan', 35.7800, 139.4600, 'Asia/Tokyo', 35000),
  ('雅加达（场馆待核实）', 'Jakarta (venue TBD)', 'Jakarta', 'Indonesia', -6.2000, 106.8000, 'Asia/Jakarta', null)
on conflict do nothing;

-- ------------------------------------------------------------
-- 巡演
-- ------------------------------------------------------------

-- The Weeknd · After Hours Til Dawn（亚洲终场站）
insert into tours (name, name_en, slug, artist_id, start_date, end_date, status)
select 'After Hours Til Dawn Tour', 'After Hours Til Dawn Tour', 'weeknd-after-hours-til-dawn',
       id, '2026-09-20', '2026-11-04', 'active'
from artists where slug = 'the-weeknd'
on conflict do nothing;

-- Ariana Grande · The Eternal Sunshine Tour
insert into tours (name, name_en, slug, artist_id, start_date, end_date, status)
select 'The Eternal Sunshine Tour', 'The Eternal Sunshine Tour', 'ariana-eternal-sunshine',
       id, '2026-06-06', '2026-08-15', 'active'
from artists where slug = 'ariana-grande'
on conflict do nothing;

-- Ed Sheeran · LOOP Tour
insert into tours (name, name_en, slug, artist_id, start_date, end_date, status)
select 'LOOP Tour', 'LOOP Tour', 'ed-loop-tour',
       id, '2026-01-01', '2026-11-30', 'active'
from artists where slug = 'ed-sheeran'
on conflict do nothing;

-- ------------------------------------------------------------
-- 演出场次（真实巡演日期，时区已按当地标注）
-- ------------------------------------------------------------

-- The Weeknd 亚洲终场站（内地粉丝可短途到达，重点内容）
insert into events (artist_id, tour_id, venue_id, city, country, start_time, timezone, status, ticket_url, notes)
select a.id, t.id, v.id, v.city, v.country,
       d.ts, v.timezone, 'onsale',
       'https://www.ticketmaster.com', 'The Weeknd 亚洲终场站，数据需二次核实场馆名'
from artists a
join tours t on t.artist_id = a.id and t.slug = 'weeknd-after-hours-til-dawn'
join (values
  ('Tokyo',        '2026-09-20 19:00:00+09:00'),
  ('Jakarta',      '2026-09-26 19:00:00+07:00'),
  ('Jakarta',      '2026-09-27 19:00:00+07:00'),
  ('Singapore',    '2026-10-02 20:00:00+08:00'),
  ('Singapore',    '2026-10-03 20:00:00+08:00'),
  ('Seoul',        '2026-10-07 19:00:00+09:00'),
  ('Seoul',        '2026-10-08 19:00:00+09:00'),
  ('Bangkok',      '2026-10-11 19:00:00+07:00'),
  ('Kuala Lumpur', '2026-11-04 19:00:00+08:00')
) as d(city, ts)
join venues v on v.city = d.city
where a.slug = 'the-weeknd'
on conflict do nothing;

-- Ariana Grande · The Eternal Sunshine Tour（北美站部分，真实日期）
insert into events (artist_id, tour_id, city, country, start_time, timezone, status, ticket_url, notes)
select a.id, t.id, d.city, 'United States',
       d.ts, d.tz, 'onsale', 'https://www.ticketmaster.com', 'Ariana Grande 北美站'
from artists a
join tours t on t.artist_id = a.id and t.slug = 'ariana-eternal-sunshine'
join (values
  ('Oakland, CA',   '2026-06-06 20:00:00-07:00', 'America/Los_Angeles'),
  ('Oakland, CA',   '2026-06-09 20:00:00-07:00', 'America/Los_Angeles'),
  ('Los Angeles, CA','2026-06-13 20:00:00-07:00', 'America/Los_Angeles'),
  ('Brooklyn, NY',  '2026-07-18 20:00:00-04:00', 'America/New_York'),
  ('Brooklyn, NY',  '2026-07-19 20:00:00-04:00', 'America/New_York'),
  ('Chicago, IL',   '2026-08-03 20:00:00-05:00', 'America/Chicago'),
  ('Chicago, IL',   '2026-08-05 20:00:00-05:00', 'America/Chicago'),
  ('Chicago, IL',   '2026-08-06 20:00:00-05:00', 'America/Chicago')
) as d(city, ts, tz)
where a.slug = 'ariana-grande'
on conflict do nothing;

-- Ed Sheeran · LOOP Tour（部分真实日期）
insert into events (artist_id, tour_id, city, country, start_time, timezone, status, ticket_url, notes)
select a.id, t.id, d.city, d.country,
       d.ts, d.tz, 'onsale', 'https://www.ticketmaster.com', 'Ed Sheeran LOOP Tour'
from artists a
join tours t on t.artist_id = a.id and t.slug = 'ed-loop-tour'
join (values
  ('Milwaukee, WI',   'United States', '2026-06-25 19:30:00-05:00', 'America/Chicago'),
  ('Chicago, IL',     'United States', '2026-06-27 17:30:00-05:00', 'America/Chicago'),
  ('Minneapolis, MN', 'United States', '2026-08-15 17:30:00-05:00', 'America/Chicago'),
  ('Toronto, ON',     'Canada',        '2026-08-20 17:30:00-04:00', 'America/Toronto')
) as d(city, country, ts, tz)
where a.slug = 'ed-sheeran'
on conflict do nothing;

-- 数据来源
-- ⚠️ 2026-09-08：Songkick 已移除——新 API key 基本不再发放，不作为数据源。
--    首年主数据源是「艺人官网/官方公告 + 人工录入」，见 CLAUDE.md 第 5 节。
insert into sources (name, url, type) values
  ('艺人官网/官方公告', 'https://www.theweeknd.com', 'official'),
  ('人工录入', null, 'manual'),
  ('用户纠错投稿', null, 'manual'),
  ('Ticketmaster Discovery API', 'https://developer.ticketmaster.com', 'api')
on conflict do nothing;

-- ============================================================
-- 验证查询
-- ============================================================
-- 首批名单（只看在巡演的，按场次数排）：
-- select a.name, a.is_active, count(e.id) as events
-- from artists a left join events e on e.artist_id = a.id
-- where a.is_active = true group by a.name, a.is_active order by events desc;
--
-- 亚洲可达场次（本项目的核心价值区）：
-- select a.name, e.city, e.country, e.start_time
-- from events e join artists a on a.id = e.artist_id
-- where e.country in ('Singapore','Japan','South Korea','Thailand','Hong Kong',
--                     'Malaysia','Indonesia','Taiwan','Philippines','Vietnam')
-- order by e.start_time;
--
-- 数据纪律检查：哪些场次还没核实过来源（CLAUDE.md 第 4 节）
-- select a.name, e.city, e.start_time, e.last_verified_at
-- from events e join artists a on a.id = e.artist_id
-- where e.last_verified_at is null order by e.start_time;

