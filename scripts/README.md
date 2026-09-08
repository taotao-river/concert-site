# 巡演数据「校验」脚本 · 使用说明

> ⚠️ **2026-09-08 定位变更：本脚本不再是数据主链路。**
> 首年主数据源是「艺人官网/官方公告 + 人工录入 + 用户纠错」，脚本只做交叉校验和艺人排序。
> 原因见 `CLAUDE.md` 第 5 节：数据不是壁垒，数据获取权才是风险。
>
> ⚠️ **商用授权待确认**：Ticketmaster Discovery API 免费档面向开发者。
> 在带联盟链接或付费墙的站点上做商业展示前，须先读它的 TOS。

## 它能做什么

1. 用 **Spotify** 查候选艺人的热度（0-100，作为中文搜索热度的粗代理）
2. 用 **Ticketmaster** 查这些艺人的真实巡演场次（城市、场馆、日期、购票链接）
3. 按 `CLAUDE.md` 第 7 节的规则打分排序，产出 **首批艺人建议名单**
4. 输出三个 JSON：`artists.json`、`events.json`、`artist_priority.json`

## 它不再能做什么

- ❌ **自动扩展艺人名单**。Spotify 的 `related-artists` 端点自 2024-11-27 起对新应用停用，
  相关代码已移除。候选池请手动维护 `CANDIDATE_ARTISTS`。

## 第一步：注册两个免费 key（约 10 分钟）

### Spotify（只拿热度）

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

## `artist_priority.json` 怎么用（这是本脚本的主要产出）

打分规则来自 `CLAUDE.md` 第 7 节：

```
优先级 = 是否在巡演 × 亚洲可达场次数 × 中文搜索热度 ÷ 已有中文攻略供给
```

脚本能自动算前三项，**第四项「已有中文攻略供给」必须你人工填**——它无法自动测量：

| 字段 | 谁填 | 说明 |
|---|---|---|
| `is_touring` | 脚本 | **否决项**。为 false 则不进首批名单 |
| `asia_events` / `asia_cities` | 脚本 | 大陆粉丝短途可达的场次 |
| `spotify_popularity` | 脚本 | 中文搜索热度的粗代理，不精确 |
| `auto_score` | 脚本 | 前三项的乘积 |
| **`cn_guide_supply`** | **你** | low / medium / high。小红书搜一下该艺人就知道 |
| **`final_priority`** | **你** | auto_score ÷ 供给系数。**顶流通常 high（竞争激烈），中腰部通常 low（空白）** |

**一个反直觉但重要的结论：一个有亚洲场次的中腰部艺人，商业价值可能高于一个不在巡演的顶流。**

## 下一步

1. 人工填完 `artist_priority.json` 的两个字段，定出首批 5-10 个艺人
2. 对照艺人官网**二次核实**场次（脚本输出的 `verified` 全是 false，未核实的不入库）
3. 不在巡演的艺人在 `artists` 表置 `is_active = false`

## 常见问题

- **Ticketmaster 查不到某些艺人**：TM 主要覆盖北美/欧洲/澳洲，亚洲场次可能不全，属正常现象。
  **这也正是本项目的价值所在**——亚洲场次信息在中文环境更稀缺，但也意味着不能只靠 TM
- **Spotify 说 rate limit**：脚本里已加延时，等一会儿再跑
- **`related-artists` 报 403/404**：该端点已停用，脚本已移除调用。如果你在别处看到教程用它，那是过时的
- **想换候选艺人**：改 `fetch_tours.py` 里的 `CANDIDATE_ARTISTS`。
  注意那是**候选池**不是名单，排序由脚本按数据产出，不要按名气手排

