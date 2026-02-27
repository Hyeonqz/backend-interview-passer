# ObjectMapper_스레드안전성

## Q1
> 차량 데이터를 파싱해서 JSON으로 변환하는 작업을 멀티 스레드 환경에서 처리할 때, <br>
> ObjectMapper를 매번 새로 생성하는 것과 싱글톤으로 공유하는 것 중 어떤 방식이 좋을까요? <br>
> ObjectMapper가 스레드 안전한지 여부를 포함해서 설명해주세요.


## A1) 
```text
ObjectMapper는 초기 설정 완료 후 Thread-Safe하기 때문에 Bean으로 등록해서 싱글톤으로 공유하는 게 올바른 방식이에요. 
실무에서도 API 응답용과 내부 처리용 두 가지를 Bean으로 등록해서 용도별로 분리해서 사용하고 있습니다.
```

### 개념 정리
```text
ObjectMapper 스레드 안전 여부:

결론: Thread-Safe 해요.

단, 조건이 있어요.
초기 설정(configure) 완료 후 읽기/쓰기 작업에서만 안전
→ 런타임 중 설정 변경은 안전하지 않음

// 안전한 사용법
@Configuration
public class JacksonConfig {

    @Bean
    @Primary
    public ObjectMapper objectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        // 설정은 Bean 생성 시점에 한번만
        return mapper; // 이후 멀티 스레드에서 공유 안전
    }

    @Bean
    @Qualifier("prettyMapper")
    public ObjectMapper prettyObjectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.enable(SerializationFeature.INDENT_OUTPUT);
        return mapper;
    }
}

// 위험한 사용법
@Service
public class VehicleService {
    @Autowired
    private ObjectMapper objectMapper;

    public void process() {
        // 런타임 중 설정 변경 → 스레드 안전하지 않음
        objectMapper.configure(
            SerializationFeature.INDENT_OUTPUT, true
        );
    }
}


실무에서 2개 ObjectMapper 운영하는 이유:
기본 ObjectMapper: API 응답용 (snake_case 등)
커스텀 ObjectMapper: 내부 직렬화용 (다른 날짜 포맷 등)
→ 용도별 설정 분리로 충돌 방지
```