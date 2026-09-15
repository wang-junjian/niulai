---
type: Component
title: WolfController · 狼影
description: 贴地飞奔横穿屏幕的灰狼，全场速度最快的地面角色，触发豹拉护卫联动。
tags: [wolf, controller, easter-egg]
resource: ../../Sources/Niulai/Controllers/WolfController.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: wolf-src
    resource: ../../Sources/Niulai/Controllers/WolfController.swift
    title: WolfController.swift
  - id: wolf-view
    resource: ../../Sources/Niulai/Views/WolfView.swift
    title: WolfView.swift（奔驰步态）
  - id: events-src
    resource: ../../Sources/Niulai/Pet/PetViewModel+Events.swift
    title: 彩蛋调度（护卫联动）
status: stable
---

* `size: 170×95`，`speed: 300` px/s 飞奔——比牛来追蝴蝶的 121px/s 快得多，纯威胁不可追。[^(wolf-src)]
* `runAcross(fromLeft:groundY:)` 薄封装。
* 联动链：触发 → 牛来 `startled` 2.2s → 豹拉在场则 `guardAgainst(fromLeft:)` 冲到牛来与狼之间（护卫位见[豹拉控制器](companion-controller.md)）→ 狼出屏 `onExit` → `endGuard()` + 道谢 / 自我安慰台词。[^(events-src)]
* 两节腿奔驰步态在 [WolfView](../views/drawing-conventions.md) 绘制层。

[^wolf-src]: WolfController.swift
[^wolf-view]: WolfView.swift（奔驰步态）
[^events-src]: 彩蛋调度（护卫联动）
