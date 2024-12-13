//
//  SectionView.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 03.12.24.
//

import SwiftUI

struct SectionView: View {
    let section: MenuSection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Text(section.name)
                Spacer()
            }

            // Use toMenuSection to get a mixed array of sections and items
            ForEach(
                section.toMenuSection(),
                id: \.self // The id is based on the MenuResult itself (MenuItem or MenuSection)
            ) { result in
                // Handle MenuSection
                if case .section(let childSection) = result, childSection.containsHotkey() {
                    SectionView(section: childSection)
                        .padding(6)
                }

                // Handle MenuItem and ensure it has a hotkey
                if case .item(let item) = result, let _ = item.hotkey, item.hidden != true {
                    HotkeyListView(item: item)
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
