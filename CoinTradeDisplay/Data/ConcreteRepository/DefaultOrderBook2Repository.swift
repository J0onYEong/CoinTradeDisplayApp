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
    
    let webSocketService: WebSocketService
    let decoder = JSONDecoder()
    
    public init(webSocketService: WebSocketService) {
        self.webSocketService = webSocketService
    }
    
    public func getInitialDataSet(coinSymbol: String) -> RxSwift.Single<[Domain.OrderBookL2Data]> {
        
        let url = URL(string: "wss://ws.bitmex.com/realtime?subscribe=orderBookL2:\(coinSymbol)")!
        
        return Single<[OrderBookL2Data]>.create { [weak self] singleObserver in
            
            self?.webSocketService
                .startConnection(url: url) { [singleObserver] string, data in
                    
                    var jsonData: Data!
                    
                    if let string {
                        jsonData = string.data(using: .utf8)
                    } else if let data {
                        jsonData = data
                    } else {
                        return
                    }
                    
                    if let decoded = try? self?.decoder.decode(OrderBookL2DTO.self, from: jsonData) {
                        
                        if decoded.action == .partial {
                            
                            // partial상태일 때만 이벤트를 전달한다.
                            singleObserver(.success(decoded.data))
                        }
                    }
                }
            
            return Disposables.create { }
        }
    }
    
    public func getDataContinuosly(bufferSize: Int, timeSpan: Int) -> RxSwift.Observable<[Domain.OrderBookL2Data]> {
        
        let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
        
        let observable = Observable<[OrderBookL2Data]>.create { [weak self] observer in
            
            self?.webSocketService.changeCompletion { string, data in
                var jsonData: Data!
                
                if let string {
                    jsonData = string.data(using: .utf8)
                } else if let data {
                    jsonData = data
                } else {
                    return
                }
                
                if let decoded = try? self?.decoder.decode(OrderBookL2DTO.self, from: jsonData) {
                    
                    observer.onNext(decoded.data)
                }
            }
            
            return Disposables.create {
                self?.webSocketService.resignConnection()
            }
        }
        
        return observable
            .buffer(
                timeSpan: .milliseconds(5000),
                count: bufferSize,
                scheduler: scheduler
            )
            .map { dimention2Data in
                dimention2Data.flatMap { $0 }
            }
            .throttle(.milliseconds(timeSpan), scheduler: scheduler)
    }
}
