//
//  HotkeyColorText.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 12.12.24.
//

import SwiftUI

struct HotkeyColorText: View {
    let hotkey: Hotkey

    let size: Font

    var body: some View {
        HStack(spacing: 2) {
            if hotkey.command {
                Text("􀆔 ")
                    .foregroundColor(.red)
                    .font(size)
            }
            if hotkey.shift {
                Text("􀆝 ")
                    .foregroundColor(.green)
                    .font(size)

            }
            if hotkey.option {
                Text("􀆕 ")
                    .foregroundColor(.blue)
                    .font(size)

            }
            if hotkey.control {
                Text("􀆍 ")
                    .foregroundColor(.yellow)
                    .font(size)

            }
            Text(hotkey.keyCode.displayString)
                .font(size)
        }
    }

    init(hotkey: Hotkey, size: Font = .body) {
        self.hotkey = hotkey
        self.size = size
    }
}
