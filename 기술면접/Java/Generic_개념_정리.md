# Generic_개념_정리

## 면접 답변 완성본
> "Generic은 클래스나 메서드를 타입에 종속되지 않게 설계하는 기능이에요. <br>
> 타입 안정성을 컴파일 시점에 보장하고 형변환 코드를 제거할 수 있어요. <br>
> 실시간 차량 데이터 처리에서 GPS, 배터리, 속도 데이터를 각각 별도 클래스로 만들지 않고 VehicleDataProcessor<T extends VehicleData>로 통합해서 코드 중복을 제거할수있습니다. <br>
> extends VehicleData로 바운드를 걸면 T가 반드시 VehicleData를 상속하므로 공통 메서드를 안전하게 호출할 수 있습니다."


## 개념 설명
```java
// Generic 없는 코드
public class DataProcessor {
    public Object process(Object data) {
        return data;
    }
}

// 사용 시
DataProcessor processor = new DataProcessor();
String result = (String) processor.process("차량데이터"); // 강제 형변환
Integer num = (Integer) processor.process("차량데이터");  // 런타임 에러
// ClassCastException → 컴파일 시점에 잡을 수 없음
```

```java
// Generic 적용
public class DataProcessor<T> {
    public T process(T data) {
        return data;
    }
}

// 사용 시
DataProcessor<String> processor = new DataProcessor<>();
String result = processor.process("차량데이터"); // 형변환 불필요
Integer num = processor.process("차량데이터");   // 컴파일 에러로 즉시 감지
```

---

**Generic 핵심 3가지**
```
1. 타입 안정성
   컴파일 시점에 타입 오류 감지
   → 런타임 ClassCastException 방지

2. 코드 재사용성
   타입만 다른 중복 코드 제거
   → 하나의 클래스로 여러 타입 처리

3. 형변환 제거
   자동으로 타입 캐스팅
   → 코드가 깔끔해짐
```

### <? extends T> vs <? super T> 차이
```java
// <? extends T> : T 또는 T의 하위 타입 허용 (읽기 전용)
List<? extends VehicleData> list = new ArrayList<GpsData>();
VehicleData data = list.get(0); // 읽기 OK
list.add(new GpsData());        // 컴파일 에러 (쓰기 불가)

// 용도: 데이터를 읽어서 처리할 때
public void printAll(List<? extends VehicleData> list) {
    for (VehicleData data : list) {
        System.out.println(data.getVehicleId());
    }
}


// <? super T> : T 또는 T의 상위 타입 허용 (쓰기 전용)
List<? super GpsData> list = new ArrayList<VehicleData>();
list.add(new GpsData()); // 쓰기 OK
GpsData data = list.get(0); // 컴파일 에러 (읽기 불가)

// 용도: 데이터를 컬렉션에 담을 때
public void addData(List<? super GpsData> list) {
    list.add(new GpsData(37.5, 127.0));
}


쉽게 기억하는 방법:
extends = Producer (생산, 읽기)
super   = Consumer (소비, 쓰기)
→ PECS 원칙 (Producer Extends, Consumer Super)
```