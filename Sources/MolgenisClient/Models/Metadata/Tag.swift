//
//  File.swift
//  
//
//  Created by Esther van Enckevort on 21-02-2020.
//

import Foundation

public final class Tag: Decodable {
    static var _entityName = "sys_md_Tag"
    var _id: String { id }
    var _label: String { label }
    public let id: String
    public let objectIRI: String?
    public let label: String
    public let relationIRI: String?
    public let relationLabel: String?
    public let codeSystem: String?
}
