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
    func resignConnection(url: URL)
    
    /// 콜백함수를 변경합니다.
    func changeCompletion(url: URL, _ completion: @escaping WebSocketServiceOnReciveHandler)
}

public typealias WebSocketServiceOnReciveHandler = (String?, Data?) -> Void

public class DefaultWebSocketService: NSObject, WebSocketService {
    
    private(set) var currentTask: [String: URLSessionWebSocketTask] = [:]
    private(set) var completion: [String: WebSocketServiceOnReciveHandler] = [:]
    private(set) var session: [String: URLSession] = [:]
    private(set) var sessionQueue: [String: OperationQueue] = [:]
    
    let lock = NSLock()
    
    let queue = OperationQueue()
    
    #if DEBUG
    static var requestCount: Int = 0
    static var recieveCount: Int = 0
    #endif
    
    public override init() {
        super.init()
    }
    
    public func startConnection(url: URL, _ completion: @escaping WebSocketServiceOnReciveHandler) {

        if let identifier = getIdentifier(url: url) {
            
            #if DEBUG
            var timePassed = 0
            let timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                timePassed+=3
                print("[웹소켓 id: \(identifier)]")
                print("요청: \(Self.requestCount), 수신: \(Self.recieveCount) \n> 수신/s: \(round(Double(Self.recieveCount)/Double(timePassed)*100)/100)\n")
            }
            RunLoop.main.add(timer, forMode: .common)
            #endif
            
            let queue = OperationQueue()
            queue.maxConcurrentOperationCount = 1
            
            self.sessionQueue[identifier] = queue
            
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: queue)
            
            self.session[identifier] = session
            
            // 웹소켓이 실행중일 경우 시작하지 않는다.
            if currentTask[identifier] != nil { return }
            
            let task = session.webSocketTask(with: url)
            task.resume()
            
            currentTask[identifier] = task
            
            self.completion[identifier] = completion
        } else {
            print("id생성 실패")
        }
    }
    
    private func startListening(identifier: String) {
        #if DEBUG
        Self.requestCount+=1
        #endif
        
        // 수신후 재요청이, Timer를 사용한 연속호출(30ms)보다 더 수신량이 많았음
        currentTask[identifier]?.receive(completionHandler: { [weak self] result in
            #if DEBUG
            Self.recieveCount+=1
            #endif
            
            guard let self else { return }
            
            switch result {
            case let .success(message):
                switch message {
                case let .string(string):
                    completion[identifier]?(string, nil)
                case let .data(data):
                    completion[identifier]?(nil, data)
                @unknown default:
                    completion[identifier]?(nil, nil)
                }
            case let .failure(error):
                print("‼️ 웹소켓 에러 수신 \(error)")
            }
            
            startListening(identifier: identifier)
        })
    }
    
    public func resignConnection(url: URL) {
        
        if let identifier = getIdentifier(url: url) {
            resignConnection(identifier: identifier)
        } else {
            print("id생성 실패")
        }
    }
    
    private func resignConnection(identifier: String) {
        sessionQueue[identifier]?.addOperation { [weak self] in
            guard let self else { return }
            
            defer {
                self.sessionQueue.removeValue(forKey: identifier)
            }
            
            self.currentTask[identifier]?.cancel()
            self.currentTask.removeValue(forKey: identifier)
            self.completion.removeValue(forKey: identifier)
            self.session.removeValue(forKey: identifier)
        }
    }
    
    public func changeCompletion(url: URL, _ completion: @escaping WebSocketServiceOnReciveHandler) {
        
        if let identifier = getIdentifier(url: url) {
            sessionQueue[identifier]?.addOperation { [weak self] in
                self?.completion[identifier] = completion
            }
        } else {
            print("id생성 실패")
        }
    }
    
    private func getIdentifier(url: URL) -> String? {
        
        var urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        if url.scheme == "ws" {
            urlComponent?.scheme = "http"
        }
        if url.scheme == "wss" {
            urlComponent?.scheme = "https"
        }
        
        return urlComponent?.url?.absoluteString
    }
}

extension DefaultWebSocketService: URLSessionWebSocketDelegate {
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ 웹소캣 열림")
        
        if let identifier = webSocketTask.currentRequest?.url?.absoluteString {
            startListening(identifier: identifier)
        }
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("☑️ 웹소캣 닫침")
        
        if let identifier = webSocketTask.currentRequest?.url?.absoluteString {
            resignConnection(identifier: identifier)
        }
    }
}

