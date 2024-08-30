//
//  DefaultOrderBook2Repository.swift
//  Data
//
//  Created by choijunios on 8/25/24.
//

import Foundation
import Domain
import RxSwift

public class DefaultOrderBook2Repository: OrderBook2Repository {
    
    typealias Price = Double
    typealias Amount = Int64
    
    let webSocketService: WebSocketService
    let decoder = JSONDecoder()
    
    private(set) var accumulatedCoinTradeDictForBuy: [Price: Amount] = [:]
    private(set) var accumulatedCoinTradeDictForSell: [Price: Amount] = [:]
    
    /// 딕셔너리가 업데이트 된 경우 이벤트를 방출하는 옵저버블
    private var updateSignal: BehaviorSubject<Void> = .init(value: ())
    
    
    private let dataFromWebSocket: PublishSubject<OrderBookL2DTO> = .init()
    
    private var streamHolder: Disposable?
    
    public init(webSocketService: WebSocketService) {
        self.webSocketService = webSocketService
    }
    
    public func startSteam(coinSymbol: String) {
        
        let request: CoinRequest = .orderbookL2(symbol: coinSymbol)
        
        webSocketService
            .startConnection(url: request.url) { [dataFromWebSocket, weak self] string, data in
                var jsonData: Data!
                
                if let string {
                    jsonData = string.data(using: .utf8)
                } else if let data {
                    jsonData = data
                } else {
                    return
                }
                
                if let decoded = try? self?.decoder.decode(OrderBookL2DTO.self, from: jsonData) {
                    
                    dataFromWebSocket.onNext(decoded)
                }
            }
    }
    
    public func setSream(bufferSize: Int, timeSpan: Int) {
        
        // 이미스트림이 진행중
        if streamHolder != nil { return }
        
        let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
        
        streamHolder = dataFromWebSocket
            .buffer(
                timeSpan: .milliseconds(5000),
                count: bufferSize,
                scheduler: scheduler
            )
            .throttle(.milliseconds(timeSpan), scheduler: scheduler)
            .map { [weak self] buffers in
                
                guard let self else { return }
                
                for frame in buffers {
                    
                    let action = frame.action
                    
                    for transaction in frame.data {
                        
                        if transaction.side == .buy {
                            executeAction(
                                action: action,
                                dict: &self.accumulatedCoinTradeDictForBuy,
                                transaction: transaction
                            )
                        } else {
                            executeAction(
                                action: action,
                                dict: &self.accumulatedCoinTradeDictForSell,
                                transaction: transaction
                            )
                        }
                    }
                }
            }
            .subscribe(updateSignal)
    }
    
    public func joinStream(itemLimit: Int) -> Observable<OrderBookTableVO> {
        updateSignal
            .compactMap({ [weak self] _ in
                self?.fetchItems(itemLimit: itemLimit)
            })
    }
    
    public func stopStream(coinSymbol: String) {
        
        let request: CoinRequest = .orderbookL2(symbol: coinSymbol)
        
        streamHolder?.dispose()
        streamHolder = nil
        webSocketService.resignConnection(url: request.url)
    }
    
    private func fetchItems(itemLimit: Int) -> OrderBookTableVO {
        
        // DESC
        let buyListLimit = min(accumulatedCoinTradeDictForBuy.keys.count, itemLimit)
        let buyList = accumulatedCoinTradeDictForBuy.keys.sorted(by: { $0 > $1 })[0..<buyListLimit].map { key in
            CoinOrderScalar(
                accumulatedAmount: self.accumulatedCoinTradeDictForBuy[key]!,
                price: key
            )
        }
        
        // ASC
        let sellListLimit = min(accumulatedCoinTradeDictForSell.keys.count, itemLimit)
        let sellList = accumulatedCoinTradeDictForSell.keys.sorted(by: { $0 < $1 })[0..<sellListLimit].map { key in
            CoinOrderScalar(
                accumulatedAmount: self.accumulatedCoinTradeDictForSell[key]!,
                price: key
            )
        }
        
        return .init(
            sellList: sellList,
            buyList: buyList
        )
    }
    
    private func executeAction(action: OrderBookL2Action, dict: inout [Price: Amount], transaction: OrderBookL2Data) {
        
        switch action {
        case .partial, .insert:
            dict[transaction.price] = transaction.size!
        case .update:
            dict[transaction.price]? += transaction.size!
        case .delete:
            dict.removeValue(forKey: transaction.price)
        }
    }
}
