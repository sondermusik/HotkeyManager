//
//  HotkeyListView.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 13.12.24.
//

import SwiftUI

struct HotkeyListView: View {
    @EnvironmentObject var hotkeyVM: HotkeyVM
    var item: MenuItem  // Use @ObservedObject instead of @State
    @State private var isHovered = false
    @State private var showUnderline = false
    @State private var showHotkeyMenu = false  // State to control popup visibility

    var body: some View {
        HStack {
            Text(item.name)
                .font(.body)

            Spacer()

            HStack(spacing: 2) {
                if let hotkey = item.hotkey {
                    HotkeyColorText(hotkey: hotkey)
                }

            }
        }
        .padding(.bottom, 2)
        .background(
            Rectangle()
                .fill(Color.primary)
                .frame(height: showUnderline || showHotkeyMenu ? 2 : 0)
                .offset(y: 4),
            alignment: .bottom
        )
        .animation(.easeInOut(duration: 0.1), value: showUnderline)

        // Hover logic
        .onHover(perform: { hovering in
            isHovered = hovering
            if hovering {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if isHovered {
                        showUnderline = true
//                        hotkeyVM.selectedMenuItem = item
                    }
                }
            } else {
                showUnderline = false
//                if hotkeyVM.selectedMenuItem == item {
//                    hotkeyVM.selectedMenuItem = nil
//                }

            }
        })

        // Tap gesture to show the hotkey menu
        .onTapGesture {
            showHotkeyMenu = true
        }

        // Popover displaying the hotkey menu
        .popover(isPresented: $showHotkeyMenu) {
            HotkeyMenuView(item: item)  // Custom hotkey menu
        }
    }

    init(item: MenuItem) {
        self.item = item
    }
}

