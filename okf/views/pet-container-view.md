---
type: View
title: PetContainerView · 手势与布局容器
description: 牛来的手势装配层：点击 = 戳，拖拽 = 拎起移动窗口；气泡悬浮头顶不参与布局。
tags: [gesture, view, pet]
resource: ../../Sources/Niulai/Views/PetContainerView.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: container-src
    resource: ../../Sources/Niulai/Views/PetContainerView.swift
    title: PetContainerView.swift
  - id: vm-src
    resource: ../../Sources/Niulai/Pet/PetViewModel.swift
    title: PetViewModel（poke / beginDrag / endDrag）
status: stable
---

布局三层（自下而上）：[NiulaiView](niulai-view.md)（240×230，锚底）→ `.frame(240×300, alignment: .bottom)` → `.overlay(alignment: .top)` 放[气泡](speech-bubble-view.md)。[^(container-src)]

# 手势

* **点击** `onTapGesture` → `viewModel.poke()`（分支逻辑见[核心状态机](../pet/pet-view-model.md)）。
* **拖拽** `DragGesture(minimumDistance: 3)`：`onChanged` 里把窗口 origin 设为鼠标位置减去 `grabOffset`（按下时记录的抓取偏移），并 `beginDrag()`；`onEnded` → `endDrag()` 开心落地。直接改 `NSWindow.setFrameOrigin`，不走状态机移动逻辑。
* 气泡 `allowsHitTesting(false)`——出现 / 消失时牛来原地不动，也不挡手势。

[^container-src]: PetContainerView.swift
[^vm-src]: PetViewModel（poke / beginDrag / endDrag）
