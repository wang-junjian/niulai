---
type: Module
title: EyeBlink · 确定性伪随机眨眼
description: 纯函数按时间戳重放眨眼序列，各角色 seed 错开，避免四个角色齐刷刷一起眨。
tags: [animation, randomness, core]
resource: ../../Sources/Niulai/Core/EyeBlink.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: blink-src
    resource: ../../Sources/Niulai/Core/EyeBlink.swift
    title: EyeBlink.swift
  - id: views-dir
    resource: ../../Sources/Niulai/Views/
    title: Views 目录（各角色调用）
status: stable
---

# 接口

`enum EyeBlink` 唯一入口：`static func isClosed(at t: TimeInterval, seed: UInt32) -> Bool`。传入 `timeIntervalSinceReferenceDate` 与角色专属 seed，返回此刻眼睛是否闭着。[^(blink-src)]

# 为什么是确定性重放而不是随机数

* **纯函数**：同一 `(t, seed)` 永远同一结果——Canvas 每帧重绘时不需要存储任何动画状态，也天然支持任意时刻「跳帧」。
* **seed 错开**：牛来 / 豹拉 / 云雀 / 蝴蝶各传不同 seed，眨眼节奏互不同步。

# 算法细节

* 时间基数太大（上亿秒），先 `t % 7200`（两小时周期）截断再重放，控制循环规模。
* 序列由 LCG 伪随机驱动：`k = k &* 1664525 &+ 1013904223`，初值 `seed &* 2654435761 &+ 1`。
* 眨眼间隔：`2.5 ~ 6.0s` 均匀分布；每次眨眼闭眼 `0.12s`。
* 约 **1/5 概率**在 `0.36 ~ 0.48s` 后连眨第二下（双眨），让节奏更自然。

调用方为各角色视图的绘制函数，见[绘制约定](../views/drawing-conventions.md)。[^(views-dir)]

[^blink-src]: EyeBlink.swift
[^views-dir]: Views 目录（各角色调用）
