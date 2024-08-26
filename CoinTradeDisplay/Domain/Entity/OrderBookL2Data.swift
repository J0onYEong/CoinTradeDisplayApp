//
//  OrderBookL2Data.swift
//  Domain
//
//  Created by choijunios on 8/25/24.
//

import Foundation

public enum OrderType: String, Decodable {
    case sell="Sell"
    case buy="Buy"
}

public struct OrderBookL2Data: Decodable {
    
    let symbol: String
    let id: Int
    let side: OrderType
    let size: Int?
    let price: Double
    let timestamp: String
    let transactTime: String
    enum CodingKeys: String, CodingKey {
        case symbol
        case id
        case side
        case size
        case price
        case timestamp
        case transactTime
    }
}
