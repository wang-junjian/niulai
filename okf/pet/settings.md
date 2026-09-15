---
type: Config
title: Settings · 用户偏好
description: UserDefaults 的 key 与默认值集中管理；key 字符串和默认值都不允许改动。
tags: [settings, userdefaults, config]
resource: ../../Sources/Niulai/Settings.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: settings-src
    resource: ../../Sources/Niulai/Settings.swift
    title: Settings.swift
status: stable
---

# Key 与默认值[^(settings-src)]

| key | 类型 | 默认值 | 含义 | 变更入口 |
|-----|------|--------|------|----------|
| `petMode` | String(`PetMode.rawValue`) | `.leisure` | 当前模式 | [+Mode](pet-vm-mode.md) setter |
| `roamingEnabled` | Bool | `true` | 自由走动 | 菜单 Toggle → `applyRoaming()` |
| `reminderMinutes` | Int | `45` | 休息提醒间隔，0=关 | 菜单 Picker → `configureReminder()` |
| `baolaAlways` | Bool | `true` | 豹拉常伴 | 菜单 Toggle → `companion.setAlways` |
| `soundEnabled` | Bool | `true` | 音效开关 | [SoundPlayer](../core/sound-player.md) 读 |

# 使用约定

* UI 层（[菜单](../views/menu-bar-content-view.md)）用 `@AppStorage(Settings.Key.xxx)`；逻辑层用 `Settings` 的类型化计算属性。
* ⚠️ **key 字符串和默认值都不能改**——改了等于丢掉用户现有设置。
* `petMode` 背书 UserDefaults 是外部 `defaults write` 兜底生效的前提，见[三模式系统](../overview/mode-system.md)。

[^settings-src]: Settings.swift
