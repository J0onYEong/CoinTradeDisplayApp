//
//  OrderBookTableVO.swift
//  Domain
//
//  Created by choijunios on 8/25/24.
//

import Foundation

public struct CoinOrderScalar {
    public let accumulatedAmount: Double
    public let price: Double
}

public struct OrderBookTableVO {
    
    /// ascending
    public let sellList: [CoinOrderScalar]
    
    /// descending
    public let buyList: [CoinOrderScalar]
}
