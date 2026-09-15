---
type: Concept
title: 三模式系统（休闲 / 工作 / 番茄钟）
description: 模式的持久化、切换响应、安静期（isPeaceful）判定与角落归宿。
tags: [mode, state-machine, core-concept]
resource: ../../Sources/Niulai/Pet/PetViewModel+Mode.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: mode-src
    resource: ../../Sources/Niulai/Pet/PetViewModel+Mode.swift
    title: PetViewModel+Mode.swift
  - id: settings-src
    resource: ../../Sources/Niulai/Settings.swift
    title: Settings.swift
status: stable
---

# 模式定义

`PetMode` 枚举三个取值（rawValue 直接存 UserDefaults）：

| 模式 | 行为 | 豹拉 | 彩蛋（蛇/狼/蝴蝶/云雀） |
|------|------|------|--------------------------|
| `.leisure` 休闲 | 满地漫游、发呆、打盹 | 可跟随 | 正常出现 |
| `.working` 工作 | 走到右下角趴睡做梦 | 道别离开 | 全部暂停 |
| `.pomodoro` 番茄钟 | 专注期睡觉 / 休息期活动，见[番茄钟](../pet/pomodoro.md) | 专注离开、休息可回 | 休息阶段正常 |

# 持久化与响应机制

`mode` 是直接背书 `UserDefaults`（[Settings.petMode](../pet/settings.md)）的计算属性，不用 `@Published` 存储（规避 nonisolated init 的隔离问题），setter 手动 `objectWillChange.send()`。[^(mode-src)]

改动来源有两种：菜单按钮（走 setter）和外部 `defaults write` 命令（绕过 setter）。兜底机制：主循环 [tick](../pet/pet-view-model.md) 每帧比对 `mode != lastReactedMode`，发现不一致立刻调 `reactToModeChange()`——保证无论改动来自哪里都生效。

`reactToModeChange()` 的分支：

* → `.working`：停番茄钟、通知豹拉离开、冒泡「我去做个勇敢的梦啦」、`settleIntoCorner()`。
* → `.pomodoro`：`startPomodoro()`。
* → `.leisure`：停番茄钟、冒泡「我醒啦」、`stateUntil = Date()` 立刻恢复自由行为。

最后无条件调 `configureReminder()`：休息提醒只伺候工作模式，切入工作从头计时，切走停表。见[休息提醒与电量感知](../pet/reminder-battery.md)。

# 安静期（isPeaceful）

```swift
var isPeaceful: Bool {
    switch mode {
    case .leisure: return false
    case .working: return true
    case .pomodoro: return pomodoroPhase == .focus
    }
}
```

「安静期」是全应用的行为总开关：云雀 / 蛇 / 狼彩蛋不触发、戳一戳只迷糊应一声、漫游停止、梦话与梦到妈妈原声不播放。番茄钟只有专注期算安静，休息期不安静。

# 角落归宿（settleIntoCorner）

安静期的归宿是屏幕右下角：`cornerX = visibleFrame.maxX - 窗口宽 - 30`；离角落超过 40pt 就进入 `.walkingToSleep(cornerX)`（1.2 倍速走过去，`stateUntil` 30 秒兜底），到位后 `setState(.sleeping, duration: 3600)` 长睡，由番茄钟或提醒机制接管后续。

[^mode-src]: PetViewModel+Mode.swift
[^settings-src]: Settings.swift
