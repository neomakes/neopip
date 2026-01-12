// PIP Project - Firebase Firestore Schema (dbdiagram.io format)
// Version: 3.0 - Minimal Schema
// Last Updated: 2026.01.05
// Purpose: Minimal production-ready database schema (View-focused)
// Removed: 15 non-essential tables (daily_stats, goal_progress, goal_recommendations, trend_data, 
//          program_reviews, data_type_schemas, consent_records, data_deletion_requests, 
//          onboarding_states, user_data_collection_settings)

// ==================== 1. IDENTITY LAYER (프라이버시 분리) ====================

Table user_accounts {
  id uuid [pk, note: "Firestore Doc ID"]
  email string [unique, not null]
  created_at timestamp [not null]
  is_active boolean [default: true]
  
  Indexes {
    (email)
  }
  
  Note: "PII 영역 (users/{accountId}/*) - 개인식별정보"
}

Table anonymous_user_identities {
  id uuid [pk, note: "Firestore Doc ID"]
  created_at timestamp [not null]
  is_active boolean [default: true]
  
  Note: "익명화 영역 (anonymous_users/{anonymousUserId}/*) - account_id 없음, 분석 데이터 전용"
}

Table identity_mappings {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, ref: > user_accounts.id]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  encrypted_mapping string [not null]
  created_at timestamp [not null]
  is_active boolean [default: true]
  
  Indexes {
    (account_id)
    (anonymous_user_id)
  }
  
  Note: "보안 영역 (identity_mappings/*) - Cloud Functions만 쓰기"
}

// ==================== 2. USER PROFILE LAYER (사용자 프로필) ====================

Table user_profiles {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id string [not null, unique, note: "Firebase Auth UID"]
  display_name string [null]
  profile_image_url string [null]
  background_image_url string [null]
  
  preferences string [not null, note: "JSON: {theme, notifications, ...}"]
  onboarding_state string [null, note: "JSON: {completedSteps: [...], selectedGoals: [...]}"]
  goals string [null, note: "JSON array: ['Sleep', 'Focus', ...]"]
  enabled_data_types string [not null, note: "JSON array: [mood, stress, ...]"]
  anonymization_level string [not null, note: "none|pseudonymized|fullyAnonymized"]
  permissions string [null, note: "JSON: {location: granted, ...}"]
  
  created_at timestamp [not null]
  last_active_at timestamp [not null]
  
  Note: "PII 영역 (users/{accountId}/profile) - 프로필 + 설정 + 온보딩 + 목표"
}

// ==================== 3. TIME SERIES DATA LAYER (시계열 데이터) ====================

Table time_series_data_points {
  id uuid [pk, note: "Firestore Doc ID"]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  timestamp timestamp [not null]
  date date [not null]
  
  values string [not null, note: "JSON: {mood: {type: double, value: 75}, stress: {...}}"]
  notes string [null, note: "메모, 최대 1000자"]
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
  }
  
  Note: "익명화 영역 (anonymous_users/{anonymousUserId}/data_points/*) - HomeView 입력 데이터"
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
  }
  
  Note: "익명화 영역 - ML 특징 벡터"
}

Table ml_model_outputs {
  id uuid [pk, note: "Firestore Doc ID"]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  ml_feature_vector_id uuid [not null, ref: > ml_feature_vectors.id]
  model_version string [not null]
  
  reconstruction_performance double [not null, note: "0.0 ~ 1.0"]
  prediction_accuracy double [not null, note: "0.0 ~ 1.0"]
  
  predictions string [not null, note: "JSON: predicted values"]
  anomaly_scores string [not null, note: "JSON: anomaly detection scores"]
  
  executed_at timestamp [not null]
  
  Indexes {
    (anonymous_user_id)
  }
  
  Note: "익명화 영역 - ML 모델 결과 (InsightsView용)"
}

// ==================== 4. AGGREGATION LAYER (집계 데이터) ====================

Table daily_gems {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, ref: > user_accounts.id]
  date date [not null]
  
  gem_type string [not null, note: "standard|rare|epic|legendary"]
  brightness double [not null, note: "0.0 ~ 1.0"]
  uncertainty double [not null, note: "0.0 ~ 1.0"]
  color_theme string [not null, note: "JSON: {primary: #RRGGBB, secondary: #RRGGBB}"]
  
  data_point_ids string [not null, note: "JSON array: related TimeSeriesDataPoint IDs"]
  
  created_at timestamp [not null]
  
  Indexes {
    (account_id, date) [type: composite]
  }
  
  Note: "PII 영역 (users/{accountId}/daily_gems/*) - account_id만 포함, HomeView GemDetailView + RailroadView 데이터"
}

Table period_reports {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, ref: > user_accounts.id]
  
  period_type string [not null, note: "weekly|monthly|quarterly|semi_annual|yearly"]
  period_start_date date [not null]
  period_end_date date [not null]
  
  summary_metrics string [not null, note: "JSON: aggregated statistics"]
  insight_ids string [not null, note: "JSON array: related insight IDs"]
  
  created_at timestamp [not null]
  
  Indexes {
    (account_id, period_type, period_start_date) [type: composite]
  }
  
  Note: "PII 영역 (users/{accountId}/period_reports/*) - account_id만 포함, HomeView RailroadView 기간별 리포트"
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
  
  Note: "익명화 영역 - InsightsView Analysis + StatusView 값 분석용"
}

Table orb_visualizations {
  id uuid [pk, note: "Firestore Doc ID"]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  ml_model_output_id uuid [not null, ref: > ml_model_outputs.id]
  insight_id uuid [not null, ref: > insights.id]
  
  brightness double [not null, note: "0.0 ~ 1.0, 재생성 성능"]
  border_brightness double [not null, note: "0.0 ~ 1.0, 예측 정확도"]
  color_gradient string [not null, note: "JSON array: 3 colors"]
  
  data_point_ids string [not null, note: "JSON array: related TimeSeriesDataPoint IDs"]
  unique_features string [not null, note: "JSON array: top 3 features"]
  
  created_at timestamp [not null]
  
  Indexes {
    (anonymous_user_id)
  }
  
  Note: "익명화 영역 - InsightsView OrbViz 시각화"
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
  
  Note: "익명화 영역 - InsightsView StoryView 카드뉴스 형식"
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
  
  Note: "익명화 영역 - InsightsView Dashboard 예측 데이터"
}

// ==================== 6. GOAL & PROGRAM LAYER (목표 & 프로그램) ====================

// Table goals {
// Dropped: Merged into user_profiles as simple JSON array for MVP
// }

Table programs {
  id uuid [pk, note: "Firestore Doc ID"]
  
  title string [not null]
  description string [not null]
  category string [not null, note: "mind|behavior|physical"]
  
  duration_weeks integer [not null]
  difficulty string [not null, note: "easy|medium|hard"]
  
  illustration_3d_url string [not null]
  popularity double [not null, note: "0.0 ~ 1.0"]
  rating double [not null, note: "1.0 ~ 5.0"]
  review_count integer [not null]
  
  created_at timestamp [not null]
  
  Indexes {
    (category)
    (popularity)
  }
  
  Note: "글로벌 영역 - GoalView + HomeView에서 프로그램 선택"
}

Table program_missions {
  id uuid [pk, note: "Firestore Doc ID"]
  program_id uuid [not null, ref: > programs.id]
  
  day integer [not null]
  title string [not null] 
  description string [not null]
  estimated_duration integer [null, note: "minutes"]
  type string [null, note: "mindfulness|journaling|physical|mixed"]
  
  content_pages string [not null, note: "JSON array: Rich content pages (ProgramStoryPage format)"]
  
  created_at timestamp [not null]
  
  Indexes {
    (program_id, day) [type: composite]
  }
  
  Note: "글로벌 영역 - programs/{programId}/missions/* (Sub-collection)"
}

Table user_program_enrollments {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, ref: > user_accounts.id]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  program_id uuid [not null, ref: > programs.id]
  
  enrollment_status string [not null, note: "active|completed|paused|abandoned"]
  start_date date [not null]
  target_completion_date date [null]
  actual_completion_date date [null]
  
  initial_metrics string [not null, note: "JSON: 프로그램 시작 시 초기값"]
  success_progress double [not null, note: "0.0 ~ 1.0 - Cloud Functions 계산"]
  success_rate double [null, note: "0.0 ~ 1.0 - 완료 후 계산"]
  
  created_at timestamp [not null]
  updated_at timestamp [not null]
  
  Indexes {
    (account_id, enrollment_status) [type: composite]
    (program_id, enrollment_status) [type: composite]
  }
  
  Note: "PII 영역 - GoalView 프로그램 진행도 추적"
}

Table program_specific_data_points {
  id uuid [pk, note: "Firestore Doc ID"]
  anonymous_user_id uuid [not null, ref: > anonymous_user_identities.id]
  user_program_enrollment_id uuid [not null, ref: > user_program_enrollments.id]
  
  timestamp timestamp [not null]
  date date [not null]
  
  values string [not null, note: "JSON: {program_metric_1: {...}, ...}"]
  notes string [null]
  
  confidence double [not null, note: "0.0 ~ 1.0"]
  completeness double [not null, note: "0.0 ~ 1.0"]
  
  created_at timestamp [not null]
  updated_at timestamp [not null]
  
  Indexes {
    (user_program_enrollment_id, date) [type: composite]
  }
  
  Note: "익명화 영역 - GoalView 프로그램 특화 데이터"
}

Table program_success_metrics {
  id uuid [pk, note: "Firestore Doc ID"]
  program_id uuid [not null, ref: > programs.id]
  
  metric_name string [not null, note: "프로그램별 성공 지표"]
  target_value double [not null]
  metric_type string [not null, note: "improvement|threshold"]
  weight double [not null]
  
  description string [not null]
  created_at timestamp [not null]
  
  Indexes {
    (program_id)
  }
  
  Note: "글로벌 영역 - GoalView 성공률 계산용"
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
  
  Note: "PII 영역 - StatusView ProfileHeader 통계"
}

Table badges {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, ref: > user_accounts.id]
  
  name string [not null]
  description string [not null]
  badge_type string [not null, note: "program_completion|milestone|streak|hidden_condition"]
  
  illustration_3d_url string [not null]
  color_scheme string [not null, note: "JSON: {primary: #RRGGBB, secondary: #RRGGBB}"]
  
  condition string [not null]
  unlock_rule string [not null, note: "JSON: unlock 규칙"]
  
  unlocked_at timestamp [null]
  
  Indexes {
    (account_id, badge_type) [type: composite]
  }
  
  Note: "PII 영역 - StatusView Achievements 배지"
}

Table value_analysis {
  id uuid [pk, note: "Firestore Doc ID"]
  account_id uuid [not null, ref: > user_accounts.id]
  
  value_name string [not null]
  value_score double [not null, note: "0.0 ~ 1.0"]
  supporting_data_points integer [not null]
  
  analyzed_at timestamp [not null]
  
  Indexes {
    (account_id, value_name) [type: composite]
  }
  
  Note: "PII 영역 - StatusView Values 월간 값 분석"
}

// ==================== 8. NOTES ====================

// Minimal Schema (21 tables, -15 from v2.0)
// Removed: daily_stats, goal_progress, goal_recommendations, trend_data, program_reviews,
//          data_type_schemas, consent_records, data_deletion_requests, 
//          onboarding_states, user_data_collection_settings

// Cloud Functions Automation (5 tasks)
// 1. Daily Aggregation (00:00 KST): TimeSeriesDataPoint → DailyGems + PeriodReports
// 2. Program Monitoring (01:00 KST): ProgramSpecificDataPoints → success_progress
// 3. Weekly ML (Sunday 10:00 KST): TimeSeriesDataPoint → MLModelOutput → Insights
// 4. Monthly Value Analysis (1st, 03:00 KST): TimeSeriesDataPoint → ValueAnalysis + feature_color
// 5. Period Consolidation (Daily 02:00 KST): Milestone-based auto-consolidation

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

// Data Retention
// - TimeSeriesDataPoint: 2 years (configurable)
// - DailyGem: Permanent (user's PII)
// - Insights, OrbVisualization: 1 year after generation
// - MLTrainingDataset: Per user consent (usually 30 days)

// Security Rules Key Principles
// 1. PII segregation: users/* requires auth + accountId match
// 2. Anonymity: anonymous_users/* has no link to PII
// 3. IdentityMapping: Read-only for app, write-only for Cloud Functions
// 4. GDPR: Cleanup handled by application-level policies