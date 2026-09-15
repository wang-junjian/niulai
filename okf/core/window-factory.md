---
type: Module
title: WindowFactory · 悬浮窗工厂
description: 无边框、透明、置顶、全空间可见的 NSWindow 工厂，全部六个角色窗口都从这里创建。
tags: [window, appkit, core]
resource: ../../Sources/Niulai/Core/WindowFactory.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: window-src
    resource: ../../Sources/Niulai/Core/WindowFactory.swift
    title: WindowFactory.swift
status: stable
---

# 窗口配置

`enum WindowFactory` 的静态方法 `makeFloatingWindow(size:origin:ignoresMouseEvents:rootView:)` 固定输出这套配置[^(window-src)]：

| 配置 | 值 | 效果 |
|------|-----|------|
| `styleMask` | `.borderless` | 无边框无标题栏 |
| `isOpaque` / `backgroundColor` | `false` / `.clear` | 透明背景，只显示 Canvas 画的形象 |
| `hasShadow` | `false` | 无投影 |
| `level` | `.floating` | 悬浮于普通窗口之上 |
| `collectionBehavior` | `[.canJoinAllSpaces, .stationary, .ignoresCycle]` | 所有桌面空间可见、不随空间切换移动、不进 Cmd+` 窗口循环 |
| `isReleasedWhenClosed` | `false` | 出屏 orderOut 后窗口对象可复用 |
| `contentView` | `NSHostingView(rootView:)` | 承载 SwiftUI 视图 |
| `setContentSize(size)` | 显式调用 | 固定尺寸，防止 SwiftUI 自适应改窗 |

# 鼠标穿透参数

`ignoresMouseEvents` 的选择是全库统一约定：

* **纯视觉角色**（云雀 / 蛇 / 狼 / 蝴蝶，即全部 [ScreenCrosser](../controllers/screen-crosser.md) 子类）传 `true`，不挡下方应用的点击。
* **可交互角色**（[牛来](../pet/pet-window-controller.md)、[豹拉](../controllers/companion-controller.md)）用默认 `false`，响应戳和拖拽。

调用方：[PetWindowController](../pet/pet-window-controller.md)、`ScreenCrosser.ensureWindow()`、`CompanionController.ensureWindow()`。

[^window-src]: WindowFactory.swift
