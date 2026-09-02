import AppKit
import SwiftUI

/// 蛇：贴着地面蜿蜒爬过屏幕。纯视觉威胁，不响应鼠标。
/// 移动骨架在 ScreenCrosser 基类；这里只剩速度和外壳。
@MainActor
final class SnakeController: ScreenCrosser {

    override class var size: NSSize { NSSize(width: 170, height: 70) }
    override var speed: CGFloat { 110 }

    func slitherAcross(fromLeft: Bool, groundY: CGFloat) {
        startCrossing(fromLeft: fromLeft, groundY: groundY)
    }

    override func makeContentView() -> AnyView {
        AnyView(SnakeView(controller: self))
    }
}
