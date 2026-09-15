---
type: View
title: NiulaiView · 主角牛来的绘制
description: SwiftUI Canvas 纯代码绘制的电影直立版小牛——正面视角、橙黄身体、灰白大嘴套、丧萌表情。
tags: [canvas, pet, view]
resource: ../../Sources/Niulai/Views/NiulaiView.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: niulai-view
    resource: ../../Sources/Niulai/Views/NiulaiView.swift
    title: NiulaiView.swift
  - id: container-src
    resource: ../../Sources/Niulai/Views/PetContainerView.swift
    title: PetContainerView.swift（承载与手势）
status: stable
---

共通画法见[绘制约定](drawing-conventions.md)。本视图的独有点：[^(niulai-view)]

* **形象**：电影直立版——正面视角、橙黄身体、标志性灰白大嘴套、细眉耷拉眼的丧萌表情。全部 `Canvas` path 手绘，无图片素材。
* **`AnimationParams`**：按 15 个 [State](../pet/pet-view-model.md) 逐个编排（squashX/Y 挤压拉伸、tilt/lean 倾斜、buttLunge 起跳冲量、lift、spinFlip……），`chasing` / `walking` 等运动状态叠加步伐摆动。
* **瞳孔**：`pupilOffset()` 按状态决定视线——追蝴蝶盯着蝴蝶、被拎看鼠标（`NSEvent.mouseLocation` 换算）、`idle` 偷瞟鼠标、走路看前方。
* **状态徽标**：`sleeping` 头顶漂浮 💤（正弦浮动 + 半透明），`dizzy` 头顶 💫。
* **容器**：画布 240×230，锚定在 240×300 窗口底部（上方 70pt 留给[气泡](speech-bubble-view.md)）。

[^niulai-view]: NiulaiView.swift
[^container-src]: PetContainerView.swift（承载与手势）
