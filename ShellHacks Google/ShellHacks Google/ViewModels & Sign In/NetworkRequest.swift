//
//  NetworkRequest.swift
//  ShellHacks Google
//
//  Created by Peter Khouly on 9/25/21.
//

import Foundation
import SwiftyJSON


struct NetworkRequest {
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }
    
    enum RequestError: Error {
        case invalidResponse
        case networkCreationError
        case otherError
        case sessionExpired
    }
    
    enum RequestType: Equatable {
        case codeExchange(code: String, verifier: String)
        case getUser
        case signIn(challenger: String)
        
        func networkRequest() -> NetworkRequest? {
            guard let url = url() else {
                return nil
            }
            return NetworkRequest(method: httpMethod(), url: url)
        }
        
        private func httpMethod() -> NetworkRequest.HTTPMethod {
            switch self {
            case .codeExchange:
                return .post
            case .getUser:
                return .get
            case .signIn:
                return .get
            }
        }
        
        private func url() -> URL? {
            switch self {
            case .codeExchange(let code, let verifier):
                let queryItems = [
                    URLQueryItem(name: "code", value: code),
                    URLQueryItem(name: "client_id", value: NetworkRequest.clientID),
                    URLQueryItem(name: "client_secret", value: NetworkRequest.clientSecret),
                    URLQueryItem(name: "redirect_uri", value: "com.Peter-Khouly.Inferno:/oauth2Callback"),
                    URLQueryItem(name: "grant_type", value: "authorization_code"),
                    URLQueryItem(name: "code_verifier", value: verifier)
                ]
                return urlComponents(host: "oauth2.googleapis.com", path: "/token", queryItems: queryItems).url
            case .getUser:
                return urlComponents(path: "/user", queryItems: nil).url
            case .signIn(let challenger):
                let queryItems = [
                    URLQueryItem(name: "client_id", value: NetworkRequest.clientID),
                    URLQueryItem(name: "redirect_uri", value: "com.Peter-Khouly.Inferno:/oauth2Callback"),
                    URLQueryItem(name: "response_type", value: "code"),
                    URLQueryItem(name: "scope", value: NetworkRequest.scope),
                    URLQueryItem(name: "state", value: NetworkRequest.state),
                    URLQueryItem(name: "code_challenge", value: challenger),
                    URLQueryItem(name: "code_challenge_method", value: "plain"),
                    URLQueryItem(name: "access_type", value: "offline")
                ]
                return urlComponents(host: "accounts.google.com", path: "/o/oauth2/auth", queryItems: queryItems).url
            }
        }
        
        func urlComponents(host: String = "googleapis.com", path: String, queryItems: [URLQueryItem]?) -> URLComponents {
            switch self {
            default:
                var urlComponents = URLComponents()
                urlComponents.scheme = "https"
                urlComponents.host = host
                urlComponents.path = path
                urlComponents.queryItems = queryItems
                return urlComponents
            }
        }
    }
    
    typealias NetworkResult<T: Decodable> = (response: HTTPURLResponse, object: T)
    
    // MARK: Private Constants
    static let callbackURLScheme = "com.Peter-Khouly.Inferno"
    static let clientID = "842741067623-316knspbqom765ph2no7jjc4kv06k2jo.apps.googleusercontent.com"
    static let clientSecret = ""
    static let scope = "https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/monitoring"
    static let state = "GOOGLE"
    
    
    // MARK: Properties
    var method: HTTPMethod
    var url: URL
    
    // MARK: Methods
    func start<T: Decodable>(responseType: T.Type, completionHandler: @escaping ((Result<NetworkResult<T>, Error>) -> Void)) {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        let session = URLSession.shared.dataTask(with: request) { (data, response, error) -> Void in
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completionHandler(.failure(RequestError.invalidResponse))
                }
                return
            }
            guard
                error == nil,
                let data = data
            else {
                DispatchQueue.main.async {
                    let error = error ?? NetworkRequest.RequestError.otherError
                    completionHandler(.failure(error))
                }
                return
            }
            
            if T.self == String.self, let responseString = String(data: data, encoding: .utf8) {
                let components = responseString.components(separatedBy: ",")
                var dictionary: [String: String] = [:]
                print(responseString)
                UserDefaults.standard.setValue(data, forKey: "authJSON")
                for component in components {
                    let itemComponents = component.components(separatedBy: ":")
                    if let key = itemComponents.first, let value = itemComponents.last {
                        dictionary[key] = value
                        print(key)
                        print(value)
                    }
                }
                DispatchQueue.main.async {
                    do {
                        let json = try JSON(data: data, options: [])
                        for (key,subJson):(String, JSON) in json {
                            if key == "access_token" {
                                UserDefaults.standard.setValue(String(describing: subJson), forKey: "accessToken")
                            }
                            if key == "refresh_token" {
                                UserDefaults.standard.setValue(String(describing: subJson), forKey: "refreshToken")
                            }
                            if key == "expires_in" {
                                UserDefaults.standard.setValue(subJson.int, forKey: "expiresIn")
                            }
                            print("key : \(key)")
                            print(subJson)
                        }
                    } catch {
                        print("error")
                    }

                    completionHandler(.success((response, "Success" as! T)))
                }
                return
            } else if let object = try? JSONDecoder().decode(T.self, from: data) {
                DispatchQueue.main.async {
                    completionHandler(.success((response, object)))
                }
                return
            } else {
                DispatchQueue.main.async {
                    completionHandler(.failure(NetworkRequest.RequestError.otherError))
                }
            }
        }
        session.resume()
    }
}

