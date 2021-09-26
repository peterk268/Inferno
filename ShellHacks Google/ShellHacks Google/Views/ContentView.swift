//
//  ContentView.swift
//  ShellHacks Google
//
//  Created by Peter Khouly on 9/25/21.
//

import SwiftUI
import SwiftyJSON
import LocalAuthentication

struct ContentView: View {
    @State var isUnlocked = false
    @AppStorage ("lockApp") var lockApp = false

    @Environment(\.scenePhase) var scenePhase
    var body: some View {
        ZStack {
            MainView()
                .blur(radius: isUnlocked || !lockApp ? 0 : 15)
                .zIndex(0)
                .disabled(!isUnlocked && lockApp)
            
            if !isUnlocked && lockApp {
                Button(action: authenticate) {
                    Text("Unlock Inferno")
                        .foregroundColor(.primary)
                        .font(.title3)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).foregroundColor(.accentColor))
                }
                .zIndex(1)
            }
        }
        .onAppear(perform: authenticate)
    }
    func lockApp(newPhase: ScenePhase) {
        #if os(iOS)
        if newPhase == .inactive || newPhase == .background {
            if lockApp {
                isUnlocked = false
            }
        }
        print("yolo")
        #endif
    }
    func authenticate() {
        if lockApp {
            let context = LAContext()
            var error: NSError?
            
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reason = "Please authenticate yourself to unlock Inferno."
                
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                    
                    DispatchQueue.main.async {
                        if success {
                            withAnimation {
                                self.isUnlocked = true
                            }
                        } else {
                            // error
                        }
                    }
                }
            } else {
                if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                    let reason = "Please authenticate yourself to unlock Inferno."
                    
                    context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                        
                        DispatchQueue.main.async {
                            if success {
                                withAnimation {
                                    self.isUnlocked = true
                                }
                            } else {
                                // error
                            }
                        }
                    }
                }
            }
        }
    }
}

struct MainView: View {
    @State var selection = 0
    
    var body: some View {
        TabView(selection: $selection) {
            NavigationView {
                OverviewView()
                    .navigationTitle("Usage")
            }.tabItem {
                Label("Usage", systemImage: "newspaper")
            }
            .tag(0)
            .navigationViewStyle(StackNavigationViewStyle())
            
            NavigationView {
                SettingsView()
                    .navigationTitle("Settings")
            }.tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(1)
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
