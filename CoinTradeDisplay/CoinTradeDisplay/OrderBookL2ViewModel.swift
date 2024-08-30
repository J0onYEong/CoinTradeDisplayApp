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
    
    // Init
    let coinStreamUseCase: CoinStreamUseCase
    
    // Input
    let startStreamButtonClicked: PublishRelay<Void> = .init()
    
    // Output
    private(set) var buyListRO: Driver<[PriceAndAmountCellRO]>?
    private(set) var sellListRO: Driver<[PriceAndAmountCellRO]>?
    
    let disposeBag = DisposeBag()
    
    init(coinStreamUseCase: CoinStreamUseCase) {
        self.coinStreamUseCase = coinStreamUseCase
        
        
        let coinStream = coinStreamUseCase
            .getStream()
            
        
        let buyStream = coinStream.map { vo in
            vo.buyList
        }
        let sellStream = coinStream.map { vo in
            vo.sellList
        }
        
        
        // MARK: Buy
        buyListRO = buyStream.map({ buyData in
            
            let maxAmount = buyData.max { lhs, rhs in lhs.accumulatedAmount < rhs.accumulatedAmount }?.accumulatedAmount
            
            var roList = buyData.map { vo in
                
                var percentage: CGFloat = 0.0
                
                if let maxAmount, maxAmount != 0 {
                    percentage = self.circularExp(target: Double(vo.accumulatedAmount), base: Double(maxAmount))
                }
                
                return PriceAndAmountCellRO(
                    type: .buy,
                    price: vo.price,
                    amount: vo.accumulatedAmount,
                    percentage: percentage
                )
            }
            
            if roList.count < 20 {
                let emptySize = 20 - roList.count
                let emptyRoList: [PriceAndAmountCellRO] = (0..<emptySize).map { _ in .emptyObject(.buy) }
                roList.append(contentsOf: emptyRoList)
            }
            
            return roList
        })
        .asDriver(onErrorDriveWith: .never())
        
        // MARK: Sell
        sellListRO = sellStream.map({ sellData in
            
            let maxAmount = sellData.max { lhs, rhs in lhs.accumulatedAmount < rhs.accumulatedAmount }?.accumulatedAmount
            
            var roList = sellData.map { vo in
                
                var percentage: CGFloat = 0.0
                if let maxAmount, maxAmount != 0 {
                    percentage = self.circularExp(target: Double(vo.accumulatedAmount), base: Double(maxAmount))
                }
                
                return PriceAndAmountCellRO(
                    type: .sell,
                    price: vo.price,
                    amount: vo.accumulatedAmount,
                    percentage: percentage
                )
            }
            
            if roList.count < 20 {
                let emptySize = 20 - roList.count
                let emptyRoList: [PriceAndAmountCellRO] = (0..<emptySize).map { _ in .emptyObject(.sell) }
                roList.append(contentsOf: emptyRoList)
            }
            
            return roList
        })
        .asDriver(onErrorDriveWith: .never())
        
        startStreamButtonClicked
            .subscribe(onNext: { [coinStreamUseCase] _ in
                coinStreamUseCase.startStream()
            })
            .disposed(by: disposeBag)
    }
    
    func circularExp(target: Double, base: Double) -> Double {
        sqrt(pow(base, 2) - pow(abs(base-target), 2)) / base
    }
}
