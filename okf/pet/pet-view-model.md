---
type: State Machine
title: PetViewModel · 核心状态机
description: 牛来的行为大脑：15 个状态、60fps 主循环、加权随机行为池、互动响应与气泡管理。
tags: [state-machine, core-class, pet]
resource: ../../Sources/Niulai/Pet/PetViewModel.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: vm-src
    resource: ../../Sources/Niulai/Pet/PetViewModel.swift
    title: PetViewModel.swift
  - id: container-src
    resource: ../../Sources/Niulai/Views/PetContainerView.swift
    title: PetContainerView.swift（手势入口）
status: stable
---

# 发布的可见状态（@Published）

| 字段 | 含义 |
|------|------|
| `state: State` | 当前离散状态（约定仅 PetViewModel* 扩展内可写） |
| `facingLeft` | 朝向 |
| `bubbleText: String?` | 对话气泡文本 |
| `isVisible` | 显隐 |
| `pomodoroPhase` / `pomodoroCountdown` / `pomodoroPaused` / `menuBarLabel` | 番茄钟（方法在 [+Pomodoro](pomodoro.md)） |

`stateStartedAt` 记录当前状态开始时刻，`stateElapsed` 供视图按经过时间编排子阶段动画。

# State 枚举（15 态）[^(vm-src)]

`idle` 发呆 / `walking` 漫游 / `walkingTo(CGFloat)` 走向提醒点 / `walkingToSleep(CGFloat)` 走向角落 / `sitting` 坐下 / `sleeping` 打盹 / `happy` 开心短反应 / `dragged` 被拎 / `startled` 吓一跳 / `chasing` 追蝴蝶 / `pouncing` 扑蝴蝶 / `stretching` 伸懒腰 / `headbutting` 顶墙 / `spinning` 转圈追尾巴 / `dizzy` 转晕坐地。

# 跨扩展共享的存储属性（集中在主文件）

Swift 扩展不能持有存储属性，番茄钟 / 彩蛋 / 电量状态全放这里，用注释约定归属（`internal: +Xxx 写`）：`stateUntil`（状态到点时刻）、`reminderTicker` / `reminderInterval` / `nextReminderAt`、`wasCharging` / `lowBatteryWarned`、`phaseEndsAt` / `pausedRemaining` / `completedFocusCount`、`nextSnakeAt` / `nextWolfAt` / `nextButterflyAt`、`lastReactedMode`、`demoMode`（`--demo` 参数）、mamaDream 的 arm/played 标记。

# 主循环 tick(dt:)

由 60fps [FrameTicker](../core/frame-ticker.md) 驱动，顺序：

1. **模式轮询**：`mode != lastReactedMode` 则 `reactToModeChange()`（兜底外部 defaults 改动，见[三模式系统](../overview/mode-system.md)）。
2. **移动状态**：`walking`（55px/s，撞边检测含顶墙）、`walkingTo`（1.6 倍速，距目标 <24px 到达）、`walkingToSleep`（1.2 倍速）、`chasing`（2.2 倍速小跑，蝴蝶没了 / 距离 >420px 放弃；距蝴蝶 <24px 死区内不横跳防翻转闪烁）、`pouncing`（向前 35px/s 小跳）。
3. **状态到点**（`now >= stateUntil` 且非 dragged）：`sleeping` → 60% 伸懒腰（2.8s）否则 `pickNextState`；`spinning` → 坐下 3-6s；`headbutting` → `dizzy` 1.8s；`dizzy` → 掉头走路；`pouncing` → 扑空「嘿嘿……差点就抓到了」；`chasing` → `butterflyGone()`。
4. **梦到妈妈**：`mamaDreamArmed` 的觉睡过 1.2s 且气泡空闲 → 「（梦话）妈妈，快跑……」+ mama 原声 0.3 音量（一觉一次）。
5. **随机梦话**：非番茄钟睡觉时每帧 1/1200 概率冒一句[梦话](pet-phrases.md)。

# 行为决策 pickNextState

安静期（[isPeaceful](../overview/mode-system.md)）→ `settleIntoCorner()`；漫游关闭 → 坐 60s。否则按权重池加权随机：

| 状态 | idle | walking | sitting | sleeping | spinning |
|------|------|---------|---------|----------|----------|
| 权重 | 3 | 3.5 | 2 | 1 | 0.7 |

walking 持续 5-12s 随机方向；spinning 固定 1.6s；其余 4-9s。

# 移动与撞边

* `move(dx:)`：只改 x，y 恒为 `visibleFrame.minY + 24`（贴屏幕底部走）。
* `bounceOffScreenEdge(allowHeadbutt:)`：越界回弹 + 掉头；漫游中的撞边 **30% 概率**触发顶墙——低头顶 1.3s → 撞晕 `dizzy`（[NiulaiView](../views/niulai-view.md) 画螺旋眼 + 💫），50% 概率先冒「哞！这堵墙跟我较劲！」。

# 互动

* `poke()`（来自 [PetContainerView](../views/pet-container-view.md) 的点击）：番茄钟专注期不吵醒只报倒计时；工作模式睡觉报休息提醒倒计时；其他安静期迷糊应一声；休闲正常开心 1.4s + 随机[台词](pet-phrases.md)。
* `beginDrag()` / `endDrag()`：`dragged` 状态由手势驱动，放下开心落地 0.9s。
* `setVisible(_:)`：同时控制五个角色窗口显隐。
* `applyRoaming()`：关漫游坐 60s，开漫游把 `stateUntil` 置为现在立刻重新决策。

# 气泡的代数机制

`showBubble(_:duration:)` 用自增 `bubbleGeneration` 防竞态：Task 延时到期后只有 generation 仍匹配才清空 `bubbleText`——新气泡不会让旧气泡的定时器提前清掉自己。

[^vm-src]: PetViewModel.swift
[^container-src]: PetContainerView.swift（手势入口）
