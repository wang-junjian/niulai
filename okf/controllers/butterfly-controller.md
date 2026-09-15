---
type: Component
title: ButterflyController · 蝴蝶
description: 慢悠悠掠过的小蝴蝶，被追加速、被扑全速逃走；翻飞与逃逸逻辑实现于 ScreenCrosser hook。
tags: [butterfly, controller, chase]
resource: ../../Sources/Niulai/Controllers/ButterflyController.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: bfly-src
    resource: ../../Sources/Niulai/Controllers/ButterflyController.swift
    title: ButterflyController.swift
  - id: bfly-view
    resource: ../../Sources/Niulai/Views/ButterflyView.swift
    title: ButterflyView.swift（分层翅膀）
  - id: vm-src
    resource: ../../Sources/Niulai/Pet/PetViewModel.swift
    title: PetViewModel（追蝴蝶主循环）
status: stable
---

# 速度体系[^(bfly-src)]

| 状态 | 速度 | 说明 |
|------|------|------|
| `cruiseSpeed` | 65 px/s | 巡航翻飞 |
| `chasedSpeed` | 180 px/s | 被追时——相对牛来（追速约 121）每秒拉开约 60px，几秒内甩掉 |
| `escapeSpeed` | 260 px/s | 被扑后的全力逃走，全场最快 |

几何参照传 `referenceWindow: pet?.window`（跟随牛来所在屏）。`panicked` 计算属性：被牛来盯上（还没被扑）时眼睛紧张、瞳孔收缩后瞟。

# 出场与 hook

* `canStart()`：要求牛来可见、非安静期——蝴蝶只在牛来能互动时出场。
* `onWillStart`：每次出场从 `schemes` 随机选一种配色（主色 / 中间色带 / 眼斑芯 / 远翅深色四元组，共 5 套：天蓝粉带、明黄橘带、薄荷黄带、粉红杏带、紫罗兰粉带），重置逃逸标志与「只被扑一次」标记。
* `updatePosition`：巡航时正弦起伏翻飞；`escaping` 后加速往上逃。
* `afterMove`：牛来进入触发距离回调 `pet.startChasingButterfly()`；快到屏幕边且正在被追回调 `pet.pounceAtButterfly()`（一次飞行各限一次的判定在 hook 内）。
* 追 / 扑的牛来侧状态推进在[核心状态机](../pet/pet-view-model.md)的 `chasing` / `pouncing` 分支。[^(vm-src)]

`size: 110×95`；分层翅膀 + 随机配色绘制见 [ButterflyView](../views/drawing-conventions.md)。[^(bfly-view)]

[^bfly-src]: ButterflyController.swift
[^bfly-view]: ButterflyView.swift（分层翅膀）
[^vm-src]: PetViewModel（追蝴蝶主循环）
