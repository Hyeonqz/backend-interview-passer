## Kafka Flow

### AS-IS
```mermaid
---
config:
  theme: mc
---
sequenceDiagram
    autonumber

    participant C as Client
    participant DGW as Domestic GW
    participant OGW as Overseas GW
    participant TP as Third Party

    C->>DGW: QR 요청

    note right of DGW: 국내 GW -> 해외 GW 직접 동기 호출

    DGW->>OGW: QR 생성 요청
    note right of OGW: 해외 GW가 Third Party 직접 동기 호출

    OGW->>TP: QR 생성 요청
    TP-->>OGW: QR 생성 응답

    OGW-->>DGW: 응답

    DGW-->>C:  응답
```


### TO-BE
```mermaid
---
config:
  theme: mc
---
sequenceDiagram
    autonumber

    participant C as Client
    participant DGW as Domestic GW
    participant K as Kafka
    participant OW as Overseas Worker
    participant TP as Third Party

    C->>DGW: QR생성 요청

    DGW->>K: 이벤트 발행 <br>(payment-request-topic)

    OW->>K: 메시지 Poll <br>(payment-request-topic)

    OW->>TP: QR 생성 요청

    alt          ✅ QR 생성 성공
        TP-->>OW: QR 생성 응답
        OW->>K: 결과 이벤트 발행 (payment-reply-topic)
        K-->>DGW: QR 페이로드 응답
        DGW-->>C: 응답 (성공)

    else         ❌ QR 생성 실패
        TP-->>OW: QR 생성 실패 응답
        OW->>K: 실패 이벤트 발행 (payment-dlq-topic)

        K-->>DGW: 실패 결과 전달
        DGW-->>C: 응답 (실패)
    end
```