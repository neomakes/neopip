//
//  GemDetailView.swift
//  PIP_Project
//
//  Gem 상세 정보 및 해당 날짜의 데이터 포인트 표시
//

import SwiftUI
import Combine

// MARK: - Helper Function
/// 카테고리 표시 이름을 반환하는 공통 헬퍼 함수
private func categoryDisplayName(_ category: DataCategory) -> String {
    switch category {
    case .mind: return "Mind"
    case .behavior: return "Behavior"
    case .physical: return "Physical"
    case .social: return "Social"
    case .cognitive: return "Cognitive"
    case .custom: return "Other"
    }
}

struct GemDetailView: View {
    let gem: DailyGem
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var dataPoints: [TimeSeriesDataPoint] = []
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Gem 시각화
                    VStack(spacing: 16) {
                        GemView(gem: gem, size: 150)
                        
                        Text(formatDate(gem.date))
                            .font(.pip.title1)
                            .foregroundColor(.white)
                        
                        // Gem info
                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Text("Brightness")
                                    .font(.pip.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Text("\(Int(gem.brightness * 100))%")
                                    .font(.pip.title2)
                                    .foregroundColor(.pip.home.numRecords)
                            }
                            
                            VStack(spacing: 4) {
                                Text("Uncertainty")
                                    .font(.pip.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Text("\(Int(gem.uncertainty * 100))%")
                                    .font(.pip.title2)
                                    .foregroundColor(.pip.home.numStreaks)
                            }
                            
                            VStack(spacing: 4) {
                                Text("Data Count")
                                    .font(.pip.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Text("\(dataPoints.count)")
                                    .font(.pip.title2)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )
                    }
                    .padding(.top, 40)
                    
                    // 데이터 포인트 목록 (카테고리별로 그룹화)
                    if !dataPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Recorded Data")
                                .font(.pip.title2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            // Group by category
                            let groupedDataPoints = groupDataPointsByCategory(dataPoints)
                            
                            ForEach(Array(groupedDataPoints.keys.sorted(by: { categoryOrder($0) < categoryOrder($1) })), id: \.self) { category in
                                if let points = groupedDataPoints[category], !points.isEmpty {
                                    CategorySection(category: category, dataPoints: points)
                                }
                            }
                        }
                    } else if !isLoading {
                        VStack(spacing: 12) {
                            Text("No data recorded for this date")
                                .font(.pip.body)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding()
                    }
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                    }
                }
                .padding(.bottom, 100)
            }
            
            // Close button (Liquid Glass)
            VStack {
                HStack {
                    Spacer()
                    LiquidGlassButton(
                        systemIcon: "xmark",
                        size: 44,
                        isCircle: true
                    ) {
                        dismiss()
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onAppear {
            loadDataPoints()
        }
    }
    
    private func loadDataPoints() {
        isLoading = true
        var cancellable: AnyCancellable?
        cancellable = viewModel.fetchDataPoints(for: gem.date)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [self] completion in
                    isLoading = false
                    cancellable?.cancel()
                    if case .failure(let error) = completion {
                        print("Error loading data points: \(error)")
                    }
                },
                receiveValue: { [self] points in
                    dataPoints = points.sorted { $0.timestamp > $1.timestamp }
                }
            )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
    
    /// 데이터 포인트를 카테고리별로 그룹화
    private func groupDataPointsByCategory(_ dataPoints: [TimeSeriesDataPoint]) -> [DataCategory: [TimeSeriesDataPoint]] {
        var grouped: [DataCategory: [TimeSeriesDataPoint]] = [:]
        
        for point in dataPoints {
            let category = point.category ?? .custom
            if grouped[category] == nil {
                grouped[category] = []
            }
            grouped[category]?.append(point)
        }
        
        // 각 카테고리 내에서 시간순 정렬 (최신순)
        for key in grouped.keys {
            grouped[key]?.sort { $0.timestamp > $1.timestamp }
        }
        
        return grouped
    }
    
    /// 카테고리 표시 순서
    private func categoryOrder(_ category: DataCategory) -> Int {
        switch category {
        case .mind: return 1
        case .behavior: return 2
        case .physical: return 3
        case .social: return 4
        case .cognitive: return 5
        case .custom: return 6
        }
    }
}

// MARK: - Category Section
struct CategorySection: View {
    let category: DataCategory
    let dataPoints: [TimeSeriesDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 카테고리 헤더
            HStack {
                Text(categoryDisplayName(category))
                    .font(.pip.title2)
                    .foregroundColor(.white)
                Spacer()
                Text("\(dataPoints.count) items")
                    .font(.pip.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            
            // 해당 카테고리의 데이터 포인트들
            ForEach(dataPoints) { dataPoint in
                DataPointCard(dataPoint: dataPoint, category: dataPoint.category ?? category)
            }
        }
    }
}

// MARK: - Data Point Card
struct DataPointCard: View {
    let dataPoint: TimeSeriesDataPoint
    let category: DataCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 시간
            HStack {
                Text(formatTime(dataPoint.timestamp))
                    .font(.pip.caption)
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text(categoryDisplayName(category))
                    .font(.pip.caption)
                    .foregroundColor(.pip.home.buttonAddGrad1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.pip.home.buttonAddGrad1.opacity(0.2))
                    )
            }
            
            // 데이터 값들
            if !dataPoint.values.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(dataPoint.values.keys.sorted()), id: \.self) { key in
                        if let value = dataPoint.values[key] {
                            HStack {
                                Text(key)
                                    .font(.pip.body)
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text(formatValue(value))
                                    .font(.pip.title2)
                                    .foregroundColor(.pip.home.numRecords)
                            }
                        }
                    }
                }
            }
            
            // 메모
            if let notes = dataPoint.notes, !notes.isEmpty {
                Text(notes)
                    .font(.pip.body)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatValue(_ value: DataValue) -> String {
        switch value {
        case .double(let val):
            return String(format: "%.0f", val)
        case .integer(let val):
            return "\(val)"
        case .boolean(let val):
            return val ? "Yes" : "No"
        case .string(let val):
            return val
        case .array(let arr):
            return "[\(arr.count) items]"
        case .object(let obj):
            return "{\(obj.count) fields}"
        }
    }
}

#Preview {
    GemDetailView(
        gem: DailyGem(
            id: UUID(),
            accountId: UUID(),
            date: Date(),
            gemType: .sphere,
            brightness: 0.8,
            uncertainty: 0.2,
            dataPointIds: [],
            colorTheme: .teal,
            createdAt: Date()
        ),
        viewModel: HomeViewModel()
    )
}
