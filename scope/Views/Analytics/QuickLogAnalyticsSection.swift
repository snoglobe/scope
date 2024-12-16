import SwiftUI
import Charts

struct QuickLogAnalyticsSection: View {
    @EnvironmentObject var dataManager: HealthDataManager
    let timeRange: AnalyticsView.TimeRange
    @State private var selectedType: String?
    @Environment(\.colorScheme) var colorScheme
    
    var quickLogData: [(String, [(Date, Double)])] {
        let notes = getNotesInRange(timeRange)
        let allQuickLogs = notes.flatMap { note in
            note.quickLogData.map { entry in
                (entry.type, (note.timestamp, entry.value))
            }
        }
        
        let groupedByType = Dictionary(grouping: allQuickLogs) { $0.0 }
        return groupedByType.map { type, entries in
            (type, entries.map { $0.1 }.sorted { $0.0 > $1.0 })
        }.sorted { $0.1.count > $1.1.count }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Type Selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(quickLogData, id: \.0) { type, _ in
                        Button {
                            withAnimation {
                                selectedType = selectedType == type ? nil : type
                            }
                        } label: {
                            Text(type)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedType == type ? 
                                            Theme.primary : Color(.systemGray6).opacity(0.25))
                                .foregroundColor(selectedType == type ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            if quickLogData.isEmpty {
                NoDataView(message: "No quick log data available for the selected time period")
                    // .cardStyle()
            } else {
                if let selectedType = selectedType,
                   let typeData = quickLogData.first(where: { $0.0 == selectedType }) {
                    QuickLogDetailView(type: typeData.0, data: typeData.1)
                        //.cardStyle()
                } else {
                    QuickLogOverview(data: quickLogData)
                        //.cardStyle()
                }
            }
        }
    }
}

struct QuickLogDetailView: View {
    let type: String
    let data: [(Date, Double)]
    @State private var selectedPoint: (Date, Double)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(type)
                .titleStyleLeading()
            
            Chart {
                ForEach(data, id: \.0) { date, value in
                    LineMark(
                        x: .value("Time", date),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(Theme.primary.gradient)
                    
                    if let selected = selectedPoint, selected.0 == date {
                        PointMark(
                            x: .value("Time", date),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(Theme.primary)
                        .annotation {
                            ChartAnnotation(date: date, value: value)
                        }
                    }
                }
            }
            .chartStyle()
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let x = value.location.x
                                    guard let date = proxy.value(atX: x, as: Date.self) else { return }
                                    
                                    let closest = data.min(by: {
                                        abs($0.0.timeIntervalSince(date)) < abs($1.0.timeIntervalSince(date))
                                    })
                                    selectedPoint = closest
                                }
                                .onEnded { _ in
                                    selectedPoint = nil
                                }
                        )
                }
            }
            
            // Statistics
            StatisticsGrid(stats: calculateStats())
        }
    }
    
    private func calculateStats() -> [(String, Double)] {
        let values = data.map { $0.1 }
        guard !values.isEmpty else { return [] }
        
        return [
            ("Average", values.reduce(0, +) / Double(values.count)),
            ("Minimum", values.min() ?? 0),
            ("Maximum", values.max() ?? 0)
        ]
    }
}

struct QuickLogOverview: View {
    let data: [(String, [(Date, Double)])]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Log Overview")
                .titleStyleLeading()
            
            if data.isEmpty {
                NoDataView(message: "No quick log data available")
            } else {
                Chart {
                    ForEach(data, id: \.0) { type, values in
                        ForEach(values, id: \.0) { date, value in
                            LineMark(
                                x: .value("Time", date),
                                y: .value("Value", value)
                            )
                            .foregroundStyle(by: .value("Type", type))
                        }
                    }
                }
                .chartStyle()
                .chartLegend(position: .bottom)
            }
            
            // Summary Statistics
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(data, id: \.0) { type, values in
                        let avg = values.map { $0.1 }.reduce(0, +) / Double(values.count)
                        VStack(spacing: 4) {
                            Text(type)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Text(String(format: "%.1f", avg))
                                .font(.headline)
                                .foregroundColor(Theme.primary)
                        }
                    }
                }
                .padding(.horizontal, 2)  // Reduced outer padding
            }
        }
    }
}

// Helper function to get notes within the selected time range
func getNotesInRange(_ timeRange: AnalyticsView.TimeRange) -> [HealthNote] {
    let calendar = Calendar.current
    let now = Date()
    let startDate: Date
    
    switch timeRange {
    case .day:
        startDate = calendar.date(byAdding: .day, value: -1, to: now)!
    case .week:
        startDate = calendar.date(byAdding: .day, value: -7, to: now)!
    case .month:
        startDate = calendar.date(byAdding: .day, value: -30, to: now)!
    case .year:
        startDate = calendar.date(byAdding: .year, value: -1, to: now)!
    }
    
    return HealthDataManager().notes.filter { $0.timestamp >= startDate }
} 
