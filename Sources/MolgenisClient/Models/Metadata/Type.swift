//
//  File.swift
//  
//
//  Created by Esther van Enckevort on 21-02-2020.
//

import Foundation

public enum Type: String, Decodable {
    case bool
    case categorical
    case categoricalmref
    case compound
    case date
    case datetime
    case decimal
    case email
    case `enum`
    case file
    case html
    case hyperlink
    case int
    case long
    case mref
    case onetomany
    case script
    case string
    case text
    case xref
}
