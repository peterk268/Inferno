//
//  SignInViewModel.swift
//  ShellHacks Google
//
//  Created by Peter Khouly on 9/25/21.
//

import AuthenticationServices
import SwiftUI
import CryptoKit

class SignInViewModel: NSObject, ObservableObject {
    @Published var isShowingRepositoriesView = false
    @Published private(set) var isLoading = false
    
    func signInTapped() {
        let verifier = randomNonceString()
        
        guard let signInURL =
                NetworkRequest.RequestType.signIn(challenger: verifier).networkRequest()?.url
        else {
            print("Could not create the sign in URL .")
            return
        }
        
        let callbackURLScheme = NetworkRequest.callbackURLScheme
        let authenticationSession = ASWebAuthenticationSession(
            url: signInURL,
            callbackURLScheme: callbackURLScheme) { [weak self] callbackURL, error in
            // 1
            guard
                error == nil,
                let callbackURL = callbackURL,
                // 2
                let queryItems = URLComponents(string: callbackURL.absoluteString)?.queryItems,
                // 3
                let code = queryItems.first(where: { $0.name == "code" })?.value,
                // 4
                let networkRequest =
                    NetworkRequest.RequestType.codeExchange(code: code, verifier: verifier).networkRequest()
            else {
                // 5
                print("An error occurred when attempting to sign in.")
                return
            }
            DispatchQueue.main.async {
                self?.isLoading = true
            }
            networkRequest.start(responseType: String.self) { (result) -> Void in
                switch result {
                case .success:
                    self?.isLoading = false
                //          self?.getUser()
                case .failure(let error):
                    print("Failed to exchange access code for tokens: \(error)")
                    self?.isLoading = false
                }
            }
        }
        
        authenticationSession.presentationContextProvider = self
        authenticationSession.prefersEphemeralWebBrowserSession = true
        
        if !authenticationSession.start() {
            print("Failed to start ASWebAuthenticationSession")
        }
    }
    
    
}

//Hashing function using CryptoKit
func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
    }.joined()
    
    return hashString
}

func randomNonceString(length: Int = 76) -> String {
    precondition(length > 0)
    let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._~")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
            return random
        }
        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }
            
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    return result
}

extension SignInViewModel: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession)
    -> ASPresentationAnchor {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}

