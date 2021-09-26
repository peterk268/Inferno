//
//  ShellHacks_GoogleApp.swift
//  ShellHacks Google
//
//  Created by Peter Khouly on 9/25/21.
//

import SwiftUI

@main
struct ShellHacks_GoogleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(usageViewModel)

        }
    }
}
var usageViewModel = UsageViewModel()
