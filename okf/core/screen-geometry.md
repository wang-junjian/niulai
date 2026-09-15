---
type: Module
title: ScreenGeometry · 屏幕几何工具
description: visibleFrame 三级回退链，解决锁屏 / 显示睡眠时 NSScreen 返回垃圾坐标的问题。
tags: [screen, geometry, core]
resource: ../../Sources/Niulai/Core/ScreenGeometry.swift
generated: { by: workbuddy/glm-5.3, at: 2026-09-15T09:10:00Z }
sources:
  - id: geometry-src
    resource: ../../Sources/Niulai/Core/ScreenGeometry.swift
    title: ScreenGeometry.swift
status: stable
---

# 回退链

```swift
window?.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? fallback
```

窗口所在屏 → 主屏 → 调用方给的 fallback。`@MainActor` 静态方法。[^(geometry-src)]

# fallback 的调用方差异（有意为之）

* **[PetViewModel](../pet/pet-view-model.md)** 传 `1440×900`：锁屏 / 显示睡眠时 `NSScreen` 可能返回垃圾坐标，牛来仍需落在合理位置继续走。
* **其余角色**（横穿类、豹拉）用默认 `.zero`：横穿出屏判定时拿到 zero 直接判「出屏」，放行清理，不会卡死。

[^geometry-src]: ScreenGeometry.swift
