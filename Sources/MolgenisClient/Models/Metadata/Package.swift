//
//  File.swift
//  
//
//  Created by Esther van Enckevort on 21-02-2020.
//

import Foundation

public final class Package: Decodable {
    public let id: String
    public let label: String
    public let description: String?
    public let parent: Package?
    public let children: [Package]?
    public let entityTypes: [EntityType]?
    public let tags: [Tag]?
}
