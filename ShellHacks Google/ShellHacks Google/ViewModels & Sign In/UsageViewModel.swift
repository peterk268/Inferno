//
//  UsageViewModel.swift
//  ShellHacks Google
//
//  Created by Peter Khouly on 9/25/21.
//

import Foundation
import SwiftUI
import Alamofire
import SwiftyJSON

struct ComponentModel: Identifiable {
    
    let id = UUID()
    let name: String
    let imageName: String
    let color: Color
    var metricType: String? = nil
    var count: Any? = nil
    let billable: Bool
}

class UsageViewModel: ObservableObject {
    @ObservedObject var refreshRequest = RefreshRequest()
    @AppStorage ("refreshToken") var refreshToken = ""
    @AppStorage ("expirationDate") var expirationDate: Date = Date().addingTimeInterval(3599)
    
    
    @AppStorage ("projectID") var projectID = ""
    @AppStorage ("accessToken") var accessToken = ""
    
    @AppStorage ("selectedProject") var selectedProject: String = ""
    @AppStorage ("selectedTime") var selectedTime: String = "24 hours"

    @Published var metrics: [ComponentModel] = [
        ComponentModel(name: "Bill", imageName: "creditcard", color: .green, billable: false),
        ComponentModel(name: "Reads", imageName: "envelope.open", color: .blue, metricType: "document/read_count", billable: true),
        ComponentModel(name: "Writes", imageName: "rectangle.and.pencil.and.ellipsis", color: .orange, metricType: "document/write_count", billable: true),
        ComponentModel(name: "Deletes", imageName: "trash", color: .red, metricType: "document/delete_count", billable: true),
        ComponentModel(name: "Listeners", imageName: "phone.connection", color: .pink, metricType: "network/snapshot_listeners", billable: false),
        ComponentModel(name: "Connections", imageName: "point.topleft.down.curvedto.point.bottomright.up", color: Color(UIColor.cyan), metricType: "network/active_connections", billable: false)
    ]
    
    @AppStorage ("startDate") var startDate: Date = Date().addingTimeInterval(-86400)
    @AppStorage ("endDate") var endDate: Date = Date()
    
    func load(projectID: String, authToken: String) {
        
        checkIfAuthExpired(accessToken: accessToken, refreshToken: refreshToken, expirationDate: expirationDate, refreshRequest: refreshRequest)
        
        let startTime = firestoreDateToString(date: literalStringToDate(string: selectedTime))
        let endTime = firestoreDateToString(date: loadEndDate())
        
        DispatchQueue.main.async {
            //clearing the metrics
            for index in self.metrics.indices {
                self.metrics[index].count = nil
            }
        }
        
        let group = DispatchGroup()
        
        for (index, i) in metrics.enumerated() {
            if let metricType = i.metricType {
                group.enter()

                var totalCount = 0
                
                let urlBase = "https://content-monitoring.googleapis.com/v3/projects/\(projectID)/timeSeries"
                let parameters = "?filter=metric.type = \"firestore.googleapis.com/\(metricType)\"&interval.endTime=\(endTime)&interval.startTime=\(startTime)&access_token=\(authToken)"
                let url = urlBase + parameters
//                print(url)
                guard let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {return}
                print(encodedURL)
                AF.request(encodedURL, method: .get, encoding: JSONEncoding.default, headers: nil).validate(statusCode: 200 ..< 299).responseJSON { response in
                    switch response.result {
                    case .success(let value):
                        let json = JSON(value)
                        for (_, subJson):(String, JSON) in json {
                            //unit, timeSeries <--
                            for (_, subsubJson):(String, JSON) in subJson {
                                for (_, subsubsubJson):(String, JSON) in subsubJson {
                                    //valueType, metricKind, metric, resource, points <--
                                    //points is an array
                                    for (_, subsubsubsubJson):(String, JSON) in subsubsubJson {
                                        //0,1,2,3
                                        for (key5, subsubsubsubsubJson):(String, JSON) in subsubsubsubJson {
                                            //interval, value <--
                                            if key5 == "value" {
                                                for (_, subsubsubsubsubsubJson):(String, JSON) in subsubsubsubsubJson {
                                                    //int64Value
                                                    DispatchQueue.global().async {
                                                        totalCount += subsubsubsubsubsubJson.intValue
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                    case .failure(let error):
                        print(error)
                    }
                    group.leave()
                }
                group.notify(queue: DispatchQueue.main) {
                    self.metrics[index].count = totalCount
                    self.getBill()
                }
            }

        }
    }
    func getBill() {
        var bill: Double = 0
        
        var diffInDays = loadEndDate().interval(ofComponent: .day, fromDate: literalStringToDate(string: selectedTime)) //Calendar.current.dateComponents([.day], from: literalStringToDate(string: selectedTime), to: loadEndDate()).day ?? 1
        
        if diffInDays == 0 || selectedTime == "Custom" || selectedTime == "Current Billing Period" {
            diffInDays += 1
        }
        
        for i in metrics.filter({$0.billable == true}) {
            if let count = i.count as? Int {
                switch i.name {
                case "Reads":
                    bill += billableCount(diffInDays: diffInDays, count: count, free: 50000) * 0.06 / 100000 //50k a day free
                case "Writes":
                    bill += billableCount(diffInDays: diffInDays, count: count, free: 20000) * 0.18 / 100000 //20k a day free
                case "Deletes":
                    bill += billableCount(diffInDays: diffInDays, count: count, free: 20000) * 0.02 / 100000 //20k a day free
                default:
                    break
                }
            }
        }
//        print(bill)
        if let index = metrics.filter({$0.name == "Bill"}).indices.first {
            metrics[index].count = bill
        }
    }
    
    func billableCount(diffInDays: Int, count: Int, free: Int) -> Double {
        var billable = count - (free * diffInDays)
        if billable < 0 {
            billable = 0
        }
        return Double(billable)
    }
    
    func dateFormatter(date: Date) -> String {
        let timestampFormatter = DateFormatter()

        timestampFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        timestampFormatter.timeZone = TimeZone.current
        
        return timestampFormatter.string(from: date)
    }
    
    func loadEndDate() -> Date {
        if selectedTime == "Custom" {
            return endDate
        } else {
            return Date()
        }
    }

    func literalStringToDate(string: String) -> Date {
        var date: Date?
        if selectedTime == "Custom" {
            return startDate
        } else {
            if string == "Current Quota Period" {
                date = Calendar.current.date(byAdding: .day, value: -1, to: Date())
            }
            if string == "Current Billing Period" {
                let calendar = Calendar(identifier: .gregorian)
                let components = calendar.dateComponents([.year, .month], from: Date())
                date = calendar.date(from: components)
            }
            if string.contains("seconds") {
                let seconds = string.replacingOccurrences(of: " seconds", with: "")
                date = Calendar.current.date(byAdding: .second, value: -(Int(seconds) ?? 0), to: Date())
                
            } else if string.contains("minutes") {
                let minutes = string.replacingOccurrences(of: " minutes", with: "")
                date = Calendar.current.date(byAdding: .minute, value: -(Int(minutes) ?? 0), to: Date())

            } else if string.contains("hours") {
                let hours = string.replacingOccurrences(of: " hours", with: "")
                date = Calendar.current.date(byAdding: .hour, value: -(Int(hours) ?? 0), to: Date())

            } else if string.contains("days") {
                let days = string.replacingOccurrences(of: " days", with: "")
                date = Calendar.current.date(byAdding: .day, value: -(Int(days) ?? 0), to: Date())

            } else if string.contains("weeks") {
                let weeks = string.replacingOccurrences(of: " weeks", with: "")
                date = Calendar.current.date(byAdding: .weekOfMonth, value: -(Int(weeks) ?? 0), to: Date())

            } else if string.contains("months") {
                let months = string.replacingOccurrences(of: " months", with: "")
                date = Calendar.current.date(byAdding: .month, value: -(Int(months) ?? 0), to: Date())
                
            } else if string.contains("years") {
                let years = string.replacingOccurrences(of: " years", with: "")
                date = Calendar.current.date(byAdding: .year, value: -(Int(years) ?? 0), to: Date())
                
            }
            
            return date ?? Date().addingTimeInterval(-86400)
        }
    }
    func dateString() -> String {
        if selectedTime == "Custom" {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            return "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
            
        } else {
            return selectedTime
        }
    }
}
