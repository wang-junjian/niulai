---
type: Component
title: SnakeController · 青蛇
description: 贴地蜿蜒爬过屏幕的青蛇，纯视觉威胁；移动骨架在基类，本类只剩速度和外壳。
tags: [snake, controller, easter-egg]
resource: ../../Sources/Niulai/Controllers/SnakeController.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: snake-src
    resource: ../../Sources/Niulai/Controllers/SnakeController.swift
    title: SnakeController.swift
  - id: snake-view
    resource: ../../Sources/Niulai/Views/SnakeView.swift
    title: SnakeView.swift（蜿蜒动画）
  - id: events-src
    resource: ../../Sources/Niulai/Pet/PetViewModel+Events.swift
    title: 彩蛋调度（触发与牛来反应）
status: stable
---

* `size: 170×70`，`speed: 110` px/s 贴地直线移动——**蜿蜒起伏的动画完全在 [SnakeView](../views/drawing-conventions.md) 绘制层**（脊线波浪 + 吐信子），控制器只推窗口。[^(snake-src)]
* `slitherAcross(fromLeft:groundY:)` 薄封装调 `startCrossing`。
* 由[彩蛋调度](../pet/events-scheduler.md)触发：牛来 `startled` 2s，蛇出屏后松口气；与狼互斥。[^(events-src)]
* 绘制见 [SnakeView](../views/drawing-conventions.md)。

[^snake-src]: SnakeController.swift
[^snake-view]: SnakeView.swift（蜿蜒动画）
[^events-src]: 彩蛋调度（触发与牛来反应）
