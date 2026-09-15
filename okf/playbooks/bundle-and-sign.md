---
type: Playbook
title: 打包与签名
description: bundle.sh 把 SwiftPM 产物拼装成 Niulai.app：通用二进制、ad-hoc 签名、Gatekeeper 放行。
tags: [build, bundle, codesign, playbook]
resource: ../../bundle.sh
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: bundle-src
    resource: ../../bundle.sh
    title: bundle.sh
  - id: readme
    resource: ../../README.md
    title: 仓库 README
status: stable
---

# 用法

```bash
./bundle.sh [版本号]    # 例：./bundle.sh 0.2，产物 ./Niulai.app
```

# 步骤拆解[^(bundle-src)]

1. `swift build -c release --arch arm64 --arch x86_64` —— 双架构通用二进制。
2. 从 `.build/apple/Products/Release/` 取出 `Niulai` 放进 `Niulai.app/Contents/MacOS/`。
3. 复制 SwiftPM 资源包 `Niulai_Niulai.bundle`（含两段 mp3）到 `Contents/Resources/`。
4. 生成 `Info.plist`：`CFBundleIdentifier=com.niulai.desktoppet`、显示名「牛来」、**`LSUIElement=true`（无 Dock 图标）**、最低系统 14.0。
5. `codesign --force --sign -` —— ad-hoc 签名（无付费开发者证书）。

# Gatekeeper 放行（分发用户侧）

首次打开被拦，二选一：右键 App → 打开 → 再点打开；或终端 `xattr -cr Niulai.app`。[^(readme)]

# 日常使用

开机自启：系统设置 → 通用 → 登录项 → 添加 Niulai.app。Mac 上的 SwiftPM 本机编译流程无额外环境要求，见[本地运行](run-and-debug.md)。

[^bundle-src]: bundle.sh
[^readme]: 仓库 README
