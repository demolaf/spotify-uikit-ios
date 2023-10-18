//
//  AuthManager.swift
//  spotify-uikit
//
//  Created by Ademola Fadumo on 26/08/2023.
//

import Foundation

final class AuthManager {
    static let shared = AuthManager()

    private var refreshingToken = false

    struct Constants {
        static let clientID = "c8654151a2c943d495ad98bdaa5278a7"
        static let clientSecret = "5998d6f1671a426691280833e27be5f0"
        static let tokenAPIURL = "https://accounts.spotify.com/api/token"
        static let redirectURI = "https://google.com"
        static let base = "https://accounts.spotify.com/authorize"
        static let scopes = "user-read-email user-read-private playlist-modify-public playlist-read-private playlist-modify-private user-follow-read user-library-modify user-library-read"
    }

    private init() {}

    public var signInURL: URL? {

        let string = "\(Constants.base)?response_type=code&client_id=\(Constants.clientID)&scope=\(Constants.scopes)&redirect_uri=\(Constants.redirectURI)&show_dialog=TRUE"
        return URL(string: string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
    }

    var isSignedIn: Bool {
        return accessToken != nil
    }

    private var accessToken: String? {
        return UserDefaults.standard.string(forKey: "access_token")
    }

    private var refreshToken: String? {
        return UserDefaults.standard.string(forKey: "refresh_token")
    }

    private var tokenExpirationDate: Date? {
        return UserDefaults.standard.object(forKey: "expirationDate") as? Date
    }

    private var shouldRefreshToken: Bool {
        guard let expirationDate = tokenExpirationDate else {
            return false
        }

        let currentDate = Date()
        let fiveMinutes: TimeInterval = 300
        return currentDate.addingTimeInterval(fiveMinutes) >= expirationDate
    }

    public func exchangeCodeForToken(code: String, completion: @escaping (Bool) -> Void) {
        // Get Token api call
        guard let url = URL(string: Constants.tokenAPIURL) else {
            completion(false)
            return
        }

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI)
        ]

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = components.query?.data(using: .utf8)
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let basicToken = Constants.clientID+":"+Constants.clientSecret
        let data = basicToken.data(using: .utf8)

        guard let base64String = data?.base64EncodedString() else {
            print("Failure to get base64")
            completion(false)
            return
        }

        urlRequest.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                completion(false)
                return
            }

            do {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                print("SUCCESS: \(result)")

                self?.cacheToken(result: result)
                completion(true)
            } catch {
                print(error)
                completion(false)
            }
        }

        task.resume()
    }

    public func exchangeCodeForToken(code: String) async -> Bool {
        // Get Token api call
        guard let url = URL(string: Constants.tokenAPIURL) else {
            return false
        }

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI)
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = components.query?.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let basicToken = Constants.clientID+":"+Constants.clientSecret
        let data = basicToken.data(using: .utf8)

        guard let base64String = data?.base64EncodedString() else {
            print("Failure to get base64")
            return false
        }

        request.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            let result = try JSONDecoder().decode(AuthResponse.self, from: data)

            print("PRINT SUCCESS: \(result)")
            self.cacheToken(result: result)
            return true
        } catch {
            return false
        }
    }

    public func refreshAccessToken(completion: ((Bool) -> Void)?) {
        // Get Token api call
        guard let url = URL(string: Constants.tokenAPIURL) else {
            completion?(false)
            return
        }

        refreshingToken = true

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ]

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = components.query?.data(using: .utf8)
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let basicToken = Constants.clientID+":"+Constants.clientSecret
        let data = basicToken.data(using: .utf8)

        guard let base64String = data?.base64EncodedString() else {
            print("Failure to get base64")
            completion?(false)
            return
        }

        urlRequest.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, _, error in
            self?.refreshingToken = false

            guard let data = data, error == nil else {
                completion?(false)
                return
            }

            do {
                let response = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                print("Check here: \(response)")

                let result = try JSONDecoder().decode(AuthResponse.self, from: data)

                //
                self?.onRefreshBlocks.forEach { $0(result.access_token) }
                self?.onRefreshBlocks.removeAll()

                self?.cacheToken(result: result)
                completion?(true)
            } catch {
                print(error)
                completion?(false)
            }
        }

        task.resume()
    }

    private var onRefreshBlocks = [((String) -> Void)]()

    /// Supplies valid token to be used with API Calls
    public func withValidToken(completion: @escaping (String) -> Void) {
        guard !refreshingToken else {
            // Append completion
            onRefreshBlocks.append(completion)
            return
        }

        if shouldRefreshToken {
            // Refresh
            refreshIfNeeded { [weak self] success in
                if success {
                    if let token = self?.accessToken, success {
                        completion(token)
                    }
                }
            }
        } else if let token = accessToken {
            completion(token)
        }
    }

    public func refreshIfNeeded(completion: ((Bool) -> Void)?) {
        guard !refreshingToken else {
            return
        }

        guard shouldRefreshToken else {
            completion?(true)
            return
        }

        self.refreshAccessToken { success in
            completion?(success)
        }
    }

    private func cacheToken(result: AuthResponse) {
        UserDefaults.standard.setValue(result.access_token, forKey: "access_token")

        // to avoid overriding the refresh token when refreshing access token
        if let refresh_token = result.refresh_token {
            UserDefaults.standard.setValue(refresh_token, forKey: "refresh_token")
        }
        UserDefaults.standard.setValue(Date().addingTimeInterval(TimeInterval(result.expires_in)), forKey: "expirationDate")
    }
}
