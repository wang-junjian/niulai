---
type: Convention
title: Canvas 绘制约定（各角色视图共通）
description: TimelineView(.animation) + Canvas 纯函数绘制 + EyeBlink seed 错开——全部六套角色形象的统一画法。
tags: [canvas, swiftui, convention, views]
resource: ../../Sources/Niulai/Views/
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: niulai-view
    resource: ../../Sources/Niulai/Views/NiulaiView.swift
    title: NiulaiView.swift
  - id: views-dir
    resource: ../../Sources/Niulai/Views/
    title: Views 目录（全部视图源码）
status: stable
---

# 统一画法

1. **`TimelineView(.animation)` 包裹 Canvas**：每帧重绘，`context.date.timeIntervalSinceReferenceDate` 作为唯一时间输入 `t`——绘制是 `(state, t)` 的纯函数，同样的状态 + 时刻永远同一帧，无需存储动画进度。
2. **动画参数结构体**：视图内先算一个 `AnimationParams`（squash / tilt / lift / 瞳孔偏移……），再交给 Canvas 与 modifier——状态机只给离散状态，子阶段（哈欠 → 伸懒腰）按 `stateElapsed` 经过时间在参数层编排。
3. **`EyeBlink.isClosed(at:seed:)`**：各角色传不同 seed，眨眼节奏错开（见 [EyeBlink](../core/eye-blink.md)）。
4. **朝向**：`facingLeft` 用 `scaleEffect(x: -1)` 翻转实现；转圈追尾巴的快速翻转用 `spinFlip` 参数叠加。[^(niulai-view)]

# 角色视图索引[^(views-dir)]

| 视图 | 行数 | 绘制要点 |
|------|------|----------|
| `NiulaiView` | 416 | 主角，见 [NiulaiView](niulai-view.md) |
| `BaolaView` | 188 | 豹拉：黄底黑斑小豹，眼神望牛来 |
| `LarkView` | 78 | 云雀：`perched` 切换飞行 / 收翅姿势 |
| `SnakeView` | 172 | 青蛇：脊线正弦波浪 + 吐信子 |
| `WolfView` | 188 | 狼：两节腿奔驰步态 |
| `ButterflyView` | 202 | 蝴蝶：分层翅膀 + 随机配色 scheme |

[^niulai-view]: NiulaiView.swift
[^views-dir]: Views 目录（全部视图源码）
