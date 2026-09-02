import AppKit

/// 番茄钟：25 分钟专注（牛来睡觉做梦）+ 5 分钟休息，每 4 轮一次 15 分钟长休息。
/// 本文件成员仅 PetViewModel* 扩展内互相访问（单模块 app，internal 即模块内私有约定）。
extension PetViewModel {


    private var focusDuration: TimeInterval { demoMode ? 30 : 25 * 60 }
    private var restDuration: TimeInterval { demoMode ? 15 : 5 * 60 }
    private var longRestDuration: TimeInterval { demoMode ? 45 : 15 * 60 }

    // MARK: - 番茄钟

    /// 进入番茄钟：立刻开始第一个专注阶段
    func startPomodoro() {   // internal: +Mode/核心 start() 用
        pomodoroPhase = .focus
        completedFocusCount = 0
        pomodoroPaused = false
        phaseEndsAt = Date().addingTimeInterval(focusDuration)
        companion?.onPetModeChanged(.working)   // 专注时豹拉不打扰
        showBubble("番茄钟开始！专注 25 分钟，我去梦里陪你~", duration: 4)
        settleIntoCorner()
        pomodoroTicker.start()
        pomodoroTick()
    }

    func stopPomodoro() {   // internal: +Mode 用
        pomodoroTicker.stop()
        pomodoroPaused = false
        pomodoroCountdown = ""
        menuBarLabel = "🐮"
    }

    func pomodoroTick() {   // internal: 主文件 pomodoroTicker 闭包调用
        guard mode == .pomodoro else { return }
        if pomodoroPaused {
            if pomodoroCountdown != "已暂停" { pomodoroCountdown = "已暂停" }
            return
        }
        let remain = max(0, phaseEndsAt.timeIntervalSinceNow)
        // 菜单栏图标静态化、菜单内倒计时分钟级：都不每秒变，避免打开的菜单被反复重渲染闪白。
        // 相同字符串不重复赋值（@Published 每次赋值都触发 objectWillChange）。
        let label = pomodoroPhase == .focus ? "🐮🍅" : "🐮☕️"
        if menuBarLabel != label { menuBarLabel = label }
        let minutes = Int(remain) / 60
        let text = minutes >= 1 ? "还剩 \(minutes) 分钟" : "不到 1 分钟"
        if pomodoroCountdown != text { pomodoroCountdown = text }
        if remain <= 0 { advancePomodoroPhase() }
    }

    /// 阶段切换：专注→休息（每 4 轮一次 15 分钟长休息），休息→专注
    private func advancePomodoroPhase() {
        SoundPlayer.play(SoundPlayer.niulai, volume: 0.8)   // 一声「牛来！」叫你换阶段
        switch pomodoroPhase {
        case .focus:
            completedFocusCount += 1
            pomodoroPhase = .rest
            let longRest = completedFocusCount % 4 == 0
            phaseEndsAt = Date().addingTimeInterval(longRest ? longRestDuration : restDuration)
            companion?.onPetModeChanged(.leisure)   // 休息时豹拉可以来玩
            setState(.stretching, duration: 3)   // 睡醒伸个大懒腰
            showBubble(
                longRest
                    ? "哞！四轮专注完成！好好休息 15 分钟，你太棒了！"
                    : "哞！休息 5 分钟！站起来活动活动，喝口水~",
                duration: 5
            )
        case .rest:
            pomodoroPhase = .focus
            phaseEndsAt = Date().addingTimeInterval(focusDuration)
            companion?.onPetModeChanged(.working)
            showBubble("继续专注！我去梦里给你加油，待会儿见~", duration: 4)
            settleIntoCorner()
        }
    }

    func togglePomodoroPause() {
        guard mode == .pomodoro else { return }
        if pomodoroPaused {
            pomodoroPaused = false
            phaseEndsAt = Date().addingTimeInterval(pausedRemaining)
        } else {
            pomodoroPaused = true
            pausedRemaining = max(0, phaseEndsAt.timeIntervalSinceNow)
            menuBarLabel = "🐮 ⏸"
        }
        pomodoroTick()
    }

    func skipPomodoroPhase() {
        guard mode == .pomodoro else { return }
        pomodoroPaused = false
        advancePomodoroPhase()
        pomodoroTick()
    }
}
