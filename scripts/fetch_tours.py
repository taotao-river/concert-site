#!/usr/bin/env python3
"""
欧美艺人巡演数据「校验」脚本

⚠️ 定位变更（2026-09-08）：本脚本不再是数据主链路。
   首年主数据源是「艺人官网/官方公告 + 人工录入 + 用户纠错」，
   本脚本只用于交叉校验和艺人优先级排序。原因见 CLAUDE.md 第 5 节：
   数据不是壁垒，数据获取权才是风险。

⚠️ 使用前必读：
   - Ticketmaster Discovery API 免费档面向开发者（5,000 次/日、5 次/秒）。
     在带联盟链接或付费墙的站点上做商业展示前，须先确认其 TOS 是否允许。
   - Spotify 的 related-artists / recommendations / audio-features 端点
     自 2024-11-27 起对新应用停用，本脚本已移除相关调用。
     现在只用 search 端点取 popularity（作为中文搜索热度的粗代理）。

用法：
  1. 注册两个免费 key（见 README.md）
  2. export SPOTIFY_CLIENT_ID=... SPOTIFY_CLIENT_SECRET=... TICKETMASTER_API_KEY=...
  3. python3 fetch_tours.py

输出：
  - artists.json          艺人基础信息（含 Spotify popularity）
  - events.json           查到的场次（原始）
  - artist_priority.json  ★ 按 CLAUDE.md 第 7 节规则排序的艺人优先级表
"""

import json
import os
import sys
import time

import requests

# ============================================================
# 配置（key 只从环境变量读，不要写进代码）
# ============================================================
SPOTIFY_CLIENT_ID = os.environ.get("SPOTIFY_CLIENT_ID", "")
SPOTIFY_CLIENT_SECRET = os.environ.get("SPOTIFY_CLIENT_SECRET", "")
TICKETMASTER_API_KEY = os.environ.get("TICKETMASTER_API_KEY", "")

# 候选艺人池。
#
# ⚠️ 这是「候选池」，不是「首批名单」。
#    首批名单由脚本按实际巡演数据打分产出（见 artist_priority.json），
#    不要在这里按名气排序——不在巡演的顶流产生不了任何交易。
#    详见 CLAUDE.md 第 7 节。
CANDIDATE_ARTISTS = [
    # 已知 2026 在巡演（来自 database/seed.sql，需二次核实）
    "The Weeknd", "Ariana Grande", "Ed Sheeran",
    # 巡演状态待核实
    "Taylor Swift", "Adele", "Billie Eilish", "Justin Bieber",
    "Dua Lipa", "Olivia Rodrigo", "Sabrina Carpenter",
    "Harry Styles", "SZA", "Doja Cat", "Post Malone",
    "Beyonce", "Lady Gaga", "Bruno Mars", "Coldplay",
    "Miley Cyrus", "Lana Del Rey",
]

# 亚洲可达城市所在国家/地区：大陆粉丝短途可达，是本项目的核心价值区
# 与 项目总框架_MasterPlan.md 4.1 节的城市清单对应
ASIA_REACHABLE = {
    "Singapore", "Japan", "South Korea", "Korea, Republic of",
    "Thailand", "Hong Kong", "Malaysia", "Indonesia",
    "Taiwan", "Philippines", "Vietnam", "Macau", "China",
}

SPOTIFY_TOKEN_URL = "https://accounts.spotify.com/api/token"
SPOTIFY_API = "https://api.spotify.com/v1"
TM_API = "https://app.ticketmaster.com/discovery/v2"


# ============================================================
# Spotify：只用 search 取 popularity
# ============================================================
def spotify_get_token():
    if not SPOTIFY_CLIENT_ID or not SPOTIFY_CLIENT_SECRET:
        print("[错误] 缺少 Spotify Client ID / Secret，请先注册（见 README.md）")
        sys.exit(1)
    resp = requests.post(
        SPOTIFY_TOKEN_URL,
        data={"grant_type": "client_credentials"},
        auth=(SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET),
        timeout=15,
    )
    resp.raise_for_status()
    return resp.json()["access_token"]


def spotify_search_artist(token, name):
    headers = {"Authorization": f"Bearer {token}"}
    params = {"q": name, "type": "artist", "limit": 1}
    resp = requests.get(f"{SPOTIFY_API}/search", headers=headers, params=params, timeout=15)
    if resp.status_code != 200:
        return None
    items = resp.json().get("artists", {}).get("items", [])
    return items[0] if items else None


# 注：原有的 spotify_related_artists() 已删除。
# /artists/{id}/related-artists 自 2024-11-27 起对新应用返回 403/404，
# 「从种子艺人自动扩展名单」的设计不再可行。
# 扩展候选池请手动维护 CANDIDATE_ARTISTS，或改用其他公开榜单。


# ============================================================
# Ticketmaster：查真实场次
# ============================================================
def ticketmaster_events(artist_name, country_code=None):
    if not TICKETMASTER_API_KEY:
        print("[错误] 缺少 Ticketmaster API Key，请先注册（见 README.md）")
        sys.exit(1)
    params = {
        "apikey": TICKETMASTER_API_KEY,
        "keyword": artist_name,
        "size": 50,
        "sort": "date,asc",
    }
    if country_code:
        params["countryCode"] = country_code
    resp = requests.get(f"{TM_API}/events.json", params=params, timeout=20)
    if resp.status_code != 200:
        print(f"  [警告] Ticketmaster 返回 {resp.status_code}（{artist_name}）")
        return []
    data = resp.json()
    if "_embedded" not in data:
        return []
    return data["_embedded"].get("events", [])


def parse_tm_event(artist_name, ev):
    """把 Ticketmaster 的一条 event 转成我们的结构"""
    date_info = ev.get("dates", {}).get("start", {})
    venues = ev.get("_embedded", {}).get("venues", [])
    venue = venues[0] if venues else {}
    country = venue.get("country", {}).get("name", "")
    return {
        "artist": artist_name,
        "event_name": ev.get("name", ""),
        "city": venue.get("city", {}).get("name", ""),
        "country": country,
        "venue": venue.get("name", ""),
        "local_date": date_info.get("localDate", ""),
        "local_time": date_info.get("localTime", ""),
        "timezone": ev.get("dates", {}).get("timezone", ""),
        "status": ev.get("dates", {}).get("status", {}).get("code", ""),
        "ticket_url": ev.get("url", ""),
        "is_asia_reachable": country in ASIA_REACHABLE,
        # 数据纪律：来源和抓取时间必须留痕（CLAUDE.md 第 4 节）
        "source": "Ticketmaster Discovery API",
        "fetched_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "verified": False,  # API 结果仍需人工二次核实后才能入库
    }


# ============================================================
# 艺人优先级打分（CLAUDE.md 第 7 节）
# ============================================================
def score_artists(artists, events):
    """
    优先级 = 是否在巡演 × 亚洲可达场次数 × 中文搜索热度 ÷ 已有中文攻略供给

    其中：
      - 是否在巡演    → 由 Ticketmaster 是否返回场次判定（否决项，为 0 则整体为 0）
      - 亚洲可达场次  → 场次所在国家落在 ASIA_REACHABLE
      - 中文搜索热度  → 用 Spotify popularity 做粗代理（不精确，但可自动获取）
      - 已有攻略供给  → ⚠️ 无法自动测量，需人工填。脚本输出占位，由人判断后回填。
    """
    by_artist = {}
    for ev in events:
        a = by_artist.setdefault(ev["artist"], {"total": 0, "asia": 0, "asia_cities": set()})
        a["total"] += 1
        if ev["is_asia_reachable"]:
            a["asia"] += 1
            if ev["city"]:
                a["asia_cities"].add(f'{ev["city"]}, {ev["country"]}')

    rows = []
    for name, info in artists.items():
        stat = by_artist.get(name, {"total": 0, "asia": 0, "asia_cities": set()})
        is_touring = 1 if stat["total"] > 0 else 0
        popularity = info.get("popularity", 0)

        # 否决项：不在巡演则整体为 0
        # +1 是为了让「在巡演但无亚洲场次」的艺人仍有基础分（欧美场次也有中文受众）
        score = is_touring * (1 + stat["asia"]) * (popularity / 100.0)

        rows.append({
            "name": name,
            "is_touring": bool(is_touring),
            "total_events": stat["total"],
            "asia_events": stat["asia"],
            "asia_cities": sorted(stat["asia_cities"]),
            "spotify_popularity": popularity,
            "auto_score": round(score, 3),
            # 需要人工填的字段
            "cn_guide_supply": None,   # 已有中文攻略供给：low / medium / high
            "final_priority": None,    # auto_score ÷ 攻略供给系数，人工判断后回填
            "note": "" if is_touring else "当前无巡演场次 → 不进首批名单，artists.is_active 应置 false",
        })

    rows.sort(key=lambda r: r["auto_score"], reverse=True)
    return rows


# ============================================================
# 主流程
# ============================================================
def main():
    print("==> 1/4 获取 Spotify 令牌")
    token = spotify_get_token()

    print(f"==> 2/4 查询艺人热度（候选池 {len(CANDIDATE_ARTISTS)} 个）")
    artists = {}
    for name in CANDIDATE_ARTISTS:
        artist = spotify_search_artist(token, name)
        if not artist:
            print(f"  - 未找到: {name}")
            continue
        info = {
            "name": artist.get("name", name),
            "spotify_id": artist.get("id", ""),
            "popularity": artist.get("popularity", 0),
            "genres": artist.get("genres", []),
            "followers": artist.get("followers", {}).get("total", 0),
        }
        artists[info["name"]] = info
        print(f"  - {info['name']}  热度 {info['popularity']}")
        time.sleep(0.3)

    print(f"\n==> 3/4 查询巡演场次（{len(artists)} 个艺人）")
    all_events = []
    for i, name in enumerate(artists.keys(), 1):
        for ev in ticketmaster_events(name):
            all_events.append(parse_tm_event(name, ev))
        if i % 5 == 0 or i == len(artists):
            print(f"  进度 {i}/{len(artists)} · 已找到 {len(all_events)} 场")
        time.sleep(0.6)  # 遵守 Ticketmaster 频率限制（5 次/秒）

    print("\n==> 4/4 按 CLAUDE.md 第 7 节规则打分排序")
    priority = score_artists(artists, all_events)

    for f, data in [
        ("artists.json", list(artists.values())),
        ("events.json", all_events),
        ("artist_priority.json", priority),
    ]:
        with open(f, "w", encoding="utf-8") as fh:
            json.dump(data, fh, ensure_ascii=False, indent=2)

    touring = [r for r in priority if r["is_touring"]]
    print("\n========== 完成 ==========")
    print(f"候选艺人 {len(artists)} 个，其中在巡演 {len(touring)} 个")
    print(f"场次 {len(all_events)} 场，其中亚洲可达 {sum(1 for e in all_events if e['is_asia_reachable'])} 场")
    print("\n--- 建议首批名单（auto_score 前 10，仅供参考，需人工确认）---")
    for r in touring[:10]:
        cities = "、".join(r["asia_cities"][:3]) or "无亚洲场次"
        print(f"  {r['auto_score']:6.2f}  {r['name']:<20} 亚洲 {r['asia_events']:>2} 场  {cities}")

    if not touring:
        print("  （无在巡演艺人。这不是脚本故障，是候选池需要更新。）")

    print("""
下一步（重要）：
  1. artist_priority.json 里的 cn_guide_supply / final_priority 需要你人工填
     —— 已有中文攻略供给无法自动测量，顶流通常 high（竞争激烈），中腰部通常 low（空白）
  2. API 结果的 verified 均为 false，入库前必须对照艺人官网二次核实
  3. 不在巡演的艺人在 artists 表置 is_active = false，不进内容排期
""")


if __name__ == "__main__":
    main()
