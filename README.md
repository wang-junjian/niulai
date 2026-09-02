# 牛来 · macOS 桌宠 🐮

一只住在桌面上的 Q 版小牛，灵感来自动画电影《牛来》——那只从胆小到勇敢、最终站起来追上牛群的小牛。

纯代码绘制（SwiftUI Canvas），无外部素材；macOS 原生，SwiftUI + AppKit 混合实现。

## 功能

- **开场呼唤**：每次启动，牛来立刻喊一声「妈妈——！」（气泡 + 电影原声），停一拍，远处传来牛妈妈焦急的回应「牛来——！」（只闻其声）——电影名场面的开场白
- **三种模式**（菜单栏切换）：
  - 🎈 **休闲**：满地漫游、发呆、坐下、打盹
  - 💤 **工作（梦境）**：牛来走到屏幕角落趴下安静做梦，偶尔说句梦话；豹拉道别离开，云雀暂停飞过；休息提醒照常，说完自己回角落继续睡
  - 🍅 **番茄钟**：真正的番茄工作法搭子——25 分钟专注（牛来趴角落做梦陪你）→ 5 分钟休息（牛来醒来叫你起来活动），每 4 轮一次 15 分钟长休息；菜单栏图标显示阶段（🍅/☕️）可暂停/继续、提前切换阶段；菜单内显示分钟级倒计时；**专注中想知道时间？戳一下牛来，它迷迷糊糊报时「哞……还剩 14:32」**；休息阶段云雀/蛇/狼彩蛋照常出现
- **灵动眼神**：瞳孔会看人——追蝴蝶时盯着蝴蝶、被拎着时看鼠标、闲时偷偷瞟你的鼠标、走路看前方；豹拉平时望着牛来，狼影来了转而盯狼；蝴蝶被追时瞳孔收缩回头瞟。四个角色各自按不规则节奏眨眼（偶尔连眨两下）
- **拖拽**：按住拎起来放到任何地方（被拎着时会举起双手晃荡），放下时开心落地
- **点击互动**：戳一下会跳起来，冒出电影台词气泡（「七天站不起来就会被抛弃……但我做到了！」）；工作模式下被戳只会迷迷糊糊应一声
- **梦话彩蛋**：打盹/做梦时偶尔冒梦话气泡（「（梦话）豹拉，别走……」）；休闲模式打盹约 1/4 概率被「抽中」梦到妈妈——这觉的第一次梦话低音量播放电影里呢喃的「妈妈」原声（一觉最多一次；工作/番茄钟的睡绝不播放）
- **番茄钟提示音**：阶段切换（专注↔休息）时播放电影里的「牛来！」呼唤，比系统提示音有性格；菜单可关音效
- **豹拉客串**：黄底黑斑的小豹会在牛来散步时随机跑来跟随（30% 概率）；「豹拉常伴」默认开启（菜单可关），朋友就该贴身挨着走；戳豹拉它也会回应
- **云雀飞过**：翅膀受伤的云雀每隔几分钟慢慢飞过屏幕，有 30% 概率落在牛来头顶歇脚
- **青蛇爬过**（休闲模式）：一条吐着信子的青蛇偶尔蜿蜒爬过屏幕，牛来吓一跳（「蛇……蛇！！」），蛇爬走后才松一口气
- **狼影掠过**（休闲模式）：灰狼飞奔横穿屏幕，牛来吓得原地连跳；豹拉在场时会冲到牛来身前护卫（「嗷呜！！有我在，别怕！」），狼跑掉后牛来会道谢。蛇和狼不会同时出现，都可能从左或右边出场
- **追蝴蝶**（休闲模式）：小蝴蝶慢悠悠掠过，牛来发现后会小跑着追（「蝴蝶！等等我！」）；蝴蝶被追会加速甩开，拉开距离后牛来就放弃了（「飞得好快……不追了不追了」）；快飞出屏幕时牛来还会跳起来扑——多半扑空
- **睡醒伸懒腰**：打盹醒来或番茄钟休息开始时，先闭眼打个大哈欠，再双臂上举把身体拉得长长的
- **顶屏幕边缘**：走到边缘不总是掉头，偶尔把屏幕边当对手，低头用角顶一下（「哞！这堵墙跟我较劲！」），结果把自己撞晕了（螺旋眼+💫），晕完掉头就走
- **转圈追尾巴**：偶尔原地转圈追自己尾巴，转完停下坐下歇会儿
- **电量感知**：插上电源时牛来开心（「来电啦！⚡ 满血复活！」）；电量 ≤20% 未充电时会提醒你充电，自己也没精打采地坐下
- **菜单栏控制**：🐮 图标 → 模式切换、显示/隐藏、自由走动、豹拉常伴、休息提醒间隔、退出
- **休息提醒**（仅工作模式）：定时走到屏幕中间提醒你起来活动（默认 45 分钟，可关；重新设置后从头计时；番茄钟有自己的节奏，不受此影响）

## 下载安装（Release）

从 [Releases](../../releases) 页面下载 `Niulai-vX.Y-macOS.zip`，解压得到 `Niulai.app`（Apple Silicon + Intel 通用）。

因为应用使用 ad-hoc 签名（没有付费开发者证书），首次打开会被 Gatekeeper 拦截，任选一种方式放行：

- 右键 `Niulai.app` → **打开** → 在弹窗中再点 **打开**；或
- 终端执行：`xattr -cr Niulai.app`

## 运行

```bash
swift run Niulai
```

或用 Xcode 打开 `Package.swift` 进行开发调试。

## 打包成 App

```bash
./bundle.sh [版本号]   # 生成 Niulai.app（通用二进制，ad-hoc 签名）
```

打包后无 Dock 图标（LSUIElement）。开机自启：系统设置 → 通用 → 登录项 → 添加 Niulai.app。

## 发布新版本

打了 `v*` 标签就会触发 GitHub Actions 自动打包并发布到 Releases 页面：

```bash
git tag v0.2
git push origin v0.2
```

流水线见 [.github/workflows/release.yml](.github/workflows/release.yml)：macOS 运行器上编译通用二进制 → 打包压缩 → 创建 Release 并自动生成更新说明。

## 代码结构

```
Sources/Niulai/
├── NiulaiApp.swift               # 入口 + 菜单栏（MenuBarExtra）
├── Settings.swift                # UserDefaults key/默认值集中 + 类型化访问
├── Core/
│   ├── FrameTicker.swift         # 间隔参数化定时器（dt 封顶 + .common runloop）
│   ├── WindowFactory.swift       # 无边框透明悬浮窗工厂
│   ├── ScreenGeometry.swift      # visibleFrame 回退链
│   ├── EyeBlink.swift            # 确定性伪随机眨眼（各角色 seed 错开节奏）
│   └── SoundPlayer.swift         # 音效播放（电影原声 mp3，存于 Resources/）
├── Pet/
│   ├── PetViewModel.swift        # 核心状态机：tick/移动/撞边/互动/气泡/显隐
│   ├── PetViewModel+Mode.swift   # 三种模式切换与安静期判定
│   ├── PetViewModel+Pomodoro.swift   # 番茄钟（专注做梦 + 休息陪伴）
│   ├── PetViewModel+Events.swift     # 蛇/狼影/蝴蝶彩蛋调度 + 追蝴蝶回调
│   ├── PetViewModel+Reminder.swift   # 休息提醒 + 电量感知
│   ├── PetViewModel+Opening.swift    # 开场呼唤（妈妈——！/ 牛来——！）
│   ├── PetPhrases.swift          # 台词库（戳/梦话/工作戳/提醒）
│   └── PetWindowController.swift # 牛来窗口：鼠标所在屏出生
├── Controllers/
│   ├── ScreenCrosser.swift       # 横穿屏幕基类（入场→移动→出屏回调 + hook）
│   ├── SnakeController.swift     # 青蛇：速度/外壳，蜿蜒动画在 Views
│   ├── WolfController.swift      # 狼影：飞奔横穿 + 豹拉护卫联动
│   ├── ButterflyController.swift # 蝴蝶：翻飞/逃逸/追扑触发 hook
│   ├── LarkController.swift      # 云雀：飞行调度 + 歇脚子状态机
│   └── CompanionController.swift # 豹拉：跟随走位/登场离场
├── Views/
│   ├── NiulaiView.swift          # Canvas 绘制牛来（电影直立版）+ 动画参数
│   ├── PetContainerView.swift    # 牛来的拖拽/点击手势装配
│   ├── BaolaView.swift           # Canvas 绘制豹拉
│   ├── LarkView.swift            # Canvas 绘制云雀
│   ├── SnakeView.swift           # Canvas 绘制青蛇（脊线波浪 + 吐信子）
│   ├── WolfView.swift            # Canvas 绘制狼（两节腿奔驰步态）
│   ├── ButterflyView.swift       # Canvas 绘制蝴蝶（分层翅膀 + 随机配色）
│   ├── SpeechBubbleView.swift    # 对话气泡（牛来/豹拉共用）
│   └── MenuBarContentView.swift  # 菜单栏控制项
└── Resources/                    # 电影原声 mp3（妈妈/牛来）
```

## 设计说明

- 窗口 `level = .floating` + `canJoinAllSpaces`：悬浮于普通窗口之上，所有桌面空间可见
- 动画由 `TimelineView(.animation)` 驱动，状态机只管离散状态切换（60fps 的 Timer）
- 形象为原创卡通小牛，仅致敬电影角色气质，不涉及电影素材版权
