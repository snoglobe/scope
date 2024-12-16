import SwiftUI
import Charts

struct TagCloudSection: View {
    @EnvironmentObject var dataManager: HealthDataManager
    let timeRange: AnalyticsView.TimeRange
    @State private var selectedTag: String?
    @Environment(\.colorScheme) var colorScheme
    
    var tagFrequency: [(String, Int)] {
        let notes = getNotesInRange(timeRange)
        let allTags = notes.flatMap { Array($0.tags) }
        let frequency = Dictionary(grouping: allTags) { $0 }.mapValues { $0.count }
        return frequency.sorted { $0.0 < $1.0 }.sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Tag Cloud - Horizontal ScrollView
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(tagFrequency, id: \.0) { tag, count in
                        Button {
                            withAnimation {
                                selectedTag = selectedTag == tag ? nil : tag
                            }
                        } label: {
                            Text("\(tag) (\(count))")
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedTag == tag ? 
                                          Theme.primary : Color(.systemGray6))
                                .foregroundColor(selectedTag == tag ? .white : .primary)
                                .cornerRadius(8)
                        }
                        .frame(height: 32)
                        .id("\(tag)-\(count)")
                    }
                }
            }
            
            if let tag = selectedTag {
                TagAnalysis(tag: tag, timeRange: timeRange)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct TagAnalysis: View {
    @EnvironmentObject var dataManager: HealthDataManager
    let tag: String
    let timeRange: AnalyticsView.TimeRange
    
    var taggedNotes: [HealthNote] {
        getNotesInRange(timeRange).filter { $0.tags.contains(tag) }
    }
    
    var commonCorrelations: [(String, Int)] {
        let otherTags = taggedNotes.flatMap { note in
            note.tags.filter { $0 != tag }
        }
        let frequency = Dictionary(grouping: otherTags) { $0 }.mapValues { $0.count }
        return frequency.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Usage Over Time
            VStack(alignment: .leading, spacing: 8) {
                Text("Usage Frequency")
                    .titleStyle()
                
                Chart {
                    ForEach(groupByDate(), id: \.date) { data in
                        BarMark(
                            x: .value("Date", data.date),
                            y: .value("Count", data.count)
                        )
                        .foregroundStyle(Theme.primary.gradient)
                    }
                }
                .chartStyle()
            }
            
            // Common Correlations
            if !commonCorrelations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Common Correlations")
                        .titleStyle()
                    
                    ForEach(commonCorrelations, id: \.0) { tag, count in
                        HStack {
                            Text(tag)
                                .font(.subheadline)
                            Spacer()
                            Text("\(count) times")
                                .subtitleStyle()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // Quick Log Averages
            if !averageQuickLogs().isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Associated Metrics")
                        .titleStyle()
                    
                    ForEach(averageQuickLogs(), id: \.type) { data in
                        HStack {
                            Text(data.type)
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "Avg: %.1f", data.average))
                                .subtitleStyle()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .cardStyle()
    }
    
    private func groupByDate() -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: taggedNotes) { note in
            calendar.startOfDay(for: note.timestamp)
        }
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.date < $1.date }
    }
    
    private func averageQuickLogs() -> [(type: String, average: Double)] {
        let allQuickLogs = taggedNotes.flatMap { $0.quickLogData }
        let grouped = Dictionary(grouping: allQuickLogs) { $0.type }
        
        return grouped.compactMap { type, entries in
            guard !entries.isEmpty else { return nil }
            let average = entries.map { $0.value }.reduce(0, +) / Double(entries.count)
            return (type: type, average: average)
        }
    }
}
