# Graceful_Shutdown_Consumer

## Q1)
> 서버가 종료될 때 처리 중이던 Kafka 메시지를 유실하지 않고 안전하게 종료(Graceful Shutdown) 하려면 어떻게 설계해야 하나요? <br>
> @PreDestroy와 Kafka Consumer의 관계를 포함해서 설명해주세요. 


## A1)
```text
Kafka Consumer Graceful Shutdown 흐름:

Spring Boot 종료 신호 (SIGTERM) 수신
        ↓
Spring Boot Graceful Shutdown 활성화 시
현재 처리 중인 요청 완료까지 대기
        ↓
@PreDestroy 호출
→ KafkaListenerEndpointRegistry.stop()
→ Consumer가 poll() 중단
→현재 처리 중인 메시지 완료 후 종료
        ↓
Consumer → Kafka Broker에 LeaveGroup 요청
        ↓
Kafka Broker → Consumer Group 리밸런싱 시작
→ 해당 Consumer가 맡던 파티션을
  다른 Consumer에게 재할당
        ↓
다른 인스턴스가 파티션 인수 → 메시지 계속 소비


"기본적으로 되지 않나?"에 대한 정확한 답:

맞아요. Spring Kafka가 자동으로 처리해줘요.
다만 아래 설정이 있어야 완전한 Graceful Shutdown:

# application.yml
server:
  shutdown: graceful  # 활성화 필수

spring:
  lifecycle:
    timeout-per-shutdown-phase: 30s  # 최대 대기 시간

위 설정 없으면:
SIGTERM 즉시 → 처리 중인 메시지 강제 중단
→ offset 커밋 안 된 메시지 재처리 (중복 발생)

@PreDestroy 직접 구현이 필요한 경우:
Consumer 종료 전 특별한 정리 작업이 필요할 때

@PreDestroy
public void shutdown() {
    // 1. 새 메시지 수신 중단
    registry.stop();

    // 2. 처리 중인 메시지 완료 대기
    registry.getListenerContainers()
            .forEach(container -> container.stop());

    // 3. 미커밋 offset 강제 커밋
    acknowledgment.acknowledge();
}
```