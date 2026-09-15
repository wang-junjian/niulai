---
type: Feature
title: 番茄钟（PetViewModel+Pomodoro）
description: 25 分钟专注 + 5 分钟休息循环，每 4 轮一次 15 分钟长休息；菜单栏阶段图标与分钟级倒计时。
tags: [pomodoro, feature, pet]
resource: ../../Sources/Niulai/Pet/PetViewModel+Pomodoro.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: pomo-src
    resource: ../../Sources/Niulai/Pet/PetViewModel+Pomodoro.swift
    title: PetViewModel+Pomodoro.swift
  - id: menu-src
    resource: ../../Sources/Niulai/Views/MenuBarContentView.swift
    title: MenuBarContentView.swift（菜单操作入口）
status: stable
---

# 参数

| 参数 | 正常 | `--demo` |
|------|------|----------|
| 专注 | 25 分钟 | 30 秒 |
| 短休息 | 5 分钟 | 15 秒 |
| 长休息（每 4 轮） | 15 分钟 | 45 秒 |

专注期牛来趴角落睡觉（安静期，`isPeaceful == true`），休息期醒来活动——豹拉随之离开 / 回归（`companion?.onPetModeChanged` 联动，见[豹拉控制器](../controllers/companion-controller.md)）。[^(pomo-src)]

# 阶段推进 advancePomodoroPhase

每次切换先播一声「牛来！」原声（0.8 音量，见[SoundPlayer](../core/sound-player.md)）：

* 专注 → 休息：`completedFocusCount += 1`，`count % 4 == 0` 走长休息；醒来先 `stretching` 伸懒腰 3s；冒泡鼓励语。
* 休息 → 专注：回角落继续做梦，「继续专注！我去梦里给你加油~」。

# 暂停与跳过

* `togglePomodoroPause()`：暂停时把剩余秒数存 `pausedRemaining`，恢复时用剩余时间重建 `phaseEndsAt`；菜单栏图标变「🐮 ⏸」。
* `skipPomodoroPhase()`：菜单「提前进入休息 / 提前开始专注」，直接 `advancePomodoroPhase()`。

# 防闪白技巧

`pomodoroTick()` 每秒跑一次，但**相同字符串不重复赋值**——`@Published` 每次赋值都触发 `objectWillChange`，菜单栏图标（🐮🍅 / 🐮☕️）和菜单内倒计时都是分钟级文本，若每秒赋值会把打开着的菜单反复重渲染导致闪白。[^(pomo-src)]

# 用户入口

菜单项见[菜单栏控制视图](../views/menu-bar-content-view.md)：阶段 + 倒计时文本、暂停 / 继续、提前切换；[专注中戳牛来](pet-view-model.md)会迷糊报时「哞……还剩 14:32」。

[^pomo-src]: PetViewModel+Pomodoro.swift
[^menu-src]: MenuBarContentView.swift（菜单操作入口）
