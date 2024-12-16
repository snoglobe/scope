import SwiftUI
import Charts
import HealthKit

struct HealthKitAnalytics: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.colorScheme) var colorScheme
    let timeRange: AnalyticsView.TimeRange
    @State private var selectedMetric: HKQuantityTypeIdentifier = .heartRate
    @State private var healthData: [HealthNote.HealthKitDataPoint] = []
    
    let availableMetrics = [
        HKQuantityTypeIdentifier.heartRate,
        HKQuantityTypeIdentifier.bloodPressureSystolic,
        HKQuantityTypeIdentifier.bloodPressureDiastolic,
        HKQuantityTypeIdentifier.oxygenSaturation,
        HKQuantityTypeIdentifier.respiratoryRate
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Metric Selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableMetrics, id: \.rawValue) { metric in
                        Button {
                            withAnimation {
                                selectedMetric = metric
                            }
                        } label: {
                            Text(formatMetricName(metric))
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedMetric == metric ? 
                                          Theme.primary : Color(.systemGray6))
                                .foregroundColor(selectedMetric == metric ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Data Visualization
            if healthData.isEmpty {
                NoDataView(message: "No health data available for this time period", 
                          icon: "heart.text.square")
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    // Chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text(formatMetricName(selectedMetric))
                            .titleStyleLeading()
                        
                        Text("Last \(timeRange.rawValue)")
                            .subtitleStyleLeading()
                        
                        Chart {
                            ForEach(filterDataForMetric(selectedMetric), id: \.0) { date, value in
                                LineMark(
                                    x: .value("Time", date),
                                    y: .value("Value", value)
                                )
                                .foregroundStyle(Theme.primary.gradient)
                            }
                        }
                        .chartStyle()
                    }
                    
                    // Statistics
                    StatisticsGrid(stats: calculateStats(for: selectedMetric))
                }
            }
        }
        .onAppear {
            healthKitManager.fetchRecentData { data in
                healthData = data
            }
        }
    }
    
    private func formatMetricName(_ metric: HKQuantityTypeIdentifier) -> String {
        metric.rawValue
            .replacingOccurrences(of: "HKQuantityTypeIdentifier", with: "")
            .map { $0.isUppercase ? " \($0)" : String($0) }
            .joined()
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func filterDataForMetric(_ metric: HKQuantityTypeIdentifier) -> [(Date, Double)] {
        healthData
            .filter { $0.type == metric.rawValue }
            .map { ($0.timestamp, $0.value) }
            .sorted { $0.0 < $1.0 }
    }
    
    private func calculateStats(for metric: HKQuantityTypeIdentifier) -> [(String, Double)] {
        let values = filterDataForMetric(metric).map { $0.1 }
        guard !values.isEmpty else { return [] }
        
        return [
            ("Average", values.reduce(0, +) / Double(values.count)),
            ("Minimum", values.min() ?? 0),
            ("Maximum", values.max() ?? 0)
        ]
    }
}

struct StatisticsGrid: View {
    let stats: [(String, Double)]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
            ForEach(stats, id: \.0) { stat in
                VStack(spacing: 4) {
                    Text(stat.0)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", stat.1))
                        .font(.headline)
                        .foregroundColor(Theme.primary)
                }
                .padding()
                .background(Color(.systemBackground).opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}
