import Foundation

struct JournalEntry: Identifiable {
    let id = UUID()           // 각 데이터의 고유번호
    var date: Date            // 날짜
    var title: String         // 제목
    var content: String       // 내용
    var emotionScore: Double  // 0.0 ~ 1.0 (Orb의 밝기를 결정할 데이터)
}//
//  JournalEntry.swift
//  PIP_Project
//
//  Created by NEO on 12/18/25.
//

