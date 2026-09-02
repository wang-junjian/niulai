import AppKit

/// 三种模式（休闲/工作/番茄钟）的切换与安静期判定。
/// mode 直接背书 UserDefaults（Settings.petMode），改动来源无论是
/// 菜单按钮还是外部 defaults 命令，tick 轮询 lastReactedMode 兜底都能生效。
extension PetViewModel {

    /// 直接读写 UserDefaults 的计算属性，避免 @Published 在 nonisolated init 中的隔离问题
    var mode: PetMode {
        get {
            Settings.petMode
        }
        set {
            objectWillChange.send()
            Settings.petMode = newValue
            reactToModeChange()
        }
    }

    // MARK: - 模式切换

    func reactToModeChange() {   // internal: 核心 tick() 轮询兜底调用
        lastReactedMode = mode
        objectWillChange.send()
        switch mode {
        case .working:
            stopPomodoro()
            companion?.onPetModeChanged(mode)
            showBubble("我去做个勇敢的梦啦，你专心工作~", duration: 3)
            settleIntoCorner()
        case .pomodoro:
            startPomodoro()
        case .leisure:
            stopPomodoro()
            companion?.onPetModeChanged(mode)
            showBubble("我醒啦！梦里的我可勇敢了！", duration: 3)
            stateUntil = Date()   // 立刻恢复自由行为
        }
    }

    /// 需要安静做梦的时期：工作模式，或番茄钟的专注阶段。
    /// 云雀/蛇/狼彩蛋、戳一戳反应、漫游都以此为准。
    var isPeaceful: Bool {
        switch mode {
        case .leisure: return false
        case .working: return true
        case .pomodoro: return pomodoroPhase == .focus
        }
    }


    /// 工作模式的归宿：走到屏幕右下角趴睡；已经在角落就直接睡
    func settleIntoCorner() {
        let cornerX = visibleFrame.maxX - (window?.frame.width ?? 240) - 30
        let currentX = window?.frame.minX ?? cornerX
        if abs(currentX - cornerX) > 40 {
            state = .walkingToSleep(cornerX)
            stateUntil = Date().addingTimeInterval(30)
        } else {
            setState(.sleeping, duration: 3600)
        }
    }
}
