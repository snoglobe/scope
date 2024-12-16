import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var dataManager: HealthDataManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedInsight: InsightCard? = nil
    @Environment(\.colorScheme) var colorScheme
    
    enum TimeRange: String, CaseIterable {
        case day = "24h"
        case week = "7d"
        case month = "30d"
        case year = "1y"
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Time Range Selector
                    HStack {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button {
                                withAnimation {
                                    selectedTimeRange = range
                                }
                            } label: {
                                Text(range.rawValue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedTimeRange == range ? 
                                                Theme.primary : Color(.systemGray6).opacity(0.25))
                                    .foregroundColor(selectedTimeRange == range ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Analytics Sections
                    LazyVStack(spacing: 20) {
                        // Quick Logs
                        if !dataManager.quickLogTypes.isEmpty {
                            InfoCard(title: "Quick Logs", icon: "list.bullet") {
                                QuickLogAnalyticsSection(timeRange: selectedTimeRange)
                            }
                        }
                        
                        // HealthKit Data
                        InfoCard(title: "Health Data", icon: "heart.text.square") {
                            HealthKitAnalytics(timeRange: selectedTimeRange)
                        }
                        
                        // Tags
                        InfoCard(title: "Tags", icon: "tag") {
                            TagCloudSection(timeRange: selectedTimeRange)
                        }
                    }
                    .padding(.horizontal)
                }
                // .padding(.vertical)
            }
        }
        .navigationTitle("Analytics")
        .sheet(item: $selectedInsight) { insight in
            InsightDetailView(insight: insight)
        }
    }
}

extension AnalyticsView.TimeRange {
    func getDateRange(from now: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let end = now
        let start: Date
        
        switch self {
        case .day:
            start = calendar.date(byAdding: .day, value: -1, to: end)!
        case .week:
            start = calendar.date(byAdding: .day, value: -7, to: end)!
        case .month:
            start = calendar.date(byAdding: .month, value: -1, to: end)!
        case .year:
            start = calendar.date(byAdding: .year, value: -1, to: end)!
        }
        
        return (start, end)
    }
}
