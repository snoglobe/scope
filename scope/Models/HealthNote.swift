import Foundation

struct HealthNote: Identifiable, Codable {
    let id: String
    var timestamp: Date
    var content: String
    var images: [ImageData]
    var quickLogData: [QuickLogEntry]
    var healthKitData: [HealthKitDataPoint]
    var customMeasurements: [CustomMeasurement]
    var analysisResults: AnalysisResults?
    var tags: Set<String>
    
    struct QuickLogEntry: Identifiable, Codable {
        let id: String
        let type: String
        let value: Double
        let unit: String?
    }
    
    struct ImageData: Identifiable, Codable {
        let id: String
        let imageData: Data
        var caption: String?
    }
    
    struct HealthKitDataPoint: Identifiable, Codable {
        let id: String
        let type: String
        let value: Double
        let unit: String
        let timestamp: Date
    }
    
    struct CustomMeasurement: Identifiable, Codable {
        let id: String
        let name: String
        let value: Double
        let unit: String
    }
    
    struct AnalysisResults: Codable {
        var structuredData: [String: String]
        var categories: [String]
        var insights: [String]
    }
    
    init(id: UUID = UUID(), 
         timestamp: Date = Date(),
         content: String = "",
         images: [ImageData] = [],
         quickLogData: [QuickLogEntry] = [],
         healthKitData: [HealthKitDataPoint] = [],
         customMeasurements: [CustomMeasurement] = [],
         analysisResults: AnalysisResults? = nil,
         tags: Set<String> = []) {
        self.id = id.uuidString
        self.timestamp = timestamp
        self.content = content
        self.images = images
        self.quickLogData = quickLogData
        self.healthKitData = healthKitData
        self.customMeasurements = customMeasurements
        self.analysisResults = analysisResults
        self.tags = tags
    }
} 