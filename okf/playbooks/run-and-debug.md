---
type: Playbook
title: 本地运行与调试
description: 用 swift run / Xcode / VS Code 运行牛来，--demo 参数快速触发彩蛋。
tags: [dev, debug, playbook]
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: readme
    resource: ../../README.md
    title: 仓库 README
  - id: launch-src
    resource: ../../.vscode/launch.json
    title: VS Code 调试配置
status: stable
---

# SwiftPM 命令行

```bash
swift run Niulai                 # debug 运行
swift run Niulai --demo          # 演示节奏（彩蛋 / 番茄钟加速）
swift build -c release           # release 编译
```

# Xcode

打开根目录 `Package.swift` 即可开发调试。[^(readme)]

# VS Code

`.vscode/launch.json` 预置 Debug / Release 两个配置（swift 扩展，preLaunchTask 自动构建）。[^(launch-src)]

# --demo 加速节奏

详见[产品全景](../overview/product-overview.md)：8s 蛇 / 15s 蝴蝶 / 30s 狼、番茄钟 30+15s、云雀 5s 必歇脚。`demoMode` 是 `CommandLine.arguments.contains("--demo")`，读一次全局生效（[状态机](../pet/pet-view-model.md)与[云雀](../controllers/lark-controller.md)各读各的）。

# 调试技巧

* 模式可以用外部命令改：`defaults write com.niulai.desktoppet petMode pomodoro`——主循环轮询兜底保证生效（见[三模式系统](../overview/mode-system.md)）。注意 `swift run` 未打包时 bundle id 不同，直接跑起来用菜单切换最简单。
* 菜单打开时定时器不暂停：[FrameTicker](../core/frame-ticker.md) 把 Timer 加在 RunLoop `.common` 上，调试彩蛋时可以开着菜单观察。

[^readme]: 仓库 README
[^launch-src]: VS Code 调试配置
