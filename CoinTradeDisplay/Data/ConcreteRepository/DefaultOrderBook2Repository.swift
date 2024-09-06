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
    
    /// 방출이벤트를 처리하는 스케쥴러
    let timerScheduler = ConcurrentDispatchQueueScheduler(qos: .background)
    
    /// buyList, sellList방출 스케쥴러
    let accumulatedDataContactScheduler = SerialDispatchQueueScheduler(qos: .userInteractive)
    
    private var streamHolder: Disposable?
    
    public init(webSocketService: WebSocketService) {
        self.webSocketService = webSocketService
        
        // 데이터가 전달되면 딕셔너리를 업데이트 합니다.
        streamHolder = dataFromWebSocket
            .observe(on: accumulatedDataContactScheduler)
            .map { [weak self] frame in
                
                guard let self else { return }
                
                // 데이터를 레포지토리 딕셔너리에 기록합니다.
                
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
            .subscribe(updateSignal)
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
    
    public func joinStream(bufferSize: Int, timeSpan: Int, itemLimit: Int) -> Observable<OrderBookTableVO> {
        
        updateSignal
            .buffer(
                timeSpan: .milliseconds(5000),
                count: bufferSize,
                scheduler: timerScheduler
            )
            .throttle(.milliseconds(timeSpan), scheduler: timerScheduler)
            .observe(on: accumulatedDataContactScheduler)
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
