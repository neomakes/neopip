// PIP Project - Firebase Firestore Schema (dbdiagram.io format)
// Version: 2.0
// Last Updated: 2026.01.05
// Purpose: Production-ready database schema visualization

// ==================== 1. IDENTITY LAYER (프라이버시 분리) ====================

Table user_accounts {
  id uuid [pk, note: "Firestore Doc ID"]
  email string [unique, not null]
  created_at timestamp [not null]
  deletion_requested_at timestamp [null, note: "PII 삭제 요청 시간"]
  is_active boolean [default: true]
  
  Indexes {
    (email)
    (created_at)
  }
  
  Note: "PII 영역 (users/{accountId}/*) - 개인식별정보 포함"
}

Table anonymous_user_identities {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, ref: > user_accounts.id]
  created_at timestamp [not null]
  is_active boolean [default: true]
  
  Indexes {
    (account_id)
  }
  
  Note: "익명화 영역 (anonymous_users/{anonymousUserId}/*) - 분석 데이터 전용"
}

Table identity_mappings {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, ref: > user_accounts.id]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  encrypted_mapping string [not null, note: "암호화된 매핑"]
  created_at timestamp [not null]
  is_active boolean [default: true]
  
  Indexes {
    (account_id)
    (anonymous_user_id)
  }
  
  Note: "보안 영역 (identity_mappings/*) - 읽기전용, Cloud Functions만 쓰기"
}

Table consent_records {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, ref: > user_accounts.id]
  consent_type string [not null, note: "analytics|ml_training|data_sharing"]
  given_at timestamp [not null]
  version string [not null]
  
  Indexes {
    (account_id)
    (consent_type)
  }
  
  Note: "PII 영역 - 데이터 사용 동의 기록"
}

Table data_deletion_requests {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, ref: > user_accounts.id]
  requested_at timestamp [not null]
  completed_at timestamp [null]
  status string [not null, note: "pending|completed|failed"]
  
  Indexes {
    (account_id)
    (status)
  }
  
  Note: "PII 영역 - GDPR/삭제권 관리"
}

// ==================== 2. USER PROFILE LAYER (사용자 프로필) ====================

Table user_profiles {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, unique, ref: > user_accounts.id]
  profile_image_url string [null]
  background_image_url string [null]
  feature_color string [null, note: "JSON: {primary: #RRGGBB, secondary: #RRGGBB, tertiary: #RRGGBB} - ML feature vector 기반 색상"]
  onboarding_state string [null, note: "JSON: {completedSteps: [...], selectedGoals: [...]}"]
  created_at timestamp [not null]
  updated_at timestamp [not null]
  
  Note: "PII 영역 (users/{accountId}/profile) - 프로필 정보"
}

Table user_data_collection_settings {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, unique, ref: > user_accounts.id]
  enabled_data_types string [not null, note: "JSON array: [mood, stress, energy, focus, sleep_score, ...]"]
  anonymization_level string [not null, note: "full|partial|none"]
  permissions string [not null, note: "JSON: {location: true, healthKit: false, ...}"]
  created_at timestamp [not null]
  updated_at timestamp [not null]
  
  Note: "PII 영역 - 데이터 수집 설정"
}

Table onboarding_states {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, unique, ref: > user_accounts.id]
  completed_steps string [not null, note: "JSON array: step names"]
  selected_goals string [null, note: "JSON array: goal IDs"]
  is_completed boolean [default: false]
  created_at timestamp [not null]
  updated_at timestamp [not null]
  
  Note: "PII 영역 (users/{accountId}/onboarding) - 온보딩 진행 상황"
}

Table pip_scores {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, unique, ref: > user_accounts.id]
  overall_score double [not null, note: "0.0 ~ 1.0"]
  mind_score double [not null]
  behavior_score double [not null]
  physical_score double [not null]
  calculated_at timestamp [not null]
  updated_at timestamp [not null]
  
  Indexes {
    (overall_score)
  }
  
  Note: "PII 영역 (users/{accountId}/pip_score) - 종합 점수"
}

// ==================== 3. TIME SERIES DATA LAYER (시계열 데이터) ====================

Table data_type_schemas {
  id uuid [pk, note: "Firestore Doc ID"]
  name string [unique, not null, note: "mood|stress|energy|focus|sleep_score|..."]
  data_type string [not null, note: "double|integer|string|boolean"]
  min_value double [null]
  max_value double [null]
  description string [not null]
  created_at timestamp [not null]
  
  Note: "글로벌 영역 (data_type_schemas/*) - 데이터 타입 정의"
}

Table time_series_data_points {
  id uuid [pk, note: "Firestore Doc ID"]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  timestamp timestamp [not null]
  date date [not null, note: "YYYY-MM-DD"]
  
  values string [not null, note: "JSON: {mood: {type: double, value: 75}, stress: {type: double, value: 30}, ...}"]
  notes string [null, note: "PII-removed memo, 최대 1000자"]
  category string [null, note: "mind|behavior|physical"]
  source string [not null, note: "manual|screenTime|healthKit|wearable"]
  
  confidence double [not null, note: "0.0 ~ 1.0"]
  completeness double [not null, note: "0.0 ~ 1.0"]
  
  features string [null, note: "JSON: extracted ML features"]
  predictions string [null, note: "JSON: raw predictions from model"]
  anomalies string [null, note: "JSON array: detected anomalies"]
  
  created_at timestamp [not null]
  updated_at timestamp [not null]
  
  Indexes {
    (anonymous_user_id, date) [type: composite]
    (timestamp)
    (category)
    (source)
  }
  
  Note: "익명화 영역 (anonymous_users/{anonymousUserId}/data_points/*) - 핵심 데이터"
}

Table ml_feature_vectors {
  id uuid [pk, note: "Firestore Doc ID"]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  time_period_start date [not null]
  time_period_end date [not null]
  
  features string [not null, note: "JSON: {feature_1: 0.75, feature_2: 0.32, ...}"]
  normalization_params string [not null, note: "JSON: {mean: [...], std: [...]}"]
  
  created_at timestamp [not null]
  
  Indexes {
    (anonymous_user_id)
    (time_period_start)
  }
  
  Note: "익명화 영역 (anonymous_users/{anonymousUserId}/ml_features/*) - ML 특징 벡터"
}

Table ml_model_outputs {
  id uuid [pk, note: "Firestore Doc ID"]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  ml_feature_vector_id uuid [not null, ref: > ml_feature_vectors.id]
  model_version string [not null]
  
  reconstruction_performance double [not null, note: "0.0 ~ 1.0 - 재생성 성능"]
  prediction_accuracy double [not null, note: "0.0 ~ 1.0 - 예측 정확도"]
  
  predictions string [not null, note: "JSON: predicted values"]
  anomaly_scores string [not null, note: "JSON: anomaly detection scores"]
  
  executed_at timestamp [not null]
  
  Indexes {
    (anonymous_user_id)
  }
  
  Note: "익명화 영역 (anonymous_users/{anonymousUserId}/ml_outputs/*) - ML 모델 결과"
}

// ==================== 4. AGGREGATION LAYER (집계 데이터) ====================

Table daily_gems {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, ref: > user_accounts.id]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  date date [not null, note: "YYYY-MM-DD"]
  
  gem_type string [not null, note: "standard|rare|epic|legendary"]
  brightness double [not null, note: "0.0 ~ 1.0"]
  uncertainty double [not null, note: "0.0 ~ 1.0"]
  color_theme string [not null, note: "JSON: {primary: #RRGGBB, secondary: #RRGGBB}"]
  
  data_point_ids string [not null, note: "JSON array: related TimeSeriesDataPoint IDs"]
  
  created_at timestamp [not null]
  
  Indexes {
    (account_id, date) [type: composite]
  }
  
  Note: "PII 영역 (users/{accountId}/daily_gems/*) - 일일 Gem 시각화"
}

Table daily_stats {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, ref: > user_accounts.id]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  date date [not null, note: "YYYY-MM-DD"]
  
  total_data_points integer [not null, note: "그날 입력한 데이터 수"]
  notes_count integer [not null, note: "메모가 있는 데이터 수"]
  
  mind_score double [not null, note: "0.0 ~ 1.0"]
  behavior_score double [not null, note: "0.0 ~ 1.0"]
  physical_score double [not null, note: "0.0 ~ 1.0"]
  
  completeness_ratio double [not null, note: "0.0 ~ 1.0"]
  confidence_ratio double [not null, note: "0.0 ~ 1.0"]
  
  notes_by_category string [not null, note: "JSON: {mind: 3, behavior: 2, physical: 1}"]
  data_source_counts string [not null, note: "JSON: {manual: 5, screenTime: 2, healthKit: 1}"]
  
  created_at timestamp [not null]
  
  Indexes {
    (account_id, date) [type: composite]
  }
  
  Note: "PII 영역 (users/{accountId}/daily_stats/*) - 일일 통계 (Cloud Functions 자동 생성)"
}

Table trend_data {
  id uuid [pk, note: "Firestore Doc ID"]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  metric_name string [not null, note: "mood|stress|energy|focus|..."]
  time_period string [not null, note: "week|month|month_3|year"]
  
  values string [not null, note: "JSON array: [75, 72, 80, 85, ...]"]
  trend_direction string [not null, note: "up|down|stable"]
  trend_strength double [not null, note: "0.0 ~ 1.0"]
  
  calculated_at timestamp [not null]
  
  Indexes {
    (anonymous_user_id, metric_name)
  }
  
  Note: "익명화 영역 (anonymous_users/{anonymousUserId}/trends/*) - 트렌드 분석"
}

// ==================== 5. INSIGHT LAYER (인사이트) ====================

Table insights {
  id uuid [pk, note: "Firestore Doc ID"]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  ml_model_output_id uuid [not null, ref: > ml_model_outputs.id]
  
  type string [not null, note: "pattern|anomaly|prediction|recommendation"]
  title string [not null]
  description string [not null]
  findings string [not null, note: "JSON: detailed findings"]
  recommendations string [not null, note: "JSON array: recommendations"]
  
  confidence double [not null, note: "0.0 ~ 1.0"]
  is_actionable boolean [not null]
  
  created_at timestamp [not null]
  
  Indexes {
    (anonymous_user_id, created_at) [type: composite]
    (type)
  }
  
  Note: "익명화 영역 (anonymous_users/{anonymousUserId}/insights/*) - Cloud Functions 자동 생성"
}

Table orb_visualizations {
  id uuid [pk, note: "Firestore Doc ID"]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  ml_model_output_id uuid [not null, ref: > ml_model_outputs.id]
  insight_id uuid [not null, ref: > insights.id]
  
  brightness double [not null, note: "0.0 ~ 1.0, 재생성 성능 (reconstruction_performance)"]
  border_brightness double [not null, note: "0.0 ~ 1.0, 예측 정확도 (prediction_accuracy)"]
  color_gradient string [not null, note: "JSON array: 3 colors [#RRGGBB, #RRGGBB, #RRGGBB] from unique features"]
  
  data_point_ids string [not null, note: "JSON array: based on these TimeSeriesDataPoints"]
  unique_features string [not null, note: "JSON array: top 3 distinguishing features"]
  
  created_at timestamp [not null]
  
  Indexes {
    (anonymous_user_id)
  }
  
  Note: "익명화 영역 (anonymous_users/{anonymousUserId}/orbs/*) - Orb 시각화 (Cloud Functions 생성)"
}

Table insight_analysis_cards {
  id uuid [pk, note: "Firestore Doc ID"]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  insight_id uuid [not null, ref: > insights.id]
  
  title string [not null]
  description string [not null]
  
  pages string [not null, note: "JSON array: [{ title, image, caption, dataViz }, ...]"]
  action_proposals string [not null, note: "JSON array: [{ action, calendar, alarm }, ...]"]
  
  is_shared boolean [default: false]
  shared_at timestamp [null]
  
  created_at timestamp [not null]
  
  Indexes {
    (anonymous_user_id)
  }
  
  Note: "익명화 영역 (anonymous_users/{anonymousUserId}/insight_cards/*) - 카드뉴스 형식"
}

Table prediction_data {
  id uuid [pk, note: "Firestore Doc ID"]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  ml_model_output_id uuid [not null, ref: > ml_model_outputs.id]
  
  metric_name string [not null]
  predicted_values string [not null, note: "JSON array: predicted values"]
  confidence_intervals string [not null, note: "JSON: {lower: [...], upper: [...]}"]
  
  prediction_horizon integer [not null, note: "days ahead"]
  
  created_at timestamp [not null]
  
  Indexes {
    (anonymous_user_id)
  }
  
  Note: "익명화 영역 (anonymous_users/{anonymousUserId}/predictions/*) - 예측 데이터"
}

// ==================== 6. GOAL & PROGRAM LAYER (목표 & 프로그램) ====================

Table goals {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, ref: > user_accounts.id]
  
  title string [not null]
  description string [not null]
  category string [not null, note: "mind|behavior|physical"]
  
  status string [not null, note: "active|completed|paused|abandoned"]
  progress double [not null, note: "0.0 ~ 1.0"]
  
  start_date date [not null]
  target_date date [null]
  
  related_data_point_ids string [not null, note: "JSON array: related TimeSeriesDataPoint IDs (via IdentityMapping)"]
  
  created_at timestamp [not null]
  updated_at timestamp [not null]
  
  Indexes {
    (account_id, status) [type: composite]
    (target_date)
  }
  
  Note: "PII 영역 (users/{accountId}/goals/*) - 목표 관리"
}

Table goal_progress {
  id uuid [pk, note: "Firestore Doc ID"]
  goal_id uuid [not null, ref: > goals.id]
  
  date date [not null]
  progress_value double [not null, note: "0.0 ~ 1.0"]
  notes string [null]
  
  created_at timestamp [not null]
  
  Indexes {
    (goal_id, date) [type: composite]
  }
  
  Note: "PII 영역 (users/{accountId}/goals/{goalId}/progress/*) - 진행 기록"
}

Table goal_recommendations {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, ref: > user_accounts.id]
  insight_id uuid [not null, ref: > insights.id]
  
  recommended_goal string [not null, note: "추천 목표 제목"]
  reason string [not null]
  relevance_score double [not null, note: "0.0 ~ 1.0"]
  
  is_accepted boolean [default: false]
  accepted_at timestamp [null]
  
  created_at timestamp [not null]
  
  Indexes {
    (account_id, is_accepted) [type: composite]
  }
  
  Note: "PII 영역 (users/{accountId}/recommendations/*) - AI 기반 목표 추천"
}

Table programs {
  id uuid [pk, note: "Firestore Doc ID"]
  
  title string [not null]
  description string [not null]
  category string [not null, note: "mind|behavior|physical"]
  
  duration_weeks integer [not null]
  difficulty string [not null, note: "easy|medium|hard"]
  
  illustration_3d_url string [not null, note: "3D 일러스트 URL"]
  popularity double [not null, note: "0.0 ~ 1.0"]
  rating double [not null, note: "1.0 ~ 5.0"]
  review_count integer [not null]
  
  created_at timestamp [not null]
  
  Indexes {
    (category)
    (popularity)
  }
  
  Note: "글로벌 영역 (programs/*) - 제시된 프로그램 카탈로그"
}

Table program_reviews {
  id uuid [pk, note: "Firestore Doc ID"]
  program_id uuid [not null, ref: > programs.id]
  account_id uuid [not null, ref: > user_accounts.id]
  
  rating double [not null, note: "1.0 ~ 5.0"]
  review_text string [not null]
  helpful_count integer [default: 0]
  
  created_at timestamp [not null]
  
  Indexes {
    (program_id, rating) [type: composite]
  }
  
  Note: "PII 영역 (users/{accountId}/program_reviews/*) - 프로그램 리뷰"
}

// ==================== 7. ACHIEVEMENT & STATUS LAYER (성취 & 통계) ====================

Table user_stats {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, unique, ref: > user_accounts.id]
  
  total_data_points integer [not null]
  total_gems integer [not null]
  streak_days integer [not null]
  
  last_recorded_at timestamp [null]
  
  updated_at timestamp [not null]
  
  Note: "PII 영역 (users/{accountId}/stats) - 사용자 통계"
}

// ==================== 6-1. HOME VIEW - PROGRAM ENROLLMENT ====================

Table user_program_enrollments {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, ref: > user_accounts.id]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  program_id uuid [not null, ref: > programs.id]
  
  enrollment_status string [not null, note: "active|completed|paused|abandoned"]
  start_date date [not null]
  target_completion_date date [null]
  actual_completion_date date [null]
  
  initial_metrics string [not null, note: "JSON: {metric_1: 75, metric_2: 30, ...} - 프로그램 시작 시 초기값"]
  success_progress double [not null, note: "0.0 ~ 1.0 - Cloud Functions 자동 계산"]
  success_rate double [null, note: "0.0 ~ 1.0 - 프로그램 완료 후 계산"]
  
  created_at timestamp [not null]
  updated_at timestamp [not null]
  
  Indexes {
    (account_id, enrollment_status) [type: composite]
    (program_id, enrollment_status) [type: composite]
  }
  
  Note: "PII 영역 (users/{accountId}/program_enrollments/*) - 프로그램 참여 기록"
}

Table program_specific_data_points {
  id uuid [pk, note: "Firestore Doc ID"]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  user_program_enrollment_id uuid [not null, ref: > user_program_enrollments.id]
  
  timestamp timestamp [not null]
  date date [not null, note: "YYYY-MM-DD"]
  
  values string [not null, note: "JSON: {program_metric_1: {type: double, value: 65}, program_metric_2: {...}, ...}"]
  notes string [null, note: "프로그램 특화 메모, 최대 1000자"]
  
  confidence double [not null, note: "0.0 ~ 1.0"]
  completeness double [not null, note: "0.0 ~ 1.0"]
  
  created_at timestamp [not null]
  updated_at timestamp [not null]
  
  Indexes {
    (user_program_enrollment_id, date) [type: composite]
    (timestamp)
  }
  
  Note: "익명화 영역 (anonymous_users/{anonymousUserId}/program_data_points/*) - 프로그램 특화 시계열 데이터"
}

Table period_reports {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, ref: > user_accounts.id]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  
  period_type string [not null, note: "weekly|monthly|quarterly|semi_annual|yearly"]
  period_start_date date [not null]
  period_end_date date [not null]
  
  summary_metrics string [not null, note: "JSON: aggregated statistics for period"]
  insight_ids string [not null, note: "JSON array: related insight IDs"]
  
  created_at timestamp [not null]
  
  Indexes {
    (account_id, period_type, period_start_date) [type: composite]
  }
  
  Note: "PII 영역 (users/{accountId}/period_reports/*) - 기간별 자동 생성 리포트"
}

Table program_success_metrics {
  id uuid [pk, note: "Firestore Doc ID"]
  program_id uuid [not null, ref: > programs.id]
  
  metric_name string [not null, note: "프로그램별 성공 지표 (예: addiction_symptom_reduction)"]
  target_value double [not null, note: "목표값"]
  metric_type string [not null, note: "improvement|threshold"]
  weight double [not null, note: "여러 지표의 가중치 (합 = 1.0)"]
  
  description string [not null]
  created_at timestamp [not null]
  
  Indexes {
    (program_id)
  }
  
  Note: "글로벌 영역 (program_success_metrics/*) - 프로그램별 성공 정의"
}
Table badges {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, ref: > user_accounts.id]
  
  name string [not null]
  description string [not null]
  badge_type string [not null, note: "program_completion|milestone|streak|hidden_condition"]
  
  illustration_3d_url string [not null, note: "3D 일러스트 URL"]
  color_scheme string [not null, note: "JSON: {primary: #RRGGBB, secondary: #RRGGBB}"]
  
  condition string [not null, note: "unlock 조건 설명"]
  unlock_rule string [not null, note: "JSON: 프로그램 ID, 기준값 등 unlock 규칙"]
  
  unlocked_at timestamp [null]
  
  Indexes {
    (account_id, badge_type) [type: composite]
  }
  
  Note: "PII 영역 (users/{accountId}/badges/*) - 배지 시스템 (프로그램 완료 및 조건 달성)"
}

Table value_analysis {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, ref: > user_accounts.id]
  
  value_name string [not null, note: "예: 창의성, 공감, 자기관리"]
  value_score double [not null, note: "0.0 ~ 1.0"]
  supporting_data_points integer [not null]
  
  analyzed_at timestamp [not null]
  
  Indexes {
    (account_id, value_name) [type: composite]
  }
  
  Note: "PII 영역 (users/{accountId}/values/*) - 개인의 핵심 가치 분석"
}

// ==================== 8. NOTES ====================

// Authentication & Identity
// - All users must authenticate via Firebase Auth
// - UserAccount.id is the Firebase Auth UID
// - AnonymousUserIdentity provides unlinkable analytics identity
// - IdentityMapping enables secure linking (Cloud Functions only)

// Firestore Structure
// ROOT COLLECTIONS:
//   - user_accounts/ (PII, requires auth)
//   - anonymous_users/ (analytics, no PII)
//   - identity_mappings/ (security layer, Cloud Functions only)
//   - programs/ (public, read-only)
//   - data_type_schemas/ (public, config)

// Cloud Functions Automation
// 1. Daily Aggregation (00:00 KST)
//    - Input: TimeSeriesDataPoint (yesterday)
//    - Output: DailyStats + DailyGem
//    - Frequency: Once per day

// 2. Weekly ML Execution (Sunday 10:00 KST)
//    - Input: TimeSeriesDataPoint (7 days)
//    - Process: Feature extraction → Model inference
//    - Output: MLModelOutput → Insight → OrbVisualization + PredictionData
//    - Frequency: Once per week

// 3. Program Enrollment Monitoring (Daily 01:00 KST)
//    - Input: ProgramSpecificDataPoints + UserProgramEnrollment
//    - Output: Update success_progress based on ProgramSuccessMetrics
//    - Auto-unlock badges on completion
//    - Frequency: Once per day

// 4. Period Report Generation (Daily 02:00 KST)
//    - Input: TimeSeriesDataPoint, DailyGems (past 7/30/90/180/365+ days)
//    - Trigger: Milestone-based (7d, 30d, 90d, 180d, 365d+)
//    - Process: Aggregate data, consolidate old reports when gems exceed 7
//    - Output: PeriodReports (auto-delete old weekly/monthly when new period created)
//    - Frequency: Once per day (on milestone dates)

// 5. Monthly Value Analysis (1st of month, 03:00 KST)
//    - Input: TimeSeriesDataPoint (all historical)
//    - Process: ML-based value extraction and scoring
//    - Output: ValueAnalysis + UserProfile.feature_color update
//    - Frequency: Once per month

// 6. PII Cleanup (1st of month, 04:00 KST)
//    - Input: DataDeletionRequest (completed)
//    - Actions: Delete related data, disable IdentityMapping
//    - Frequency: Once per month

// Data Retention
// - TimeSeriesDataPoint: 2 years (configurable)
// - DailyGem, DailyStats: Permanent (user's PII)
// - Insights, OrbVisualization: 1 year after generation
// - MLTrainingDataset: Per user consent (usually 30 days)

// Security Rules Key Principles
// 1. PII segregation: users/* requires auth + accountId match
// 2. Anonymity: anonymous_users/* has no link to PII
// 3. IdentityMapping: Read-only for app, write-only for Cloud Functions
// 4. Consent-based: Access controlled by ConsentRecord
// 5. GDPR: DataDeletionRequest triggers automatic cleanup
