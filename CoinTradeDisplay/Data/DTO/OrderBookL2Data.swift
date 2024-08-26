//
//  OrderBookL2Data.swift
//  Data
//
//  Created by choijunios on 8/25/24.
//

import Foundation


struct OrderBookL2Data: Decodable {
    
    enum OrderType: String, Decodable {
        case sell="Sell"
        case buy="Buy"
    }
    
    public let symbol: String
    public let id: Int
    public let side: OrderType
    public let size: Int64?
    public let price: Double
    public let timestamp: String
    public let transactTime: String
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
