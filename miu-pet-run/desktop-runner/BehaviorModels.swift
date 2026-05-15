import CoreGraphics
import Foundation

enum PetMode: String {
    case work
    case leisure
    case night
    case morning
    case sleepy
    case idle

    var chineseName: String {
        switch self {
        case .work: return "工作"
        case .leisure: return "休闲"
        case .night: return "睡觉"
        case .morning: return "早晨"
        case .sleepy: return "困了"
        case .idle: return "空闲"
        }
    }
}

enum PlacementPreference: String {
    case auto
    case lowerRight
    case lowerLeft
    case upperRight
    case upperLeft

    var chineseName: String {
        switch self {
        case .auto: return "自动"
        case .lowerRight: return "右下"
        case .lowerLeft: return "左下"
        case .upperRight: return "右上"
        case .upperLeft: return "左上"
        }
    }
}

enum BehaviorState: String {
    case fullscreen
    case temporaryReaction
    case night
    case morning
    case sleepy
    case work
    case leisure
    case idle

    var chineseName: String {
        switch self {
        case .fullscreen: return "全屏避让"
        case .temporaryReaction: return "临时互动"
        case .night: return "夜间休息"
        case .morning: return "早晨醒来"
        case .sleepy: return "睡前安静"
        case .work: return "工作陪伴"
        case .leisure: return "休闲活动"
        case .idle: return "空闲陪伴"
        }
    }
}

struct BehaviorDecision {
    var state: BehaviorState
    var action: String
    var minimumSeconds: TimeInterval
    var shouldHide: Bool
    var shouldPlace: Bool
    var keepWalkingPlacement: Bool
}
