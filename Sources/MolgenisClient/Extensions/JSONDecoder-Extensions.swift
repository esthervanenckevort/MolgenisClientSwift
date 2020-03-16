//
//  File.swift
//  
//
//  Created by Esther van Enckevort on 16-03-2020.
//

import Foundation

extension JSONDecoder {
    static func iso8601() -> JSONDecoder {
        let decoder = JSONDecoder()
        if #available(OSX 10.12, *) {
            decoder.dateDecodingStrategy = .iso8601
        } else {
            let RFC3339DateFormatter = DateFormatter()
            RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
            RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            decoder.dateDecodingStrategy = .formatted(RFC3339DateFormatter)
        }
        return decoder
    }
}
