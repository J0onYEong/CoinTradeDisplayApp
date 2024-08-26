//
//  OrderBookTableVO.swift
//  Domain
//
//  Created by choijunios on 8/25/24.
//

import Foundation

public enum OrderType {
    case sell
    case buy
}

public struct CoinOrderScalar {
    public let accumulatedAmount: Int64
    public let price: Double
    
    public init(accumulatedAmount: Int64, price: Double) {
        self.accumulatedAmount = accumulatedAmount
        self.price = price
    }
}

public struct OrderBookTableVO {
    
    /// ascending
    public let sellList: [CoinOrderScalar]
    
    /// descending
    public let buyList: [CoinOrderScalar]
    
    public init(sellList: [CoinOrderScalar], buyList: [CoinOrderScalar]) {
        self.sellList = sellList
        self.buyList = buyList
    }
}
