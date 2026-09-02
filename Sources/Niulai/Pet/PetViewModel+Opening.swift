import AppKit

/// 开场呼唤：每次启动，牛来站稳后先喊一声「妈妈——！」，
/// 停顿片刻，远处传来牛妈妈焦急的回应「牛来——！」。
/// 源自电影名场面——小牛被蛇咬伤，受惊拖着长音委屈大喊，妈妈闻声回应。
/// 纯声音 + 气泡字幕，不编排剧情；音效关闭时只出字幕。
extension PetViewModel {

    func openingCall() {   // internal: 核心 start() 用
        Task { [weak self] in
            // 微等一下，等牛来在屏幕上站稳、用户注意到它
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard let self, !Task.isCancelled, self.isVisible else { return }
            self.showBubble("妈妈——！", duration: 3.2)
            SoundPlayer.play(SoundPlayer.mama)

            // 停一拍，妈妈的回应从远处传来
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled, self.isVisible else { return }
            self.showBubble("（远处妈妈的声音）牛来——！", duration: 3.2)
            SoundPlayer.play(SoundPlayer.niulai, volume: 0.85)
        }
    }
}
