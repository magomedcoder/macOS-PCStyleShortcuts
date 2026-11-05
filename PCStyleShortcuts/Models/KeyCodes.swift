import Carbon.HIToolbox

enum KeyCodes {
    static let modifiersOnly: UInt16 = 0xFFFF

    static let a = UInt16(kVK_ANSI_A)
    static let b = UInt16(kVK_ANSI_B)
    static let c = UInt16(kVK_ANSI_C)
    static let f = UInt16(kVK_ANSI_F)
    static let g = UInt16(kVK_ANSI_G)
    static let i = UInt16(kVK_ANSI_I)
    static let l = UInt16(kVK_ANSI_L)
    static let n = UInt16(kVK_ANSI_N)
    static let p = UInt16(kVK_ANSI_P)
    static let r = UInt16(kVK_ANSI_R)
    static let s = UInt16(kVK_ANSI_S)
    static let t = UInt16(kVK_ANSI_T)
    static let u = UInt16(kVK_ANSI_U)
    static let v = UInt16(kVK_ANSI_V)
    static let w = UInt16(kVK_ANSI_W)
    static let x = UInt16(kVK_ANSI_X)
    static let z = UInt16(kVK_ANSI_Z)

    static let leftArrow = UInt16(kVK_LeftArrow)
    static let rightArrow = UInt16(kVK_RightArrow)
    static let downArrow = UInt16(kVK_DownArrow)
    static let upArrow = UInt16(kVK_UpArrow)

    static let delete = UInt16(kVK_Delete)
    static let forwardDelete = UInt16(kVK_ForwardDelete)
    static let home = UInt16(kVK_Home)
    static let end = UInt16(kVK_End)
    static let tab = UInt16(kVK_Tab)
    static let equal = UInt16(kVK_ANSI_Equal)
    static let minus = UInt16(kVK_ANSI_Minus)

    static func displayName(for keyCode: UInt16) -> String {
        if keyCode == modifiersOnly { return "" }
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_LeftArrow: return "<-"
        case kVK_RightArrow: return "->"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_Delete: return "⌫"
        case kVK_ForwardDelete: return "⌦"
        case kVK_Home: return "Home"
        case kVK_End: return "End"
        case kVK_Space: return "Space"
        case kVK_Tab: return "⇥"
        case kVK_ANSI_Equal: return "="
        case kVK_ANSI_Minus: return "-"
        default: return "Key(\(keyCode))"
        }
    }
}
