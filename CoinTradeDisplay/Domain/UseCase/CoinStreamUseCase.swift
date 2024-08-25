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
    
    /// #1. 내부 스트림에 접근할 수 있습니다.
    var coinDataSubject: BehaviorSubject<OrderBookTableVO> { get }
    
    /// #2. 웹소켓 스트림을 시작합니다.
    func startStream()
    
    /// #3. 웹소켓 스트림을 종료합니다.
    func stopStream()
}


public class DefaultCoinStreamUseCase: CoinStreamUseCase {
    
    typealias Price = Double
    typealias Amount = Double
    
    let orderBook2Repository: OrderBook2Repository
    
    private(set) var accumulatedCoinTradeDictForBuy: [Price: Amount] = [:]
    private(set) var accumulatedCoinTradeDictForSell: [Price: Amount] = [:]
    
    public let coinDataSubject: BehaviorSubject<OrderBookTableVO> = .init(value: .init(sellList: [], buyList: []))
    
    private(set) var streamDisposable: Disposable?
    
    public init(orderBook2Repository: OrderBook2Repository) {
        self.orderBook2Repository = orderBook2Repository
    }
    
    public func startStream() {
        
        // 최초 Fetching
        let initialFetch = orderBook2Repository
            .getInitialDataSet(coinSymbol: "XBTUSD")
            .asObservable()
            .map { [weak self] orderList in
                
                guard let self else { return }
                
                self.updateAndEmit(orderList: orderList)
            }
        
        // 연속적 Fetching
        self.streamDisposable = initialFetch
            .flatMap { [orderBook2Repository] _ in
                
                orderBook2Repository
                    .getDataContinuosly(
                        bufferSize: 20,
                        timeSpan: 300
                    )
            }
            .subscribe(onNext: { [weak self] orderList in
                
                self?.updateAndEmit(orderList: orderList)
            })
    }
    
    public func stopStream() {
        streamDisposable?.dispose()
        streamDisposable = nil
    }
    
    private func updateAndEmit(orderList: [OrderBookL2Data]) {
        for order in orderList {
            switch order.side {
            case .buy:
                if accumulatedCoinTradeDictForBuy[order.price] != nil {
                    accumulatedCoinTradeDictForBuy[order.price]! += (Double(order.size ?? 0))
                } else {
                    accumulatedCoinTradeDictForBuy[order.price] = 0.0
                }
            case .sell:
                if accumulatedCoinTradeDictForSell[order.price] != nil {
                    accumulatedCoinTradeDictForSell[order.price]! += (Double(order.size ?? 0))
                } else {
                    accumulatedCoinTradeDictForSell[order.price] = 0.0
                }
            }
        }
        
        // DESC
        let buyList = accumulatedCoinTradeDictForBuy.keys.sorted(by: { $0 > $1 })[0..<10].map { key in
            CoinOrderScalar(
                accumulatedAmount: self.accumulatedCoinTradeDictForBuy[key]!,
                price: key
            )
        }
        let sellList = accumulatedCoinTradeDictForSell.keys.sorted(by: { $0 < $1 })[0..<10].map { key in
            CoinOrderScalar(
                accumulatedAmount: self.accumulatedCoinTradeDictForBuy[key]!,
                price: key
            )
        }
        
        self.coinDataSubject.onNext(
            .init(
                sellList: sellList,
                buyList: buyList
            )
        )
    }
}
