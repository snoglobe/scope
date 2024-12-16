import SwiftUI
import Charts

struct HealthSummarySection: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    let timeRange: AnalyticsView.TimeRange
    @State private var healthData: [HealthNote.HealthKitDataPoint] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if healthData.isEmpty {
                NoDataView(message: "No health data available", icon: "heart.text.square")
            } else {
                ForEach(Dictionary(grouping: healthData) { $0.type }.sorted(by: { $0.key < $1.key }), id: \.key) { type, points in
                    let average = points.map { $0.value }.reduce(0, +) / Double(points.count)
                    HStack {
                        Text(type.replacingOccurrences(of: "HKQuantityTypeIdentifier", with: ""))
                            .font(.subheadline)
                        Spacer()
                        Text("\(average, specifier: "%.1f") \(points[0].unit)")
                            .font(.headline)
                            .foregroundColor(Theme.primary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .onAppear {
            healthKitManager.fetchRecentData { data in
                healthData = data
            }
        }
    }
}

struct QuickLogSummarySection: View {
    @EnvironmentObject var dataManager: HealthDataManager
    let timeRange: AnalyticsView.TimeRange
    
    var quickLogData: [(String, Double)] {
        let notes = getNotesInRange(timeRange)
        let allQuickLogs = notes.flatMap { $0.quickLogData }
        let groupedByType = Dictionary(grouping: allQuickLogs) { $0.type }
        
        return groupedByType.map { type, entries in
            let average = entries.map { $0.value }.reduce(0, +) / Double(entries.count)
            return (type, average)
        }.sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if quickLogData.isEmpty {
                NoDataView(message: "No quick log data available", icon: "list.bullet")
            } else {
                ForEach(quickLogData, id: \.0) { type, average in
                    HStack {
                        Text(type)
                            .font(.subheadline)
                        Spacer()
                        Text("\(average, specifier: "%.1f")")
                            .font(.headline)
                            .foregroundColor(Theme.primary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

struct TagAnalysisSection: View {
    @EnvironmentObject var dataManager: HealthDataManager
    let timeRange: AnalyticsView.TimeRange
    
    var tagFrequency: [(String, Int)] {
        let notes = getNotesInRange(timeRange)
        let allTags = notes.flatMap { Array($0.tags) }
        let frequency = Dictionary(grouping: allTags) { $0 }.mapValues { $0.count }
        return frequency.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if tagFrequency.isEmpty {
                NoDataView(message: "No tags available", icon: "tag")
            } else {
                ForEach(tagFrequency, id: \.0) { tag, count in
                    HStack {
                        Text(tag)
                            .font(.subheadline)
                        Spacer()
                        Text("\(count) times")
                            .font(.headline)
                            .foregroundColor(Theme.primary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
