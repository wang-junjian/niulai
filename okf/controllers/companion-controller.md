---
type: Component
title: CompanionController · 豹拉（跟随伙伴）
description: 豹拉的「经纪人」：管理小窗、贴身跟随牛来走位、随机客串登场与护卫姿态。不继承 ScreenCrosser。
tags: [companion, follow, guard, controllers]
resource: ../../Sources/Niulai/Controllers/CompanionController.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: comp-src
    resource: ../../Sources/Niulai/Controllers/CompanionController.swift
    title: CompanionController.swift
status: stable
---

豹拉不横穿屏幕，有自己的 60fps [FrameTicker](../core/frame-ticker.md) 跟随循环，所以不走 [ScreenCrosser](screen-crosser.md)。窗口 200×250，响应点击（[戳豹拉有专属台词](../pet/pet-phrases.md)）。[^(comp-src)]

# 登场 / 离场

* **随机客串**：牛来每次开始散步回调 `onPetStartedWalking()`，「常伴」开着必登场，否则 30% 概率；从牛来前进方向的**反侧**屏幕边缘跑进来。
* **常伴模式**（`Settings.baolaAlways`，默认开）：菜单 Toggle / 模式变化 / 牛来重新显示（`setVisible`，且非安静期）都会拉它回来——「朋友就该贴身挨着走」。
* **离开**：牛来睡着非常伴模式 60% 概率悄悄走；切工作 / 番茄钟专注则道别「你忙吧，我改天再来找牛来玩~」。离场是走向最近屏幕边缘（320px/s），出界才真正消失。

# 跟随主循环

* **目标位**：护卫位优先，否则牛来身后一个身位——窗口重叠 110pt：两边画布边缘都是透明留白，视觉上刚好贴身。
* **迟滞防抖**：距离 >12pt 才起跟、<4pt 才停，避免阈值附近来回切换。
* **比例速度**：`min(340, max(30, |dx| * 4))`——离得远跑得快，接近时平滑减速到与牛来同速。
* **垂直平滑跟随**：`origin.y += (目标 y - 当前 y) * min(1, 6*dt)`，牛来被拎到别处时跟上去。
* 静止时**镜像状态**：牛来坐 / 睡 / 开心则豹拉同款姿势，护卫时保持警觉弹跳（`.happy`），被戳或牛来吓一跳有 1.4~1.6s 反应期原地不动。

# 护卫（狼影事件）

`guardAgainst(fromLeft:)` 设定 `guardTargetX`：狼从左来挡牛来左侧（`minX - width - 4`），从右来挡右侧（`maxX + 4`），冒「嗷呜！！有我在，别怕！」；狼出屏 `endGuard()` 清除。联动编排见[彩蛋调度](../pet/events-scheduler.md)。

[^comp-src]: CompanionController.swift
