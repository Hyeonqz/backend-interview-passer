# OSI_7계층_HTTP_TCP_관계

## Q1)
> OSI 7계층 모델에서 HTTP와 TCP의 관계를 설명해주세요.

## A1)
```text
브라우저에서 https://api.qrbank.com 호출 시:

1. DNS 조회 → IP 주소 획득

2. TCP 3-way handshake (4계층)
   Client → Server: SYN
   Server → Client: SYN-ACK
   Client → Server: ACK
   → TCP 연결 수립

3. TLS handshake (HTTPS인 경우)
   → 암호화 키 교환

4. HTTP 요청/응답 (7계층)
   GET /api/payment HTTP/1.1
   → 실제 데이터 전송

5. TCP 연결 종료 또는 Keep-Alive로 유지
```

### 핵심 개념
```text
HTTP는 TCP 위에서 동작하는 프로토콜이에요.

HTTP  = "무슨 데이터를 어떻게 주고받을지" 규약 (7계층)
TCP   = "데이터를 신뢰성 있게 전달하는 통로" (4계층)

즉:
HTTP 요청을 보내려면
반드시 먼저 TCP 연결(3-way handshake)이 선행돼야 해요

HTTP/1.1: 요청마다 또는 Keep-Alive로 TCP 연결 재사용
HTTP/2:   하나의 TCP 연결로 여러 요청을 동시 처리 (멀티플렉싱)
HTTP/3:   TCP 대신 UDP 기반 QUIC 프로토콜 사용
          → 3-way handshake 제거 → 연결 속도 향상
```