//
//  PriceAndAmountCellRO.swift
//  Presentation
//
//  Created by choijunios on 8/30/24.
//

import Foundation
import Domain

public struct PriceAndAmountCellRO {
    public let type: OrderType
    public let price: Double
    public let amount: Int64
    public let percentage: Double
    
    public init(type: OrderType, price: Double, amount: Int64, percentage: Double) {
        self.type = type
        self.price = price
        self.amount = amount
        self.percentage = percentage
    }
    
    public static func emptyObject(_ type: OrderType) -> PriceAndAmountCellRO {
        .init(
            type: type,
            price: 0.0,
            amount: 0,
            percentage: 0
        )
    }
    
    public static func mockObject(_ type: OrderType) -> PriceAndAmountCellRO {
        .init(
            type: type,
            price: 1234.0,
            amount: 23,
            percentage: 0.32
        )
    }
}
