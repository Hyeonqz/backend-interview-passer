## Q1)
> 이력서에서 트랜잭셔널 아웃박스 패턴을 도입하셨는데요. <br>
> 아웃박스 패턴에서 핵심은 DB 저장과 이벤트 발행의 원자성 보장이에요. <br>
> @TransactionalEventListener와 아웃박스 패턴은 둘 다 트랜잭션 이후 이벤트를 처리하는 방식인데, <br> 
> 두 방식의 근본적인 차이가 무엇이고, 이력서에서 아웃박스 패턴을 선택한 이유가 @TransactionalEventListener로는 해결할 수 없는 문제가 있었기 때문인가요?


## A1)
```text
@TransactionalEventListener을 사용하여 이벤트 발행 트랜잭션 commit 이후에 AFTER_COMMIT 옵션을 사용하여 처리를 하였지만, 위 부분만으로는 해결할 수 없었습니다. 

위 트랜잭션이 종료된 이후 실제 파일을 저장하고 outbox 테이블이 있었는데
그 테이블에 파일 데이터 저장 및 성공 여부를 기록하였습니다.

처음 이벤트가 발행되는 시점에는 파일 업로드 상태를 PENDING 으로 처리를 하였고

실제로 파일 업로드가 완료가 되면 이후에 COMPLETED 로 업데이트를 치는 방식으로 했습니다.
```


## 모범 답안
```text
@TransactionalEventListener:
메인 트랜잭션 커밋 이후 이벤트를 발행하는 "타이밍 제어" 메커니즘
→ 이벤트 발행 자체가 실패하면 재시도 수단이 없음
→ 파일 업로드 실패 시 복구 불가

트랜잭셔널 아웃박스 패턴:
이벤트 발행 대신 DB에 "처리해야 할 작업"을 기록해두고
별도 프로세스(배치)가 꺼내서 처리하는 "내결함성 설계 패턴"
→ 실패해도 DB에 기록이 남아있어 재처리 가능
```

실제 구현한 것 
```text
[메인 트랜잭션]
가맹점 접수 DB 저장
+ outbox 테이블에 파일 업로드 작업 INSERT (status=PENDING)
→ 단일 트랜잭션으로 커밋 ✅

[비동기 처리]
@TransactionalEventListener(AFTER_COMMIT)
→ 로컬 임시 디렉토리에 파일 저장
→ SFTP 업로드 시도
→ 성공 시 outbox status = COMPLETED
→ 실패 시 status = FAIL 유지

[배치 처리 - 30분 주기]
outbox 테이블에서 PENDING/FAIL 건 재처리
```

모범 답안
```text
"@TransactionalEventListener의 AFTER_COMMIT으로 메인 트랜잭션 커밋 이후 파일 업로드를 트리거했습니다. 
그런데 SFTP 업로드 실패 시 복구 수단이 없다는 문제가 있었어요. 
이를 해결하기 위해 메인 트랜잭션 내에서 outbox 테이블에 PENDING 상태로 작업을 기록하고, 
10분 배치가 PENDING/FAIL 건을 재처리하는 트랜잭셔널 아웃박스 패턴을 도입했습니다. 
이렇게 하면 애플리케이션 장애가 발생해도 DB에 기록이 남아있어 파일 유실률을 0%로 달성할 수 있었습니다."
```