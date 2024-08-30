//
//  RepositoryInterface.swift
//  Domain
//
//  Created by choijunios on 8/25/24.
//

import Foundation
import RxSwift

public protocol OrderBook2Repository {
    
    /**     
    스트림의 데이터 흐름을 설정합니다.
     > 스트림의 데이터 흐름을 설정합니다.
     - Parameters:
        - bufferSize: 한 번에 가져오는 데이터의 양을 의미합니다.
        - timeSpan: 데이터를 수신받는 주기를 의미합니다. (밀리초 단위)
    */
    func setSream(bufferSize: Int, timeSpan: Int)
    
    /// 웹소켓 스트림을 시작합니다.
    func startSteam(coinSymbol: String)
    
    /// 스트림에 참여합니다.
    func joinStream(itemLimit: Int) -> Observable<OrderBookTableVO>
    
    /// 스트림을 종료합니다.
    func stopStream(coinSymbol: String)
}
