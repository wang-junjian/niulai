---
type: Asset
title: 音频资产
description: 两段电影原声 mp3——「妈妈」与「牛来」呼唤——的存放位置、打包链路与使用场景。
tags: [audio, assets]
resource: ../../Sources/Niulai/Resources/
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: player-src
    resource: ../../Sources/Niulai/Core/SoundPlayer.swift
    title: SoundPlayer.swift（常量与播放）
  - id: bundle-src
    resource: ../../bundle.sh
    title: bundle.sh（打包复制）
status: stable
---

# 清单

| 文件 | 常量 | 内容 | 使用场景 |
|------|------|------|----------|
| `Sources/Niulai/Resources/mama.mp3` | `SoundPlayer.mama` | 委屈的「妈妈——！」 | [开场呼唤](../pet/opening-call.md)；休闲打盹梦到妈妈的 0.3 音量呢喃 |
| `Sources/Niulai/Resources/niulai.mp3` | `SoundPlayer.niulai` | 「牛来！」呼唤 | 开场时远处妈妈的回应（0.85）；[番茄钟](../pet/pomodoro.md)阶段切换（0.8） |

# 打包链路

SwiftPM `.process("Resources")` → 构建产物 `Niulai_Niulai.bundle` → [bundle.sh](../playbooks/bundle-and-sign.md) 复制进 `Niulai.app/Contents/Resources/` → 运行时 `Bundle.module.url(forResource:)` 读取。播放与开关见 [SoundPlayer](../core/sound-player.md)。[^(player-src)] [^(bundle-src)]

[^player-src]: SoundPlayer.swift（常量与播放）
[^bundle-src]: bundle.sh（打包复制）
