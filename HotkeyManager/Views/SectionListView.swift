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
        Text("Sections")
        List(
            hotkeyVM.appMenuItems
                .sorted(by: { $0.index < $1.index })
        ) { category in
            SectionView(section: category)
                .padding(.vertical, 6)

        }
    }
}


#Preview {
    SectionListView()
}
