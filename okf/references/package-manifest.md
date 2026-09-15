---
type: Reference
title: Package.swift · 构建清单
description: SwiftPM 单可执行目标，macOS 14+，Resources 目录经 .process 打进 Bundle.module。
tags: [swiftpm, build, reference]
resource: ../../Package.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: pkg-src
    resource: ../../Package.swift
    title: Package.swift
status: stable
---

* `swift-tools-version: 5.9`，平台 `.macOS(.v14)`——菜单栏 `MenuBarExtra` 与部分 SwiftUI API 的版本下限。[^(pkg-src)]
* 单个 `.executableTarget(name: "Niulai", path: "Sources/Niulai")`，无第三方依赖——全应用零依赖。
* `resources: [.process("Resources")]`：mp3 音频按规则处理进运行时 `Bundle.module`（构建产物名 `Niulai_Niulai.bundle`，[打包脚本](../playbooks/bundle-and-sign.md)会把它复制进 App）。

[^pkg-src]: Package.swift
