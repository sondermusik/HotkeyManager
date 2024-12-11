//
//  SectionView.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 03.12.24.
//

import SwiftUI

struct SectionView: View {
    let section: MenuItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Text(section.name)
                Spacer()
            }

            ForEach(
                section.children
                    .filter { child in child.type == MenuItemType.section || child.type == MenuItemType.hotkey }
                    .sorted(by: { $0.index < $1.index }),
                id: \.id
            ) { child in
                // Check if the child is a section and contains a hotkey
                if child.type == MenuItemType.section && child.containsHotkey() {
                    SectionView(section: child)
                        .padding(6)
                }
                
                // Check if the child is a hotkey
                if child.type == MenuItemType.hotkey {
                    HStack {
                        Text(child.name)
                        Spacer()
                        Text(child.hotkey?.toDisplay() ?? "")
                    }
                    .padding(6)
                }
            }

        }
        .padding(6)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 2)
        )
    }
}
