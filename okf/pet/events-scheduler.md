---
type: Module
title: 彩蛋事件调度（PetViewModel+Events）
description: 蛇 / 狼影 / 蝴蝶的随机出场调度、蛇狼互斥、忙碌延后与追蝴蝶回调。
tags: [events, easter-egg, pet]
resource: ../../Sources/Niulai/Pet/PetViewModel+Events.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: events-src
    resource: ../../Sources/Niulai/Pet/PetViewModel+Events.swift
    title: PetViewModel+Events.swift
status: stable
---

# 出场间隔

由 5s 的 [eventTicker](../core/frame-ticker.md) 轮询 `checkEvents()`，到点即触发（均随机区间，秒）：[^(events-src)]

| 事件 | 正常 | `--demo` |
|------|------|----------|
| 蛇（`nextSnakeAt`） | 300~900 | 8 |
| 蝴蝶（`nextButterflyAt`） | 240~720 | 15 |
| 狼（`nextWolfAt`） | 600~1500 | 30 |

# 触发前置条件

* 非安静期（`isPeaceful`）且牛来可见，否则直接跳过本次轮询。
* `isBusyForEvent`：被拎 / 惊吓 / 走向某点 / 开心 / 追扑蝴蝶 / 伸懒腰 / 顶墙 / 转圈 / 晕——忙碌中所有事件延后 20 秒重试。
* **蛇狼互斥**：狼在屏上则蛇延后 20 秒，反之亦然（`wolf?.running` / `snake?.running` 互查）。

# 事件编排

* **蛇**：`snake.slitherAcross` 入场 → 牛来 `startled` 2.0s +「蛇……蛇！！」→ 豹拉陪着吓一跳（`onPetStartled`）→ 蛇出屏 `onExit` 回调 →「呼……爬走了爬走了，我不怕」。
* **狼**：`wolf.runAcross` 入场 → `startled` 2.2s +「狼……狼！！」→ 豹拉在场则 `guardAgainst` 冲到牛来与狼之间护卫（「嗷呜！！有我在，别怕！」）→ 狼出屏 → `endGuard()`，按豹拉是否在场说「豹拉……谢谢你保护我」或「呼……它跑掉了」。
* **蝴蝶**：`butterfly.flyAcross(fromLeft:groundY:)` 入场；追 / 扑由蝴蝶的 hook 反向回调牛来（见[蝴蝶控制器](../controllers/butterfly-controller.md)）。

# 追蝴蝶回调（牛来侧）

* `startChasingButterfly()`：`chasing` 16s 兜底（正常由甩开距离 420px 结束）。
* `pounceAtButterfly()`：蝴蝶快到屏幕边时 `pouncing` 0.9s。
* `butterflyGone()`：追丢 / 扑空的收尾台词。

`onExit` 回调经 `MainActor.assumeIsolated` 回主线程。

[^events-src]: PetViewModel+Events.swift
