# Spring Bean_생명주기

## Q1)
> Spring Bean 생명주기를 순서대로 설명하고, <br>
> 차량 데이터 처리 서버에서 서버 시작 시 Kafka Consumer 연결을 초기화하는 시점을 어디서 처리하는 게 좋은지 설명해주세요.

## A1)
```text
Spring Bean 생명주기 전체 순서:

1. Bean 정의 로드
   → @Component, @Service, @Bean 스캔

2. Bean 인스턴스 생성
   → 생성자 호출

3. 의존성 주입
   → @Autowired, 생성자 주입

4. 초기화 콜백 (3가지 방법)
   → @PostConstruct 메서드 실행
   → InitializingBean.afterPropertiesSet()
   → @Bean(initMethod = "init")

5. ApplicationContext 완전 초기화
   → ApplicationReadyEvent 발행
   → @EventListener(ApplicationReadyEvent.class)

6. Bean 사용 (서비스 운영)

7. 소멸 전 콜백
   → @PreDestroy 메서드 실행
   → DisposableBean.destroy()

8. Bean 소멸


각 초기화 시점 선택 기준:

@PostConstruct:
- Bean 의존성 주입 직후 실행
- 단순 초기화 작업에 적합
- 예: 설정값 검증, 내부 캐시 초기화

@EventListener(ApplicationReadyEvent.class):
- 모든 Bean이 완전히 초기화된 후 실행
- 다른 Bean에 의존하는 초기화 작업에 적합
- 예: Kafka Consumer 시작, 외부 API 연결

Kafka Consumer 초기화 적합한 시점:
@KafkaListener → 자동으로 ApplicationContext
                  초기화 이후 동작
                  별도 초기화 코드 불필요

수동 초기화가 필요한 경우:
@EventListener(ApplicationReadyEvent.class)
public void startConsumer() {
    // 모든 Bean 준비 완료 후 Consumer 시작
    // DB 연결, 외부 서비스 준비 확인 후 시작 가능
}


@PostConstruct를 쓰면 안 되는 케이스:
@PostConstruct
public void init() {
    // 다른 Bean이 아직 초기화 안 됐을 수 있음
    // DB 조회, 외부 API 호출 → 위험
    otherService.doSomething(); // NullPointerException 위험
}
```