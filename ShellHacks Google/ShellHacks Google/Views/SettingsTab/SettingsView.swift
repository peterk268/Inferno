//
//  SettingsView.swift
//  ShellHacks Google
//
//  Created by Peter Khouly on 9/25/21.
//

import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @ObservedObject private var viewModel = SignInViewModel()
    @AppStorage ("accessToken") var accessToken = ""
    @AppStorage ("refreshToken") var refreshToken = ""
    
    @AppStorage ("lockApp") var lockApp = false

    let context = LAContext()

    var body: some View {
        Form {
            Section(header: Text("Account")) {
                Button(action: {viewModel.signInTapped()}) {
                    HStack {
                        Label(
                            title: { Text("Authenticate") },
                            icon: { Image(systemName: "person.circle").foregroundColor(.green) }
                        )
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        }
                    }
                }.disabled(viewModel.isLoading)
                if !accessToken.isEmpty {
                    Button(action: {accessToken = ""; refreshToken = ""}) {
                        Label(
                            title: { Text("Sign Out") },
                            icon: { Image(systemName: "signpost.left").foregroundColor(.red) }
                        )
                    }
                }
            }
            Section(header: Text("App Preferences")) {
                Toggle(isOn: $lockApp) {
                    if context.biometricType == .faceID {
                        Label {
                            Text("Face ID").foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "faceid").foregroundColor(.blue)
                        }
                    } else if context.biometricType == .touchID {
                        Label {
                            Text("Touch ID").foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "touchid").foregroundColor(.red)
                        }
                    } else {
                        Label {
                            Text("Lock App").foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "lock").foregroundColor(.gray)
                        }
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
