//
//  DataSchemaModels.swift
//  PIP_Project
//
//  Data Schema Registry: 동적 데이터 타입 정의
//  확장 가능한 데이터 수집 구조
//

import Foundation

// MARK: - Data Type Schema
/// 데이터 타입을 동적으로 정의하는 메타데이터 구조
/// Firestore의 data_type_schemas/{schemaId}에 저장
struct DataTypeSchema: Identifiable, Codable {
    let id: UUID
    var name: String                    // "mood", "sleep_score", "productivity" 등
    var displayName: String             // "기분", "수면 점수", "생산성" 등
    var category: DataCategory
    var dataType: DataValueType
    var unit: String?                   // "점", "시간", "분" 등
    var range: ValueRange?
    var sensitivity: SensitivityLevel
    var collectionMethod: CollectionMethod
    var isRequired: Bool                // 필수 데이터인지
    var isEnabled: Bool                 // 기본 활성화 여부
    var description: String?
    var createdAt: Date
    var updatedAt: Date
    
    var schemaIdString: String {
        id.uuidString
    }
}

enum DataCategory: String, Codable {
    case dailyLog   // 일일 기록 (통합)
    case mind       // 마음
    case behavior   // 행동
    case physical   // 신체
    case social     // 사회적
    case cognitive  // 인지
    case custom     // 커스텀
}

enum DataValueType: String, Codable {
    case integer
    case double
    case boolean
    case string
    case timestamp
    case array
    case object
}

enum SensitivityLevel: String, Codable {
    case low        // 낮음 (공개 가능)
    case medium     // 중간 (익명화 가능)
    case high       // 높음 (암호화 필요)
    case critical   // 매우 높음 (로컬만 저장)
}

enum CollectionMethod: String, Codable {
    case manual         // 수동 입력
    case screenTime     // 스크린타임 연동
    case healthKit      // HealthKit 연동
    case location       // 위치 기반
    case inferred       // AI 추론
    case thirdParty     // 서드파티 연동
}

struct ValueRange: Codable {
    var min: Double?
    var max: Double?
    var step: Double?
}

// MARK: - Data Value
/// 동적 데이터 값 타입
/// Firestore에서 Map으로 저장됨
enum DataValue: Codable {
    case integer(Int)
    case double(Double)
    case boolean(Bool)
    case string(String)
    case array([DataValue])
    case object([String: DataValue])
    
    // ML 모델 입력으로 변환
    func toMLFeature() -> Double? {
        switch self {
        case .integer(let value):
            return Double(value) / 100.0
        case .double(let value):
            return value
        case .boolean(let value):
            return value ? 1.0 : 0.0
        default:
            return nil
        }
    }
    
    // Firestore 호환 인코딩
    enum CodingKeys: String, CodingKey {
        case type, value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "integer":
            let value = try container.decode(Int.self, forKey: .value)
            self = .integer(value)
        case "double":
            let value = try container.decode(Double.self, forKey: .value)
            self = .double(value)
        case "boolean":
            let value = try container.decode(Bool.self, forKey: .value)
            self = .boolean(value)
        case "string":
            let value = try container.decode(String.self, forKey: .value)
            self = .string(value)
        case "array":
            let value = try container.decode([DataValue].self, forKey: .value)
            self = .array(value)
        case "object":
            let value = try container.decode([String: DataValue].self, forKey: .value)
            self = .object(value)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .integer(let value):
            try container.encode("integer", forKey: .type)
            try container.encode(value, forKey: .value)
        case .double(let value):
            try container.encode("double", forKey: .type)
            try container.encode(value, forKey: .value)
        case .boolean(let value):
            try container.encode("boolean", forKey: .type)
            try container.encode(value, forKey: .value)
        case .string(let value):
            try container.encode("string", forKey: .type)
            try container.encode(value, forKey: .value)
        case .array(let value):
            try container.encode("array", forKey: .type)
            try container.encode(value, forKey: .value)
        case .object(let value):
            try container.encode("object", forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}

// MARK: - Data Source
enum DataSource: String, Codable {
    case manual       // 사용자 수동 입력
    case screenTime   // 스크린타임 연동
    case healthKit    // HealthKit 연동
    case inferred     // AI 추론
    case thirdParty   // 서드파티 연동
}
