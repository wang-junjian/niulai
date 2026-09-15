---
type: Module
title: PetWindowController · 牛来窗口
description: 牛来的 240×300 悬浮窗，多屏时在鼠标所在屏出生。
tags: [window, pet]
resource: ../../Sources/Niulai/Pet/PetWindowController.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: pwc-src
    resource: ../../Sources/Niulai/Pet/PetWindowController.swift
    title: PetWindowController.swift
status: stable
---

* 窗口尺寸固定 `240×300`（`windowSize`），内容由 [PetContainerView](../views/pet-container-view.md) 装配，经 [WindowFactory](../core/window-factory.md) 创建（响应鼠标，不穿透）。[^(pwc-src)]
* 出生位置：`NSEvent.mouseLocation` 找到鼠标所在屏（多屏贴心），屏幕底部居中 `y = visibleFrame.minY + 24`；找不到屏回退 1440×900。
* 创建后把窗口引用交给 `viewModel.window`——状态机所有移动 / 撞边都操作这扇窗。
* `show()` 用 `orderFrontRegardless()`，不抢焦点。

[^pwc-src]: PetWindowController.swift
