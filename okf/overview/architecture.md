---
type: Architecture
title: 架构总览
description: 牛来的分层结构、离散状态机 + 连续时间轴的双驱动模型与启动装配流程。
tags: [architecture, swiftui, appkit]
resource: ../../Sources/Niulai/
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: app-src
    resource: ../../Sources/Niulai/NiulaiApp.swift
    title: NiulaiApp.swift（入口与装配）
  - id: readme
    resource: ../../README.md
    title: 仓库 README（设计说明）
  - id: ticker-src
    resource: ../../Sources/Niulai/Core/FrameTicker.swift
    title: FrameTicker.swift
status: stable
---

# 分层结构

```
NiulaiApp.swift            入口：MenuBarExtra 菜单栏 + AppDelegate 装配
Settings.swift             UserDefaults key / 默认值集中管理
Pet/                       核心状态机 PetViewModel + 按职责拆分的 5 个扩展
Controllers/               ScreenCrosser 基类 + 5 个角色控制器
Views/                     SwiftUI Canvas 纯代码绘制 + 拖拽手势 + 气泡 + 菜单
Core/                      FrameTicker / WindowFactory / ScreenGeometry / EyeBlink / SoundPlayer
Resources/                 电影原声 mp3（SwiftPM resources 打包进 Bundle.module）
```

代码结构逐文件说明见仓库 README 的「代码结构」一节；各目录的逐模块知识见本库 [core](../core/)、[pet](../pet/)、[controllers](../controllers/)、[views](../views/) 分区。

# 双驱动模型

整个应用把「动画」拆成两层，这是理解代码的关键：

1. **离散状态机（逻辑层）**：[PetViewModel](../pet/pet-view-model.md) 由 [FrameTicker](../core/frame-ticker.md)（默认 60fps Timer）驱动，只负责状态切换（`State` 枚举 15 个状态）、窗口 `setFrameOrigin` 移动、定时决策。动画参数不在这里算。
2. **连续绘制（表现层）**：所有角色视图用 `TimelineView(.animation)` 驱动 SwiftUI [Canvas](../views/drawing-conventions.md) 每帧重绘，按「状态 + 经过时间」编排子阶段（如哈欠 → 伸懒腰），纯函数式：同样的 `(state, t)` 永远画出同样的帧。

窗口层是 [WindowFactory](../core/window-factory.md) 产出的无边框透明悬浮窗（`.floating` + `canJoinAllSpaces` + `.stationary`），悬浮于普通窗口之上且所有桌面空间可见。

# 启动装配流程

`NiulaiApp` 用 `@NSApplicationDelegateAdaptor` 挂 `AppDelegate`，`applicationDidFinishLaunching` 中的装配顺序[^(app-src)]：

1. `NSApp.setActivationPolicy(.accessory)` —— 无 Dock 图标、不抢焦点。
2. 创建 [PetViewModel](../pet/pet-view-model.md) 与 [PetWindowController](../pet/pet-window-controller.md)（牛来窗口）。
3. 创建豹拉 / 云雀 / 蛇 / 狼 / 蝴蝶五个控制器，以 `weak` 引用互相接线（`pet.companion = companion`、`butterfly.pet = pet` 等）——所有跨角色联动（护卫、跟随、吓一跳）都靠这组 weak 引用。
4. `controller.show()` → `pet.start()` → `lark.start()`。
5. 若上次「豹拉常伴」开着且当前是休闲模式，`companion.appear()` 直接登场。

菜单栏是 `MenuBarExtra`（`.menu` 样式），图标文本来自 `pet.menuBarLabel`（番茄钟运行时显示 🐮🍅 / 🐮☕️ / 🐮 ⏸），内容视图为 [MenuBarContentView](../views/menu-bar-content-view.md)。

# 线程与并发约定

* 全部逻辑在主线程：状态机、控制器都标 `@MainActor`；Timer 闭包内用 `MainActor.assumeIsolated` 桥接。
* `PetViewModel` 与 `ScreenCrosser` 用 `nonisolated init() {}` 规避 Swift 并发检查下的初始化隔离问题。
* 扩展不能持有存储属性——番茄钟、彩蛋、电量等跨扩展共享的状态全部集中在 `PetViewModel.swift` 主文件，并用注释约定「internal: +Xxx 写」标注归属。见[核心状态机](../pet/pet-view-model.md)的存储属性清单。

[^app-src]: NiulaiApp.swift（入口与装配）
[^readme]: 仓库 README（设计说明）
