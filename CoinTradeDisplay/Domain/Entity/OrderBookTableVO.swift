//
//  OrderBookTableVO.swift
//  Domain
//
//  Created by choijunios on 8/25/24.
//

import Foundation

public struct CoinOrderScalar {
    var accumulatedAmount: Double
    var price: Double
}

public struct OrderBookTableVO {
    
    /// ascending
    var sellList: [CoinOrderScalar]
    
    /// descending
    var buyList: [CoinOrderScalar]
}
