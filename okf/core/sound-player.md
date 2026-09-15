---
type: Module
title: SoundPlayer · 音效播放
description: 两段电影原声 mp3 的播放封装，NSSound 播放期间自持有，受全局音效开关控制。
tags: [sound, core]
resource: ../../Sources/Niulai/Core/SoundPlayer.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: sound-src
    resource: ../../Sources/Niulai/Core/SoundPlayer.swift
    title: SoundPlayer.swift
  - id: assets
    resource: ../references/audio-assets.md
    title: 音频资产
status: stable
---

# 音效清单

| 常量 | 文件 | 使用场景 |
|------|------|----------|
| `SoundPlayer.mama` | `mama.mp3` | [开场呼唤](../pet/opening-call.md)的「妈妈——！」；休闲打盹梦到妈妈的低音量（0.3）呢喃 |
| `SoundPlayer.niulai` | `niulai.mp3` | 开场时远处妈妈的回应（0.85）；[番茄钟](../pet/pomodoro.md)阶段切换提示音（0.8） |

音频资源经 SwiftPM `.process("Resources")` 打进 `Bundle.module`，打包 App 时随 `Niulai_Niulai.bundle` 复制。资产细节见[音频资产](../references/audio-assets.md)。

# 播放机制

```swift
static func play(_ name: String, volume: Float = 1.0)
```

* `NSSound(contentsOf:byReference: true)` 播放期间自持有，播完自动释放，无需持有引用。
* 全局开关读 `Settings.soundEnabled`（菜单「音效」Toggle，默认开），关了静默返回。[^(sound-src)]

[^sound-src]: SoundPlayer.swift
[^assets]: 音频资产
