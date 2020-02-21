//
//  File.swift
//  
//
//  Created by Esther van Enckevort on 21-02-2020.
//

import Foundation

public protocol Entity: Decodable {
    static var _entityName: String { get }
    var _id: String { get }
    var _label: String { get }
}
