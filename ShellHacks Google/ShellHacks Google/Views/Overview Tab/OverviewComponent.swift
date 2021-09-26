//
//  OverviewComponent.swift
//  ShellHacks Google
//
//  Created by Peter Khouly on 9/25/21.
//

import SwiftUI

struct OverviewComponent: View {
    let name: String
    let imageName: String
    let count: Any?
    let color: Color
    
    var formattedCount: String {
        let formatter = NumberFormatter()
        if name == "Bill" {
            formatter.numberStyle = .currency
            let string = formatter.string(from: count as? NSNumber ?? 0) ?? "$0"
            return string
        } else {
            formatter.numberStyle = .decimal
            let string = formatter.string(from: count as? NSNumber ?? 0) ?? "0"
            return string
        }
    }
    var body: some View {
        HStack {
            Label(
                title: { Text(name).bold() },
                icon: { Image(systemName: imageName).foregroundColor(color) }
            ).font(watchOSFont(isLargeFont: false))
            Spacer()
            if count != nil {
                Text(formattedCount)
                    .bold()
                    .font(watchOSFont(isLargeFont: true))
            } else {
                ProgressView()
            }
        }
    }
}

struct OverviewComponent_Previews: PreviewProvider {
    static var previews: some View {
        OverviewComponent(name: "Reads", imageName: "arrow.down", count: 364872, color: .blue)
    }
}
