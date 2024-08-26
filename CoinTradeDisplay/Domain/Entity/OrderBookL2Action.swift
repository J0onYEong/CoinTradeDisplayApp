//
//  OrderBookL2Action.swift
//  Domain
//
//  Created by choijunios on 8/25/24.
//

import Foundation

public enum OrderBookL2Action: String, Decodable {
    case partial
    case update
    case delete
    case insert
}
