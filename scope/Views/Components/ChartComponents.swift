import SwiftUI
import Charts

struct LineChartView: View {
    let data: [(Date, Double)]
    let title: String
    let subtitle: String?
    @State private var selectedPoint: (Date, Double)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .titleStyle()
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .subtitleStyle()
                }
            }
            
            // Chart
            if data.isEmpty {
                NoDataView(message: "No data available")
            } else {
                Chart {
                    ForEach(data, id: \.0) { point in
                        LineMark(
                            x: .value("Time", point.0),
                            y: .value("Value", point.1)
                        )
                        .foregroundStyle(Theme.primary.gradient)
                        
                        if let selected = selectedPoint, selected.0 == point.0 {
                            PointMark(
                                x: .value("Time", point.0),
                                y: .value("Value", point.1)
                            )
                            .foregroundStyle(Theme.primary)
                            .annotation {
                                ChartAnnotation(date: point.0, value: point.1)
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
            }
        }
        .cardStyle()
    }
}

struct ChartAnnotation: View {
    let date: Date
    let value: Double
    
    var body: some View {
        VStack {
            Text(String(format: "%.1f", value))
                .font(.caption)
                .bold()
            Text(date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .subtitleStyle()
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct BarChartView: View {
    let data: [(String, Double)]
    let title: String
    let subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .titleStyle()
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .subtitleStyle()
                }
            }
            
            // Chart
            if data.isEmpty {
                NoDataView(message: "No data available")
            } else {
                Chart {
                    ForEach(data, id: \.0) { item in
                        BarMark(
                            x: .value("Category", item.0),
                            y: .value("Value", item.1)
                        )
                        .foregroundStyle(Theme.primary.gradient)
                    }
                }
                .chartStyle()
            }
        }
        .cardStyle()
    }
}

struct StatisticsView: View {
    let stats: [(String, String)]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(3, stats.count)), spacing: 16) {
            ForEach(stats, id: \.0) { stat in
                VStack(spacing: 4) {
                    Text(stat.0)
                        .subtitleStyle()
                    Text(stat.1)
                        .titleStyle()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
    }
} 
