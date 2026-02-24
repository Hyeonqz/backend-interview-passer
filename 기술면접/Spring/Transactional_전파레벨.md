## Q1) REQUIRED vs REQUIRES_NEW 차이와 아웃박스 패턴에서의 적용
> `REQUIRED`와 `REQUIRES_NEW`의 차이를 설명하고, 아웃박스 패턴에서 `REQUIRES_NEW`를 사용하면 어떤 문제가 발생하나요?

## A1) 내 답변
REQUIRED는 트랜잭션을 상속해서 그대로 사용한다. REQUIRES_NEW를 사용하면 새로운 트랜잭션을 생성하여
비즈니스 로직 저장과 아웃박스 테이블 저장 트랜잭션의 원자성이 깨진다.
아웃박스 저장 시 서비스 로직을 사용하게 되므로 REQUIRES_NEW를 사용하면 no-session 에러가 날 수도 있을 것 같다.

## 모범 답변

**REQUIRED (기본값)**
- 기존 트랜잭션 있으면 합류(participate), 없으면 신규 생성
- 부모와 동일한 DB 커넥션 공유
- 내부 메서드 예외 발생 시 부모 트랜잭션까지 rollback-only 마킹

**REQUIRES_NEW**
- 항상 독립적인 신규 트랜잭션 생성
- 기존 트랜잭션은 suspend(일시 중단)
- 별도 DB 커넥션을 HikariCP에서 추가 획득
- 내부 커밋/롤백이 부모 트랜잭션에 영향 없음

**아웃박스 패턴에서 REQUIRES_NEW를 쓰면 안 되는 이유**

```java
// 잘못된 설계 예시
@Transactional  // 커넥션 A 획득
public void saveMerchant(MerchantRequest request) {
    merchantRepository.save(...);         // 커넥션 A 사용
    outboxService.saveOutbox(...);        // REQUIRES_NEW → 커넥션 B 추가 획득
    // 커넥션 A는 suspend 상태로 점유 유지
    // 커넥션 A, B 동시 점유 → 풀 사이즈가 작으면 데드락 위험
}

@Transactional(propagation = Propagation.REQUIRES_NEW)
public void saveOutbox(...) {
    outboxRepository.save(...);  // 별도 트랜잭션으로 커밋
    // 이 시점에 커밋되어 버리면 부모가 롤백해도 아웃박스는 남음
    // → 아웃박스 패턴의 원자성 목적 자체가 무너짐
}

// 올바른 설계
@Transactional  // 커넥션 하나로 비즈니스 저장 + 아웃박스 저장 원자적으로 처리
public void saveMerchant(MerchantRequest request) {
    merchantRepository.save(...);
    outboxRepository.save(...);  // REQUIRED(기본값) → 같은 트랜잭션에 합류
    // 둘 다 커밋되거나 둘 다 롤백 → 원자성 보장
}
```

**REQUIRES_NEW가 유효한 케이스**
- 감사 로그(Audit Log): 메인 트랜잭션 롤백과 무관하게 반드시 기록해야 하는 경우
- 결제 실패 알림: 롤백 여부와 무관하게 발송되어야 하는 이벤트

**주의사항**: REQUIRES_NEW는 DB 커넥션을 추가로 점유하므로 HikariCP 커넥션 풀 고갈 위험이 있다.
꼭 필요한 경우에만 사용한다.
