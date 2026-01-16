# 📊 PIP Analytics Guide: Privacy-First Analysis

이 문서는 `engagement_analysis.ipynb` 노트북의 차트 해석 방법과 이를 통한 "In-App Feedback Loop" 활용 가이드를 제공합니다.

---

## 🏗️ 1. 기본 원칙 (The iOS Reality)
이 분석 도구는 애플의 ATT(앱 추적 투명성) 정책을 준수하며, **IDFV(벤더 식별자)**를 기준으로 "익명화된 행동 패턴"을 분석합니다.

*   **No Fingerprinting**: 기기 정보는 `iPhone 13 Series`와 같이 **그룹화**되어 저장됩니다.
*   **No Exact Latency**: 성능 데이터는 구간(Bucket)으로 분석되어 개인 식별을 방지합니다.

---

## 👑 2. 의사결정자 대시보드 (Decision Maker)

### A. Global Cohort Retention (히트맵)
*   **차트 설명**: 가로축은 "가입 후 경과 일수(Day N)", 세로축은 "가입 시점(Cohort)"입니다.
*   **🟢 좋은 신호 (Healthy)**: 색상이 오른쪽으로 갈수록 완만하게 옅어짐 (예: Day 1: 40% -> Day 7: 20%).
*   **🔴 위험 신호 (Warning)**: 특정 날짜(Day 1)에 급격히 색이 옅어지거나(이탈), 특정 코호트 전체가 어두운 색이 없음(유입 품질 저하).
*   **Action**: Day 1 리텐션이 낮다면 **온보딩 경험(First Run Experience)**을 점검하세요.

---

## 💻 3. 개발자 대시보드 (Stability & Friction)

### A. Session Outcomes by Device Group (막대 그래프)
*   **차트 설명**: 기기 그룹별(iPhone 13, 14 등) 세션 성공(`completed`) vs 실패(`aborted`) 비율입니다.
*   **🟢 좋은 신호**: 모든 기기 그룹에서 `completed` 비율이 비슷함.
*   **🔴 위험 신호**: 특정 기기 그룹(예: "Older iPhones")에서만 `aborted` 비율이 유독 높음.
*   **Action**: 해당 기기 모델을 구하여 성능 테스트(UI Freezing)를 수행하세요.

---

## 📈 4. 마케터 대시보드 (Growth)

### A. Time to Magic (TTM) (히스토그램)
*   **차트 설명**: 앱 설치 시점부터 **첫 번째 핵심 가치(글쓰기 완료)**를 경험하기까지 걸린 시간의 분포입니다.
*   **🟢 좋은 신호**: 그래프의 피크(Peak)가 앞쪽(5분 이내)에 쏠려 있음. (빠른 아하 모먼트).
*   **🔴 위험 신호**: 분포가 매우 넓거나, 평균 시간이 10분 이상임.
*   **Action**: 홈 화면의 UI를 단순화하거나, 첫 글쓰기 유도 마이크로카피를 수정하세요.

---

## 🔁 5. 피드백 루프 (The Struggler Trigger)

### A. "Struggler" 감지 로직
단순한 실패가 아니라, **"노력했으나 실패한"** 유저를 찾아냅니다.

> **Trigger Condition**:
> 1. 세션 상태가 `completed`가 아님 (Aborted/Unknown).
> 2. 체류 시간이 **개인 평균 시간 + (2 * 표준편차)**를 초과함.

### B. 활용 시나리오
이 로직에 걸린 유저 ID(`subject_id`) 리스트를 추출하여, 다음 앱 실행 시 **"마이크로 서베이"**를 띄웁니다.

*   **상황**: 평소 10초면 글을 쓰는 유저가, 40초 동안 머물다 나감.
*   **메시지**: "어제 글쓰기가 평소보다 오래 걸리셨네요. 어떤 점이 불편하셨나요?"
*   **옵션**:
    1.  앱이 버벅거림 (→ 성능 이슈 티켓 생성)
    2.  뭘 쓸지 모르겠음 (→ '글감 추천' 기능 켜주기)
    3.  그냥 바빴음 (→ 무시)

이 루프는 유저의 "불만(Friction)"을 "개선(Insight)"으로 바꾸는 핵심 장치입니다.
