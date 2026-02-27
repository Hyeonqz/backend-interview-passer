# String_StringBuilder_StringBuffer_차이

## Q1)
> Java에서 String은 불변(Immutable) 객체예요. <br>
> 실시간 데이터 처리 서버에서 차량 데이터를 파싱할 때 String을 반복적으로 합치는 작업이 있다면, String vs StringBuilder vs StringBuffer 중 어떤 걸 선택하시겠어요? <br>
> 각각의 차이와 선택 기준을 설명해주세요.


## A1)
> String 반복 합치기는 매번 새 객체를 생성해서 GC 부담이 크기 때문에 배제합니다. <br>
> StringBuffer는 synchronized로 스레드 안전하지만 오버헤드가 있고, StringBuilder는 빠르지만 스레드 안전하지 않아요. <br>
> 실무에서는 대부분 메서드 내 로컬 변수로 사용하므로 StringBuilder를 선택하고, 공유 자원에서 문자열을 조작해야 하는 경우에만 StringBuffer를 사용합니다."


### 개념 정리
```text
String:
- 불변(Immutable) 객체
- 값 변경 시 새 객체 생성 → 기존 객체는 String Pool에 잔존
- 반복 합치기 시 메모리 낭비 심함

// 위험한 코드
String result = "";
for (VehicleData data : dataList) {
    result += data.toString(); // 매번 새 String 객체 생성
    // 1만 건 처리 시 1만 개 String 객체 → GC 부담
}


StringBuffer:
- 가변(Mutable) 객체
- 모든 메서드에 synchronized 적용
- 멀티 스레드 환경에서 안전
- 동기화 오버헤드로 인해 느림

StringBuffer buffer = new StringBuffer();
buffer.append(data); // synchronized → 스레드 안전


StringBuilder:
- 가변(Mutable) 객체
- synchronized 없음 → 빠름
- 단일 스레드 환경에서만 안전

StringBuilder builder = new StringBuilder();
builder.append(data); // 빠르지만 스레드 안전하지 않음


선택 기준:

단일 스레드 (메서드 내 로컬 변수):
→ StringBuilder 선택
→ 스택에 저장, 스레드 간 공유 없음 → 안전

멀티 스레드 (공유 자원):
→ StringBuffer 선택
→ synchronized 보장

실시간 데이터 처리 실무:
대부분 메서드 내 로컬 변수로 사용
→ StringBuilder가 현실적 선택
→ 공유 자원이면 StringBuilder + 외부 동기화
   또는 StringBuffer 사용
```