//
//  IdentityModels.swift
//  PIP_Project
//
//  Responsible AI: Identity Separation Models
//  사용자 식별자와 데이터를 분리하여 프라이버시 보호
//

import Foundation

// MARK: - User Account (PII 포함)
/// 실제 사용자 계정 정보 (PII - Personal Identifiable Information)
/// Firebase Auth와 연동, Firestore의 users/{accountId}/account에 저장
struct UserAccount: Identifiable, Codable {
    let id: String                    // Firebase Auth UID (String, not UUID)
    var email: String?
    var displayName: String?
    var createdAt: Date
    var lastLoginAt: Date
}

// MARK: - Anonymous User Identity
/// 익명화된 사용자 식별자 (분석용)
/// ML 모델 학습 시 이 ID만 사용
/// Firestore의 anonymous_users/{anonymousUserId}에 저장
struct AnonymousUserIdentity: Identifiable, Codable {
    let id: UUID
    var accountId: String?              // 암호화된 계정 ID 참조 (매핑 테이블용)
    var createdAt: Date
    
    var anonymousUserIdString: String {
        id.uuidString
    }
}

// MARK: - Identity Mapping
/// ID 매핑 테이블 (암호화, 접근 제어)
/// Firestore의 identity_mappings/{mappingId}에 저장
/// 보안 규칙으로 접근 제어 필요
struct IdentityMapping: Identifiable, Codable {
    let id: UUID
    var accountId: String              // Firebase Auth UID (String, not UUID)
    var anonymousUserId: UUID
    var encryptedKey: String          // 암호화된 매핑 키
    var createdAt: Date
    var isActive: Bool
    var deletionRequestedAt: Date?

    var anonymousUserIdString: String {
        anonymousUserId.uuidString
    }
}

// MARK: - Consent Record
/// 동의 관리 레코드
/// Firestore의 users/{accountId}/consents/{consentId}에 저장
struct ConsentRecord: Identifiable, Codable {
    let id: UUID
    var accountId: String              // Firebase Auth UID (String, not UUID)
    var consentType: ConsentType
    var purpose: ConsentPurpose
    var isGranted: Bool
    var grantedAt: Date?
    var revokedAt: Date?
    var expiresAt: Date?
    var version: String                // 동의 버전 (정책 변경 추적)
    var createdAt: Date
    var updatedAt: Date
}

enum ConsentType: String, Codable {
    case dataCollection        // 데이터 수집
    case dataProcessing        // 데이터 처리
    case mlTraining            // ML 모델 학습
    case dataSharing           // 데이터 공유 (익명화)
    case analytics             // 분석 목적
}

enum ConsentPurpose: String, Codable {
    case personalInsights      // 개인 인사이트 제공
    case modelImprovement      // 모델 개선
    case research              // 연구 목적 (익명화)
    case serviceImprovement    // 서비스 개선
}

// MARK: - User Consent Status
/// 사용자별 동의 상태
/// Firestore의 users/{accountId}/settings/consentStatus에 저장
struct UserConsentStatus: Codable {
    var accountId: String              // Firebase Auth UID (String, not UUID)
    var consents: [String: ConsentRecord]  // ConsentType.rawValue를 키로 사용
    var lastUpdatedAt: Date

    func canUseForMLTraining() -> Bool {
        guard let consent = consents[ConsentType.mlTraining.rawValue],
              consent.isGranted,
              consent.expiresAt == nil || consent.expiresAt! > Date() else {
            return false
        }
        return true
    }

    func canCollectData() -> Bool {
        guard let consent = consents[ConsentType.dataCollection.rawValue],
              consent.isGranted,
              consent.expiresAt == nil || consent.expiresAt! > Date() else {
            return false
        }
        return true
    }
}

// MARK: - Data Deletion Request
/// 데이터 삭제 요청
/// Firestore의 users/{accountId}/deletion_requests/{requestId}에 저장
struct DataDeletionRequest: Identifiable, Codable {
    let id: UUID
    var accountId: String              // Firebase Auth UID (String, not UUID)
    var requestType: DeletionType
    var requestedAt: Date
    var status: DeletionStatus
    var completedAt: Date?
    var errorMessage: String?
}

enum DeletionType: String, Codable {
    case account              // 전체 계정 삭제
    case dataOnly            // 데이터만 삭제 (계정 유지)
    case specificDataType    // 특정 데이터 타입만 삭제
    case timeRange           // 특정 기간 데이터만 삭제
}

enum DeletionStatus: String, Codable {
    case pending
    case inProgress
    case completed
    case failed
}

// MARK: - Deletion Log
/// 삭제 작업 로그
/// Firestore의 deletion_logs/{logId}에 저장
struct DeletionLog: Codable {
    var deletionId: UUID
    var accountId: String              // Firebase Auth UID (String, not UUID)
    var anonymousUserId: UUID
    var deletedDataPoints: Int
    var deletedInsights: Int
    var deletedAt: Date
    var verificationHash: String      // 삭제 검증 해시

    var anonymousUserIdString: String {
        anonymousUserId.uuidString
    }
}
