//
//  File.swift
//  
//
//  Created by Esther van Enckevort on 21-02-2020.
//

import Foundation

public struct CollectionResponse<T: Decodable>: Decodable {
    let href: URL
    let nextHref: URL?
    let prefHref: URL?
    let start: Int
    let num: Int
    let total: Int
    let items: [T]
}
