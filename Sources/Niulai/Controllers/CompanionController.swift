import AppKit
import SwiftUI

/// 豹拉的「经纪人」：管理它的小窗、跟随牛来的走位、登场和离场。
/// 登场方式两种——牛来出发漫步时随机客串（30%），或菜单栏「豹拉常伴」强制在线。
@MainActor
final class CompanionController: ObservableObject {

    @Published var present = false
    @Published var state: PetViewModel.State = .idle
    @Published var facingLeft = false
    @Published var bubbleText: String?

    let pet: PetViewModel

    private var window: NSWindow?
    private lazy var ticker = FrameTicker { [weak self] dt in self?.tick(dt: dt) }
    private var leaving = false
    private var following = false
    private var reactionUntil = Date.distantPast
    private var guardTargetX: CGFloat?   // 护卫位：狼影事件时挡在牛来身前
    private var bubbleGeneration = 0

    static let size = NSSize(width: 200, height: 250)

    /// 窗口中心 x（豹拉的眼神定位用）
    var midX: CGFloat? { window?.frame.midX }

    static let pokePhrases = [
        "嗷呜~",
        "我会保护牛来的！",
        "牛来是我最好的朋友",
        "我不是野兽……我是豹拉",
        "别告诉别人我在这儿"
    ]

    nonisolated init(pet: PetViewModel) {
        self.pet = pet
    }

    private var alwaysOn: Bool {
        Settings.baolaAlways
    }

    // MARK: - 登场/离场

    func setAlways(_ on: Bool) {
        if on { appear() } else { disappear() }
    }

    /// 牛来开始漫步时回调：30% 概率来客串
    func onPetStartedWalking() {
        if alwaysOn, !present { appear(); return }
        guard !present, Double.random(in: 0..<1) < 0.3 else { return }
        appear()
    }

    /// 牛来睡着了：非「常伴」模式下豹拉大概率悄悄离开
    func onPetStartedSleeping() {
        guard present, !alwaysOn, Double.random(in: 0..<1) < 0.6 else { return }
        disappear()
    }

    /// 工作模式（含番茄钟专注阶段）只留牛来一个人做梦，豹拉道别离开；
    /// 回休闲（含番茄钟休息阶段）时若「常伴」开着就回来
    func onPetModeChanged(_ mode: PetViewModel.PetMode) {
        if mode != .leisure {
            if present {
                showBubble("你忙吧，我改天再来找牛来玩~", duration: 2.5)
                disappear()
            }
        } else if alwaysOn, !present {
            appear()
        }
    }

    func appear() {
        guard !present, pet.isVisible else { return }   // 牛来被隐藏时不单独冒出来
        ensureWindow()
        guard let window, let petWindow = pet.window else { return }
        let vf = ScreenGeometry.visibleFrame(of: petWindow)

        // 从牛来前进方向的反侧屏幕边缘跑进来
        let fromLeft = !pet.facingLeft
        let startX = fromLeft ? vf.minX - Self.size.width : vf.maxX
        window.setFrameOrigin(NSPoint(x: startX, y: petWindow.frame.minY))
        facingLeft = !fromLeft
        present = true
        leaving = false
        window.orderFrontRegardless()
        ticker.start()
    }

    func disappear() {
        guard present, !leaving else { return }
        leaving = true
    }

    // MARK: - 跟随主循环

    private func tick(dt: CGFloat) {
        let now = Date()
        guard present, let window, let petWindow = pet.window else { return }
        let vf = ScreenGeometry.visibleFrame(of: petWindow)

        if leaving {
            // 走向最近的屏幕边缘，走出去就消失
            let goLeft = window.frame.midX < vf.midX
            facingLeft = goLeft
            state = .walking
            var origin = window.frame.origin
            origin.x += (goLeft ? -1 : 1) * 320 * dt
            window.setFrameOrigin(origin)
            if origin.x + window.frame.width < vf.minX || origin.x > vf.maxX {
                present = false
                leaving = false
                window.orderOut(nil)
                ticker.stop()
            }
            return
        }

        // 目标位：护卫位优先（狼影事件），否则牛来身后一个身位
        // 窗口重叠 110pt：两边画布边缘都是透明留白，视觉上刚好贴身跟随（朋友就该挨着走）
        let targetX = guardTargetX ?? (pet.facingLeft
            ? petWindow.frame.maxX - 110
            : petWindow.frame.minX - Self.size.width + 110)
        var origin = window.frame.origin
        let dx = targetX - origin.x

        if now < reactionUntil {
            // 被戳的反应时间，原地不动
        } else {
            // 迟滞：距离超过 12pt 才开始跟，小于 4pt 才停下，避免在阈值附近来回切换
            if !following, abs(dx) > 12 { following = true }
            if following, abs(dx) < 4 { following = false }

            if following {
                // 比例速度：离得远跑得快，接近时平滑减速到与牛来同速
                let speed = min(340, max(30, abs(dx) * 4))
                origin.x += dx > 0 ? min(speed * dt, dx) : max(-speed * dt, dx)
                facingLeft = dx < 0
                state = .walking
            } else {
                // 护卫时保持警觉的弹跳姿态
                state = guardTargetX != nil ? .happy : mirroredState(from: pet.state)
            }
        }

        // 垂直平滑跟随（牛来被拎到别处时）
        origin.y += (petWindow.frame.minY - origin.y) * min(1, 6 * dt)
        window.setFrameOrigin(origin)
    }

    private func mirroredState(from petState: PetViewModel.State) -> PetViewModel.State {
        switch petState {
        case .sitting: return .sitting
        case .sleeping: return .sleeping
        case .happy: return .happy
        default: return .idle
        }
    }

    // MARK: - 护卫（狼影事件）

    /// 狼来了：冲到牛来与狼之间，摆出护卫姿态
    func guardAgainst(fromLeft: Bool) {
        guard present, let petWindow = pet.window else { return }
        guardTargetX = fromLeft
            ? petWindow.frame.minX - Self.size.width - 4
            : petWindow.frame.maxX + 4
        showBubble("嗷呜！！有我在，别怕！", duration: 3)
    }

    func endGuard() {
        guardTargetX = nil
    }

    /// 牛来被小绳头吓到：豹拉也陪着吓一跳
    func onPetStartled() {
        guard present else { return }
        reactionUntil = Date().addingTimeInterval(1.6)
        state = .startled
    }

    // MARK: - 互动

    func poke() {
        reactionUntil = Date().addingTimeInterval(1.4)
        state = .happy
        showBubble(Self.pokePhrases.randomElement() ?? "嗷呜~", duration: 2.5)
    }

    private func showBubble(_ text: String, duration: TimeInterval = 3) {
        bubbleGeneration += 1
        let gen = bubbleGeneration
        bubbleText = text
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard let self, !Task.isCancelled, self.bubbleGeneration == gen else { return }
            self.bubbleText = nil
        }
    }

    // MARK: - 显隐（跟随牛来的显隐）

    func setVisible(_ visible: Bool) {
        if visible {
            if present {
                window?.orderFrontRegardless()
            } else if alwaysOn, !pet.isPeaceful {
                appear()   // 牛来重新显示时，该回来的要回来
            }
        } else {
            window?.orderOut(nil)
        }
    }

    // MARK: - 窗口

    private func ensureWindow() {
        guard window == nil else { return }
        // 豹拉要响应点击（poke），不忽略鼠标事件
        window = WindowFactory.makeFloatingWindow(
            size: Self.size,
            rootView: BaolaContainerView(controller: self)
        )
    }
}
