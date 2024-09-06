//
//  RepositoryInterface.swift
//  Domain
//
//  Created by choijunios on 8/25/24.
//

import Foundation
import RxSwift

public protocol OrderBook2Repository {
    
    /// 웹소켓 스트림을 시작합니다.
    func startSteam(coinSymbol: String)
    
    /// 스트림에 참여합니다.
    func joinStream(bufferSize: Int, timeSpan: Int, itemLimit: Int) -> Observable<OrderBookTableVO>
    
    /// 스트림을 종료합니다.
    func stopStream(coinSymbol: String)
}
