import AppKit

/// 彩蛋事件调度：蛇 / 狼影 / 蝴蝶的随机出场，以及追蝴蝶的回调。
/// 蛇狼互斥（对方在屏上则延后 20 秒），牛来忙碌时全部延后。
extension PetViewModel {

    // MARK: - 彩蛋事件（蛇 / 狼影）

    func scheduleEvents() {   // internal: 核心 start() 用
        let now = Date()
        // --demo：8 秒来蛇、15 秒来蝴蝶、30 秒来狼，方便演示
        nextSnakeAt = now.addingTimeInterval(demoMode ? 8 : .random(in: 300...900))
        nextButterflyAt = now.addingTimeInterval(demoMode ? 15 : .random(in: 240...720))
        nextWolfAt = now.addingTimeInterval(demoMode ? 30 : .random(in: 600...1500))
        eventTicker.start()
    }

    func checkEvents() {   // internal: 主文件 eventTicker 闭包调用
        guard !isPeaceful, isVisible else { return }
        let now = Date()
        // 蛇和狼不同时出现：对方还在屏幕上时就延后
        if now >= nextSnakeAt {
            if isBusyForEvent || wolf?.running == true {
                nextSnakeAt = now.addingTimeInterval(20)   // 忙就 20 秒后再试
            } else {
                nextSnakeAt = now.addingTimeInterval(.random(in: 300...900))
                triggerSnakeEvent()
            }
        }
        if now >= nextWolfAt {
            if isBusyForEvent || snake?.running == true {
                nextWolfAt = now.addingTimeInterval(20)
            } else {
                nextWolfAt = now.addingTimeInterval(.random(in: 600...1500))
                triggerWolfEvent()
            }
        }
        if now >= nextButterflyAt {
            if isBusyForEvent {
                nextButterflyAt = now.addingTimeInterval(20)
            } else {
                nextButterflyAt = now.addingTimeInterval(.random(in: 240...720))
                if let window {
                    butterfly?.flyAcross(fromLeft: Bool.random(), groundY: window.frame.minY)
                }
            }
        }
    }

    /// 忙碌中（被拎/正在惊吓/正在追蝴蝶等）不触发彩蛋
    var isBusyForEvent: Bool {   // internal: 核心电量提醒也用
        switch state {
        case .dragged, .startled, .walkingTo, .walkingToSleep, .happy,
             .chasing, .pouncing, .stretching, .headbutting, .spinning, .dizzy:
            return true
        default:
            return false
        }
    }

    private func triggerSnakeEvent() {
        guard !isBusyForEvent, let snake, let window else { return }
        let fromLeft = Bool.random()
        snake.slitherAcross(fromLeft: fromLeft, groundY: window.frame.minY)
        facingLeft = fromLeft
        setState(.startled, duration: 2.0)
        showBubble("蛇……蛇！！", duration: 2)
        companion?.onPetStartled()
        snake.onExit = { [weak self] in
            MainActor.assumeIsolated { self?.afterSnake() }
        }
    }

    private func afterSnake() {
        showBubble("呼……爬走了爬走了，我不怕", duration: 3)
        setState(.happy, duration: 1.5)
    }

    // MARK: - 追蝴蝶

    /// 蝴蝶路过附近：开追！
    func startChasingButterfly() {
        guard !isPeaceful, isVisible, !isBusyForEvent, butterfly != nil else { return }
        showBubble("蝴蝶！等等我！", duration: 2)
        setState(.chasing, duration: 8)   // 兜底：追不上自己停下
    }

    /// 蝴蝶快到屏幕边了：跳起来扑
    func pounceAtButterfly() {
        guard state == .chasing else { return }
        setState(.pouncing, duration: 0.9)
    }

    /// 蝴蝶飞出屏幕（可能在追/扑中途消失）
    func butterflyGone() {
        switch state {
        case .chasing:
            showBubble("咦？蝴蝶呢……", duration: 2)
            setState(.idle, duration: 2)
        case .pouncing:
            showBubble("嘿嘿……差点就抓到了", duration: 2.5)
            setState(.idle, duration: 2.5)
        default:
            break
        }
    }

    private func triggerWolfEvent() {
        guard !isBusyForEvent, let wolf, let window else { return }
        let fromLeft = Bool.random()
        wolf.runAcross(fromLeft: fromLeft, groundY: window.frame.minY)
        facingLeft = fromLeft
        setState(.startled, duration: 2.2)
        showBubble("狼……狼！！", duration: 2.2)
        if companion?.present == true {
            companion?.guardAgainst(fromLeft: fromLeft)
        }
        wolf.onExit = { [weak self] in
            MainActor.assumeIsolated { self?.afterWolf() }
        }
    }

    private func afterWolf() {
        companion?.endGuard()
        let protected = companion?.present == true
        showBubble(protected ? "豹拉……谢谢你保护我" : "呼……它跑掉了，我不怕我不怕", duration: 3)
        setState(.happy, duration: 1.5)
    }
}
