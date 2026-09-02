import AppKit
import IOKit.ps

/// 休息提醒（分钟级定时走到屏幕中间提醒）与电量感知（充电/低电彩蛋）。
extension PetViewModel {

    // MARK: - 休息提醒

    /// 读取设置并（重新）安排提醒定时器。reminderMinutes == 0 表示关闭。
    /// 只伺候工作模式：番茄钟有自己的节奏，休闲本来就在休息。
    /// 每次调用都从头计时（重建定时器）——改设置、切入工作模式都会重置。
    func configureReminder() {
        reminderTicker?.stop()
        reminderTicker = nil
        nextReminderAt = nil
        let minutes = Settings.reminderMinutes
        guard minutes > 0, mode == .working else { return }
        reminderInterval = TimeInterval(minutes * 60)
        nextReminderAt = Date().addingTimeInterval(reminderInterval)
        let ticker = FrameTicker(interval: reminderInterval) { [weak self] _ in
            self?.beginReminder()
        }
        ticker.start()
        reminderTicker = ticker
    }

    private func beginReminder() {
        nextReminderAt = Date().addingTimeInterval(reminderInterval)   // 提醒完，重新计下一轮
        // 双保险：定时器存续期间被切到别的模式（如直接改 defaults）也不打扰
        guard mode == .working, isVisible, state != .dragged else { return }
        let target = visibleFrame.midX - (window?.frame.width ?? 240) / 2
        state = .walkingTo(target)
        stateUntil = Date().addingTimeInterval(20)   // 兜底：走太久就放弃
    }

    func arriveAtReminderSpot() {   // internal: 核心 tick() 走到位时调用
        setState(.happy, duration: 2.5)
        showBubble(Self.reminderPhrases.randomElement() ?? "休息一下吧~", duration: 6)
    }

    // MARK: - 电量感知

    func startBatteryMonitor() {   // internal: 核心 start() 用
        checkBattery()
        batteryTicker.start()
    }

    func checkBattery() {   // internal: 主文件 batteryTicker 闭包调用
        guard let (percent, charging) = Self.readBattery() else { return }

        if charging, !wasCharging {
            setState(.happy, duration: 1.5)
            showBubble("来电啦！⚡ 满血复活！", duration: 3)
        }
        if !charging, percent <= 20, !lowBatteryWarned {
            lowBatteryWarned = true
            showBubble("你快没电了……我也饿得没力气了……记得充电", duration: 5)
            if !isPeaceful, !isBusyForEvent {
                setState(.sitting, duration: 60)   // 没精打采
            }
        }
        if percent > 30 { lowBatteryWarned = false }
        wasCharging = charging
    }

    /// 通过 IOKit 读取内置电池（台式机无电池时返回 nil）
    private static func readBattery() -> (percent: Int, charging: Bool)? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
              (desc[kIOPSTypeKey] as? String) == kIOPSInternalBatteryType,
              let capacity = desc[kIOPSCurrentCapacityKey] as? Int,
              let charging = desc[kIOPSIsChargingKey] as? Bool
        else { return nil }
        return (capacity, charging)
    }
}
