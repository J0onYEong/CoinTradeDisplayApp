//
//  asd.swift
//  Data
//
//  Created by choijunios on 8/30/24.
//

import Foundation

enum CoinRequest {
    case orderbookL2(symbol: String)

    var url: URL {
        let baseURLStr: String = "wss://ws.bitmex.com/realtime?subscribe=orderBookL2"
        switch self {
        case .orderbookL2(let symbol):
            return URL(string: "\(baseURLStr):\(symbol)")!
        }
    }
}
