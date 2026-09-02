import AppKit
import SwiftUI

/// 牛来的家：一个无边框、透明、悬浮在所有窗口之上的 NSWindow。
/// 点击穿透交给 SwiftUI 手势处理，窗口本身不接受焦点。
@MainActor
final class PetWindowController {

    static let windowSize = NSSize(width: 240, height: 300)

    private let window: NSWindow

    init(viewModel: PetViewModel) {
        // 在鼠标所在的屏幕上出生，多屏时更贴心
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        let screenFrame = screen?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(
            x: screenFrame.midX - Self.windowSize.width / 2,
            y: screenFrame.minY + 24
        )

        window = WindowFactory.makeFloatingWindow(
            size: Self.windowSize,
            origin: origin,
            rootView: PetContainerView(viewModel: viewModel)
        )

        viewModel.window = window
    }

    func show() {
        window.orderFrontRegardless()
    }
}
