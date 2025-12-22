//
//  RadarChartView.swift
//  PIP_Project
//
//  Created by Gemini on 2025/12/22.
//

import SwiftUI

// MARK: - Main Radar Chart View
struct RadarChartView: View {
    let dataSet: RadarChartDataSet
    let gridColor: Color = Color.white.opacity(0.4)
    let labelColor: Color = .white
    let levels: Int = 4 // 격자선 개수 (예: 25%, 50%, 75%, 100%)

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            // 그래프 크기를 조금 더 줄여서 점수와 겹치지 않도록 조정
            let radius = (size / 2) * 0.60 

            ZStack {
                // 1. 격자 및 축선 그리기
                RadarChartGrid(
                    levels: levels,
                    dataCount: dataSet.data.count
                )
                .stroke(gridColor, lineWidth: 0.5)
                .frame(width: radius * 2, height: radius * 2)
                .position(center)

                // 2. 데이터 경로 그리기
                RadarChartPath(data: dataSet.data.map { $0.value })
                    .fill(dataSet.dataColor.opacity(0.4))
                    .overlay(
                        RadarChartPath(data: dataSet.data.map { $0.value })
                            .stroke(dataSet.dataColor, lineWidth: 2)
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                // 3. 축 아이콘 및 데이터 값 표시
                ForEach(dataSet.data.indices, id: \.self) { index in
                    let item = dataSet.data[index]
                    let angle = angleFor(index: index, dataCount: dataSet.data.count)
                    
                    // 아이콘 위치: 차트 바깥쪽으로 더 넘겨서 배치
                    let iconRadius = radius + 35
                    let iconPoint = pointFor(angle: angle, radius: iconRadius, center: center)
                    
                    // 값 레이블 위치: 데이터 꼭지점 약간 바깥쪽. 아이콘과 겹치지 않도록 조정.
                    let valuePointRadius = radius * item.value
                    let valueLabelRadius = valuePointRadius + (item.value > 0.9 ? 10 : 18) // 값이 높을 때 덜 띄움
                    let valuePoint = pointFor(angle: angle, radius: valueLabelRadius, center: center)

                    // 축 아이콘 표시 (크기를 36x36으로 증가)
                    Image(item.iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .position(iconPoint)

                    // 데이터 값 레이블 표시
                    Text(item.displayValue)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.7), radius: 2, y: 1)
                        .position(valuePoint)
                }
            }
        }
    }
    
    /// 주어진 인덱스에 대한 각도를 계산합니다 (라디안).
    private func angleFor(index: Int, dataCount: Int) -> CGFloat {
        return CGFloat(index) * (2 * .pi) / CGFloat(dataCount) - .pi / 2
    }
    
    /// 주어진 각도와 반지름에 대한 좌표를 계산합니다.
    private func pointFor(angle: CGFloat, radius: CGFloat, center: CGPoint) -> CGPoint {
        return CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }
}

// MARK: - Radar Chart Grid Shape
private struct RadarChartGrid: Shape {
    let levels: Int
    let dataCount: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = rect.width / 2
        
        guard dataCount > 0 else { return path }

        // 1. 동심원 격자 (다각형) 그리기
        for level in 1...levels {
            let levelRadius = radius * (CGFloat(level) / CGFloat(levels))
            var points: [CGPoint] = []
            
            for i in 0..<dataCount {
                let angle = CGFloat(i) * (2 * .pi) / CGFloat(dataCount) - .pi / 2
                let point = CGPoint(
                    x: center.x + levelRadius * cos(angle),
                    y: center.y + levelRadius * sin(angle)
                )
                points.append(point)
            }
            path.addLines(points)
            path.closeSubpath()
        }

        // 2. 중심에서 각 꼭지점으로 이어지는 축선 그리기
        for i in 0..<dataCount {
            let angle = CGFloat(i) * (2 * .pi) / CGFloat(dataCount) - .pi / 2
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            path.move(to: center)
            path.addLine(to: point)
        }

        return path
    }
}

// MARK: - Radar Chart Data Path Shape
private struct RadarChartPath: Shape {
    let data: [Double]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = rect.width / 2
        
        guard let firstPointValue = data.first, data.count > 1 else { return path }
        
        // 데이터 포인트들을 연결하는 경로 생성
        var points: [CGPoint] = []
        for (index, value) in data.enumerated() {
            let angle = CGFloat(index) * (2 * .pi) / CGFloat(data.count) - .pi / 2
            // value는 0.0 ~ 1.0 사이의 정규화된 값
            let pointRadius = radius * CGFloat(value)
            let point = CGPoint(
                x: center.x + pointRadius * cos(angle),
                y: center.y + pointRadius * sin(angle)
            )
            points.append(point)
        }
        
        path.addLines(points)
        path.closeSubpath()

        return path
    }
}


// MARK: - Preview
#if DEBUG
struct RadarChartView_Previews: PreviewProvider {
    static var mindData: RadarChartDataSet {
        let dataItems = [
            RadarChartDataItem(iconName: "insight_mood", value: 0.8, displayValue: "80"),
            RadarChartDataItem(iconName: "insight_stress", value: 0.4, displayValue: "40"),
            RadarChartDataItem(iconName: "insight_energy", value: 0.9, displayValue: "90"),
            RadarChartDataItem(iconName: "insight_focus", value: 0.7, displayValue: "70")
        ]
        return RadarChartDataSet(title: "Mind", data: dataItems, dataColor: .cyan)
    }
    
    static var behaviorData: RadarChartDataSet {
        let dataItems = [
            RadarChartDataItem(iconName: "insight_productivity", value: 0.9, displayValue: "90"),
            RadarChartDataItem(iconName: "insight_social", value: 0.6, displayValue: "60"),
            RadarChartDataItem(iconName: "insight_distraction", value: 0.3, displayValue: "30"),
            RadarChartDataItem(iconName: "insight_exploration", value: 0.5, displayValue: "50")
        ]
        return RadarChartDataSet(title: "Behavior", data: dataItems, dataColor: .orange)
    }

    static var bodyData: RadarChartDataSet {
        let dataItems = [
            RadarChartDataItem(iconName: "insight_sleep", value: 0.9, displayValue: "90"),
            RadarChartDataItem(iconName: "insight_fatigue", value: 0.5, displayValue: "50"),
            RadarChartDataItem(iconName: "insight_activity", value: 0.8, displayValue: "80"),
            RadarChartDataItem(iconName: "insight_nutrition", value: 0.6, displayValue: "60")
        ]
        return RadarChartDataSet(title: "Body", data: dataItems, dataColor: .green)
    }
    
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 40) {
                RadarChartView(dataSet: mindData)
                    .frame(width: 300, height: 300)
                
                RadarChartView(dataSet: behaviorData)
                    .frame(width: 200, height: 200)
            }
        }
    }
}
#endif
