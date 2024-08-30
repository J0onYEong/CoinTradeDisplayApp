//
//  WebSocketServiceTests.swift
//  CoinTradeDisplayTests
//
//  Created by choijunios on 8/25/24.
//

import XCTest
@testable import Data

final class WebSocketServiceTests: XCTestCase {
    
    var webSocketService: WebSocketService!
    
    let testURL = URL(string: "wss://ws.bitmex.com/realtime?subscribe=orderBookL2:XBTUSD")!
    
    override func setUp() {
        super.setUp()
        webSocketService = DefaultWebSocketService()
    }
    
    override func tearDown() {
        webSocketService.resignConnection(url: testURL)
        webSocketService = nil
        super.tearDown()
    }
    
    func testWebSocketReceivesTenMessages() {
        let expectation = self.expectation(description: "응답 10개수신")
        var count = 0
        
        
        
        webSocketService.startConnection(url: testURL) { (string, data) in
            if let string = string {
                print("문자열", string, "\n\n\n\n")
                count+=1
            }
        
            if count == 10 {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 15.0, handler: nil)
        
        XCTAssertGreaterThan(count, 10, "응답 10개 수신")
    }
    
}
