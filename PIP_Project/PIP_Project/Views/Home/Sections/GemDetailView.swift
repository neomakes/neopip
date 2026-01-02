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
    @State private var dailyNote: String?
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

                    // 하단: 저널 텍스트
                    if let note = dailyNote, !note.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Journal")
                                .font(.pip.title2)
                                .foregroundColor(.white)
                            
                            ScrollView(.vertical, showsIndicators: true) {
                                Text(note)
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

        // Radar Chart 데이터 로드
        viewModel.createRadarChartDataSets(for: gemRecord.date) { result in
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

        // 저널 노트 로드 (TimeSeriesDataPoint에서)
        viewModel.fetchDataPoints(for: gemRecord.date)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { dataPoints in
                    self.dailyNote = dataPoints.first?.notes
                }
            )
            .store(in: &viewModel.cancellables)
    }

    // MARK: - Helper Functions
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
