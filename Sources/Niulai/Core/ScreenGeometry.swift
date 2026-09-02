import AppKit

/// 屏幕几何工具。
enum ScreenGeometry {
    /// 窗口所在屏的 visibleFrame 回退链：窗口屏 → 主屏 → fallback。
    /// fallback 由各调用方保持现状差异：PetViewModel 用 1440×900 兜底
    /// （锁屏/显示睡眠时 NSScreen 可能返回垃圾坐标，牛来仍需落在合理位置），
    /// 其余角色用 .zero（横穿出屏判定直接放行）。
    @MainActor
    static func visibleFrame(of window: NSWindow?, fallback: NSRect = .zero) -> NSRect {
        window?.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? fallback
    }
}
