//
//  RecommendationsResponse.swift
//  spotify-uikit
//
//  Created by Ademola Fadumo on 31/08/2023.
//

import Foundation

struct RecommendationsResponse: Codable {
    let tracks: [AudioTrack]
}
