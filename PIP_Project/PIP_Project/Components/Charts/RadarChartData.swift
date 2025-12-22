//
//  RadarChartData.swift
//  PIP_Project
//
//  Created by Gemini on 2025/12/22.
//

import Foundation
import SwiftUI

/// Radar Chart의 한 축을 나타내는 데이터 항목입니다.
struct RadarChartDataItem: Identifiable {
    let id = UUID()
    /// 축에 표시될 아이콘의 이름 (예: "mood", "energy")
    let iconName: String
    /// 정규화된 값 (0.0 ~ 1.0)
    let value: Double
    /// 차트에 표시될 실제 점수 문자열 (예: "80")
    let displayValue: String
}

/// 전체 Radar Chart를 렌더링하기 위한 데이터 세트입니다.
struct RadarChartDataSet {
    /// 차트 제목 (예: "Mind", "Behavior")
    let title: String
    /// 차트에 표시될 데이터 항목의 배열
    let data: [RadarChartDataItem]
    /// 차트의 데이터 영역 색상
    let dataColor: Color
}
