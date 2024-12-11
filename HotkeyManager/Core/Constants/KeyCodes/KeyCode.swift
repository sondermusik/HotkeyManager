//
//  KeyCode.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 11.12.24.
//

import Foundation

enum KeyCode: Int, CaseIterable {
    case keyCode0 = 0
    case keyCode1 = 1
    case keyCode2 = 2
    case keyCode3 = 3
    case keyCode4 = 4
    case keyCode5 = 5
    case keyCode6 = 6
    case keyCode7 = 7
    case keyCode8 = 8
    case keyCode9 = 9
    case keyCode10 = 10
    case keyCode11 = 11
    case keyCode12 = 12
    case keyCode13 = 13
    case keyCode14 = 14
    case keyCode15 = 15
    case keyCode16 = 16
    case keyCode17 = 17
    case keyCode18 = 18
    case keyCode19 = 19
    case keyCode20 = 20
    case keyCode21 = 21
    case keyCode22 = 22
    case keyCode23 = 23
    case keyCode24 = 24
    case keyCode25 = 25
    case keyCode26 = 26
    case keyCode27 = 27
    case keyCode28 = 28
    case keyCode29 = 29
    case keyCode30 = 30
    case keyCode31 = 31
    case keyCode32 = 32
    case keyCode33 = 33
    case keyCode34 = 34
    case keyCode35 = 35
    case keyCode36 = 36
    case keyCode37 = 37
    case keyCode38 = 38
    case keyCode39 = 39
    case keyCode40 = 40
    case keyCode41 = 41
    case keyCode42 = 42
    case keyCode43 = 43
    case keyCode44 = 44
    case keyCode45 = 45
    case keyCode46 = 46
    case keyCode47 = 47
    case keyCode48 = 48
    case keyCode49 = 49
    case keyCode50 = 50
    case keyCode51 = 51
    case keyCode52 = 52
    case keyCode53 = 53
    case keyCode54 = 54
    case keyCode55 = 55
    case keyCode56 = 56
    case keyCode57 = 57
    case keyCode58 = 58
    case keyCode59 = 59
    case keyCode60 = 60
    case keyCode61 = 61
    case keyCode62 = 62
    case keyCode63 = 63
    case keyCode64 = 64
    case keyCode65 = 65
    case keyCode67 = 67
    case keyCode69 = 69
    case keyCode71 = 71
    case keyCode72 = 72
    case keyCode73 = 73
    case keyCode74 = 74
    case keyCode75 = 75
    case keyCode76 = 76
    case keyCode78 = 78
    case keyCode79 = 79
    case keyCode80 = 80
    case keyCode81 = 81
    case keyCode82 = 82
    case keyCode83 = 83
    case keyCode84 = 84
    case keyCode85 = 85
    case keyCode86 = 86
    case keyCode87 = 87
    case keyCode88 = 88
    case keyCode89 = 89
    case keyCode90 = 90
    case keyCode91 = 91
    case keyCode92 = 92
    case keyCode93 = 93
    case keyCode94 = 94
    case keyCode95 = 95
    case keyCode96 = 96
    case keyCode97 = 97
    case keyCode98 = 98
    case keyCode99 = 99
    case keyCode100 = 100
    case keyCode101 = 101
    case keyCode102 = 102
    case keyCode103 = 103
    case keyCode104 = 104
    case keyCode105 = 105
    case keyCode106 = 106
    case keyCode107 = 107
    case keyCode109 = 109
    case keyCode110 = 110
    case keyCode111 = 111
    case keyCode113 = 113
    case keyCode114 = 114
    case keyCode115 = 115
    case keyCode116 = 116
    case keyCode117 = 117
    case keyCode118 = 118
    case keyCode119 = 119
    case keyCode120 = 120
    case keyCode121 = 121
    case keyCode122 = 122
    case keyCode123 = 123
    case keyCode124 = 124
    case keyCode125 = 125
    case keyCode126 = 126
    case keyCode127 = 127
    
    var displayString: String {
        let localizationKey = "keyCode\(self.rawValue)"
        return NSLocalizedString(localizationKey, tableName: "KeyCodes", bundle: .main, comment: "Localized description for \(self)")
    }
    
    /// Finds the keycode matching a localized string.
    /// - Parameter localizedString: The localized string to match.
    /// - Returns: The `Int` value of the matching keycode, or `nil` if no match is found.
    static func keyCode(for localizedString: String) -> Int? {
        let normalizedInput = localizedString.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        for keyCode in KeyCode.allCases {
            let normalizedKey = keyCode.displayString.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if normalizedKey == normalizedInput {
                return keyCode.rawValue
            }
        }
        return nil
    }
}
