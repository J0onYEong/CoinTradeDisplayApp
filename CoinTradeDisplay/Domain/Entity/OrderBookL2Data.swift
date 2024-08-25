//
//  OrderBookL2Data.swift
//  Domain
//
//  Created by choijunios on 8/25/24.
//

import Foundation

public struct OrderBookL2Data: Codable {
    
    enum OrderType: String, Decodable {
        case sell="Sell"
        case buy="Buy"
    }
    
    let symbol: String
    let id: Int
    let side: String
    let size: Int
    let price: Double
    let timestamp: Date
    let transactTime: Date
    
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
