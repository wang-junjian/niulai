---
type: Module
title: 开场呼唤（PetViewModel+Opening）
description: 启动即演的电影名场面：「妈妈——！」字幕加原声，三秒后远处传来「牛来——！」只闻其声。
tags: [opening, easter-egg, pet]
resource: ../../Sources/Niulai/Pet/PetViewModel+Opening.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: opening-src
    resource: ../../Sources/Niulai/Pet/PetViewModel+Opening.swift
    title: PetViewModel+Opening.swift
status: stable
---

# 时序编排

源自电影名场面——小牛被蛇咬伤，受惊拖着长音委屈大喊，妈妈闻声回应。启动时 `start()` 末尾调 `openingCall()`：[^(opening-src)]

1. `showBubble("妈妈——！", duration: 3.2)` + `SoundPlayer.play(mama)`（满音量，字幕 + 原声）。
2. `Task.sleep(3s)` 停一拍（期间取消或隐藏则不再回应）。
3. `SoundPlayer.play(niulai, volume: 0.85)`——远处牛妈妈焦急的回应，**只闻其声，不出字幕**。

前置条件 `isVisible`；声音素材见[音频资产](../references/audio-assets.md)。

[^opening-src]: PetViewModel+Opening.swift
