//
//  HotkeyManagerApp.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 11.12.24.
//

import SwiftUI

@main
struct HotkeyManagerApp: App {
    @ObservedObject private var appVM = AppVM.shared
    @ObservedObject private var hotkeyVM = HotkeyVM()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appVM)
                .environmentObject(hotkeyVM)
        }
    }
}
