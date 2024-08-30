//
//  WebSocketService.swift
//  Data
//
//  Created by choijunios on 8/25/24.
//

import Foundation

public protocol WebSocketService {
    
    /// 웹소켓 연결을 시작하고 데이터를 전달받습니다.
    func startConnection(url: URL, _ completion: @escaping WebSocketServiceOnReciveHandler)
    
    /// 윕소켓 연결을 종료합니다.
    func resignConnection()
    
    /// 콜백함수를 변경합니다.
    func changeCompletion(_ completion: @escaping WebSocketServiceOnReciveHandler)
}

public typealias WebSocketServiceOnReciveHandler = (String?, Data?) -> Void

public class DefaultWebSocketService: NSObject, WebSocketService {
    
    private(set) var session: URLSession!
    private(set) var currentTask: URLSessionWebSocketTask?
    private(set) var completion: WebSocketServiceOnReciveHandler?
    
    let queue = OperationQueue()
    
    public override init() {
        super.init()
        
        queue.maxConcurrentOperationCount = 1
        
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: queue)
    }
    
    public func startConnection(url: URL, _ completion: @escaping WebSocketServiceOnReciveHandler) {
        self.currentTask = session.webSocketTask(with: url)
        self.currentTask?.resume()
        self.completion = completion
    }
    
    var timer: Timer?
    
    private func startListening() {
        
        // 수신후 재요청이, Timer를 사용한 연속호출(30ms)보다 더 수신량이 많았음
        self.currentTask?.receive(completionHandler: { [weak self] result in
            
            guard let self else { return }
            
            switch result {
            case let .success(message):
                switch message {
                case let .string(string):
                    completion?(string, nil)
                case let .data(data):
                    completion?(nil, data)
                @unknown default:
                    completion?(nil, nil)
                }
            case let .failure(error):
                print("‼️ 웹소켓 에러 수신 \(error)")
            }
            
            startListening()
        })
    }
    
    private func sendPing() {
        
        currentTask?.sendPing(pongReceiveHandler: { error in
            print("pong수신 실패")
        })
    }
    
    public func resignConnection() {
        self.currentTask?.cancel()
        self.currentTask = nil
    }
    
    public func changeCompletion(_ completion: @escaping WebSocketServiceOnReciveHandler) {
        queue.addOperation { [weak self] in
            self?.completion = completion
        }
    }
}

extension DefaultWebSocketService: URLSessionWebSocketDelegate {
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ 웹소캣 열림")
        
        startListening()
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("☑️ 웹소캣 닫침")
        
        self.currentTask = nil
    }
}

