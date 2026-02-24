## Q1) @Transactional 내부 동작 원리
> `@Transactional`이 내부적으로 어떤 메커니즘으로 동작하는지 원리를 설명해주세요.

## A1) 내 답변
Spring 3대 원리인 AOP를 사용해서 동작한다. 더 자세한 내용은 모르겠다.

## 모범 답변
Spring `@Transactional`은 CGLIB 기반 프록시 패턴으로 동작한다.

핵심 컴포넌트 3가지:
1. **CGLIB 프록시**: Bean 등록 시 서브클래스 프록시 생성, 외부 호출을 가로챔
2. **TransactionInterceptor**: AOP Advice 역할, 트랜잭션 시작/커밋/롤백 처리
3. **TransactionSynchronizationManager**: 현재 스레드에 커넥션을 ThreadLocal로 바인딩하여 같은 트랜잭션 내 쿼리들이 동일 커넥션 사용 보장

```java
// 실제 호출 흐름
// 1. 외부에서 Bean 호출 시 프록시 객체가 먼저 가로챔
// 2. TransactionInterceptor가 트랜잭션 시작
// 3. TransactionSynchronizationManager에 커넥션을 ThreadLocal로 바인딩
// 4. 실제 메서드 실행
// 5. 정상 완료 → commit / RuntimeException → rollback

@Service
public class PaymentService {

    @Transactional  // 프록시가 이 메서드를 감싸서 트랜잭션 관리
    public void processPayment(...) {
        // 이 시점에 이미 DB 커넥션이 HikariCP에서 획득된 상태
        // 메서드 종료까지 커넥션을 점유
    }
}
```

**주의사항**: 같은 클래스 내부에서 `this.method()`로 호출하면 프록시를 거치지 않으므로
`@Transactional`이 동작하지 않는다. public/private 여부가 기준이 아니라
**프록시를 거치느냐**가 핵심 기준이다.

---

## Q2) @Transactional Self-Invocation 문제 회피 방법
> `@Transactional`이 같은 클래스 내부 호출 시 동작하지 않는 문제를 회피하는 방법 3가지를 설명해주세요.

## A2) 내 답변
클래스 분리(별도 Bean으로 분리) 방법만 알고 있다. 나머지 2가지는 모른다.

## 모범 답변
**방법 1. 별도 Bean으로 분리 (실무 권장)**

```java
@Service
@RequiredArgsConstructor
public class OrderService {
    private final OrderTxService orderTxService; // 별도 Bean 주입

    public void placeOrder(OrderRequest request) {
        validate(request);
        orderTxService.saveOrder(request); // 프록시를 통해 호출 → 트랜잭션 적용
    }
}

@Service
public class OrderTxService {
    @Transactional
    public void saveOrder(OrderRequest request) { ... }
}
```

**방법 2. ApplicationContext에서 자기 자신의 프록시를 직접 주입**

```java
@Service
public class OrderService implements ApplicationContextAware {
    private ApplicationContext ctx;

    public void placeOrder(OrderRequest request) {
        OrderService proxy = ctx.getBean(OrderService.class); // 프록시 Bean 획득
        proxy.saveOrder(request); // 프록시를 통한 호출 → 트랜잭션 적용
    }

    @Transactional
    public void saveOrder(OrderRequest request) { ... }

    @Override
    public void setApplicationContext(ApplicationContext ctx) {
        this.ctx = ctx;
    }
}
```

**방법 3. @Lazy로 자기 자신을 주입 (Spring 4.3+)**

```java
@Service
public class OrderService {
    @Autowired
    @Lazy
    private OrderService self; // 프록시 주입

    public void placeOrder(OrderRequest request) {
        self.saveOrder(request); // 프록시를 통한 호출 → 트랜잭션 적용
    }

    @Transactional
    public void saveOrder(OrderRequest request) { ... }
}
```

방법 2, 3은 가능하지만 구조가 지저분해지므로 **방법 1(클래스 분리)이 실무에서 유일한 정답**에 가깝다.
