---
type: View
title: SpeechBubbleView · 对话气泡
description: 牛来与豹拉共用的头顶气泡：奶黄圆角卡片 + 指向头部的小尾巴，弹簧缩放转场。
tags: [view, bubble, ui]
resource: ../../Sources/Niulai/Views/SpeechBubbleView.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: bubble-src
    resource: ../../Sources/Niulai/Views/SpeechBubbleView.swift
    title: SpeechBubbleView.swift
  - id: comp-src
    resource: ../../Sources/Niulai/Controllers/CompanionController.swift
    title: CompanionController（豹拉复用）
status: stable
---

* 纯展示组件：`text: String?`，nil 时不占视觉；13pt 深棕文字，最多 3 行，居中。[^(bubble-src)]
* 底色奶黄 `(1.0, 0.98, 0.92)`，圆角 14 + 轻投影；`BubbleTail` 自定义 Shape 画小三角，`offset(x: 40)` 指向牛来的头。
* 转场：`scale(0.5, anchor: .bottom)` + `opacity`，spring（response 0.3, damping 0.7）。
* 文本内容与显隐时长由各处的 `showBubble` 控制（[牛来](../pet/pet-view-model.md)与[豹拉](../controllers/companion-controller.md)各有一套 generation 防竞态机制）；豹拉窗口复用同一视图。

[^bubble-src]: SpeechBubbleView.swift
[^comp-src]: CompanionController（豹拉复用）
