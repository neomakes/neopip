# 🏛️ 04. Data Schema Definition: Human World Model

이 문서는 PIP 프로젝트의 핵심인 **Human World Model (Active Inference Agent)**을 구현하기 위한 데이터 스키마와 인과 관계(Causal Structure)를 정의합니다.

사용자를 단순한 '기록의 대상'이 아닌, **"환경($w$)과 상호작용하며 자신의 상태($s$)를 조절하고, 최적의 가치($O$)를 추구하는 능동적 에이전트($a$)"**로 모델링합니다.

---

## 1. Probabilistic Graphical Model (PGM)

이 모델은 시간 $t$에 따른 상태 변화를 학습하는 **Dynamic Bayesian Network**입니다. 목표는 결합 확률 분포 $P(O, o, s, a, w)$를 학습하여, 최적의 $O$를 달성하는 정책 $\pi(a|s, w)$를 도출하는 것입니다.

### 1.1. Causal Graph (DAG)

graph LR
    subgraph T["Time t (Today)"]
        direction TB
        w_t("World w_t")
        s_t("State s_t<br>(Start)")
        a_t("Action a_t<br>(Process)")
        o_t("Observation o_t<br>(Result)")
        O_t("Optimality O_t<br>(Review)")
        
        %% Intra-slice Dependencies
        w_t --> a_t
        s_t --> a_t
        a_t --> o_t
        s_t --> o_t
        a_t --> O_t
        s_t --> O_t
        o_t --> O_t
    end
    
    subgraph T1["Time t+1 (Tomorrow)"]
        direction TB
        w_t1("World w_t+1")
        s_t1("State s_t+1")
    end

    %% Time Transition
    s_t --> s_t1
    a_t --> s_t1
    w_t1 --> s_t1

    %% Styling
    classDef observable fill:#e1f5fe,stroke:#01579b,stroke-width:2px;
    classDef latent fill:#fff3e0,stroke:#ff6f00,stroke-width:2px;
    classDef optimality fill:#fce4ec,stroke:#880e4f,stroke-width:2px;

    class w_t,w_t1,a_t,o_t observable;
    class s_t,s_t1 latent;
    class O_t optimality;

### 1.2. Generative Distribution
모델은 다음 네 가지 핵심 확률 과정을 학습합니다. (Daily Log Model)

1.  **Policy (행동 선택)**: 오늘 상태와 환경에 따른 행동 선택
    $$P(a_t | s_t, w_t)$$
    > *"피곤한($s_t$) 밤($w_t$)에는 휴식($a_t$)을 취한다."*

2.  **Observation Emission (하루 결과)**: 시작 상태와 행동에 따른 오늘 결과
    $$P(o_t | s_t, a_t)$$
    > *"에너지가 적었지만($s_t$) 노력해서($a_t$) 성과($o_t$)를 냈다."*

3.  **Value Judgment (가치 평가)**: 오늘의 경험에 대한 최종 만족도
    $$P(O_t | s_t, o_t, a_t)$$
    > *"힘들었지만($s_t$) 성과($o_t$)가 좋아 보람찼다($O_t$)."*

4.  **State Transition (내일 상태)**: 오늘 활동이 내일 상태에 미치는 영향
    $$P(s_{t+1} | s_t, a_t, w_{t+1})$$
    > *"오늘 무리했더니($a_t$) 내일은($t+1$) 방전됐다($s_{t+1}$)."*

### 1.3. Joint Probability of a Trajectory

사용자의 시계열 궤적 $\tau = (s_{0:T}, a_{0:T}, o_{0:T}, O_{0:T}, w_{0:T})$에 대한 결합 확률 (Factorization):

$$
P(\tau) = \underbrace{P(s_0)}_{\text{Prior}} \prod_{t=0}^{T} \left[ 
\underbrace{P(w_t)}_{\text{Exogenous}} \cdot
\underbrace{P(a_t | s_t, w_t)}_{\text{Policy}} \cdot
\underbrace{P(o_t | s_t, a_t)}_{\text{Emission}} \cdot
\underbrace{P(O_t | s_t, o_t, a_t)}_{\text{Evaluation}} \cdot
\underbrace{P(s_{t+1} | s_t, a_t, w_{t+1})}_{\text{Transition}}
\right]
$$

*   **Goal**: Active Inference 에이전트는 이 모델 하에서 미래의 기대 가치(Expected Optimaliy $\mathbb{E}[O]$)를 최대화하거나, 기대 자유 에너지(Expected Free Energy)를 최소화하는 행동 $a_t$를 선택합니다.

---

## 2. Data Specification Table

오컴의 면도날을 적용하여, **모델링에 필수적인 변수**만 남긴 최종 명세입니다.

| 변수 | 항목 (Key) | 데이터 이름 | 정의 (Type) | 수집/출처 | 해상도 | 필수적인 이유 (Necessity) | 더 필요 없는 이유 (Sufficiency) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **$O$** | **Optimality** | `fulfillment` | **Likert Scale**<br>(1~5 Int) | **Manual**<br>(Event) | **Daily**<br>(Target) | **목적 함수(Target).**<br>단순 쾌락(State)을 넘어, "가치 있는 상태"를 학습하기 위한 최상위 지표. | 세부적 감정 명사(뿌듯함, 안도감 등)는 이 충만감(Fulfillment)의 스펙트럼 위에 있음. 단일 차원으로 충분. |
| **$a$** | **Action**<br>(Prop.) | `intervention_type` | **Enum**<br>(Activity Type) | **Manual**<br>(Event) | **Event**<br>(수시) | **개입(Control) 변수.**<br>상태($s$)를 능동적으로 변화시키는 유일한 수단. | 구체적 운동 종목 등은 노이즈. "신체 부하" 카테고리만으로 에너지 소모 모델링 충분. |
| **$a$** | **Action**<br>(Qty) | `intervention_amount` | **Float**<br>(Duration) | **Manual**<br>(Event) | **Event**<br>(수시) | **에너지 총량 제어.**<br>**수면 시간($E_0$ 결정)**이나 업무 강도는 에너지 변화량($\Delta E$)의 핵심 계수. | 시간/강도 외의 물리적 속성은 모델 복잡도를 불필요하게 높임. |
| **$a$** | **Action**<br>(Mental) | `mindset` | **Enum**<br>(Attitude) | **Manual**<br>(Event) | **Event**<br>(수시) | **심리적 개입.**<br>동일 행동의 다른 결과를 설명 (예: 억지 vs 도전). | 정량화 불가능한 생각(Text)의 행동주의적 요약. |
| **$s$** | **State** | `mood` | **Continuous**<br>(0.0~1.0) | **Manual**<br>(Slider) | **Time-Series** | **동기(Motivation).**<br>행동 지속 여부를 결정하는 쾌/불쾌(Valence). | Stress 등은 Mood/Energy 조합으로 표현 가능. 2차원 좌표면 충분. |
| **$s$** | **State** | `energy` | **Continuous**<br>(0.0~1.0) | **Manual**<br>(Slider) | **Time-Series** | **자원(Resource).**<br>번아웃 예측의 핵심인 각성(Arousal) 수준. | Fatigue는 Energy 역수. Energy 하나로 신체 예산을 모두 표현 가능. |
| **$o$** | **Outcome** | `focus_level` | **Continuous**<br>(0.0~100) | **Manual**<br>(Slider) | **Event** | **1인칭 증거(Evidence).**<br>상태 추론의 주관적 검증 지표. | "몰입"이 가장 본질적 성과 지표. 생산성 점수 등은 파생 변수임. |
| **$o$** | **Outcome** | `motion_context` | **Enum**<br>(Category) | **Auto**<br>(Sensor) | **Event** | **객관적 증거(Evidence).**<br>행동($a$)의 Ground Truth 검증. | 구체적 헬스 데이터(심박수)는 노이즈가 큼. 움직임 유형만으로 충분. |
| **$w$** | **World** | `weather` | **Enum**<br>(Condition) | **Auto**<br>(API) | **Hourly** | **외생적 스트레서.**<br>저기압 등 생리적 변화의 외부 요인 설명. | 습도, 풍속 등 세부 정보는 불필요. 거시적 날씨가 지배적. |
| **$w$** | **World** | `local_time` | **Structure**<br>(Time) | **System**<br>(Clock) | **Auto** | **생체 주기(Circadian) 기준.**<br>시간대별 에너지 예측 모델 분리. | 초 단위 불필요. 시간대(Hour) 해상도면 충분. |
| **$w$** | **World** | `location` | **Enum**<br>(POI Cat) | **System**<br>(Map) | **Auto** | **공간적 맥락.**<br>장소에 따른 행동 패턴($\pi$) 구분. | 실제 좌표는 불필요(Privacy & Noise). "집/회사" 여부만 알면 충분. |

---

## 3. Data Structure (Swift Representation)

```swift
/// The unified data point for Human World Model
struct TimeSeriesDataPoint: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    
    // 1. World Context (w_t)
    struct WorldContext: Codable {
        let weather: WeatherCondition // sunny, rain, cloudy...
        let locationLabel: LocationLabel // home, work, transit...
        let dayPhase: DayPhase // morning, afternoon, night
    }
    let world: WorldContext
    
    // 2. Action (Intervention) (a_t)
    struct Intervention: Codable {
        let type: ActivityType // work, rest, exercise, sleep, social...
        let amount: Double // duration in hours or intensity (0-1)
        let mindset: Mindset // challenge, duty, relax, passive...
    }
    let action: Intervention
    
    // 3. Internal State (s_t)
    struct InternalState: Codable {
        let mood: Double // 0.0 ~ 1.0 (Valence)
        let energy: Double // 0.0 ~ 1.0 (Arousal)
    }
    let state: InternalState
    
    // 4. Observation (Outcome) (o_t)
    struct Outcome: Codable {
        let focusLevel: Double // 0.0 ~ 100.0
        let detectedMotion: MotionType // stationary, walking, automotive...
    }
    let outcome: Outcome
    
    // 5. Optimality (Review) (O_t)
    let fulfillment: Int // 1 ~ 5 (Evaluative Emotion)
}
```
