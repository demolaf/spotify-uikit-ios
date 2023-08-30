//
//  Artist.swift
//  spotify-uikit
//
//  Created by Ademola Fadumo on 26/08/2023.
//

import Foundation

struct Artist: Codable {
    let id: String
    let name: String
    let type: String
    let external_urls: [String: String]
}
