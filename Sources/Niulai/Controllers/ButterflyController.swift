import AppKit
import SwiftUI

/// 小蝴蝶：慢悠悠掠过屏幕。牛来注意到会小跑着追，快飞出屏幕时
/// 跳起来扑——多半扑空，蝴蝶加速往上逃走。纯视觉，不响应鼠标。
/// 移动骨架在 ScreenCrosser 基类；这里实现翻飞/逃逸/追扑触发的 hook。
@MainActor
final class ButterflyController: ScreenCrosser {

    @Published private(set) var scheme = ButterflyController.schemes[0]

    /// 翅膀配色方案：主色 / 中间色带 / 眼斑芯 / 远翅深色
    struct ButterflyScheme {
        let wing: Color
        let band: Color
        let spot: Color
        let far: Color
    }

    /// 每次出场随机选一种配色
    nonisolated static let schemes: [ButterflyScheme] = [
        ButterflyScheme(wing: Color(red: 0.36, green: 0.68, blue: 0.94),   // 天蓝粉带
                        band: Color(red: 0.90, green: 0.60, blue: 0.88),
                        spot: Color(red: 0.30, green: 0.70, blue: 0.35),
                        far:  Color(red: 0.28, green: 0.55, blue: 0.82)),
        ButterflyScheme(wing: Color(red: 0.98, green: 0.80, blue: 0.30),   // 明黄橘带
                        band: Color(red: 0.96, green: 0.55, blue: 0.30),
                        spot: Color(red: 0.70, green: 0.35, blue: 0.60),
                        far:  Color(red: 0.88, green: 0.68, blue: 0.22)),
        ButterflyScheme(wing: Color(red: 0.50, green: 0.85, blue: 0.62),   // 薄荷黄带
                        band: Color(red: 0.85, green: 0.90, blue: 0.45),
                        spot: Color(red: 0.30, green: 0.55, blue: 0.75),
                        far:  Color(red: 0.38, green: 0.72, blue: 0.50)),
        ButterflyScheme(wing: Color(red: 0.95, green: 0.55, blue: 0.68),   // 粉红杏带
                        band: Color(red: 0.98, green: 0.78, blue: 0.55),
                        spot: Color(red: 0.55, green: 0.40, blue: 0.80),
                        far:  Color(red: 0.82, green: 0.40, blue: 0.55)),
        ButterflyScheme(wing: Color(red: 0.68, green: 0.55, blue: 0.92),   // 紫罗兰粉带
                        band: Color(red: 0.92, green: 0.65, blue: 0.85),
                        spot: Color(red: 0.95, green: 0.75, blue: 0.30),
                        far:  Color(red: 0.55, green: 0.42, blue: 0.80)),
    ]

    weak var pet: PetViewModel?

    private var baseY: CGFloat = 0
    private var flyTime: TimeInterval = 0
    private var escaping = false      // 被扑之后加速逃走
    private var hasPounced = false    // 一次飞行只被扑一次

    override class var size: NSSize { NSSize(width: 110, height: 95) }
    private let cruiseSpeed: CGFloat = 65
    private let escapeSpeed: CGFloat = 190

    func flyAcross(fromLeft: Bool, groundY: CGFloat) {
        startCrossing(fromLeft: fromLeft, groundY: groundY, referenceWindow: pet?.window)
    }

    // MARK: - ScreenCrosser hook

    override func canStart() -> Bool {
        guard let pet, pet.isVisible, !pet.isPeaceful, pet.window != nil else { return false }
        return true
    }

    override func onWillStart(fromLeft: Bool, groundY: CGFloat) {
        scheme = Self.schemes.randomElement() ?? Self.schemes[0]
        baseY = groundY + 95   // 牛来脑袋的高度，跳一跳够得着
        flyTime = 0
        escaping = false
        hasPounced = false
    }

    override func startOrigin(fromLeft: Bool, vf: NSRect, groundY: CGFloat) -> CGPoint {
        CGPoint(x: fromLeft ? vf.minX - Self.size.width : vf.maxX, y: baseY)
    }

    override func updatePosition(dt: CGFloat, origin: inout CGPoint, vf: NSRect) {
        flyTime += dt
        origin.x += direction * (escaping ? escapeSpeed : cruiseSpeed) * dt
        origin.y = baseY + sin(flyTime * 3) * 16   // 蝴蝶式上下翻飞
        if escaping { baseY += 50 * dt }           // 逃走时往上爬升
    }

    override func afterMove(vf: NSRect) {
        guard let pet, let petWindow = pet.window, let origin = window?.frame.origin else { return }

        // 路过牛来附近：牛来注意到了，开始追
        if !escaping, pet.state != .chasing, abs(currentX - petWindow.frame.midX) < 340 {
            pet.startChasingButterfly()
        }

        // 快到出口：牛来起跳扑蝶，蝴蝶受惊加速逃走
        if !escaping, !hasPounced, pet.state == .chasing {
            let remaining = direction > 0
                ? vf.maxX - origin.x
                : origin.x + Self.size.width - vf.minX
            if remaining < 380 {
                hasPounced = true
                escaping = true
                pet.pounceAtButterfly()
            }
        }
    }

    override func onDidExit() {
        pet?.butterflyGone()
    }

    /// 预览/调试用：直接指定配色
    func setSchemeForPreview(_ scheme: ButterflyScheme) {
        self.scheme = scheme
    }

    override func makeContentView() -> AnyView {
        AnyView(ButterflyView(controller: self))
    }
}
