import SwiftUI

struct InsightCard: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let trend: Trend
    let description: String
    let details: [String]
    let relatedNoteIds: [UUID]
    
    enum Trend {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.circle.fill"
            case .down: return "arrow.down.circle.fill"
            case .neutral: return "equal.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .blue
            }
        }
    }
    
    init(
        title: String,
        value: String,
        trend: Trend,
        description: String,
        details: [String] = [],
        relatedNoteIds: [UUID] = []
    ) {
        self.title = title
        self.value = value
        self.trend = trend
        self.description = description
        self.details = details
        self.relatedNoteIds = relatedNoteIds
    }
}

struct AnalyticsPeriod {
    let startDate: Date
    let endDate: Date
    let interval: TimeInterval
    
    static func from(_ timeRange: AnalyticsView.TimeRange) -> AnalyticsPeriod {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeRange {
        case .day:
            return AnalyticsPeriod(
                startDate: calendar.date(byAdding: .day, value: -1, to: now)!,
                endDate: now,
                interval: 3600 // 1 hour
            )
        case .week:
            return AnalyticsPeriod(
                startDate: calendar.date(byAdding: .day, value: -7, to: now)!,
                endDate: now,
                interval: 3600 * 6 // 6 hours
            )
        case .month:
            return AnalyticsPeriod(
                startDate: calendar.date(byAdding: .month, value: -1, to: now)!,
                endDate: now,
                interval: 3600 * 24 // 1 day
            )
        case .year:
            return AnalyticsPeriod(
                startDate: calendar.date(byAdding: .year, value: -1, to: now)!,
                endDate: now,
                interval: 3600 * 24 * 7 // 1 week
            )
        }
    }
}

struct AnalyticsDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String?
    
    init(date: Date, value: Double, label: String? = nil) {
        self.date = date
        self.value = value
        self.label = label
    }
}

struct AnalyticsSummary {
    let average: Double
    let minimum: Double
    let maximum: Double
    let trend: InsightCard.Trend
    let trendPercentage: Double
    
    var formattedTrend: String {
        let sign = trend == .up ? "+" : (trend == .down ? "-" : "")
        return "\(sign)\(String(format: "%.1f", abs(trendPercentage)))%"
    }
} 