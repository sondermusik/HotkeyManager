//
//  SectionListView.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 11.12.24.
//

import SwiftUI

struct SectionListView: View {
    @EnvironmentObject var hotkeyVM: HotkeyVM

    var body: some View {
        if hotkeyVM.appMenu.isEmpty {
            Text("Loading menu items...")
        } else {
            List(
                hotkeyVM.appMenu
                    .sorted(by: { $0.index < $1.index })
                    .filter { $0.containsHotkey() }
            ) { category in
                SectionView(section: category)
                    .padding(.vertical, 6)
            }
        }
    }
}

#Preview {
    SectionListView()
}
