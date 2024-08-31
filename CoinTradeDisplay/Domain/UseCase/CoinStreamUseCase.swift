//
//  CoinStreamUseCase.swift
//  Domain
//
//  Created by choijunios on 8/25/24.
//

import Foundation
import RxSwift
import RxRelay
 
public protocol CoinStreamUseCase {
    
    /// #1. 웹소켓 스트림을 시작합니다.
    func startStream()
    
    /// #2. 웹소켓 스트림을 획득합니다.
    func getStream() -> Observable<OrderBookTableVO>
    
    /// #3. 웹소켓 스트림을 종료합니다.
    func stopStream()
}


public class DefaultCoinStreamUseCase: CoinStreamUseCase {

    typealias Price = Double
    typealias Amount = Double
    
    let orderBook2Repository: OrderBook2Repository
    
    public init(orderBook2Repository: OrderBook2Repository) {
        self.orderBook2Repository = orderBook2Repository
    }
    
    public func startStream() {
        orderBook2Repository.startSteam(coinSymbol: "XBTUSD")
    }
    
    public func getStream() -> Observable<OrderBookTableVO> {
        orderBook2Repository.setSream(
            bufferSize: 10,
            timeSpan: 50
        )
        return orderBook2Repository
            .joinStream(itemLimit: 20)
    }
    
    public func stopStream() {
        orderBook2Repository
            .stopStream(coinSymbol: "XBTUSD")
    }
}
