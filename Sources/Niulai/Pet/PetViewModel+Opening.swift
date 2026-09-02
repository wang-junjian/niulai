import AppKit

/// 开场呼唤：每次启动，牛来立刻喊一声「妈妈——！」（气泡字幕 + 原声），
/// 停顿片刻，远处传来牛妈妈焦急的回应「牛来——！」（只出声，不出字幕）。
/// 源自电影名场面——小牛被蛇咬伤，受惊拖着长音委屈大喊，妈妈闻声回应。
extension PetViewModel {

    func openingCall() {   // internal: 核心 start() 用
        guard isVisible else { return }
        showBubble("妈妈——！", duration: 3.2)
        SoundPlayer.play(SoundPlayer.mama)

        Task { [weak self] in
            // 停一拍，妈妈的回应从远处传来：只闻其声
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard let self, !Task.isCancelled, self.isVisible else { return }
            SoundPlayer.play(SoundPlayer.niulai, volume: 0.85)
        }
    }
}
