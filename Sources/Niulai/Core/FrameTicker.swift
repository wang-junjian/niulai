import AppKit

/// 定频回调器：封装 Timer + RunLoop .common（菜单打开时也保持运行）+ dt 封顶 + MainActor 样板。
/// 60fps 动画驱动和低频调度（彩蛋 5s / 番茄钟 1s / 电量 30s / 提醒分钟级）统一走这里。
///
/// 用法：
/// ```swift
/// private lazy var ticker = FrameTicker { [weak self] dt in self?.tick(dt: dt) }
/// ticker.start()   // 重复调用安全；首帧 dt 从 start 时刻起算
/// ticker.stop()
/// ```
@MainActor
final class FrameTicker {
    private var timer: Timer?
    private var lastTick = Date()
    private let interval: TimeInterval
    private let handler: (CGFloat) -> Void

    init(interval: TimeInterval = 1.0 / 60.0, handler: @escaping (CGFloat) -> Void) {
        self.interval = interval
        self.handler = handler
    }

    /// 开始（或重新开始）。先重置 lastTick 再建 timer，首帧 dt 不会补帧。
    func start() {
        stop()
        lastTick = Date()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                let now = Date()
                let dt = min(CGFloat(now.timeIntervalSince(self.lastTick)), 0.1)   // 封顶，防补帧瞬移
                self.lastTick = now
                self.handler(dt)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
