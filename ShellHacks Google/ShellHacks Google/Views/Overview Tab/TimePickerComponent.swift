//
//  TimePickerComponent.swift
//  ShellHacks Google
//
//  Created by Peter Khouly on 9/25/21.
//

import SwiftUI

struct TimePickerComponent: View {
    var dismiss: (() -> ())?
    @Binding var selected: String
    let time: String
    var body: some View {
        Button(action: {
            selected = time
            (dismiss ?? {print("nothing")})()
        }) {
            HStack {
                Text(time)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                if selected == time {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            
        }
    }
}

struct TimePickerComponent_Previews: PreviewProvider {
    static var previews: some View {
        TimePickerComponent(dismiss: {print("dismiss")}, selected: .constant("24 hours"), time: "1 minute")
    }
}
