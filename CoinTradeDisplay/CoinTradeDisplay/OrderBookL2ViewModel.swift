//
//  OrderBookL2ViewModel.swift
//  CoinTradeDisplay
//
//  Created by choijunios on 8/30/24.
//

import Foundation
import Domain
import RxCocoa
import RxSwift
import Presentation

// MARK: ViewModel
public class OrderBookL2ViewModel {
    
    // Config
    let cellCount = 20
    
    // Init
    let coinStreamUseCase: CoinStreamUseCase
    
    // Input
    let startStreamButtonClicked: PublishRelay<Void> = .init()
    let connectStreamButtonClicked: PublishRelay<Void> = .init()
    
    // Output
    private(set) var buyListRO: Driver<[PriceAndAmountCellRO]>?
    private(set) var sellListRO: Driver<[PriceAndAmountCellRO]>?
    
    let disposeBag = DisposeBag()
    
    init(coinStreamUseCase: CoinStreamUseCase) {
        self.coinStreamUseCase = coinStreamUseCase
        
        // MARK: 스트림 시작
        startStreamButtonClicked
            .subscribe(onNext: { [coinStreamUseCase] _ in
                coinStreamUseCase.startStream()
            })
            .disposed(by: disposeBag)
        
        // MARK: 스트림 구독
        let coinStream = BehaviorSubject<OrderBookTableVO>(
            value: .init(
                sellList: [],
                buyList: []
            )
        )
        
        // 구독버튼 누를시 스트림 연결
        connectStreamButtonClicked
            .compactMap { [weak self] in self?.cellCount }
            .flatMap { [coinStreamUseCase] cellCount in
                return coinStreamUseCase
                    .getStream(itemLimit: cellCount)
            }
            .share()
            .bind(to: coinStream)
            .disposed(by: disposeBag)
            
        let buyStream = coinStream.map { vo in
            vo.buyList
        }
        let sellStream = coinStream.map { vo in
            vo.sellList
        }
        
        
        // MARK: Buy
        buyListRO = buyStream.map({ [weak self]
            buyData in
            
            let accumulatedSum: Double = buyData.reduce(0.0) { partialResult, scalar in partialResult + Double(scalar.accumulatedAmount) }
            
            var renderObjects: [PriceAndAmountCellRO] = []
            var currentAccumulatedSum: Double = 0.0
            
            for data in buyData {
                currentAccumulatedSum += Double(data.accumulatedAmount)
                let percentage = currentAccumulatedSum / accumulatedSum
                
                renderObjects.append(
                    .init(
                        type: .buy,
                        price: data.price,
                        amount: data.accumulatedAmount,
                        percentage: percentage
                    )
                )
            }
            
            if let cellCount = self?.cellCount, renderObjects.count < cellCount {
                let emptySize = cellCount - renderObjects.count
                let emptyRoList: [PriceAndAmountCellRO] = (0..<emptySize).map { _ in .emptyObject(.buy) }
                renderObjects.append(contentsOf: emptyRoList)
            }
            
            return renderObjects
        })
        .asDriver(onErrorDriveWith: .never())
        
        // MARK: Sell
        sellListRO = sellStream.map({ [weak self] sellData in
            
            let accumulatedSum: Double = sellData.reduce(0.0) { partialResult, scalar in partialResult + Double(scalar.accumulatedAmount) }
            
            var renderObjects: [PriceAndAmountCellRO] = []
            var currentAccumulatedSum: Double = 0.0
            
            for data in sellData {
                currentAccumulatedSum += Double(data.accumulatedAmount)
                let percentage = currentAccumulatedSum / accumulatedSum
                
                renderObjects.append(
                    .init(
                        type: .sell,
                        price: data.price,
                        amount: data.accumulatedAmount,
                        percentage: percentage
                    )
                )
            }
            
            if let cellCount = self?.cellCount, renderObjects.count < cellCount {
                let emptySize = cellCount - renderObjects.count
                let emptyRoList: [PriceAndAmountCellRO] = (0..<emptySize).map { _ in .emptyObject(.sell) }
                renderObjects.append(contentsOf: emptyRoList)
            }
            
            return renderObjects
        })
        .asDriver(onErrorDriveWith: .never())
    }
    
    func circularExp(target: Double, base: Double) -> Double {
        sqrt(pow(base, 2) - pow(abs(base-target), 2)) / base
    }
}
