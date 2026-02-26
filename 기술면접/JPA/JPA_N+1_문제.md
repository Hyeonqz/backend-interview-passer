## Q1) N+1 문제란 무엇이며 어떻게 해결하는가
> N+1 문제가 정확히 무엇인지, 어떤 상황에서 발생하는지, 그리고 해결 방법을 설명해주세요.

## A1) 내 답변
@ManyToOne 관계에서 자식 엔티티 조회 후 get()으로 가져와서 사용 시 N개의 데이터가 많이 조회되는 문제다.
QueryDSL에서 fetchJoin을 사용해서 해결한다. N+1 문제 자체가 발생하지 않게 하는 방법은 잘 모르겠다.

## 모범 답변

**정의**: 쿼리 1번으로 N개의 엔티티를 조회한 뒤, 각 엔티티의 연관 데이터에 접근할 때
N번의 추가 쿼리가 발생하는 현상. 총 **1 + N번**의 쿼리가 실행된다.

**오개념 정정**
- `@ManyToOne`은 자식이 부모를 참조하는 관계다.
- N+1이 가장 빈번하게 발생하는 패턴은 `@OneToMany`에서 부모 N개를 조회한 뒤
  각각의 자식 컬렉션에 접근할 때다.
- Fetch Join이 바로 N+1 해결책 중 하나다.

```java
// 예시: 가맹점(Merchant) 1개당 여러 거래(Transaction)가 있는 구조
@Entity
public class Merchant {
    @OneToMany(mappedBy = "merchant", fetch = FetchType.LAZY)
    private List<Transaction> transactions;
}

// N+1 발생 코드
List<Merchant> merchants = merchantRepository.findAll(); // 쿼리 1번
for (Merchant m : merchants) {
    // LAZY 로딩 → merchants 수만큼 추가 쿼리 발생
    // merchants가 100개면 쿼리 101번 실행
    m.getTransactions().size();
}
```

**해결 방법 3가지**

방법 1. Fetch Join (즉시 한 번에 조회) - 가장 일반적

```java
// JPQL
@Query("SELECT m FROM Merchant m JOIN FETCH m.transactions")
List<Merchant> findAllWithTransactions();

// QueryDSL
queryFactory
    .selectFrom(merchant)
    .join(merchant.transactions, transaction).fetchJoin()
    .fetch();
```

주의사항:
- 컬렉션 Fetch Join 시 데이터 뻥튀기 발생 → `distinct` 필요
- 컬렉션 Fetch Join은 둘 이상 동시 적용 불가 (`MultipleBagFetchException`)

방법 2. `@EntityGraph` (Fetch Join의 선언적 방식)

```java
@EntityGraph(attributePaths = {"transactions"})
List<Merchant> findAll();
```

방법 3. Batch Size 설정 (컬렉션이 여러 개일 때 유용)

```java
// IN 절로 N번 쿼리를 1번으로 압축
@BatchSize(size = 100)
@OneToMany(mappedBy = "merchant", fetch = FetchType.LAZY)
private List<Transaction> transactions;

// 또는 글로벌 설정 (application.yml)
// spring.jpa.properties.hibernate.default_batch_fetch_size: 100
// → SELECT * FROM transaction WHERE merchant_id IN (1, 2, 3, ... 100)
```

**Fetch Join vs Batch Size 선택 기준**

| 상황 | 권장 방법 |
|------|----------|
| 연관 컬렉션이 1개 | Fetch Join |
| 연관 컬렉션이 2개 이상 | Batch Size (MultipleBagFetchException 회피) |
| 페이징 + 컬렉션 조회 | Batch Size (Fetch Join + 페이징은 메모리에서 전체 로드 후 페이징 → 위험) |

---

## Q2) Fetch Join + 페이징을 함께 쓰면 왜 위험한가, 올바른 설계는?
> Fetch Join과 페이징을 함께 쓰면 어떤 위험이 있는지 설명하고, 페이징과 연관 데이터를 함께 내려줘야 할 때 어떻게 설계하겠습니까?

## A2) 내 답변
모름

## 모범 답변

컬렉션 Fetch Join과 페이징을 함께 쓰면 Hibernate가 **DB에서 페이징을 하지 않고
전체 데이터를 메모리로 올린 뒤 애플리케이션 레벨에서 페이징**을 수행한다.
데이터가 10만 건이면 10만 건 전부 JVM 힙으로 올라온다 → OOM 위험.

```
// Hibernate 경고 메시지
HHH90003004: firstResult/maxResults specified with collection fetch;
applying in memory!
```

```java
// 위험한 코드
@Query("SELECT m FROM Merchant m JOIN FETCH m.transactions")
Page<Merchant> findAll(Pageable pageable); // 전체 데이터 메모리 로드 후 페이징
```

**원인**: 컬렉션 Fetch Join 시 JOIN으로 인해 row가 뻥튀기된다.
Merchant 1개에 Transaction 3개이면 SQL 결과는 3 row.
DB 레벨에서 `LIMIT 10`을 하면 Merchant 기준이 아닌 row 기준으로 잘리므로
정확한 페이징이 불가능하다. Hibernate는 이를 알기 때문에 전체를 메모리에 올리는 것이다.

**올바른 설계 방법**

방법 1. 부모 페이징 + Batch Size로 자식 조회 분리 (권장)

```java
// Step 1: 부모만 페이징 조회 (컬렉션 조인 없이)
@Query(value = "SELECT m FROM Merchant m",
       countQuery = "SELECT COUNT(m) FROM Merchant m")
Page<Merchant> findAllWithPaging(Pageable pageable); // DB 레벨 페이징 정상 동작

// Step 2: Batch Size로 자식 컬렉션 IN절 일괄 조회 (application.yml)
// spring.jpa.properties.hibernate.default_batch_fetch_size: 100
// → 페이징된 N개 merchant에 대해 transaction을 IN(id1, id2, ...) 1번 쿼리로 조회
```

방법 2. QueryDSL DTO Projection으로 직접 조인

```java
// 엔티티가 아닌 DTO로 가져오므로 Dirty Checking 없음, 뻥튀기 없음
List<MerchantDto> result = queryFactory
    .select(Projections.constructor(MerchantDto.class,
        merchant.id,
        merchant.name,
        transaction.id,
        transaction.status))
    .from(merchant)
    .leftJoin(merchant.transactions, transaction)
    .offset(pageable.getOffset())
    .limit(pageable.getPageSize())
    .fetch();
```

방법 3. ToOne 관계는 Fetch Join + 페이징 안전하게 사용 가능

```java
// ToOne(ManyToOne, OneToOne)은 row 뻥튀기 없으므로 Fetch Join + 페이징 안전
@Query("SELECT t FROM Transaction t JOIN FETCH t.merchant")
Page<Transaction> findAllWithMerchant(Pageable pageable); // 안전
```

**핵심 원칙**

```
ToOne 관계  → Fetch Join + 페이징 안전 (row 수 변화 없음)
ToMany 관계 → Fetch Join + 페이징 위험 (row 뻥튀기로 페이징 기준 깨짐)
              → Batch Size 또는 DTO Projection으로 해결
```


### 개념 정리
```text
N+1 발생 원인:
Lazy Loading 기본 전략 때문에
부모 엔티티 1건 조회 후 → 연관 자식 엔티티 N건 개별 조회
→ 총 1 + N번 쿼리 발생

ex) 가맹점 10개 조회 후 각 가맹점의 거래내역 조회
→ SELECT * FROM merchant (1번)
→ SELECT * FROM transaction WHERE merchant_id=1 (N번)
→ 총 11번 쿼리


[해결 방법 비교]

fetch join:
JPQL에 직접 JOIN FETCH 명시
@Query("SELECT m FROM Merchant m JOIN FETCH m.transactions")

장점: 명시적, 복잡한 조건 제어 가능
단점: JPQL을 직접 작성해야 함
      Pageable과 함께 쓰면 메모리에서 페이징 처리 (위험)


@EntityGraph:
어노테이션으로 fetch join을 선언적으로 표현
메서드 이름 기반 쿼리에서도 사용 가능

@EntityGraph(attributePaths = {"transactions"})
List<Merchant> findAll();

장점: JPQL 없이 적용 가능, 가독성 좋음
단점: 복잡한 조건 제어 어려움


선택 기준:
복잡한 조건 + 커스텀 쿼리 필요 → fetch join
단순 연관관계 로딩만 필요     → @EntityGraph
```