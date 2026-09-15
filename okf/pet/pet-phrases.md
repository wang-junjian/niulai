---
type: Content Library
title: 台词库（PetPhrases）
description: 牛来的四组台词与豹拉的戳一戳台词，取材电影情节。
tags: [content, phrases, pet]
resource: ../../Sources/Niulai/Pet/PetPhrases.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: phrases-src
    resource: ../../Sources/Niulai/Pet/PetPhrases.swift
    title: PetPhrases.swift
  - id: companion-src
    resource: ../../Sources/Niulai/Controllers/CompanionController.swift
    title: CompanionController.swift（豹拉台词）
status: stable
---

台词以 `nonisolated static let` 存于 extension，调用点写 `Self.xxxPhrases` 不变。四组：[^(phrases-src)]

| 组 | 条数 | 使用场景 |
|----|------|----------|
| `pokePhrases` | 10 | 休闲被戳。含电影梗：「七天站不起来就会被抛弃……但我做到了！」「牛二，我不怕你。」「豹拉才不是野兽，它是我最好的朋友！」 |
| `dreamPhrases` | 5 | 打盹随机梦话，均带「（梦话）」前缀 |
| `workingPokePhrases` | 4 | 安静期被戳，迷糊应一声（「（迷迷糊糊）哞……我再睡会儿」） |
| `reminderPhrases` | 4 | 休息提醒走到屏幕中间时 |

另有散落在各处的情境台词：蛇 / 狼事件前后（[+Events](events-scheduler.md)）、顶墙 / 扑空（主文件）、番茄钟阶段切换（[+Pomodoro](pomodoro.md)）；豹拉自己的 `pokePhrases`（5 条，「嗷呜~」「别告诉别人我在这儿」）在 [CompanionController](../controllers/companion-controller.md)。[^(companion-src)]

[^phrases-src]: PetPhrases.swift
[^companion-src]: CompanionController.swift（豹拉台词）
