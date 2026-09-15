---
type: Playbook
title: 发布流程
description: 打 v* 标签触发 GitHub Actions：macOS 运行器打包通用二进制并自动创建 Release。
tags: [release, github-actions, playbook]
resource: ../../.github/workflows/release.yml
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: wf-src
    resource: ../../.github/workflows/release.yml
    title: release.yml
status: stable
---

# 触发方式

```bash
git tag v0.2
git push origin v0.2
```

# 流水线步骤[^(wf-src)]

`Release` workflow（`push: tags: v*`，`contents: write` 权限）：

1. `./bundle.sh "$VERSION"`（版本号从 tag 去 `v` 前缀）——即[打包与签名](bundle-and-sign.md)的全过程，在 `macos-latest` 运行器上完成。
2. `ditto -c -k --keepParent Niulai.app "Niulai-v0.2-macOS.zip"` 压缩，`shasum -a 256` 打印校验和。
3. `gh release create "$GITHUB_REF_NAME"` 上传 zip，`--generate-notes` 自动生成更新说明。

产物为 `Niulai-vX.Y-macOS.zip`（Apple Silicon + Intel 通用），用户下载解压后按 Gatekeeper 放行步骤安装。

[^wf-src]: release.yml
