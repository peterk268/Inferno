//
//  Extensions.swift
//  ShellHacks Google
//
//  Created by Peter Khouly on 9/25/21.
//

import SwiftUI

//MARK: - Date Extensions
extension Date: RawRepresentable {
    private static let formatter = ISO8601DateFormatter()
    
    public var rawValue: String {
        Date.formatter.string(from: self)
    }
    
    public init?(rawValue: String) {
        self = Date.formatter.date(from: rawValue) ?? Date()
    }
}


func firestoreDateToString(date: Date) -> String {
    let timestampFormatter = DateFormatter()

    timestampFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    timestampFormatter.timeZone = TimeZone.current
    
    return timestampFormatter.string(from: date)
}

//num of days
extension Date {

    func interval(ofComponent comp: Calendar.Component, fromDate date: Date) -> Int {

        let currentCalendar = Calendar.current

        guard let start = currentCalendar.ordinality(of: comp, in: .era, for: date) else { return 0 }
        guard let end = currentCalendar.ordinality(of: comp, in: .era, for: self) else { return 0 }

        return end - start
    }
}



//MARK: - Navigation Extensions
extension View {
    public func currentDeviceNavigationViewStyle() -> AnyView {
        #if !os(watchOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return AnyView(self.navigationViewStyle(DefaultNavigationViewStyle()))
        } else {
            return AnyView(self.navigationViewStyle(StackNavigationViewStyle()))
        }
        #else
        return AnyView(self.navigationViewStyle(DefaultNavigationViewStyle()))
        #endif
    }
}



struct NavigationBarTitleViewModifier: ViewModifier {
    var text: String
    var displayMode: NavigationBarItem.TitleDisplayMode
    
    func body(content: Content) -> some View {
        #if !os(watchOS)
        content
            .navigationBarTitle(text, displayMode: displayMode)
        #else
        content
        #endif

    }
}
extension View {
    @ViewBuilder
    func platformNavigationTitle(text: String, displayMode: NavigationBarItem.TitleDisplayMode) -> some View {
        self.modifier(NavigationBarTitleViewModifier(text: text, displayMode: displayMode))
    }
}


//MARK: - Biometrics
import LocalAuthentication

extension LAContext {
    enum BiometricType: String {
        case none
        case touchID
        case faceID
    }

    var biometricType: BiometricType {
        var error: NSError?

        guard self.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        if #available(iOS 11.0, *) {
            switch self.biometryType {
            case .none:
                return .none
            case .touchID:
                return .touchID
            case .faceID:
                return .faceID
            @unknown default:
                return .none
            }
        }
        
        return  self.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touchID : .none
    }
}

