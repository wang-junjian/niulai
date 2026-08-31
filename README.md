# 牛来 · macOS 桌宠 🐮

一只住在桌面上的 Q 版小牛，灵感来自动画电影《牛来》——那只从胆小到勇敢、最终站起来追上牛群的小牛。

纯代码绘制（SwiftUI Canvas），无外部素材；macOS 原生，SwiftUI + AppKit 混合实现。

## 功能

- **桌面漫游**：随机发呆、漫步、坐下、打盹 💤，撞到屏幕边缘会掉头
- **拖拽**：按住拎起来放到任何地方（被拎着时会瞪大眼睛晃荡），放下时开心落地
- **点击互动**：戳一下会跳起来，冒出电影台词气泡（「勇气已经在我心底了！」）
- **菜单栏控制**：🐮 图标 → 显示/隐藏、自由走动开关、休息提醒间隔、退出
- **休息提醒**：定时走到屏幕中间提醒你起来活动（默认 45 分钟，可关）

## 运行

```bash
swift run Niulai
```

或用 Xcode 打开 `Package.swift` 进行开发调试。

## 打包成 App

```bash
./bundle.sh        # 生成 Niulai.app（ad-hoc 签名，本机可运行）
```

打包后无 Dock 图标（LSUIElement）。开机自启：系统设置 → 通用 → 登录项 → 添加 Niulai.app。

## 代码结构

```
Sources/Niulai/
├── NiulaiApp.swift           # 入口 + 菜单栏（MenuBarExtra）
├── PetWindowController.swift # 无边框透明置顶窗口
├── PetViewModel.swift        # 行为状态机 + 提醒定时器
├── PetContainerView.swift    # 拖拽/点击手势装配
├── NiulaiView.swift          # Canvas 绘制小牛 + 动画参数
├── SpeechBubbleView.swift    # 对话气泡
└── MenuBarContentView.swift  # 菜单栏控制项
```

## 设计说明

- 窗口 `level = .floating` + `canJoinAllSpaces`：悬浮于普通窗口之上，所有桌面空间可见
- 动画由 `TimelineView(.animation)` 驱动，状态机只管离散状态切换（60fps 的 Timer）
- 形象为原创卡通小牛，仅致敬电影角色气质，不涉及电影素材版权
