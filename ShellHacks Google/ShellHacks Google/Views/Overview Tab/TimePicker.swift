//
//  TimePicker.swift
//  ShellHacks Google
//
//  Created by Peter Khouly on 9/25/21.
//

import SwiftUI

struct TimePicker: View {
    @Binding var selected: String
    let array: [String]
    @Environment (\.presentationMode) var presentationMode

    @EnvironmentObject var vm: UsageViewModel

    var body: some View {
        ScrollViewReader { proxy in
            Form {
                customDatePicker
                
                Section(header: Text("\(array.contains("24 hours") ? "Preset Date Periods": "Select a Project")")) {
                    ForEach(Array(array.filter({$0 != "Custom"}).enumerated()), id: \.offset) { index, comp in
                        TimePickerComponent(dismiss: {presentationMode.wrappedValue.dismiss()}, selected: $selected, time: comp)
                            .id(index)
                    }
                }
            }
            .onAppear {
                withAnimation {
                    proxy.scrollTo(array.firstIndex(of: selected))
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {presentationMode.wrappedValue.dismiss()}) {
                        Text("Done")
                    }
                }
            }
            .platformNavigationTitle(text: "", displayMode: .inline)
        }

    }
    var customDatePicker: some View {
        Group {
            #if !os(watchOS)
            if array.contains("24 hours") {
                Section(header: Text("Date Index"), footer: Text("Firebase provides metrics up to the past 2 months.")) {
                    TimePickerComponent(dismiss: {selected = "Custom"}, selected: $selected, time: "Custom")
                    if selected == "Custom" {
                        DatePicker(selection: $vm.startDate, label: { Text("Start Date:") })
                        DatePicker(selection: $vm.endDate, label: { Text("End Date:") })
                    }
                }.animation(.default)
            }
            #endif
        }
    }
}


struct TimePicker_Previews: PreviewProvider {
    static var previews: some View {
        TimePicker(selected: .constant(""), array: [""])
    }
}
