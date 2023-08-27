//
//  APICaller.swift
//  spotify-uikit
//
//  Created by Ademola Fadumo on 26/08/2023.
//

import Foundation

final class APICaller {
    static let shared = APICaller()
    
    private init() {}
    
    public func getCurrentUserProfile(completion: @escaping (Result<UserProfile, Error>) -> Void) {
        
    }
    
    // MARK: - Private
    
    private func createRequest(with url: URL?, completion: @escaping (URLRequest) -> Void) {
        AuthManager.shared.withValidToken { token in
            guard let apiURL = url else {
                return
            }
            
            var requsst = URLRequest(url: apiURL)
            requsst.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            completion(requsst)
        }
    }
}
