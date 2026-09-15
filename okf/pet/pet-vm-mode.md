---
type: Module
title: PetViewModel+Mode · 模式切换扩展
description: mode 计算属性背书 UserDefaults、reactToModeChange 分支、isPeaceful 与 settleIntoCorner。
tags: [mode, extension, pet]
resource: ../../Sources/Niulai/Pet/PetViewModel+Mode.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: mode-src
    resource: ../../Sources/Niulai/Pet/PetViewModel+Mode.swift
    title: PetViewModel+Mode.swift
status: stable
---

机制细节已沉淀在[三模式系统](../overview/mode-system.md)（含切换分支表、isPeaceful 定义、角落归宿公式），本文件是唯一实现处。

要点备忘：

* `mode` 用计算属性直接读写 [Settings.petMode](settings.md)，setter 手动 `objectWillChange.send()`——规避 `@Published` 在 `nonisolated init` 中的隔离问题。
* `reactToModeChange()` 是 internal，除了 setter，主循环 [tick](pet-view-model.md) 的轮询兜底也会调用。
* 切模式最后统一 `configureReminder()`：提醒只伺候工作模式，切入从头计时。

[^mode-src]: PetViewModel+Mode.swift
