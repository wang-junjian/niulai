---
type: View
title: MenuBarContentView · 菜单栏控制
description: 🐢 牛来菜单栏（MenuBarExtra .menu 样式）的全部控制项与 AppStorage 接线。
tags: [menu, view, settings]
resource: ../../Sources/Niulai/Views/MenuBarContentView.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: menu-src
    resource: ../../Sources/Niulai/Views/MenuBarContentView.swift
    title: MenuBarContentView.swift
  - id: app-src
    resource: ../../Sources/Niulai/NiulaiApp.swift
    title: NiulaiApp.swift（MenuBarExtra 装配）
status: stable
---

图标是 `MenuBarLabelView` 直接显示 `pet.menuBarLabel` 文本（🐮 / 🐮🍅 / 🐮☕️ / 🐮 ⏸）。[^(app-src)]

# 菜单项（自上而下）[^(menu-src)]

1. **模式**：休闲 / 工作 / 番茄钟三个按钮，当前模式带 ✓ 图标。⚠️ 实现注记：原来用 Picker，但 Picker 在 menu 样式的 MenuBarExtra 里选择不生效，换成按钮组。
2. **番茄钟区**（仅番茄钟模式显示）：阶段 + 分钟级倒计时文本、暂停 / 继续、提前切换阶段（见[番茄钟](../pet/pomodoro.md)）。
3. **隐藏 / 显示牛来** → `setVisible`。
4. **Toggle 三连**：自由走动（→ `applyRoaming`）、豹拉常伴（→ `companion.setAlways`）、音效（→ 直接写 [Settings](../pet/settings.md)，SoundPlayer 读）。
5. **休息提醒 Picker**：关闭 / 30 / 45 / 60 分钟（仅工作模式生效，→ `configureReminder`）。
6. **戳一下牛来** → `poke()`。
7. **退出牛来**（⌘Q）。

四个偏好项用 `@AppStorage(Settings.Key.xxx)` 双向绑定 UserDefaults，`onChange` 里调用 viewModel 的对应方法。

[^menu-src]: MenuBarContentView.swift
[^app-src]: NiulaiApp.swift（MenuBarExtra 装配）
