# WriteView → UserStats 업데이트 구현 완료

## 📋 개요
**상태**: ✅ **완료**  
**작업 날짜**: 2026년 1월 9일  
**우선순위**: 1순위 (핵심 통계 정확성)

## 🎯 구현 목표
WriteView에서 카드를 저장할 때 DailyGem 뿐만 아니라 UserStats도 함께 업데이트하여 사용자의 통계 데이터를 실시간으로 동기화

## 📝 구현 세부사항

### 1. WriteViewModel.saveCard() 메서드 개선

#### 변경 사항:
```swift
// 새로운 날짜인지 확인 (데이터포인트 추가 전에 체크)
let calendar = Calendar.current
let today = calendar.startOfDay(for: now)
let isNewGem = !localDataPoints.contains { point in
    calendar.startOfDay(for: point.timestamp) == today
}

// 데이터 저장 후 UserStats 업데이트
await updateUserStats(for: now, isNewGem: isNewGem)
```

**핵심**:
- 데이터 추가 전에 "새로운 날짜"인지 판별
- `isNewGem` 플래그를 `updateUserStats()`에 전달

### 2. updateUserStats() 메서드 (신규 추가)

#### 기능:
- `fetchUserStats()`로 현재 UserStats 조회
- 다음 필드 업데이트:
  - `totalDataPoints += 1` (항상 증가)
  - `totalGemsCreated += 1` (새로운 날에만)
  - `totalDaysActive += 1` (새로운 날에만)
  - `currentStreak` & `longestStreak` (재계산)
  - `lastUpdated = Date()` (현재 시간)
- `updateUserStats()`로 Firebase에 저장

#### 구현 코드:
```swift
private func updateUserStats(for date: Date, isNewGem: Bool) async {
    // 1. UserStats 조회
    // 2. 필드 업데이트
    //    - totalDataPoints += 1
    //    - isNewGem인 경우: totalGemsCreated += 1, totalDaysActive += 1
    // 3. Streak 계산
    // 4. Firebase에 업데이트
}
```

### 3. calculateAndUpdateStreak() 메서드 (신규 추가)

#### 기능:
- 로컬 `localDataPoints`에서 날짜 집합 생성
- 어제부터 거슬러 올라가며 연속 기록된 일수 계산
- `currentStreak` 업데이트
- `longestStreak`이 현재 streak보다 작으면 갱신

#### 로직:
```
1. 로컬 데이터에서 unique한 날짜들 추출
2. 어제부터 시작하여 과거로 거슬러감
3. 데이터가 없는 날을 만날 때까지 연속 기록 일수 카운트
4. currentStreak = 카운트된 일수
5. longestStreak이 currentStreak보다 작으면 업데이트
```

**예시**:
- 어제 기록있음 ✓
- 그 전날 기록있음 ✓
- 그 전전날 기록있음 ✓
- 그 전전전날 기록없음 ✗
→ currentStreak = 3

## 🔄 데이터 흐름

```
WriteView.saveCard()
    ↓
WriteViewModel.saveCard()
    ├─ TimeSeriesDataPoint 생성 & 로컬 저장
    ├─ DailyGem 생성/업데이트 & 저장
    └─ UserStats 업데이트 & 저장 ✨ (신규)
        ├─ fetchUserStats() 조회
        ├─ updateUserStats() 계산
        │   ├─ totalDataPoints += 1
        │   ├─ totalGemsCreated & totalDaysActive (isNewGem 확인)
        │   └─ currentStreak & longestStreak 재계산
        └─ updateUserStats() 저장
    
    ↓
HomeViewModel.loadInitialData() (자동 새로고침)
    └─ UserStats 반영 ✓
```

## 📊 업데이트되는 필드

| 필드 | 로직 | 설명 |
|------|------|------|
| `totalDataPoints` | `+= 1` (항상) | 저장된 모든 데이터 포인트 누계 |
| `totalGemsCreated` | `+= 1` (isNewGem) | 새로운 날짜의 첫 기록일 때만 증가 |
| `totalDaysActive` | `+= 1` (isNewGem) | 기록한 총 일수 |
| `currentStreak` | 재계산 | 로컬 데이터 기반 어제부터의 연속 기록일 |
| `longestStreak` | 갱신 (currentStreak > oldLongest) | 역대 최장 streak |
| `lastUpdated` | `= Date()` | 마지막 업데이트 시간 |

## ✅ 검증 체크리스트

- [x] WriteViewModel.saveCard()에서 `isNewGem` 플래그 생성
- [x] UserStats 조회 로직 구현
- [x] 필드 업데이트 로직 구현
- [x] Streak 계산 헬퍼 함수 구현
- [x] Firebase 업데이트 호출
- [x] 에러 핸들링 및 로깅
- [x] MockDataService 호환성 확인
- [x] WriteView → saveCard 호출 경로 확인

## 🔧 기술 세부사항

### Combine 패턴
```swift
dataService.fetchUserStats()
    .sink(receiveCompletion: {...}, receiveValue: {...})
```

### Async/Await 패턴
```swift
await withCheckedContinuation { continuation in
    // Combine Publisher를 async/await로 변환
}
```

## 📌 주의사항

1. **로컬 vs 서버 데이터**
   - Streak 계산은 로컬 `localDataPoints` 기반
   - 서버 동기화 전의 로컬 상태로 계산됨

2. **새로운 날짜 판별**
   - `Calendar.startOfDay()`로 시간 부분 제거
   - UTC 기준이 아닌 기기의 로컬 타임존 기준

3. **비동기 처리**
   - UserStats 업데이트는 비동기 (await 필요)
   - WriteView에서 이미 async 컨텍스트에서 호출됨

## 🚀 다음 단계 (2순위)

- [ ] 온보딩 완료 시 Goal 자동 생성
- [ ] UserProgramEnrollment 모델 생성 및 저장
- [ ] Streak → UserStats 동기화 (HomeViewModel에서)

---

**작성자**: GitHub Copilot  
**마지막 수정**: 2026년 1월 9일
