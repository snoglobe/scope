import SwiftUI
import Charts

struct InsightDetailView: View {
    let insight: InsightCard
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: HealthDataManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(spacing: 8) {
                        Image(systemName: insight.trend.icon)
                            .font(.system(size: 48))
                            .foregroundColor(insight.trend.color)
                        
                        Text(insight.title)
                            .font(.title2)
                            .bold()
                        
                        Text(insight.value)
                            .font(.title)
                            .foregroundColor(insight.trend.color)
                        
                        Text(insight.description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Detailed Analysis
                    if let detailedData = getDetailedData() {
                        DetailedInsightChart(data: detailedData)
                    }
                    
                    // Related Notes
                    RelatedNotesSection(insight: insight)
                    
                    // Recommendations
                    if let recommendations = getRecommendations() {
                        RecommendationsSection(recommendations: recommendations)
                    }
                }
                .padding()
            }
            .navigationTitle("Insight Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getDetailedData() -> [(Date, Double)]? {
        // Implementation depends on insight type
        switch insight.title {
        case "Most Tracked Metric":
            return getQuickLogData()
        case "Average Heart Rate":
            return getHeartRateData()
        default:
            return nil
        }
    }
    
    private func getQuickLogData() -> [(Date, Double)] {
        let notes = dataManager.notes.sorted { $0.timestamp < $1.timestamp }
        return notes.compactMap { note in
            note.quickLogData.first.map { (note.timestamp, $0.value) }
        }
    }
    
    private func getHeartRateData() -> [(Date, Double)] {
        let notes = dataManager.notes.sorted { $0.timestamp < $1.timestamp }
        return notes.compactMap { note in
            note.healthKitData.first.map { (note.timestamp, $0.value) }
        }
    }
    
    private func getRecommendations() -> [InsightRecommendation]? {
        // Generate recommendations based on insight type
        switch insight.title {
        case "Medication Adherence":
            return [
                InsightRecommendation(
                    title: "Set Reminders",
                    description: "Enable medication reminders to improve adherence",
                    action: .setReminder
                ),
                InsightRecommendation(
                    title: "Track Side Effects",
                    description: "Monitor and log any side effects you experience",
                    action: .trackMetric
                )
            ]
        case "Average Heart Rate":
            return [
                InsightRecommendation(
                    title: "Exercise Regularly",
                    description: "Maintain a consistent exercise routine",
                    action: .trackMetric
                ),
                InsightRecommendation(
                    title: "Monitor Stress",
                    description: "Track stress levels alongside heart rate",
                    action: .addQuickLog
                )
            ]
        default:
            return nil
        }
    }
}

struct DetailedInsightChart: View {
    let data: [(Date, Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trend Over Time")
                .font(.headline)
            
            Chart {
                ForEach(data, id: \.0) { date, value in
                    LineMark(
                        x: .value("Time", date),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    
                    PointMark(
                        x: .value("Time", date),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(Color.accentColor)
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct RelatedNotesSection: View {
    @EnvironmentObject var dataManager: HealthDataManager
    let insight: InsightCard
    
    var relatedNotes: [HealthNote] {
        // Filter notes based on insight type
        dataManager.notes.filter { note in
            switch insight.title {
            case "Most Tracked Metric":
                return !note.quickLogData.isEmpty
            case "Average Heart Rate":
                return note.healthKitData.contains { $0.type == "heartRate" }
            default:
                return false
            }
        }
        .sorted { $0.timestamp > $1.timestamp }
        .prefix(3)
        .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Notes")
                .font(.headline)
            
            ForEach(relatedNotes) { note in
                NavigationLink(destination: NoteDetailView(note: note)) {
                    RelatedNoteRow(note: note)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct RelatedNoteRow: View {
    let note: HealthNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.timestamp, style: .date)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !note.content.isEmpty {
                Text(note.content)
                    .lineLimit(2)
                    .font(.body)
            }
        }
        .padding(.vertical, 8)
    }
}

struct RecommendationsSection: View {
    let recommendations: [InsightRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
            
            ForEach(recommendations) { recommendation in
                RecommendationRow(recommendation: recommendation)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct InsightRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let action: RecommendationAction
    
    enum RecommendationAction {
        case setReminder
        case trackMetric
        case addQuickLog
    }
}

struct RecommendationRow: View {
    let recommendation: InsightRecommendation
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.headline)
                Text(recommendation.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                handleAction()
            } label: {
                Image(systemName: actionIcon)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var actionIcon: String {
        switch recommendation.action {
        case .setReminder: return "bell.fill"
        case .trackMetric: return "chart.line.uptrend.xyaxis"
        case .addQuickLog: return "plus.circle.fill"
        }
    }
    
    private func handleAction() {
        // Implement action handling
    }
} 
