//
//  RailroadView.swift
//  PIP_Project
//
//  세로 스크롤 가능한 타임라인 (원근감 효과 포함)
//  과거 6일 + 오늘 = 7개의 GemRecord 표시
//

import SwiftUI

// MARK: - Trapezoid Shape (삼각형이 화면에 의해 잘린 사다리꼴)
/// apex는 상단(소실점), 밑변은 하단(사용자)
struct TrapezoidShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Apex는 화면 상단 (소실점)
        let _ = rect.midX - 50
        let _: CGFloat = 0
        
        // 화면 상단에서 삼각형이 좌우 경계와 만나는 점 (더 좁게)
        let topLeftX: CGFloat = rect.midX - 45
        let topRightX: CGFloat = rect.midX + 45
        let topY: CGFloat = 0
        
        // 화면 하단 (밑변, 1.5배 넓게)
        let bottomLeftX: CGFloat = -rect.width * 0.25  // 좌측으로 확장
        let bottomRightX = rect.width * 1.25  // 우측으로 확장
        let bottomY = rect.height
        
        // 사다리꼴 그리기
        path.move(to: CGPoint(x: topLeftX, y: topY))
        path.addLine(to: CGPoint(x: topRightX, y: topY))
        path.addLine(to: CGPoint(x: bottomRightX, y: bottomY))
        path.addLine(to: CGPoint(x: bottomLeftX, y: bottomY))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Railroad View (세로 스크롤)
struct RailroadView: View {
    let gemRecords: [GemRecord]  // 과거 6일 + 오늘 (총 7개)
    let onGemTap: ((GemRecord) -> Void)?
    let onWriteRequested: (() -> Void)
    let currentStreak: Int  // DB 설계에 따라 UserStats에서 가져온 현재 streak
    
    @State private var scrollViewHeight: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 배경: 사다리꼴 (상단: 검은색 → 하단: railroad_front)
            TrapezoidShape()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black,
                            Color("railroad_front")
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
            
            // 스크롤 가능한 Gem 컨텐츠
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 30) {
                    ForEach(gemRecords.indices, id: \.self) { index in
                        GemSlot(
                            gemRecord: gemRecords[index],
                            onTap: onGemTap,
                            onWriteRequested: onWriteRequested,
                            scrollViewHeight: scrollViewHeight,
                            index: index,  // 젬의 인덱스 전달
                            totalCount: gemRecords.count
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.bottom, 150)  // TabBar와 더 가까워지도록 패딩 감소
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                scrollViewHeight = geometry.size.height
                            }
                            .onChange(of: geometry.size.height) { newHeight in
                                scrollViewHeight = newHeight
                            }
                    }
                )
            }
            .defaultScrollAnchor(.bottom)  // 최신 gem(Today)이 하단에 위치하도록 초기화
            .mask(
                // 하단에서 fade-out 효과
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.85),
                        .init(color: .clear, location: 1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

// MARK: - Gem Slot (개별 슬롯 - 원근감 적용)
struct GemSlot: View {
    let gemRecord: GemRecord
    let onTap: ((GemRecord) -> Void)?
    let onWriteRequested: (() -> Void)
    let scrollViewHeight: CGFloat
    let index: Int  // 젬의 인덱스 (0 = 과거, 6 = Today)
    let totalCount: Int  // 전체 젬 개수
    
    var body: some View {
        GeometryReader { geometry in
            let yPosition = geometry.frame(in: .global).midY
            let normalizedY = yPosition / max(1, scrollViewHeight)  // 0~1 사이 값
            
            ZStack {
                // 타원형 그림자 (모든 젬 하단) - 크기 변화 적용 ✨
                ZStack {
                    Ellipse()
                        .fill(radialGradient(for: gemRecord, index: index, totalCount: totalCount))
                        .frame(width: 120, height: 40)
                }
                .scaleEffect(perspectiveScale(for: normalizedY))  // 위치에 따라 크기 변화 적용 ✨
                .offset(y: 40)  // 젬 이미지 아래로 더 낮게 위치
                .opacity(gemRecord.opacity * perspectiveOpacity(for: normalizedY) * (gemRecord.isCompleted ? 1 : 0.6))  // 젬의 투명도와 동일하게 적용
                
                VStack(spacing: 12) {
                    // 날짜 라벨 (투명도 적용)
                    Text(formatDate(gemRecord.date))
                        .font(.pip.body)
                        .foregroundColor(.white.opacity(0.7 * perspectiveOpacity(for: normalizedY)))  // 투명도 적용 ✨
                    
                    // Gem 이미지 (기록 상태에 따라 시각적 표시)
                    Image("gem_\(gemIndexForAsset(gemRecord.gemIndex))")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                        .scaleEffect(perspectiveScale(for: normalizedY))  // 크기 조절 적용 ✨
                        .opacity(gemRecord.opacity * perspectiveOpacity(for: normalizedY))  // y 위치에 따라 투명도 조절
                        .opacity(gemRecord.isCompleted ? 1 : 0.6)  // 기록 안 된 경우 전체 투명도 낮춤
                    
                    // 오늘 기록이 없는 경우 아래 화살표 추가
                    if index == totalCount - 1 && !gemRecord.isCompleted {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                    }
                }
            }
            .offset(x: horizontalOffset(for: normalizedY))  // 좌우 위치 오프셋 적용 ✨
            .frame(maxWidth: .infinity)
            .onTapGesture {
                if gemRecord.isCompleted {
                    onTap?(gemRecord)
                } else {
                    onWriteRequested()
                }
            }
        }
        .frame(height: 120)  // 고정 높이로 GeometryReader가 작동하도록
    }
    
    // gem_1 ~ gem_18 순환 적용 (처음 기록된 것부터 1,2,3,...,18,1,2,... 순서)
    private func gemIndexForAsset(_ gemIndex: Int) -> Int {
        return ((gemIndex - 1) % 18) + 1  // 1~18 범위로 순환
    }
    
    // 타원형 그림자의 그라데이션
    private func radialGradient(for gemRecord: GemRecord, index: Int, totalCount: Int) -> RadialGradient {
        let centerColor: Color
        if index == totalCount - 1 && !gemRecord.isCompleted {
            centerColor = .white  // 오늘 젬이 비어있는 경우 가운데 흰색
        } else {
            centerColor = .black  // 그 외 가운데 검은색
        }
        return RadialGradient(
            colors: [centerColor, Color("railroad_front")],
            center: .center,
            startRadius: 0,
            endRadius: 60
        )
    }
    
    // 좌우 위치 오프셋 계산 (오늘 젬 제외 - 오늘은 중앙 고정)
    private func horizontalOffset(for normalizedY: CGFloat) -> CGFloat {
        guard index < totalCount - 1 else { return 0 }  // Today는 중앙 고정 ✨
        
        // NaN이나 음수 값 방지
        let safeNormalizedY = max(0, min(1, normalizedY.isFinite ? normalizedY : 0))
        
        // 도형의 닮음을 고려한 좌우 퍼짐 (간격 더 벌림)
        // normalizedY가 1에 가까울수록 더 넓게 퍼짐
        let spreadFactor = safeNormalizedY * 160  // 기존 120 → 160으로 증가 ✨
        
        // 인덱스에 따라 좌우 번갈아 배치
        let direction: CGFloat = index % 2 == 1 ? 1 : -1  // 홀수: 오른쪽, 짝수: 왼쪽
        
        return direction * spreadFactor
    }
    
    // y 위치에 따른 원근감 계산: 하단(y값 큼)에 가까울수록 크고 밝음
    private func perspectiveScale(for normalizedY: CGFloat) -> CGFloat {
        // NaN이나 음수 값 방지
        let safeNormalizedY = max(0, min(1, normalizedY.isFinite ? normalizedY : 0))
        // 더 극적인 변화: 0.1배 ~ 2.5배
        return 0.1 + (safeNormalizedY * 2.4)
    }
    
    private func perspectiveOpacity(for normalizedY: CGFloat) -> Double {
        // NaN이나 음수 값 방지
        let safeNormalizedY = max(0, min(1, normalizedY.isFinite ? normalizedY : 0))
        // Today(하단, normalizedY≈1)에서 완전 불투명, 위쪽으로 갈수록 투명해짐
        return Double(safeNormalizedY)
    }
}

// MARK: - Helper Functions
private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    
    if calendar.isDate(date, inSameDayAs: today) {
        return "Today"
    } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today)!) {
        return "Yesterday"
    } else {
        formatter.dateFormat = "M/d (E)"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        RailroadView(
            gemRecords: (0..<7).map { i in
                GemRecord(
                    id: UUID(),
                    date: Calendar.current.date(byAdding: .day, value: -i, to: Date())!,
                    gemIndex: i + 1,  // 1부터 시작해서 순차적으로 증가 (1,2,3,4,5,6,7)
                    isCompleted: i < 6,  // 마지막 하나만 미완성
                    dataPointIds: []
                )
            },
            onGemTap: { gem in
                print("Tapped gem: \(gem.date)")
            },
            onWriteRequested: {},
            currentStreak: 5  // DB 설계에 따라 UserStats에서 가져온 값
        )
    }
}
