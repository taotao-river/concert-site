#!/usr/bin/env python3
"""
欧美艺人巡演数据采集脚本（免费版）

数据源：
  - Spotify Web API（免费）：艺人热度、风格、相关艺人
  - Ticketmaster Discovery API（免费）：真实巡演场次、城市、场馆、日期

用法：
  1. 注册两个免费 key（见 README.md）
  2. 设置环境变量，或直接改下面 CONFIG 里的空字符串
  3. 运行：python3 fetch_tours.py

输出：
  - artists.json  发现的欧美艺人（含热度、风格、相关艺人）
  - events.json   查到的真实巡演场次
"""

import json
import os
import sys
import time

import requests

# ============================================================
# 配置（改成你自己的 key）
# ============================================================
SPOTIFY_CLIENT_ID = os.environ.get("SPOTIFY_CLIENT_ID", "")
SPOTIFY_CLIENT_SECRET = os.environ.get("SPOTIFY_CLIENT_SECRET", "")
TICKETMASTER_API_KEY = os.environ.get("TICKETMASTER_API_KEY", "")

# 种子艺人：先放一批高热度欧美艺人，脚本会通过 Spotify 自动扩展
SEED_ARTISTS = [
    "Taylor Swift", "Adele", "Billie Eilish", "The Weeknd",
    "Justin Bieber", "Ariana Grande", "Ed Sheeran",
    "Dua Lipa", "Olivia Rodrigo", "Sabrina Carpenter",
    "Harry Styles", "SZA", "Doja Cat", "Post Malone",
    "Beyonce", "Lady Gaga", "Bruno Mars", "Coldplay",
    "Miley Cyrus", "Lana Del Rey",
]

# 采集深度：从种子艺人扩展多少层相关艺人（1 = 只取一层相关艺人）
RELATED_DEPTH = 1
# 每个艺人最多取多少个相关艺人
MAX_RELATED = 5

SPOTIFY_TOKEN_URL = "https://accounts.spotify.com/api/token"
SPOTIFY_API = "https://api.spotify.com/v1"
TM_API = "https://app.ticketmaster.com/discovery/v2"


# ============================================================
# Spotify 部分
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


def spotify_related_artists(token, artist_id):
    headers = {"Authorization": f"Bearer {token}"}
    resp = requests.get(f"{SPOTIFY_API}/artists/{artist_id}/related-artists", headers=headers, timeout=15)
    if resp.status_code != 200:
        return []
    return resp.json().get("artists", [])


# ============================================================
# Ticketmaster 部分
# ============================================================
def ticketmaster_events(artist_name, country_code=None):
    if not TICKETMASTER_API_KEY:
        print("[错误] 缺少 Ticketmaster API Key，请先注册（见 README.md）")
        sys.exit(1)
    params = {
        "apikey": TICKETMASTER_API_KEY,
        "keyword": artist_name,
        "size": 30,
        "sort": "date,asc",
    }
    if country_code:
        params["countryCode"] = country_code
    resp = requests.get(f"{TM_API}/events.json", params=params, timeout=20)
    if resp.status_code != 200:
        return []
    data = resp.json()
    if "_embedded" not in data:
        return []
    return data["_embedded"].get("events", [])


def parse_tm_event(artist_name, ev):
    """把 Ticketmaster 返回的一条 event 转成我们的结构"""
    date_info = ev.get("dates", {}).get("start", {})
    venues = ev.get("_embedded", {}).get("venues", [])
    venue = venues[0] if venues else {}
    city = venue.get("city", {}).get("name", "")
    country = venue.get("country", {}).get("name", "")
    return {
        "artist": artist_name,
        "event_name": ev.get("name", ""),
        "city": city,
        "country": country,
        "venue": venue.get("name", ""),
        "local_date": date_info.get("localDate", ""),
        "local_time": date_info.get("localTime", ""),
        "timezone": date_info.get("dateTime", "")[-6:],
        "status": ev.get("dates", {}).get("status", {}).get("code", ""),
        "ticket_url": ev.get("url", ""),
    }


# ============================================================
# 主流程
# ============================================================
def main():
    print("==> 1/3 获取 Spotify 令牌")
    token = spotify_get_token()

    # 收集艺人：种子 + 相关艺人，去重
    artist_queue = list(SEED_ARTISTS)
    artists = {}  # name -> info

    print(f"==> 2/3 用 Spotify 查询艺人热度与相关艺人（种子 {len(artist_queue)} 个）")
    seen = set()
    for depth in range(RELATED_DEPTH + 1):
        current = [a for a in artist_queue if a not in seen]
        if not current:
            break
        for name in current:
            seen.add(name)
            artist = spotify_search_artist(token, name)
            if not artist:
                print(f"  - 未找到: {name}")
                continue
            info = {
                "name": artist.get("name", name),
                "spotify_id": artist.get("id", ""),
                "popularity": artist.get("popularity", 0),  # 0-100，当作热度榜
                "genres": artist.get("genres", []),
                "followers": artist.get("followers", {}).get("total", 0),
            }
            artists[info["name"]] = info
            print(f"  - {info['name']}  热度 {info['popularity']}  风格 {', '.join(info['genres'][:2])}")

            if depth < RELATED_DEPTH:
                related = spotify_related_artists(token, artist["id"])[:MAX_RELATED]
                for r in related:
                    if r["name"] not in seen and r["name"] not in artist_queue:
                        artist_queue.append(r["name"])
            time.sleep(0.3)

    print(f"\n==> 3/3 用 Ticketmaster 查询巡演场次（共 {len(artists)} 个艺人）")
    all_events = []
    for i, name in enumerate(artists.keys(), 1):
        events = ticketmaster_events(name)
        if events:
            for ev in events:
                all_events.append(parse_tm_event(name, ev))
        if i % 5 == 0 or i == len(artists):
            print(f"  进度 {i}/{len(artists)} · 已找到 {len(all_events)} 场")
        time.sleep(0.6)  # 遵守 Ticketmaster 频率限制（5次/秒）

    # 输出
    with open("artists.json", "w", encoding="utf-8") as f:
        json.dump(list(artists.values()), f, ensure_ascii=False, indent=2)
    with open("events.json", "w", encoding="utf-8") as f:
        json.dump(all_events, f, ensure_ascii=False, indent=2)

    print("\n========== 完成 ==========")
    print(f"发现艺人：{len(artists)} 个")
    print(f"找到巡演场次：{len(all_events)} 场")
    print("已生成 artists.json 和 events.json")


if __name__ == "__main__":
    main()

