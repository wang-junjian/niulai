---
type: Module
title: FrameTicker · 定频回调器
description: 封装 Timer + RunLoop .common + dt 封顶 + MainActor 样板，全应用唯一的定时驱动设施。
tags: [timer, animation, core]
resource: ../../Sources/Niulai/Core/FrameTicker.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: ticker-src
    resource: ../../Sources/Niulai/Core/FrameTicker.swift
    title: FrameTicker.swift
status: stable
---

# 职责

`@MainActor final class FrameTicker`：把 `Timer` 的四件样板事封装掉——

1. **RunLoop `.common` 模式**：菜单打开期间也保持运行（默认 mode 会被菜单拖住暂停）。
2. **dt 封顶**：`min(dt, 0.1)`，断点续跑 / 卡顿后不补帧瞬移。
3. **MainActor 桥接**：Timer 闭包内 `MainActor.assumeIsolated`。
4. **start 可重入**：先 `stop()` 再重建，重置 `lastTick` 保证首帧 dt 不补帧。

# 使用约定

```swift
private lazy var ticker = FrameTicker { [weak self] dt in self?.tick(dt: dt) }
ticker.start()   // 重复调用安全
ticker.stop()
```

handler 参数 `dt: CGFloat` 是距上一帧的秒数，供速度积分用。

# 全应用的 ticker 清单[^(ticker-src)]

| 持有者 | interval | 用途 |
|--------|----------|------|
| [PetViewModel.ticker](../pet/pet-view-model.md) | 1/60 | 主循环：状态推进 / 移动 |
| [PetViewModel.eventTicker](../pet/events-scheduler.md) | 5s | 彩蛋事件轮询 |
| [PetViewModel.pomodoroTicker](../pet/pomodoro.md) | 1s | 番茄钟倒计时 |
| [PetViewModel.batteryTicker](../pet/reminder-battery.md) | 30s | 电量感知 |
| [PetViewModel.reminderTicker](../pet/reminder-battery.md) | 分钟级 | 休息提醒（每次 configureReminder 重建） |
| [ScreenCrosser.ticker](../controllers/screen-crosser.md) | 1/60 | 横穿角色每帧移动 |
| [CompanionController.ticker](../controllers/companion-controller.md) | 1/60 | 豹拉跟随走位 |

注意与绘制的分工：FrameTicker 驱动**逻辑状态**，[TimelineView(.animation)](../views/drawing-conventions.md) 驱动**每帧绘制**，两者频率都是 60 但互不依赖。

[^ticker-src]: FrameTicker.swift
