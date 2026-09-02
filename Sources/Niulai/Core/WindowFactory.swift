import AppKit
import SwiftUI

/// 桌宠悬浮窗工厂：无边框、透明、置顶、全空间可见。
/// 所有角色（牛来/豹拉/云雀/蛇/狼/蝴蝶）的窗口都从这里创建，配置顺序保持一致。
enum WindowFactory {
    /// - ignoresMouseEvents: 纯视觉角色（云雀/蛇/狼/蝴蝶）传 true 不挡点击；
    ///   牛来/豹拉要响应戳和拖拽，用默认 false
    @MainActor
    static func makeFloatingWindow<Content: View>(
        size: NSSize,
        origin: NSPoint = .zero,
        ignoresMouseEvents: Bool = false,
        rootView: Content
    ) -> NSWindow {
        let w = NSWindow(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.level = .floating
        w.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        w.isReleasedWhenClosed = false
        w.ignoresMouseEvents = ignoresMouseEvents
        w.contentView = NSHostingView(rootView: rootView)
        w.setContentSize(size)   // 固定尺寸，防止 SwiftUI 自适应改窗
        return w
    }
}
