import SwiftUI
import Charts

struct MultiLineChartView: View {
    let datasets: [(String, [(Date, Double)])]
    let title: String
    let subtitle: String?
    @State private var selectedPoint: (String, Date, Double)?
    
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
            if datasets.isEmpty {
                NoDataView(message: "No data available")
            } else {
                Chart {
                    ForEach(datasets, id: \.0) { dataset in
                        ForEach(dataset.1, id: \.0) { point in
                            LineMark(
                                x: .value("Time", point.0),
                                y: .value("Value", point.1)
                            )
                            .foregroundStyle(by: .value("Dataset", dataset.0))
                            
                            if let selected = selectedPoint,
                               selected.0 == dataset.0 && selected.1 == point.0 {
                                PointMark(
                                    x: .value("Time", point.0),
                                    y: .value("Value", point.1)
                                )
                                .foregroundStyle(by: .value("Dataset", dataset.0))
                                .annotation {
                                    ChartAnnotation(date: point.0, value: point.1)
                                }
                            }
                        }
                    }
                }
                .chartStyle()
                .chartLegend(position: .bottom)
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
                                        
                                        var closestPoint: (String, Date, Double)?
                                        var minDistance = Double.infinity
                                        
                                        for (name, points) in datasets {
                                            if let (pointDate, value) = points.min(by: {
                                                abs($0.0.timeIntervalSince(date)) < abs($1.0.timeIntervalSince(date))
                                            }) {
                                                let distance = abs(pointDate.timeIntervalSince(date))
                                                if distance < minDistance {
                                                    minDistance = distance
                                                    closestPoint = (name, pointDate, value)
                                                }
                                            }
                                        }
                                        
                                        selectedPoint = closestPoint
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