# 🔥 Firebase Firestore 통합 고려사항

이 문서는 설계된 데이터 모델을 Firebase Firestore에 통합할 때 고려해야 할 사항들을 정리합니다.

---

## 1. Firebase Firestore 호환성 검토

### ✅ 호환되는 부분

1. **Codable 프로토콜**
   - 모든 모델이 `Codable`을 준수하므로 Firestore와 자동 호환
   - `Firestore.Encoder`와 `Firestore.Decoder` 사용 가능

2. **Date 타입**
   - Firestore의 `Timestamp`로 자동 변환됨
   - Swift의 `Date`와 자동 매핑

3. **Enum 타입**
   - `String` 기반 Enum은 `.rawValue`로 저장됨
   - 자동 인코딩/디코딩 지원

4. **Optional 필드**
   - `nil` 값은 Firestore에 저장되지 않음
   - 저장 공간 절약

### ⚠️ 주의해야 할 부분

1. **UUID 타입**
   - Firestore는 UUID를 직접 지원하지 않음
   - **해결책**: 모든 모델에 `*String` 프로퍼티 추가 (예: `accountIdString`)
   - Firestore 문서 ID로 사용하거나, 필드에 저장할 때는 String으로 변환

2. **중첩된 Dictionary**
   - `[String: DataValue]` 같은 복잡한 구조는 Map으로 저장됨
   - **주의**: `DataValue` enum의 커스텀 인코딩 필요

3. **배열 크기 제한**
   - Firestore는 배열 크기에 제한이 없지만, 성능 고려 필요
   - 큰 배열은 서브컬렉션으로 분리 고려

---

## 2. Firestore 컬렉션 구조

### 2.1. 사용자 계정 (PII 포함)
```
users/
  {accountId}/
    account/
      - UserAccount
    profile/
      - UserProfile
    settings/
      dataCollection/
        - UserDataCollectionSettings
      consentStatus/
        - UserConsentStatus
    consents/
      {consentId}/
        - ConsentRecord
    journal_entries/
      {entryId}/
        - JournalEntry
    daily_gems/
      {gemId}/
        - DailyGem
    daily_stats/
      {date}/
        - DailyStats
    goals/
      {goalId}/
        - Goal
        progress/
          {progressId}/
            - GoalProgress
    goal_recommendations/
      {recommendationId}/
        - GoalRecommendation
    badges/
      {badgeId}/
        - Badge
    achievements/
      {achievementId}/
        - Achievement
    stats/
      - UserStats
    value_analysis/
      {analysisId}/
        - ValueAnalysis
    deletion_requests/
      {requestId}/
        - DataDeletionRequest
```

### 2.2. 익명화된 사용자 데이터 (분석용)
```
anonymous_users/
  {anonymousUserId}/
    profile/
      - AnonymousUserProfile
    data_points/
      {dataPointId}/
        - TimeSeriesDataPoint
    ml_features/
      {featureId}/
        - MLFeatureVector
    ml_outputs/
      {outputId}/
        - MLModelOutput
    insights/
      {insightId}/
        - Insight
    orbs/
      {orbId}/
        - OrbVisualization
    trends/
      {trendId}/
        - TrendData
    predictions/
      {predictionId}/
        - PredictionData
```

### 2.3. ID 매핑 (보안)
```
identity_mappings/
  {mappingId}/
    - IdentityMapping
    (보안 규칙으로 접근 제어 필요)
```

### 2.4. 데이터 스키마 레지스트리
```
data_type_schemas/
  {schemaId}/
    - DataTypeSchema
```

### 2.5. ML 모델 및 데이터셋
```
ml_datasets/
  {datasetId}/
    - MLTrainingDataset

ml_models/
  {modelId}/
    - MLModelMetadata
```

### 2.6. 프로그램 (공유 가능)
```
programs/
  {programId}/
    - Program
```

### 2.7. 삭제 로그
```
deletion_logs/
  {logId}/
    - DeletionLog
```

---

## 3. 인덱싱 전략

### 3.1. 필수 인덱스

**users/{accountId}/journal_entries**
- `date` (descending)
- `category`
- `createdAt` (descending)

**users/{accountId}/daily_gems**
- `date` (descending)

**users/{accountId}/goals**
- `status`
- `targetDate`
- `progress`

**anonymous_users/{anonymousUserId}/data_points**
- `timestamp` (descending)
- `date` (descending)
- `source`

**anonymous_users/{anonymousUserId}/insights**
- `type`
- `createdAt` (descending)
- `confidence`

**anonymous_users/{anonymousUserId}/trends**
- `period`
- `startDate`
- `endDate`

### 3.2. 복합 인덱스

다음 쿼리를 위해 복합 인덱스 필요:
- `date` + `category` (journal_entries)
- `status` + `targetDate` (goals)
- `timestamp` + `source` (data_points)
- `type` + `createdAt` (insights)

---

## 4. 보안 규칙 (Firestore Security Rules)

### 4.1. 사용자 데이터 접근 제어

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 사용자는 자신의 데이터만 접근 가능
    match /users/{accountId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == accountId;
    }
    
    // 익명화된 사용자 데이터는 본인만 접근
    match /anonymous_users/{anonymousUserId}/{document=**} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/identity_mappings/$(mappingId)).data.accountId == request.auth.uid;
    }
    
    // ID 매핑은 읽기 전용 (서버에서만 쓰기)
    match /identity_mappings/{mappingId} {
      allow read: if request.auth != null;
      allow write: if false; // Cloud Functions에서만 쓰기
    }
    
    // ML 데이터셋은 읽기 전용 (서버에서만 쓰기)
    match /ml_datasets/{datasetId} {
      allow read: if request.auth != null;
      allow write: if false; // Cloud Functions에서만 쓰기
    }
    
    // 프로그램은 모든 인증된 사용자가 읽기 가능
    match /programs/{programId} {
      allow read: if request.auth != null;
      allow write: if false; // 관리자만 쓰기
    }
  }
}
```

---

## 5. 데이터 마이그레이션 전략

### 5.1. UUID → String 변환

기존 모델에 `*String` 프로퍼티를 추가했으므로:
- Firestore 문서 ID로 사용: `accountIdString`
- 필드에 저장할 때: `accountId.uuidString`

### 5.2. 중첩 구조 처리

복잡한 중첩 구조는:
- 작은 구조: 문서 내에 포함
- 큰 구조: 서브컬렉션으로 분리

예:
- `Goal.milestones`: 문서 내 배열로 저장 (작음)
- `Goal.progress`: 서브컬렉션으로 분리 (큼)

---

## 6. 성능 최적화

### 6.1. 쿼리 최적화

1. **인덱스 활용**: 자주 사용하는 쿼리에 인덱스 생성
2. **페이지네이션**: 큰 컬렉션은 `limit()` 사용
3. **캐싱**: 자주 읽는 데이터는 로컬 캐시 활용

### 6.2. 데이터 구조 최적화

1. **서브컬렉션 vs 배열**
   - 작은 데이터 (< 100개): 배열
   - 큰 데이터 (> 100개): 서브컬렉션

2. **읽기 최소화**
   - 필요한 필드만 읽기 (`select()` 사용)
   - 배치 읽기 활용

---

## 7. 구현 체크리스트

### Phase 1: 기본 구조
- [ ] Firebase 프로젝트 생성
- [ ] Firestore 데이터베이스 생성
- [ ] 보안 규칙 초기 설정
- [ ] 기본 인덱스 생성

### Phase 2: 사용자 인증
- [ ] Firebase Auth 연동
- [ ] UserAccount 생성 로직
- [ ] AnonymousUserIdentity 생성 로직
- [ ] IdentityMapping 생성 로직

### Phase 3: 데이터 수집
- [ ] TimeSeriesDataPoint 저장 로직
- [ ] JournalEntry 저장 로직
- [ ] 데이터 수집 설정 저장

### Phase 4: ML/AI 연동
- [ ] MLFeatureVector 저장 로직
- [ ] MLModelOutput 저장 로직
- [ ] Cloud Functions에서 ML 모델 호출

### Phase 5: 인사이트 생성
- [ ] Insight 생성 로직
- [ ] OrbVisualization 생성 로직
- [ ] TrendData 계산 및 저장

---

## 8. 주의사항

1. **비용 관리**
   - Firestore는 읽기/쓰기/저장에 따라 과금
   - 불필요한 읽기 최소화
   - 인덱스 생성 시 비용 고려

2. **데이터 일관성**
   - 트랜잭션 사용 (필요시)
   - 배치 쓰기 활용

3. **오프라인 지원**
   - Firestore는 기본적으로 오프라인 캐시 지원
   - 네트워크 상태 확인 로직 추가

4. **에러 처리**
   - Firestore 에러 타입 처리
   - 재시도 로직 구현

---

**작성일**: 2025.12  
**버전**: 1.0  
**상태**: 초안
