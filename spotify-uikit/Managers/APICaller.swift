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
    
    struct Constants {
        static let baseAPIURL = "https://api.spotify.com/v1"
    }
    
    enum APIError: Error {
        case failedToGetData
    }
    
    public func getCurrentUserProfile(completion: @escaping (Result<UserProfile, Error>) -> Void) {
        createRequest(
            with: URL(string: Constants.baseAPIURL + "/me"),
            type: .GET
        ) { baseRequest in
            let task = URLSession.shared.dataTask(with: baseRequest) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do {
                    let result = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    print(result)
                } catch {
                    print("From json serialization: \(error)")
                }
                
                do {
                    let result = try JSONDecoder().decode(UserProfile.self, from: data)
                    print(result)
                    completion(.success(result))
                } catch {
                    print(error)
                    completion(.failure(error))
                }
                
                
            }
            
            task.resume()
        }
    }
    
    public func getNewReleases(completion: @escaping ((Result<NewReleasesResponse, Error>)) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/browse/new-releases?limit=50"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(NewReleasesResponse.self, from: data)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            }
            
            task.resume()
        }
    }
    
    public func getFeaturedPlaylists(completion: @escaping ((Result<FeaturedPlaylistResponse, Error>) -> Void)) {
        createRequest(
            with: URL(string: Constants.baseAPIURL + "/browse/featured-playlists?limit=2"),
            type: .GET
        ) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(FeaturedPlaylistResponse.self, from: data)
                    print(result)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            }
            
            task.resume()
        }
    }
    
    public func getRecommendations(genres: Set<String>, completion: @escaping ((Result<String, Error>) -> Void)) {
        let seeds = genres.joined(separator: ",")
        createRequest(
            with: URL(string: Constants.baseAPIURL + "/recommendations?seed_genres=\(seeds)&limit=2"),
            type: .GET
        ) { request in
            print(request.url?.absoluteString)
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                    print(json)
                } catch {
                    completion(.failure(error))
                }
            }
            
            task.resume()
        }
    }
    
    func getRecommendedGenres(completion: @escaping ((Result<RecommendedGenresResponse, Error>) -> Void)) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/recommendations/available-genre-seeds"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(RecommendedGenresResponse.self, from: data)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            }
            
            task.resume()
        }
    }
    
    // MARK: - Private
    
    enum HTTPMethod: String {
        case GET
        case POST
    }
    
    private func createRequest(
        with url: URL?,
        type: HTTPMethod,
        completion: @escaping (URLRequest) -> Void
    ) {
        AuthManager.shared.withValidToken { token in
            guard let apiURL = url else {
                return
            }
            
            var requsst = URLRequest(url: apiURL)
            requsst.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            requsst.httpMethod = type.rawValue
            requsst.timeoutInterval = 30
            completion(requsst)
        }
    }
}
