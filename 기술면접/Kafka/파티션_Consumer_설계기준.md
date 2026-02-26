## Q1)
> 차량 5만 대 환경에서 Consumer 인스턴스가 10개라면 파티션은 최소 몇 개 이상이어야 하고, 그 이유는 무엇인가요?


## A1)
```text
핵심 원칙:
파티션 수 >= Consumer 수

이유:
Kafka는 하나의 파티션을 동일 Consumer Group 내
하나의 Consumer에만 할당
→ Consumer 10개인데 파티션 5개면 5개 Consumer는 유휴 상태

최소 파티션 수: 10개 (Consumer 1개당 파티션 1개)

실무 권장:
파티션 수를 Consumer 수보다 여유있게 설계
이유: 나중에 Consumer 늘릴 때 파티션 수 변경 불필요
     파티션 수는 증가는 가능하지만 감소 불가
     파티션 수 변경 시 파티션 키 해시 재분배 발생

차량 5만 대 / 초당 1만 건 기준:
Consumer 1개당 처리 가능 TPS 측정 후 결정
예) Consumer 1개 = 1000 TPS 처리 가능
    → 10개 Consumer 필요
    → 파티션 20개로 여유있게 설계 (2배 여유)

파티션 수 결정 공식:
목표 TPS / Consumer 1개 처리 TPS = 최소 Consumer 수
최소 Consumer 수 × 2 = 권장 파티션 수
```