//
//  RepositoryInterface.swift
//  Domain
//
//  Created by choijunios on 8/25/24.
//

import Foundation
import RxSwift

public protocol OrderBook2Repository {
    
    /// action이 partial인 데이터를 최초로한번 가져옵니다.
    func getInitialDataSet(coinSymbol: String) -> Single<[OrderBookL2Data]>
    
    /// 데이터를 지속적으로 가져옵니다.
    /// - parameters
    ///     bufferSize: 한번에가져오는 데이터의 양을 의미합니다.
    ///     timeSpan: 데이터를 수신받는 주기를 의미합니다. (밀리세컨)
    func getDataContinuosly(bufferSize: Int, timeSpan: Int) -> Observable<[OrderBookL2Data]>
}
