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
    /// Optional binding to directly present the Write overlay from this view (preferred)
    let showWriteBinding: Binding<Bool>? = nil
    
    @State private var scrollViewHeight: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 배경: 사다리꼴 (상단: 검은색 → 하단: railroad_front)
            TrapezoidShape()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.28),
                            Color("railroad_front").opacity(0.95)
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
                            showWriteBinding: showWriteBinding,
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
    let showWriteBinding: Binding<Bool>?
    let scrollViewHeight: CGFloat
    let index: Int  // 젬의 인덱스 (0 = 과거, 6 = Today)
    let totalCount: Int  // 전체 젬 개수
    
    var body: some View {
        GeometryReader { geometry in
            let yPosition = geometry.frame(in: .global).midY
            let normalizedY = yPosition / max(1, scrollViewHeight)  // 0~1 사이 값
            // Opacity pipeline: raw -> completion factor -> top fade -> bottom fade
            let rawOpacity = gemRecord.opacity * perspectiveOpacity(for: normalizedY)
            let completionFactor = gemRecord.isCompleted ? 1.0 : 0.8
            // Fade near top when gems move away; 0..start -> 0..1 -> pow to increase steepness
            let topFade = topFadeMultiplier(for: normalizedY, start: 0.12, exponent: 2.5)
            // Exponential fade near the bottom: multiplier goes from 1 -> 0 as y -> bottom
            let endFade = endFadeMultiplier(for: normalizedY, start: 0.88, exponent: 3.0)
            // Ensure full opacity between mid-screen and before bottom fade start
            // Move the top boundary slightly upward so the fully opaque zone starts higher
            let midScreenStart: CGFloat = 0.30
            let midScreenEnd: CGFloat = 0.88
            // If this is today's gem and not completed, force it to be significantly transparent
            let isTodayEmpty = (index == totalCount - 1 && !gemRecord.isCompleted)
            let finalOpacity: Double = {
                if isTodayEmpty {
                    // Today's empty gem should always be visible at minimum opacity
                    // Don't apply endFade - today's gem is at the bottom and endFade would make it invisible
                    let emptyBase: Double = 0.22
                    return min(1.0, emptyBase * Double(topFade))
                }
                if normalizedY >= midScreenStart && normalizedY <= midScreenEnd {
                    // Fully opaque in the mid region (respect completion factor)
                    return min(1.0, Double(completionFactor))
                } else {
                    return min(1.0, Double(rawOpacity * completionFactor * topFade * endFade))
                }
            }()
            
            ZStack {
                // 타원형 그림자 (모든 젬 하단) - 크기 변화 적용 ✨
                ZStack {
                    Ellipse()
                        .fill(radialGradient(for: gemRecord, index: index, totalCount: totalCount))
                        .frame(width: 90, height: 30)  // 기존 120x40에서 90x30으로 축소
                }
                .scaleEffect(perspectiveScale(for: normalizedY))  // 위치에 따라 크기 변화 적용 ✨
                .offset(y: 30)  // 기존 40에서 30으로 조정
                .opacity(finalOpacity)  // 젬의 투명도와 동일하게 적용
                
                VStack(spacing: 12) {
                    // 날짜 라벨 (투명도 적용)
                    Text(formatDate(gemRecord.date, isCompleted: gemRecord.isCompleted))
                        .font(.pip.body)
                        .foregroundColor(.white.opacity(0.7 * perspectiveOpacity(for: normalizedY)))  // 투명도 적용 ✨
                    
                    // Gem 이미지 (기록 상태에 따라 시각적 표시)
                    Image("gem_\(gemIndexForAsset(gemRecord.gemIndex))")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 70)  // 기존 100에서 70으로 축소
                        .scaleEffect(perspectiveScale(for: normalizedY))  // 크기 조절 적용 ✨
                        .opacity(finalOpacity)  // y 위치에 따라 투명도 조절
                    

                }
            }
            .offset(x: horizontalOffset(for: normalizedY))  // 좌우 위치 오프셋 적용 ✨
            .frame(maxWidth: .infinity)
            .onTapGesture {
                if gemRecord.isCompleted {
                    onTap?(gemRecord)
                } else {
                    // Prefer direct binding to present overlay if available
                    if let binding = showWriteBinding {
                        binding.wrappedValue = true
                    } else {
                        onWriteRequested()
                    }
                }
            }
        }
        .frame(height: 90)  // 고정 높이 (기존 120에서 90으로 축소)
    }
    
    // gem_1 ~ gem_18 순환 적용 (처음 기록된 것부터 1,2,3,...,18,1,2,... 순서)
    private func gemIndexForAsset(_ gemIndex: Int) -> Int {
        return ((gemIndex - 1) % 18) + 1  // 1~18 범위로 순환
    }
    
    // 타원형 그림자의 그라데이션
    private func radialGradient(for gemRecord: GemRecord, index: Int, totalCount: Int) -> RadialGradient {
        let centerColor: Color
        if index == totalCount - 1 && !gemRecord.isCompleted {
            centerColor = Color.white.opacity(0.15)  // 오늘 젬 비어있으면 훨씬 더 연하고 투명하게
        } else {
            centerColor = Color.black.opacity(0.45)  // 그 외 가운데 색상을 덜 어둡게
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
        // 적절한 크기 범위: 0.3배 ~ 1.5배 (기존 0.1~2.5배에서 축소)
        return 0.3 + (safeNormalizedY * 1.2)
    }
    
    private func perspectiveOpacity(for normalizedY: CGFloat) -> Double {
        // NaN이나 음수 값 방지
        let safeNormalizedY = max(0, min(1, normalizedY.isFinite ? normalizedY : 0))
        // Today(하단, normalizedY≈1)에서 완전 불투명, 위쪽으로 갈수록 투명해짐
        return Double(safeNormalizedY)
    }
}

// MARK: - Helper Functions
private func formatDate(_ date: Date, isCompleted: Bool) -> String {
    let formatter = DateFormatter()
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    if calendar.isDate(date, inSameDayAs: today) {
        // 오늘 날짜: 데이터가 있으면 "Today", 없으면 "Record Today"
        return isCompleted ? "Today" : "Record Today"
    } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today)!) {
        return "Yesterday"
    } else {
        formatter.dateFormat = "M/d (E)"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
}

/// Exponential fade multiplier applied near the bottom of the RailroadView.
/// - `normalizedY` expects a 0..1 value (0 top, 1 bottom).
/// - `start` is the normalized Y at which fading begins (default 0.88).
/// - `exponent` controls how sharply it falls off (higher → steeper).
private func endFadeMultiplier(for normalizedY: CGFloat, start: CGFloat = 0.88, exponent: Double = 3.0) -> Double {
    let safe = max(0, min(1, normalizedY.isFinite ? normalizedY : 0))
    guard safe > start else { return 1.0 }
    let t = (safe - start) / (1 - start) // 0..1 over fade region
    return 1.0 - pow(Double(t), exponent)
}

/// Fade multiplier for gems moving toward the top (normalizedY near 0).
/// Returns 1.0 when normalizedY >= start; otherwise returns pow(normalizedY/start, exponent).
private func topFadeMultiplier(for normalizedY: CGFloat, start: CGFloat = 0.12, exponent: Double = 2.5) -> Double {
    let safe = max(0, min(1, normalizedY.isFinite ? normalizedY : 0))
    guard safe < start else { return 1.0 }
    let t = safe / start // 0..1 over top fade region
    return pow(Double(t), exponent)
}

// MARK: - Preview
#Preview("With Today's Data") {
    ZStack {
        Color.black.ignoresSafeArea()

        RailroadView(
            gemRecords: (0..<7).map { i in
                GemRecord(
                    id: UUID(),
                    date: Calendar.current.date(byAdding: .day, value: -i, to: Date())!,
                    gemIndex: i + 1,
                    isCompleted: true,  // 모두 완성된 상태
                    dataPointIds: []
                )
            },
            onGemTap: { gem in
                print("Tapped gem: \(gem.date)")
            },
            onWriteRequested: {},
            currentStreak: 6
        )
    }
}

#Preview("Without Today's Data") {
    ZStack {
        Color.black.ignoresSafeArea()

        RailroadView(
            gemRecords: (0..<7).map { i in
                GemRecord(
                    id: UUID(),
                    date: Calendar.current.date(byAdding: .day, value: -i, to: Date())!,
                    gemIndex: i + 1,
                    isCompleted: i < 6,  // 오늘(i=0)만 미완성 → "Record Today" 표시됨
                    dataPointIds: []
                )
            },
            onGemTap: { gem in
                print("Tapped gem: \(gem.date)")
            },
            onWriteRequested: {},
            currentStreak: 5
        )
    }
}
