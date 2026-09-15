---
type: Component
title: LarkController · 云雀
description: 翅膀受伤、飞得慢的云雀，每隔几分钟飞过一次，30% 概率落在牛来头顶歇脚 20~60 秒。
tags: [lark, controller, perch]
resource: ../../Sources/Niulai/Controllers/LarkController.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: lark-src
    resource: ../../Sources/Niulai/Controllers/LarkController.swift
    title: LarkController.swift
status: stable
---

# 调度（独立于基类的 eventTicker）

自带 `scheduleNext(after:)`（`Timer` 加进 RunLoop `.common`，菜单打开也照常走）：首飞 3~8 分钟（demo 5 秒），飞完 `onDidExit` 排下一班 3~8 分钟（demo 30 秒）。[^(lark-src)]

`beginFlight()` 前置：非安静期（安静期 2~4 分钟后再来）、牛来可见。飞行高度随机取屏幕高度的 40%~70%，`flySpeed: 85`（翅膀受过伤）。

# 歇脚子状态机（覆写 updatePosition）

1. `onWillStart`：掷签 `willPerch`（30%，demo 必中），`perched = false`。
2. 飞行中若 `willPerch` 且接近「歇脚位」——牛来窗口顶部偏前（`midX - width/2`，`maxY - 40`）——落定：`perched = true`，`perchUntil = now + 20~60s`。
3. `perched` 期间每帧把窗口原点吸附到牛来头顶（跟着牛来走，牛来被拎走也跟着）。
4. 到点起飞，`willPerch = false`——**不再回头落第二次**。
5. 出屏 `onDidExit` 排下一班。

发布属性 `perched` 供 [LarkView](../views/drawing-conventions.md) 切换收翅姿势。

[^lark-src]: LarkController.swift
