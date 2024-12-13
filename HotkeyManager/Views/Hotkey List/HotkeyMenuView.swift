//
//  HotkeyMenuView.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 13.12.24.
//

import SwiftUI

struct HotkeyMenuView: View {
    @ObservedObject var item: MenuItem  // Observing changes to the item

    @State private var newHotkey: String = ""  // State for the new hotkey input
    @State private var isHotkeyAssigned = false  // To track if hotkey is assigned
    @State private var showIconPicker = false  // Flag to show icon picker

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Menu item title
            Text("\(item.name)")
                .font(.headline)

            Divider()
            HStack {
                if let hotkey = item.hotkey {
                    HotkeyColorText(hotkey: hotkey)
                }
                Spacer()
                Button(action: {
                }) {
                    Text("Assign")
                        .foregroundColor(.blue)
                }
            }

            // Instruction text
            Text("Assign or modify hotkeys here.")
                .font(.subheadline)
                .padding(.bottom, 10)

            // Current hotkey display (if any)
            if let currentHotkey = item.hotkey {
                HStack {
                    Button(action: {
                        item.hidden = true
                        print("Hotkey \(item.hidden) for \(item.name)")
                    }) {
                        Text("Hide Hotkey from Overlay")
                            .foregroundColor(.red)
                    }
                    Spacer()

                }
            } else {
                Text("No hotkey assigned.")
                    .foregroundColor(.gray)
            }


        }
        .padding()
    }
}
