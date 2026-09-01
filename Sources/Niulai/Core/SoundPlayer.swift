import AppKit

/// 音效播放：电影原声音频打包在 Bundle.module 里（SwiftPM resources）。
/// 菜单里的「音效」开关（soundEnabled，默认开）控制是否出声。
enum SoundPlayer {

    /// 牛来的名字呼唤——番茄钟阶段切换的提示音
    static let niulai = "niulai"
    /// 睡梦中呢喃的「妈妈」——那句梦话出现时低音量同步播放
    static let mama = "mama"

    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
    }

    /// NSSound 播放期间自持有，播完自动释放，无需持有引用
    static func play(_ name: String, volume: Float = 1.0) {
        guard enabled,
              let url = Bundle.module.url(forResource: name, withExtension: "mp3"),
              let sound = NSSound(contentsOf: url, byReference: true)
        else { return }
        sound.volume = volume
        sound.play()
    }
}
