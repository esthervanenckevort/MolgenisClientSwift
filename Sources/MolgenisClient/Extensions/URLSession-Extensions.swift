//
//  File.swift
//  
//
//  Created by Esther van Enckevort on 16-03-2020.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension URLSession {
    convenience init(configuration: URLSessionConfiguration, token: String?) {
        let configuration = configuration
        var headers = configuration.httpAdditionalHeaders ?? [AnyHashable: Any]()
        headers[Header.contentType.rawValue] = ContentType.json.rawValue
        if let token = token {
            headers[Header.token.rawValue] = token
        } else {
            headers.removeValue(forKey: Header.token.rawValue)
        }
        configuration.httpAdditionalHeaders = headers
        self.init(configuration: configuration)
    }

    private enum Header: String {
        case contentType = "Content-Type"
        case token = "x-molgenis-token"
    }

    private enum ContentType: String {
        case json = "application/json;charset=UTF-8"
    }
}
