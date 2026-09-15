---
type: Reference
title: release.yml · 发布流水线
description: v* 标签触发的 GitHub Actions 工作流原文位置与权限说明。
tags: [ci, github-actions, reference]
resource: ../../.github/workflows/release.yml
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: wf-src
    resource: ../../.github/workflows/release.yml
    title: release.yml
status: stable
---

文件位置 `.github/workflows/release.yml`，name 为 `Release`。要点：触发 `push: tags: v*`；`permissions: contents: write` 允许 GITHUB_TOKEN 创建 Release；单 job 单 runner（macos-latest）三步打包（详见[发布流程](../playbooks/release-process.md)的操作视角）。[^(wf-src)]

[^wf-src]: release.yml
