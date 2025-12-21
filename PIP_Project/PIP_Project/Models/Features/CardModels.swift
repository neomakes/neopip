//
//  CardModels.swift
//  PIP_Project
//
//  WriteSheet에서 사용하는 카드 데이터 모델
//

import Foundation

// MARK: - Card Data
/// 데이터 입력 카드 정보
struct CardData: Identifiable {
    let id: UUID
    var type: CardType
    var title: String
    var inputs: [CardInput]
    var textInput: TextInput?
    
    init(id: UUID = UUID(), type: CardType, title: String, inputs: [CardInput], textInput: TextInput? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.inputs = inputs
        self.textInput = textInput
    }
}

enum CardType: String {
    case mind       // 마음
    case behavior   // 행동
    case physical   // 신체
    case program    // 프로그램
}

// MARK: - Card Input
/// 카드 내 입력 필드
enum CardInput {
    case slider(key: String, label: String, range: ClosedRange<Double>, value: Double = 50.0)
    case toggle(key: String, label: String, value: Bool = false)
    case picker(key: String, label: String, options: [String], selectedIndex: Int = 0)
}

// MARK: - Text Input
/// 텍스트 입력 필드
enum TextInput {
    case required(key: String, placeholder: String)
    case optional(key: String, placeholder: String)
}
