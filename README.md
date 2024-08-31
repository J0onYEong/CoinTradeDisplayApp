## 호가창 구현 프로젝트

### 계층별 역할
Data : 웹소켓 연결, 누적된 코인거래량을 딕셔너리 형태로 저장
Domain : 누적된 데이터를 일정한 크기와 주기로 UI에 반영
Presentation : 전달받은 데이터를 시각화

### Back pressure현상 방지
웹소켓으로 부터 데이터를 전달받을 때마다 UI를 수정할 경우 뷰 업데이트 주기가 짧아져 성능저하로 이어집니다.
이문제를 RxSwift오퍼레이터로 해결할 수 있었습니다.

- buffer오퍼레이터는 웹소켓으로 부터 전달받은 데이터의 **수신횟수가 버퍼 사이즈를 만족**하는 경우 이벤트를 방출하도록 한다.
- throttle은 방출이 일어난 이후 지정한 스트림에 도착한 **이벤트를 무시**한다.
```swift
streamHolder = dataFromWebSocket
    .buffer(
        timeSpan: .milliseconds(5000),
        count: bufferSize,
        scheduler: scheduler
    )
    .throttle(.milliseconds(timeSpan), scheduler: scheduler)
```

### 시현영상


https://github.com/user-attachments/assets/a8ce6667-0660-4ced-bca6-a489bbc6b2cb

