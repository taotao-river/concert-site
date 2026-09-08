# 全球演唱会地图（欧美明星抢票攻略站）

面向中国（华人）粉丝的欧美明星全球巡演信息站。核心定位：**让每一个对欧美歌手有好感的人，都不再错过 TA 的演唱会。**

## 项目一句话

通过「全球演唱会地图 + 月度演出清单 + 中文抢票/行程攻略」，用社媒种草触达被动粉丝，不卖票、不碰黄牛。

## 目录结构

```
.
├── concert-map-prototype.html          # 全球演唱会地图原型（浏览器直接打开）
├── database/
│   ├── schema.sql                      # 数据库建表脚本（Supabase/PostgreSQL）
│   ├── seed.sql                        # 种子数据（2026 真实巡演）
│   └── README.md                       # 数据库搭建说明
├── scripts/
│   ├── fetch_tours.py                  # 巡演数据采集脚本（Spotify + Ticketmaster）
│   ├── requirements.txt                # Python 依赖
│   └── README.md                       # 采集脚本使用说明
└── *.md                                # 产品/商业/法律/自动化方案文档
```

## 核心文档

- [项目总框架 MasterPlan](项目总框架_MasterPlan.md) —— 总纲，唯一权威
- [香港身份运营方案（法律与落地分析）](香港身份运营方案_法律与落地分析.md) —— 最终执行版
- [欧美明星抢票攻略站（可行性与项目方案）](欧美明星抢票攻略站_可行性与项目方案.md)
- [欧美明星演唱会信息站（战略与商业分析）](欧美明星演唱会信息站_方案与商业分析.md)
- [产品架构文档](演唱会信息网站产品架构文档.md)
- [AI 自建指南](演唱会网站AI自建指南.md)
- [自动化系统设计](演唱会网站自动化系统设计.md)
- [商业模式分析](演唱会网站商业模式分析.md)
- [**商业化可行性分析（独立复核）**](商业化可行性分析_独立复核.md) —— 对上述商业模型的重算与证伪，财务口径以此为准

## 技术栈

- 前端：Next.js + Leaflet/Mapbox（地图）
- 后端：Next.js API 路由
- 数据库：Supabase（PostgreSQL）
- 数据源：Ticketmaster Discovery API、Spotify Web API、Songkick（均免费）
- 部署：Vercel + Supabase

## 当前进度

- ✅ 战略与商业模式定稿
- ✅ 数据库 schema 与种子数据
- ✅ 全球地图原型
- ✅ 巡演数据采集脚本
- ⬜ 接真实数据、上线网站

## 快速开始

1. 数据库：见 `database/README.md`
2. 数据采集：见 `scripts/README.md`
3. 地图原型：浏览器直接打开 `concert-map-prototype.html`
