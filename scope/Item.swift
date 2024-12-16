//
//  Item.swift
//  scope
//
//  Created by bun on 11/18/24.
//

import Foundation
import SwiftUI

//struct HealthNote: Identifiable, Codable {
//    let id: UUID
//    var timestamp: Date
//    var content: String
//    var images: [ImageData]
//    var quickLogData: [QuickLogEntry]
//    var healthKitData: [HealthKitDataPoint]
//    var customMeasurements: [CustomMeasurement]
//    var analysisResults: AnalysisResults?
//    var tags: Set<String>
//    
//    init(id: UUID = UUID(), 
//         timestamp: Date = Date(),
//         content: String = "",
//         images: [ImageData] = [],
//         quickLogData: [QuickLogEntry] = [],
//         healthKitData: [HealthKitDataPoint] = [],
//         customMeasurements: [CustomMeasurement] = [],
//         analysisResults: AnalysisResults? = nil,
//         tags: Set<String> = []) {
//        self.id = id
//        self.timestamp = timestamp
//        self.content = content
//        self.images = images
//        self.quickLogData = quickLogData
//        self.healthKitData = healthKitData
//        self.customMeasurements = customMeasurements
//        self.analysisResults = analysisResults
//        self.tags = tags
//    }
//    
//    struct ImageData: Identifiable, Codable {
//        let id: UUID
//        let imageData: Data
//        let caption: String?
//    }
//    
//    struct QuickLogEntry: Identifiable, Codable {
//        let id: UUID
//        let type: String
//        let value: Double
//        let unit: String?
//    }
//    
//    struct HealthKitDataPoint: Identifiable, Codable {
//        let id: UUID
//        let type: String
//        let value: Double
//        let unit: String
//        let timestamp: Date
//    }
//    
//    struct CustomMeasurement: Identifiable, Codable {
//        let id: UUID
//        let name: String
//        let value: Double
//        let unit: String?
//    }
//    
//    struct AnalysisResults: Codable {
//        var structuredData: [String: String]
//        var categories: [String]
//        var insights: [String]
//        
//        enum CodingKeys: String, CodingKey {
//            case structuredData, categories, insights
//        }
//    }
//}

//struct QuickLogType: Identifiable, Codable {
//    let id: UUID
//    var name: String
//    var unit: String?
//    var icon: String
//    var color: String
//}
