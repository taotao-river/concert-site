-- ============================================================
-- 种子数据：以「2026 年真实在巡演」的欧美艺人为准
-- 使用方法：先运行 schema.sql，再运行本文件
-- 数据来源：Ticketmaster / 巡演官方公告（2026-09 检索）
-- 说明：日期为真实巡演信息，场馆精确名称/坐标建议上线前二次核实
-- ============================================================

-- 艺人：保留知名度高的，同时标注是否在巡演
insert into artists (name, name_en, slug, type, genre, country, official_site, description) values
  ('威肯',           'The Weeknd',     'the-weeknd',    'solo', 'r&b/pop',       'Canada',         'https://www.theweeknd.com',      '2026 亚洲终场巡演中（After Hours Til Dawn Tour）'),
  ('爱莉安娜·格兰德','Ariana Grande',  'ariana-grande', 'solo', 'pop/r&b',       'United States',  'https://www.arianagrande.com',   '2026 The Eternal Sunshine Tour 巡演中'),
  ('艾德·希兰',      'Ed Sheeran',     'ed-sheeran',    'solo', 'pop',           'United Kingdom', 'https://www.edsheeran.com',       '2026 LOOP Tour 巡演中'),
  ('比莉·艾利什',    'Billie Eilish',  'billie-eilish', 'solo', 'pop/alternative','United States','https://www.billieeilish.com',   '2026 巡演状态待核实'),
  ('泰勒·斯威夫特',  'Taylor Swift',   'taylor-swift',  'solo', 'pop/country',   'United States',  'https://www.taylorswift.com',    'Eras Tour 已结束，暂无新巡演官宣'),
  ('阿黛尔',         'Adele',          'adele',         'solo', 'pop/soul',      'United Kingdom', 'https://www.adele.com',          '驻唱已结束，暂未官宣新巡演'),
  ('贾斯汀·比伯',    'Justin Bieber',  'justin-bieber', 'solo', 'pop',           'Canada',         'https://www.justinbiebermusic.com','近期无巡演官宣')
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
insert into sources (name, url, type) values
  ('Songkick API', 'https://www.songkick.com', 'api'),
  ('Ticketmaster', 'https://www.ticketmaster.com', 'official'),
  ('巡演官方公告', 'https://www.theweeknd.com', 'official')
on conflict do nothing;

-- ============================================================
-- 验证查询
-- ============================================================
-- 看正在巡演的艺人：
-- select a.name, count(e.id) from artists a left join events e on e.artist_id=a.id group by a.name order by count desc;
-- 看 The Weeknd 亚洲站：
-- select city, start_time from events e join artists a on a.id=e.artist_id where a.slug='the-weeknd' order by start_time;

