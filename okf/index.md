---
okf_version: "0.2"
---

# 牛来（Niulai）知识库

macOS 桌宠应用「牛来」的知识库，按 [Open Knowledge Format v0.2](https://github.com/google/open-knowledge-format) 组织：每个概念一个 markdown 文档，frontmatter 记录类型与溯源，正文记录结构化知识，概念之间用 markdown 链接连成知识图谱。

**本项目**：一只住在 macOS 桌面上的 Q 版小牛，灵感来自动画电影《牛来》。SwiftUI + AppKit 混合实现，纯代码绘制（SwiftUI Canvas），无外部素材，单 SwiftPM 模块。源码资源路径约定为仓库根目录下的 `Sources/Niulai/`。

# 总览

* [产品功能全景](overview/product-overview.md) - 桌宠「牛来」的功能清单与产品定位。
* [架构总览](overview/architecture.md) - 分层结构、驱动模型与装配流程。
* [三模式系统](overview/mode-system.md) - 休闲 / 工作 / 番茄钟的切换机制与安静期判定。

# Core（基础设施）

* [core](core/) - FrameTicker、WindowFactory、ScreenGeometry、EyeBlink、SoundPlayer 五个基础模块。

# Pet（核心状态机）

* [pet](pet/) - PetViewModel 状态机及其五个扩展、台词库、窗口控制器、用户设置。

# Controllers（角色控制器）

* [controllers](controllers/) - ScreenCrosser 基类与蛇 / 狼 / 蝴蝶 / 云雀 / 豹拉五个角色控制器。

# Views（绘制与界面）

* [views](views/) - Canvas 纯代码绘制约定与各 SwiftUI 视图。

# Playbooks（操作手册）

* [本地运行与调试](playbooks/run-and-debug.md) - swift run、--demo 模式、Xcode / VS Code 调试。
* [打包与签名](playbooks/bundle-and-sign.md) - bundle.sh 生成通用二进制 App、ad-hoc 签名、Gatekeeper 放行。
* [发布流程](playbooks/release-process.md) - 打 tag 触发 GitHub Actions 自动发布。

# References（参考资料）

* [references](references/) - Package.swift、发布流水线、音频资产。
