## Q1)
> @Modifying + @Query로 벌크 업데이트 후 entityManager.clear()가 필요한 이유가 무엇인지 설명해주세요. <br>
> 만약 clear()를 호출하지 않으면 어떤 문제가 발생하나요?
```java
// JPQL 벌크 업데이트
// 엔티티 조회 없이 직접 UPDATE 쿼리 실행

@Modifying
@Query("UPDATE Payment p SET p.status = :status WHERE p.id = :id")
void updateStatus(@Param("id") Long id, @Param("status") String status);
```

## A1)
```text
트랜잭션 자체에서는 @Transacationl 에 의해 스냅샷 자체가 찍혀 있다. 
하지만 엔티티에 의해 변경되지 않고 JPQL 을 통해 변경되기에

영속성 컨텍스트는 변경을 알 수 없다.
clear() 를 해주지 않으면 DB와 1차 캐시 사이에 데이터 불일치가 일어난다.
```


## 모범 답변
```text
JPQL 벌크 업데이트 실행
    ↓
DB: status = COMPLETED 로 변경됨
    ↓
영속성 컨텍스트 1차 캐시: status = PENDING 그대로 (모름)
    ↓
clear() 없이 payment 엔티티 다시 사용하면
    → DB는 COMPLETED인데 메모리는 PENDING
    → 잘못된 데이터로 비즈니스 로직 실행 위험

clear() 호출하면
    → 1차 캐시 전체 삭제
    → 다음 조회 시 DB에서 최신 데이터 재로딩
    → 정합성 보장
```