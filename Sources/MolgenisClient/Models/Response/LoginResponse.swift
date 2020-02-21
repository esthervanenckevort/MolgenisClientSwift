//
//  File.swift
//  
//
//  Created by Esther van Enckevort on 21-02-2020.
//

import Foundation

struct LoginResponse: Decodable {
    let username: String
    let firstname: String?
    let lastname: String?
    let token: String
}
