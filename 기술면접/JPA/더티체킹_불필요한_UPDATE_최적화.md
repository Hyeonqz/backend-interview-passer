## Q1)
> 결제 시스템에서 하나의 요청에서 여러 엔티티를 조회하고 수정하는 상황을 가정할게요. <br>
> 예를 들어 결제 완료 처리 시 Payment, Merchant, TransactionLog 3개 엔티티를 조회하고 각각 상태를 업데이트한다면, <br>
> 더티 체킹으로 인해 flush 시점에 UPDATE 쿼리가 3개 발생하는 구조잖아요.
> 이 상황에서 불필요한 UPDATE를 방지하기 위한 JPA 최적화 방법이 있다면 무엇인가요?


## A1)
```text
DTO로 조회하면 영속성 컨텍스트에 등록되지 않아 더티 체킹 자체가 일어나지 않는다는 방향은 맞아요. 읽기 전용 조회에서 유효한 최적화예요.

방법 1: @DynamicUpdate
변경된 컬럼만 UPDATE 쿼리에 포함

@Entity
@DynamicUpdate  // 이 어노테이션 하나로 적용
public class Payment {
    private String status;
    private String merchantId;
    private BigDecimal amount;
}

// status만 변경 시
// 기본: UPDATE payment SET status=?, merchant_id=?, amount=? WHERE id=?
// @DynamicUpdate: UPDATE payment SET status=? WHERE id=?

단점: 매번 변경 컬럼을 계산해야 하므로 오버헤드 발생
      컬럼이 적은 엔티티에서는 오히려 손해


방법 2: @Transactional(readOnly = true) + 필요한 것만 별도 트랜잭션
조회는 readOnly로 더티 체킹 비활성화
수정이 필요한 엔티티만 별도 메서드로 분리

@Transactional(readOnly = true)
public PaymentResult process() {
    Payment payment = paymentRepository.findById(id);   // 더티 체킹 X
    Merchant merchant = merchantRepository.findById(id); // 더티 체킹 X
    updateStatus(payment.getId()); // 수정만 별도 처리
}

@Transactional(propagation = REQUIRES_NEW)
public void updateStatus(Long id) {
    Payment payment = paymentRepository.findById(id);
    payment.complete(); // 더티 체킹 O (이것만)
}


방법 3: JPQL 벌크 업데이트
엔티티 조회 없이 직접 UPDATE 쿼리 실행

@Modifying
@Query("UPDATE Payment p SET p.status = :status WHERE p.id = :id")
void updateStatus(@Param("id") Long id, @Param("status") String status);

단점: 영속성 컨텍스트를 거치지 않아
      실행 후 반드시 entityManager.clear() 필요
```