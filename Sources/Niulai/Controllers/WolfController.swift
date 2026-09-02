import AppKit
import SwiftUI

/// 狼影：贴着地面飞奔横穿屏幕的狼。纯视觉威胁，不响应鼠标。
/// 移动骨架在 ScreenCrosser 基类；这里只剩速度和外壳。
@MainActor
final class WolfController: ScreenCrosser {

    override class var size: NSSize { NSSize(width: 170, height: 95) }
    override var speed: CGFloat { 300 }

    func runAcross(fromLeft: Bool, groundY: CGFloat) {
        startCrossing(fromLeft: fromLeft, groundY: groundY)
    }

    override func makeContentView() -> AnyView {
        AnyView(WolfView(controller: self))
    }
}
