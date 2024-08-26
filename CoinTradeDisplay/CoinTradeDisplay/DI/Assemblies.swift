//
//  Assemblies.swift
//  CoinTradeDisplay
//
//  Created by choijunios on 8/26/24.
//

import Foundation
import Domain
import Data
import Swinject

public struct DefaultAssembly: Assembly {
    public func assemble(container: Container) {
        
        // MARK: Services
        container.register(WebSocketService.self) { _ in
            return DefaultWebSocketService()
        }
        
        // MARK: Repository
        container.register(OrderBook2Repository.self) { resolver in
            let webSocketService = resolver.resolve(WebSocketService.self)!
            
            return DefaultOrderBook2Repository(
                webSocketService: webSocketService
            )
        }
        .inObjectScope(.container)
        
        // MARK: UseCase
        container.register(CoinStreamUseCase.self) { resolver in
            let orderBook2Repository = resolver.resolve(OrderBook2Repository.self)!
            
            return DefaultCoinStreamUseCase(
                orderBook2Repository: orderBook2Repository
            )
        }
    }
}
