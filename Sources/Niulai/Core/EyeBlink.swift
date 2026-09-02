import Foundation

/// 不规则眨眼：间隔 2.5~6 秒由确定性伪随机决定，约 1/5 概率 0.36s 后连眨第二下。
/// 纯函数（按 t 重放整个序列），各角色传不同 seed 错开节奏，避免齐刷刷一起眨。
enum EyeBlink {
    static func isClosed(at t: TimeInterval, seed: UInt32) -> Bool {
        // t 是 timeIntervalSinceReferenceDate（上亿秒），先截断再重放，控制循环规模
        var cursor = 0.0
        let t = t.truncatingRemainder(dividingBy: 7200)
        var k = seed &* 2654435761 &+ 1
        while cursor <= t {
            k = k &* 1664525 &+ 1013904223
            let interval = 2.5 + Double(k >> 8 & 0xFFFFFF) / Double(0x1000000) * 3.5
            if t < cursor + interval {
                let dt = t - cursor
                if dt < 0.12 { return true }
                k = k &* 1664525 &+ 1013904223
                let r2 = Double(k >> 8 & 0xFFFFFF) / Double(0x1000000)
                return r2 < 0.2 && dt >= 0.36 && dt < 0.48
            }
            cursor += interval
        }
        return false
    }
}
