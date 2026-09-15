---
type: Base Class
title: ScreenCrosser · 横穿屏幕基类
description: 「入场 → 每帧移动 → 出屏回调」的模板方法骨架，蛇 / 狼 / 蝴蝶 / 云雀四个角色的共用父类。
tags: [template-method, base-class, controllers]
resource: ../../Sources/Niulai/Controllers/ScreenCrosser.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: crosser-src
    resource: ../../Sources/Niulai/Controllers/ScreenCrosser.swift
    title: ScreenCrosser.swift
status: stable
---

# 为什么用基类而不是协议

协议扩展给不了 `@Published` 存储属性，所以用 `@MainActor class ScreenCrosser: ObservableObject`。发布的字段：`running`（在屏上）、`facingLeft`；另有 `onExit` 一次性出屏回调（调用后自动置 nil）。[^(crosser-src)]

# 模板方法（final，不可覆写）

`startCrossing(fromLeft:groundY:referenceWindow:)` 的固定流程：

1. `canStart()` 检查（蝴蝶要求牛来在场且非安静期），false 放弃。
2. `ensureWindow()`——lazy 创建 [悬浮窗](../core/window-factory.md)，横穿类一律 `ignoresMouseEvents: true` 纯视觉不挡点击。
3. `referenceWindow` 决定几何参照（蝴蝶 / 云雀传牛来的窗口，跟随牛来所在屏）。
4. 设方向（`direction = ±1`）、`onWillStart` hook、入场原点、`running = true`、起 ticker。

每帧 `tick`：`updatePosition` hook 移动 → `setFrameOrigin` → `afterMove` hook → 出屏判定（越过 `maxX+10` 或右边界外 `minX-10`）→ `running=false`、`orderOut`、停 ticker、`onDidExit()`、触发 `onExit`。

# 子类 hook 清单

| hook | 默认实现 | 覆写者 |
|------|----------|--------|
| `canStart()` | true | 蝴蝶 |
| `onWillStart(fromLeft:groundY:)` | 空 | 蝴蝶（配色 / 逃逸标志）、云雀（歇脚意愿） |
| `startOrigin(fromLeft:vf:groundY:)` | 屏幕外贴地 | — |
| `updatePosition(dt:origin:vf:)` | 直线 `direction * speed * dt` | 蝴蝶（翻飞 / 逃逸）、云雀（歇脚跟随） |
| `afterMove(vf:)` | 空 | 蝴蝶（触发追 / 扑） |
| `onDidExit()` | 空 | 云雀（排下一班） |
| `makeContentView()` | EmptyView | 四个子类各给自己的 View |

子类只需给出 `speed` 与 `size` 即可获得直线横穿（[蛇](snake-controller.md)、[狼](wolf-controller.md)各只有十几行）。

`setVisible(_:)`：隐藏时 `orderOut`；注意云雀覆写它在恢复显示时只恢复 `running` 中的窗口。

[^crosser-src]: ScreenCrosser.swift
