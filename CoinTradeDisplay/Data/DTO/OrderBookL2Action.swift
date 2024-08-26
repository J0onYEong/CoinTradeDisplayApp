//
//  OrderBookL2Action.swift
//  Data
//
//  Created by choijunios on 8/25/24.
//

import Foundation

enum OrderBookL2Action: String, Decodable {
    case partial
    case update
    case delete
    case insert
}
