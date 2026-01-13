//
//  GemDetailView.swift
//  PIP_Project
//
//  Created by Gemini on 2025/12/22.
//

import SwiftUI
import Combine

struct GemDetailView: View {
    let gemRecord: GemRecord
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State Properties
    @State private var radarDataSets: [RadarChartDataSet] = []
    @State private var categoryNotes: [String: String] = [:]  // 카테고리별 노트 저장 (mind, behavior, physical)
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack {
            // 배경
            PrimaryBackground()
            
            // 컨텐츠
            VStack(spacing: 0) {
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else if let errorMessage = errorMessage {
                    Spacer()
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.white)
                        .padding()
                    Spacer()
                } else if radarDataSets.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.6))
                        Text("No data available for this date")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                } else {
                    // 상단: Gem 및 날짜
                    VStack(spacing: 16) {
                        Image("gem_\(gemRecord.gemIndex)")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .opacity(gemRecord.opacity)
                        
                        Text(formatDate(gemRecord.date))
                            .font(.pip.title1)
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 24)

                    // 중앙: Radar Chart Carousel
                    VStack(spacing: 16) {
                        if selectedTab < radarDataSets.count {
                            let dataSet = radarDataSets[selectedTab]
                            
                            VStack(spacing: CGFloat.PIPLayout.gemDetailTitleToChartSpacing) {
                                Text(dataSet.title)
                                    .font(.pip.title2)
                                    .foregroundColor(.white)
                                
                                RadarChartView(dataSet: dataSet)
                                    .frame(maxWidth: CGFloat.PIPLayout.gemDetailChartMaxWidth, maxHeight: CGFloat.PIPLayout.gemDetailChartMaxHeight)
                                    .padding(.bottom, CGFloat.PIPLayout.gemDetailChartBottomPadding)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical)
                        }
                        
                        // 네비게이션 버튼
                        HStack {
                            Button(action: {
                                withAnimation {
                                    selectedTab = (selectedTab - 1 + radarDataSets.count) % radarDataSets.count
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding()
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                ForEach(0..<radarDataSets.count, id: \.self) { index in
                                    Circle()
                                        .fill(index == selectedTab ? Color.white : Color.white.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    selectedTab = (selectedTab + 1) % radarDataSets.count
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding()
                            }
                        }
                        .padding(.horizontal, CGFloat.PIPLayout.gemDetailNavButtonPadding)
                    }
                    .frame(maxHeight: CGFloat.PIPLayout.gemDetailTabViewMaxHeight)
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.width < -50 {
                                    withAnimation {
                                        selectedTab = (selectedTab + 1) % radarDataSets.count
                                    }
                                } else if value.translation.width > 50 {
                                    withAnimation {
                                        selectedTab = (selectedTab - 1 + radarDataSets.count) % radarDataSets.count
                                    }
                                }
                            }
                    )

                    // 인디케이터와 저널 사이 spacing
                    Spacer()
                        .frame(height: CGFloat.PIPLayout.gemDetailIndicatorToJournalSpacing)

                    // 하단: 저널 텍스트 (현재 탭에 해당하는 카테고리 노트 표시)
                    if let currentNote = getCurrentTabNote(), !currentNote.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Journal")
                                .font(.pip.title2)
                                .foregroundColor(.white)

                            ScrollView(.vertical, showsIndicators: true) {
                                Text(currentNote)
                                    .font(.pip.body)
                                    .foregroundColor(Color.gemDetail.journalTextColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)
                            }
                            .scrollIndicators(.visible)
                            .scrollContentBackground(.hidden)
                        }
                        .frame(maxHeight: CGFloat.PIPLayout.gemDetailJournalMaxHeight)
                        .padding()
                        .background(Color.gemDetail.journalBoxBackground)
                        .cornerRadius(CGFloat.PIPLayout.gemDetailJournalCornerRadius)
                        .padding(.horizontal)
                    } else {
                        Spacer()
                    }
                }
            }
            .padding(.bottom, 20)

            // 닫기 버튼 (우측 상단)
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onAppear(perform: loadData)
    }

    // MARK: - Data Loading
    private func loadData() {
        isLoading = true
        errorMessage = nil

        // 날짜를 startOfDay로 정규화하여 시간대 문제 방지
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: gemRecord.date)

        // Radar Chart 데이터 로드
        viewModel.createRadarChartDataSets(for: normalizedDate) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let dataSets):
                    self.radarDataSets = dataSets
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }

        // 저널 노트 로드 (TimeSeriesDataPoint에서 카테고리별 노트 추출)
        viewModel.fetchDataPoints(for: normalizedDate)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { dataPoints in
                    guard let dataPoint = dataPoints.first else { return }
                    self.extractCategoryNotes(from: dataPoint)
                }
            )
            .store(in: &viewModel.cancellables)
    }

    // MARK: - Helper Functions

    /// 현재 선택된 탭에 해당하는 카테고리의 노트를 반환
    private func getCurrentTabNote() -> String? {
        guard selectedTab < radarDataSets.count else { return nil }
        let dataSet = radarDataSets[selectedTab]

        // RadarChartDataSet의 title을 기반으로 카테고리 키 결정
        let categoryKey: String
        switch dataSet.title.lowercased() {
        case "mind": categoryKey = "mind"
        case "behavior": categoryKey = "behavior"
        case "physical": categoryKey = "physical"
        default: categoryKey = dataSet.title.lowercased()
        }

        return categoryNotes[categoryKey]
    }

    /// DataPoint에서 카테고리별 노트를 추출하여 저장
    private func extractCategoryNotes(from dataPoint: TimeSeriesDataPoint) {
        var notes: [String: String] = [:]

        // 카테고리별로 중첩된 구조에서 notes 추출
        // 구조: { "mind": { "notes": "...", ... }, "behavior": { "notes": "...", ... } }
        let categories = ["mind", "behavior", "physical"]

        for category in categories {
            if case .object(let categoryValues) = dataPoint.values[category],
               case .string(let noteText) = categoryValues["notes"] {
                notes[category] = noteText
            }
        }

        // 레거시 호환: 전체 notes 필드가 있고 카테고리별 노트가 없는 경우
        if notes.isEmpty, let legacyNotes = dataPoint.notes, !legacyNotes.isEmpty {
            // 전체 노트를 첫 번째 탭에 표시
            notes["mind"] = legacyNotes
        }

        self.categoryNotes = notes
        print("📝 [GemDetailView] Extracted notes for categories: \(notes.keys.joined(separator: ", "))")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#if DEBUG
struct GemDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GemDetailView(
            gemRecord: GemRecord(
                id: UUID(),
                date: Date(),
                gemIndex: 0,
                isCompleted: true,
                dataPointIds: []
            ),
            viewModel: HomeViewModel()
        )
    }
}
#endif
