//
//  OverviewView.swift
//  ShellHacks Google
//
//  Created by Peter Khouly on 9/25/21.
//

import SwiftUI

struct OverviewView: View {
    @State var presentTimePicker = false
    @State var presentProjectPicker = false

    @EnvironmentObject var vm: UsageViewModel

    var body: some View {
        Form {
            Section(header: Text(vm.dateString())) {
                ForEach(vm.metrics.filter({$0.name == "Bill"})) { i in
                    OverviewComponent(name: i.name, imageName: i.imageName, count: i.count, color: i.color)
                }
            }
            Section(header: Text("Billable")) {
                ForEach(vm.metrics.filter({$0.billable == true})) { i in
                    OverviewComponent(name: i.name, imageName: i.imageName, count: i.count, color: i.color)
                }
            }
            Section(header: Text("Subscription"), footer: Text("Note: This API is currently still in beta so figures might not be 100% accurate each time.")) {
                ForEach(vm.metrics.filter({$0.billable == false && $0.name != "Bill"})) { i in
                    OverviewComponent(name: i.name, imageName: i.imageName, count: i.count, color: i.color)
                }
            }
            
            #if os(watchOS)
                watchToolbar
            #endif
            
        }
        .onChange(of: vm.startDate, perform: { value in
            vm.load(projectID: vm.selectedProject, authToken: vm.accessToken)
        })
        .onChange(of: vm.endDate, perform: { value in
            vm.load(projectID: vm.selectedProject, authToken: vm.accessToken)
        })
        .onChange(of: vm.selectedTime, perform: { value in
            vm.load(projectID: vm.selectedProject, authToken: vm.accessToken)
        })
        .onChange(of: vm.selectedProject, perform: { value in
            vm.load(projectID: value, authToken: vm.accessToken)
        })
        .onAppear {
            if !vm.selectedProject.isEmpty {
                vm.load(projectID: vm.selectedProject, authToken: vm.accessToken)
            } else {
                vm.load(projectID: "database-test-864cc", authToken: vm.accessToken)
            }
        }
        .sheet(isPresented: $presentTimePicker) {
            NavigationView {
                timePicker
            }
        }
        .sheet(isPresented: $presentProjectPicker) {
            NavigationView {
                projectPicker
            }
        }
        .toolbar {
            #if !os(watchOS)

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {presentTimePicker = true}) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath").foregroundColor(.yellow)
                        Text("")
                    }
                    .font(.title3)
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {presentProjectPicker = true}) {
                    HStack {
                        Image(systemName: "externaldrive").foregroundColor(.blue)
                        Text("")
                    }.font(.title3)
                }
            }
            #endif
        }
    }
    var projectPicker: some View {
        //these databases are protected by security rules so i have no problem exposing them lol.
        TimePicker(selected: $vm.selectedProject, array: ["database-test-864cc", "sport-event-hoster"])
            .environmentObject(vm)
    }
    var timePicker: some View {
        TimePicker(selected: $vm.selectedTime, array: times)
            .environmentObject(vm)
    }
    var watchToolbar: some View {
        Section(header: Text("Settings")) {
            NavigationLink(destination: timePicker) {
                Label(
                    title: {
                        Text("Date")
                            .bold()
                            .foregroundColor(.primary)
                        
                    },
                    icon: { Image(systemName: "clock.arrow.circlepath").foregroundColor(.yellow) }
                ).font(.footnote)
            }
            NavigationLink(destination: projectPicker) {
                Label(
                    title: {
                        Text("Project")
                            .bold()
                            .foregroundColor(.primary)
                    },
                    icon: { Image(systemName: "externaldrive").foregroundColor(.blue) }
                ).font(.footnote)
            }
        }
    }
    var times = [
        "Custom",
        "Current Quota Period",
        "Current Billing Period",
        "60 seconds",
        "2 minutes",
        "5 minutes",
        "10 minutes",
        "20 minutes",
        "30 minutes",
        "45 minutes",
        "60 minutes",
        "2 hours",
        "4 hours",
        "6 hours",
        "9 hours",
        "12 hours",
        "16 hours",
        "24 hours",
        "2 days",
        "4 days",
        "7 days",
        "2 weeks",
        "3 weeks",
        "4 weeks",
        "1 months",
        "2 months"
    ]
}

func watchOSFont(isLargeFont: Bool) -> Font? {
    #if os(watchOS)
        return .footnote
    #else
    if isLargeFont {
        return .title2
    } else {
        return .body
    }
    #endif
}

struct OverviewView_Previews: PreviewProvider {
    static var previews: some View {
        OverviewView()
            .preferredColorScheme(.dark)
    }
}
