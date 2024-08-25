//
//  OrderBookL2DTO.swift
//  Data
//
//  Created by choijunios on 8/25/24.
//

import Foundation
import Domain

struct OrderBookL2DTO: Decodable {
    let action: OrderBookL2Action
    let data: [OrderBookL2Data]
}
