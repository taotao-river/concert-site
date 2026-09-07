# 巡演数据采集脚本 · 使用说明

这套脚本帮你自动获取欧美艺人的巡演数据，全程免费。

## 它能做什么

1. 从种子艺人名单出发，用 **Spotify** 查艺人热度（0-100，当作人气榜）和相关艺人，自动扩展名单
2. 用 **Ticketmaster** 查这些艺人的真实巡演场次（城市、场馆、日期、购票链接）
3. 输出两个 JSON 文件：`artists.json`（艺人）和 `events.json`（场次）

## 第一步：注册两个免费 key（约 10 分钟）

### Spotify（拿热度 + 相关艺人）

1. 打开 https://developer.spotify.com/dashboard
2. 登录（有 Spotify 账号即可），点「Create app」
3. 随便填名字和描述，Redirect URI 随便填 `http://localhost:3000`
4. 创建后进入 app 设置，复制 **Client ID** 和 **Client Secret**

### Ticketmaster（拿巡演场次）

1. 打开 https://developer.ticketmaster.com/products-and-docs/apis/getting-started/
2. 注册账号，创建应用
3. 复制 **Consumer Key（API Key）**

## 第二步：装依赖

打开终端，进入这个文件夹：

```bash
cd ~/scripts
pip3 install -r requirements.txt
```

## 第三步：运行

```bash
export SPOTIFY_CLIENT_ID="你的Client ID"
export SPOTIFY_CLIENT_SECRET="你的Client Secret"
export TICKETMASTER_API_KEY="你的API Key"
python3 fetch_tours.py
```

> 如果不想用环境变量，也可以直接打开 `fetch_tours.py`，把开头的三个空字符串填上你的 key。

## 运行后会看到

- 控制台逐个打印艺人和热度
- 最后生成 `artists.json` 和 `events.json`

## 输出文件长什么样

`artists.json`：

```json
[
  {
    "name": "Taylor Swift",
    "spotify_id": "06HL4z0CvFAxyc27GXpf02",
    "popularity": 100,
    "genres": ["pop"],
    "followers": 100000000
  }
]
```

`events.json`：

```json
[
  {
    "artist": "The Weeknd",
    "event_name": "The Weeknd",
    "city": "Singapore",
    "country": "Singapore",
    "venue": "National Stadium",
    "local_date": "2026-10-02",
    "local_time": "20:00:00",
    "ticket_url": "https://www.ticketmaster.sg/..."
  }
]
```

## 下一步

拿到 `events.json` 后，可以把它转成 SQL 导入数据库的 events 表。需要我帮你写转换脚本吗？

## 常见问题

- **Ticketmaster 查不到某些艺人**：Ticketmaster 主要覆盖北美/欧洲/澳洲，亚洲场次可能不全，属正常现象
- **Spotify 说 rate limit**：脚本里已加延时，等一会儿再跑
- **想换艺人名单**：直接改 `fetch_tours.py` 里的 `SEED_ARTISTS` 列表

