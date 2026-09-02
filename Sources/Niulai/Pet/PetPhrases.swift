/// 牛来的台词库。static let 存于 extension，调用点（Self.xxxPhrases）不变。
extension PetViewModel {

    nonisolated static let pokePhrases = [
        "哞~",
        "勇气已经在我心底了！",
        "今天也要加油呀！",
        "我才不是胆小鬼！",
        "七天站不起来就会被抛弃……但我做到了！",
        "豹拉才不是野兽，它是我最好的朋友！",
        "牛二，我不怕你。",
        "妈妈在等我，我要站起来！",
        "你戳我干嘛啦，哞！",
        "梦里的我，可勇敢了。"
    ]

    nonisolated static let dreamPhrases = [
        "（梦话）豹拉，别走……",
        "（梦话）我能站起来了！",
        "（梦话）妈妈，快跑……",
        "（梦话）狼来了也不怕……",
        "（梦话）哞……云雀，你也做梦吗？"
    ]

    /// 工作模式下被戳：迷迷糊糊应一声
    nonisolated static let workingPokePhrases = [
        "（迷迷糊糊）哞……我再睡会儿",
        "（揉眼睛）唔……还没到休息时间吗？",
        "（梦话）嗯……豹拉……哦，是你呀",
        "（翻身）嘘……梦里正精彩呢"
    ]

    nonisolated static let reminderPhrases = [
        "哞！该休息一下啦，喝口水活动活动~",
        "草原的牛都知道劳逸结合，起来走走吧！",
        "妈妈说过，坚持就会胜利——先站起来走走！",
        "休息是为了更好地出发，哞~"
    ]
}
