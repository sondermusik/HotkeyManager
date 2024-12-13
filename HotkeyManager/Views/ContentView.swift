//
//  ContentView.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 11.12.24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appVM: AppVM
    @EnvironmentObject private var hotkeyVM: HotkeyVM

    var body: some View {
        VStack {
            // List of recent apps
            HStack {
                ForEach(appVM.recentApps.prefix(4), id: \.id) { app in
                    Text(app.name)
                        .fontWeight(appVM.activeApp == app ? .bold : .none)
                        .underline(appVM.activeApp == app)
                        .padding()
                        .onTapGesture {
                            appVM.activateApp(app)
                        }
                }

                Spacer()

                ForEach(appVM.globalApp) { app in
                    if let icon = app.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 30, height: 30) // Adjust size as needed
                            .padding(4)
                            .onTapGesture {
                                appVM.activateApp(app)
                            }
                    } else {
                        // Fallback for apps without an icon
                        Text(app.name)
                            .padding(4)
                            .onTapGesture {
                                appVM.activateApp(app)
                            }
                    }
                }

            }

            // List of menu items
            SectionListView()

            HStack {
                // Request Accessibility
                Button("Request Accessibility") {
                    AccessibilityPermissionManager.shared.ensureAccessibilityPermissions()
                }
                Spacer()
                // Reset Hotkeys
                Button("Open Core Data Location") {
                    if let url = DataController.shared.persistentStoreURL() {
                        NSWorkspace.shared.open(url)
                    }
                }
            }

        }
        .padding()
    }
}

#Preview {
    ContentView()
}
