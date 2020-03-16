//
//  File.swift
//  
//
//  Created by Esther van Enckevort on 16-03-2020.
//

import Foundation

extension URLRequest {
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
        case patch = "PATCH"
        case put = "PUT"
    }

    var method: Method? {
        set {
            httpMethod = newValue?.rawValue
        }
        get {
            Method(rawValue: httpMethod ?? "")
        }
    }
}
