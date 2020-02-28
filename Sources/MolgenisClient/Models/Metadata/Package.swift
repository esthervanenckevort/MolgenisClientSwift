//
//  File.swift
//  
//
//  Created by Esther van Enckevort on 21-02-2020.
//

import Foundation

public final class Package: EntityResponse {
    public static var _entityName = "sys_md_Package"
    public var _id: String { id }
    public var _label: String { label }
    public let id: String
    public let label: String
    public let description: String?
    public let parent: Package?
    public let children: [Package]?
    public let entityTypes: [EntityType]?
    public let tags: [Tag]?
}
