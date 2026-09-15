---
type: Module
title: 休息提醒与电量感知（PetViewModel+Reminder）
description: 工作模式的分钟级休息提醒（走到屏幕中间）与 IOKit 电量彩蛋。
tags: [reminder, battery, pet]
resource: ../../Sources/Niulai/Pet/PetViewModel+Reminder.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: reminder-src
    resource: ../../Sources/Niulai/Pet/PetViewModel+Reminder.swift
    title: PetViewModel+Reminder.swift
  - id: settings-src
    resource: ../../Sources/Niulai/Settings.swift
    title: Settings.swift（reminderMinutes）
status: stable
---

# 休息提醒

* 只伺候工作模式：`reminderMinutes > 0 && mode == .working` 才建定时器；番茄钟有自己的节奏、休闲本来就在休息。[^(reminder-src)]
* 每次调用 `configureReminder()` 都**从头计时**（销毁重建 [reminderTicker](../core/frame-ticker.md)）——改设置、切入工作模式都会重置。
* 到点 `beginReminder()`：先把 `nextReminderAt` 推进下一轮（提醒完自动续），再双保险校验（仍是工作模式、可见、未被拎）后 `walkingTo(屏幕中线)`，20s 走不到就放弃。
* 走到位（主循环检测距目标 <24px）调 `arriveAtReminderSpot()`：开心 2.5s + 随机[提醒台词](pet-phrases.md)持续 6s。
* 菜单选项：关闭 / 30 / 45 / 60 分钟（[menuBarContentView](../views/menu-bar-content-view.md) Picker → `onChange` 调 `configureReminder()`）。

# 电量感知

30s 一次的 [batteryTicker](../core/frame-ticker.md) 调 `checkBattery()`：[^(reminder-src)]

* **插电瞬间**（charging 从 false 变 true）：开心 +「来电啦！⚡ 满血复活！」。
* **低电**（≤20% 且未充电且未警告过）：提醒「你快没电了……我也饿得没力气了……记得充电」，非安静期且不忙时坐下 60s 装没精神；电量回升 >30% 才解除 `lowBatteryWarned`，避免反复弹。

# 读电池

`readBattery()` 走 IOKit（`IOPSCopyPowerSourcesInfo` 等 C API），校验 `kIOPSInternalBatteryType`——台式机（Mac mini / Studio）无内置电池返回 nil，静默跳过。

[^reminder-src]: PetViewModel+Reminder.swift
[^settings-src]: Settings.swift（reminderMinutes）
