# TCP_3way_handshake_부하_해결

## Q1)
> TCP는 연결을 수립할 때 3-way handshake 과정을 거치는데요. <br>
> 차량 1만 대가 서버에 동시에 연결을 맺으려고 할 때, 서버에서 3-way handshake 과정에서 발생하는 부하는 구체적으로 어떤 건가요? <br>
> 그리고 이 부하를 줄이기 위한 방법이 있다면 설명해주세요.

## A1)
```text
3-way handshake 과정:
클라이언트 → 서버: SYN 패킷 전송
서버 → 클라이언트: SYN-ACK 패킷 전송
클라이언트 → 서버: ACK 패킷 전송
→ 연결 수립 완료

차량 1만 대 동시 연결 시 발생하는 부하:

1. 네트워크 부하
   → SYN 패킷 1만 개 동시 수신
   → SYN-ACK 1만 개 응답 전송
   → 패킷 처리량 급증

2. 서버 메모리 부하 (SYN Flood 위험)
   → 서버는 SYN 수신 후 SYN_RECEIVED 상태로
     연결 정보를 메모리(SYN Queue)에 저장
   → 1만 개 동시 연결 시 SYN Queue 고갈 위험
   → 악의적 공격 시 SYN Flood Attack

3. 파일 디스크립터 소진
   → OS는 각 TCP 연결마다 파일 디스크립터 1개 사용
   → 기본값: 1024개 → 1만 대 처리 불가
   → ulimit -n 설정으로 확장 필요


부하 해결 방법:
방법 1: Keep-Alive (연결 재사용)
연결을 맺은 뒤 유지하면서 여러 요청에 재사용
→ 매 요청마다 3-way handshake 불필요

HTTP/1.1:
Connection: Keep-Alive 헤더로 연결 유지
단점: 요청-응답이 순차적 (HOL Blocking)

HTTP/2:
멀티플렉싱으로 하나의 연결에서 여러 요청 병렬 처리
→ 연결 수 자체를 줄임

방법 2: Connection Pool
서버 간 통신에서 미리 연결을 맺어두고 재사용
HikariCP가 DB 연결을 Pool로 관리하는 것과 동일한 원리

방법 3: OS 파라미터 튜닝
# SYN Queue 크기 증가
net.ipv4.tcp_max_syn_backlog = 65535

# 파일 디스크립터 제한 해제
ulimit -n 65535

방법 4: 로드 밸런서
연결을 여러 서버로 분산
→ 서버 1대당 처리 연결 수 감소
```