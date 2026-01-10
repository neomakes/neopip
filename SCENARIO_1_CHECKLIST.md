# 시나리오 1: 신규 사용자 온보딩 & 첫 데이터 생성 - 체크리스트

**목표**: 온보딩 완료 후 첫 Gem 작성 → HomeView에 "Today 1 Gem" 표시

---

## 📋 체크포인트별 검증 가이드

### ✅ 1단계: 신규 사용자 로그인 & Firebase Auth 저장
```
액션: 로그인 화면 → "회원가입" → 이메일 입력 → 비밀번호 설정 → "계정생성"

예상 콘솔 로그:
   ✅ [AuthService] Successfully signed up user: {user_id}
   ✅ [AuthStateManager] Auth state changed to: loggedIn

확인:
   - Firebase Console → Authentication → Users에서 신규 계정 생성 확인
   - LaunchView가 MainTabView로 자동 전환 ✓
```

---

### ✅ 2단계: 온보딩 플로우 완료
```
액션: 프로필 설정 (이름, 아바타) → 목표 선택 → 프로그램 동의 → "완료"

예상 콘솔 로그:
   📥 [HomeViewModel] loadInitialData() called
   ✅ [HomeViewModel] Received 0 daily gems (초기에는 0개)
   ✅ [FirebaseDataService] Saved UserProfile for accountId: {accountId}
   ✅ [FirebaseDataService] Saved UserStats for accountId: {accountId}

Firebase Console 확인:
   - users/{accountId}/profile/data → UserProfile 저장됨
   - users/{accountId}/stats/summary → UserStats 저장됨 (초기값)
```

---

### ✅ 3단계: 첫 번째 Gem 작성 (WriteView)
```
액션: HomeView → "Write" 버튼 클릭 → WriteView → 데이터 입력 → "저장"
      (예: Mood 선택, 에너지 레벨, 한 줄 메모 등)

예상 콘솔 로그:
   💾 [WriteViewModel] saveCard() called
   📝 [TimeSeriesDataPoint] Saving dataPoint: {date, values, ...}
   ✅ [FirebaseDataService] Saved TimeSeriesDataPoint
   💎 [DailyGem] Creating DailyGem for {date}
   ✅ [FirebaseDataService] Saved DailyGem
   📊 [UserStats] Auto-updating:
      - totalDataPoints: 0 → 1
      - totalGemsCreated: 0 → 1
      - totalDaysActive: 0 → 1
      - currentStreak: 0 → 1

Firebase Console 확인:
   - anonymous_users/{anonId}/time_series/{dataId} → TimeSeriesDataPoint 저장됨
   - users/{accountId}/daily_gems/{gemId} → DailyGem 저장됨
   - users/{accountId}/stats/summary → UserStats 업데이트됨
```

---

### ✅ 4단계: HomeView 자동 새로고침 & 데이터 표시
```
액션: WriteView "저장" → HomeView 자동 전환 (또는 수동 새로고침)

예상 콘솔 로그 순서:
   📥 [HomeViewModel] loadInitialData() called
   📥 [HomeViewModel] Fetching daily gems from {startDate} to {endDate}
   ✅ [HomeViewModel] Received 1 daily gems
   📅 [HomeViewModel.updateLast7Days] ✅ TODAY (2026-01-10): Created gem (isCompleted=true)
   ✅ [HomeViewModel.updateLast7Days] FINAL RESULT: Updated last7Days with 1 records
      [0]: 2026-01-10 - isCompleted: true
   🔥 [HomeViewModel] Current streak: 1
   
   🚂 [RailroadView] Rendering 1 gem records:
      [0] 2026-01-10 - isCompleted: true
   
   ✨ [GemSlot.onAppear]
      - Date: 2026-01-10 HH:mm
      - Index: 0/1 (isTodayGem: true)
      - isCompleted: true
      - opacity (GemRecord): 1.0
      - yPosition: {value}
      - normalizedY: {value}
      - scrollViewHeight: {value}
      - finalOpacity: {value}
      - completionFactor: 1.0

화면 확인:
   ✅ HomeView 헤더: "Hi, {Name}" + Streak: 1 + Gems: 1 표시
   ✅ RailroadView: 오늘의 젬 1개 표시 (불투명한 상태)
   ✅ 젬 클릭 시 GemDetailView 표시
```

---

## 🔍 만약 젬이 안보인다면?

### 체크 1: Firebase에 데이터가 저장되었나?
```bash
# Firebase Console 확인
1. users/{accountId}/daily_gems 확인
   → 2026-01-10 날짜의 DailyGem이 있어야 함
2. users/{accountId}/stats/summary 확인
   → totalGemsCreated: 1, totalDaysActive: 1, currentStreak: 1
```

### 체크 2: HomeViewModel이 데이터를 로드했나?
```
콘솔에서 다음 로그 확인:
✅ [HomeViewModel] Received 1 daily gems (0이 아닌 1 이상)
✅ [HomeViewModel.updateLast7Days] FINAL RESULT: Updated last7Days with 1 records
```

### 체크 3: RailroadView가 데이터를 받았나?
```
콘솔에서 다음 로그 확인:
🚂 [RailroadView] Rendering 1 gem records:
```

### 체크 4: GemSlot이 렌더링되었나?
```
콘솔에서 다음 로그 확인:
✨ [GemSlot.onAppear] 로그가 나타나야 함
finalOpacity 값이 0.15 이상이어야 보임 (0이면 보이지 않음)
```

### 체크 5: 젬이 화면 밖에 있나?
```
다음을 확인:
- yPosition이 음수거나 매우 크면 화면 밖에 있을 수 있음
- normalizedY가 0~1 사이 범위를 벗어나면 fade 효과로 투명해질 수 있음
- horizontalOffset이 크면 좌우 밖에 있을 수 있음
```

---

## 🎯 최종 결과

### 성공한 경우 ✅
```
HomeView:
┌─────────────────────────────┐
│ Hi, User  Streak: 1 Gems: 1 │  ← 헤더
├─────────────────────────────┤
│                             │
│           💎                │  ← 오늘의 젬
│       2026-01-10            │
│                             │
└─────────────────────────────┘
```

### 실패한 경우 ❌
```
HomeView:
┌─────────────────────────────┐
│ Hi, User  Streak: ? Gems: ? │  ← 숫자가 안보이거나 0
├─────────────────────────────┤
│                             │
│     Loading gems...         │  ← 로딩 상태
│      (또는 완전히 비어있음)    │
│                             │
└─────────────────────────────┘

→ 콘솔 로그에서 위의 4개 체크포인트 중 어디서 멈추었는지 확인
```

---

## 📝 테스트 실행 가이드

1. **Xcode에서 빌드 & 실행**
   ```bash
   Cmd + R (또는 Product → Run)
   ```

2. **콘솔 창 열기**
   ```
   View → Debug Area → Show Debug Area (또는 Cmd + Shift + Y)
   ```

3. **필터로 로그 정렬**
   ```
   콘솔 검색창에 "[HomeViewModel]" 또는 "[RailroadView]" 입력
   ```

4. **각 체크포인트별 로그 확인**
   - `✅ [HomeViewModel]` → 데이터 로드 성공
   - `🚂 [RailroadView]` → 데이터 렌더링 시작
   - `✨ [GemSlot.onAppear]` → 각 젬 슬롯 렌더링
