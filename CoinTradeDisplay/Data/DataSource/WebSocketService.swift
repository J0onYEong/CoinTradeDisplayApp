//
//  WebSocketService.swift
//  Data
//
//  Created by choijunios on 8/25/24.
//

import Foundation

class WebSocketService: NSObject {
    
    typealias OnReciveHandler = (String?, Data?) -> Void
    
    static let shared = WebSocketService()
    
    private(set) var session: URLSession!
    private(set) var currentTask: URLSessionWebSocketTask?
    private(set) var completion: OnReciveHandler?
    
    let queue = OperationQueue()
    
    private override init() {
        super.init()
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: queue)
    }
    
    func startConnection(url: URL, _ completion: @escaping OnReciveHandler) {
        self.currentTask = session.webSocketTask(with: url)
        self.currentTask?.resume()
        self.completion = completion
    }
    
    private func startListening() {
        let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            self?.sendPing()
        }
        
        self.currentTask?.receive(completionHandler: { [weak self, timer] result in
            
            timer.invalidate()
            
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
    
    func resignConnection() {
        self.currentTask?.cancel()
        self.currentTask = nil
    }
}

extension WebSocketService: URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ 웹소캣 열림")
        
        startListening()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("☑️ 웹소캣 닫침")
        
        self.currentTask = nil
    }
}

