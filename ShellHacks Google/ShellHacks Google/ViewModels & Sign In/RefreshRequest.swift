//
//  RefreshRequest.swift
//  ShellHacks Google
//
//  Created by Peter Khouly on 9/25/21.
//

import Foundation
import SwiftUI
import SwiftyJSON
import Alamofire

func checkIfAuthExpired(accessToken: String, refreshToken: String, expirationDate: Date, refreshRequest: RefreshRequest) {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    if let GMT = formatter.date(from: formatter.string(from: Date())) {
        // if expiration date is less than the current date then refresh the token.
        if expirationDate < GMT && !accessToken.isEmpty && !refreshToken.isEmpty {
            refreshRequest.getNewToken()
        }
    }
}

class RefreshRequest: ObservableObject {
    @AppStorage ("accessToken") var accessToken = ""
    @AppStorage ("refreshToken") var refreshToken = ""
    @AppStorage ("expiresIn") var expiresIn = 0

    @AppStorage ("expirationDate") var expirationDate: Date = Date().addingTimeInterval(3599)
    
    #if !os(watchOS)
    @ObservedObject private var viewModel = SignInViewModel()
    #endif

    func getNewToken() {

        let params: Parameters = [
            "client_id": "842741067623-316knspbqom765ph2no7jjc4kv06k2jo.apps.googleusercontent.com",
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ]
        
        AF.request("https://oauth2.googleapis.com/token", method: .post, parameters: params, encoding: JSONEncoding.default, headers: nil).validate(statusCode: 200 ..< 299).responseJSON { AFdata in
            do {
                if let AFdata = AFdata.data {
                    guard let jsonObject = try JSONSerialization.jsonObject(with: AFdata) as? [String: Any] else {
                        print("Error: Cannot convert data to JSON object")
                        return
                    }
                    guard let prettyJsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
                        print("Error: Cannot convert JSON object to Pretty JSON data")
                        return
                    }
                    guard let prettyPrintedJson = String(data: prettyJsonData, encoding: .utf8) else {
                        print("Error: Could print JSON in String")
                        return
                    }
                    
                    if let json = try? JSON(data: prettyJsonData, options: []) {
                        for (key1,subJson):(String, JSON) in json {
                            if key1 == "access_token" {
                                if let newToken = subJson.string {
                                    self.accessToken = newToken
                                }
                            }
                            if key1 == "expires_in" {
                                if let expiration = subJson.int {
                                    self.expiresIn = expiration
                                    self.expirationDate = Date().addingTimeInterval(TimeInterval(expiration - 60))
                                    print(self.expirationDate)
                                    // 1 minute leeway
                                }
                            }
                        }
                    }
                    
                    print(prettyPrintedJson)
                }
            } catch {
                print("Error: Trying to convert JSON data to string")
                return
            }
        }
    }
}
