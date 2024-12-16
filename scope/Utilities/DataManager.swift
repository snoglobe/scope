import Foundation

class DataManager {
    static let shared = DataManager()
    private let storageManager = StorageManager()
    
    // Export data structure
    struct ExportData: Codable {
        let version: String
        let exportDate: Date
        let notes: [HealthNote]
        let quickLogTypes: [QuickLogType]
        let settings: ExportSettings
        
        struct ExportSettings: Codable {
            let aiModel: String
            let autoAnalyze: Bool
            let retentionPeriod: Int
        }
    }
    
    func exportData() throws -> Data {
        let settings = ExportData.ExportSettings(
            aiModel: UserDefaults.standard.string(forKey: "aiModel") ?? "claude-3-sonnet-latest",
            autoAnalyze: UserDefaults.standard.bool(forKey: "autoAnalyze"),
            retentionPeriod: UserDefaults.standard.integer(forKey: "retentionPeriod")
        )
        
        let exportData = ExportData(
            version: "1.0",
            exportDate: Date(),
            notes: HealthDataManager.instance.notes,
            quickLogTypes: HealthDataManager.instance.quickLogTypes,
            settings: settings
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        return try encoder.encode(exportData)
    }
    
    func importData(_ data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        print("importing data")
        
        let importedData = try decoder.decode(ExportData.self, from: data)
        
        print(importedData)
        
        // Validate version compatibility
        guard importedData.version.starts(with: "1.") else {
            throw DataError.incompatibleVersion
        }
        
        print("data imported ?")
        
        // Import settings
        UserDefaults.standard.set(importedData.settings.aiModel, forKey: "aiModel")
        UserDefaults.standard.set(importedData.settings.autoAnalyze, forKey: "autoAnalyze")
        UserDefaults.standard.set(importedData.settings.retentionPeriod, forKey: "retentionPeriod")
        
        // Import data
        HealthDataManager.instance.importData(
            notes: importedData.notes,
            quickLogTypes: importedData.quickLogTypes
        )
    }
    
    func backupData() async throws {
        let backupData = try exportData()
        let backupFileName = "scope_backup_\(Date().ISO8601Format()).json"
        
        // Save locally
        try storageManager.saveBackup(backupData, to: backupFileName)
        
        // Upload to iCloud if enabled
        if UserDefaults.standard.bool(forKey: "autoBackup") {
            try await CloudManager.shared.uploadBackup(backupData, filename: backupFileName)
        }
    }
    
    func restoreFromBackup(_ url: URL) throws {
        let data = try Data(contentsOf: url)
        try importData(data)
    }
    
    func cleanupOldData() {
        let retentionPeriod = UserDefaults.standard.integer(forKey: "retentionPeriod")
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -retentionPeriod,
            to: Date()
        )!
        
        HealthDataManager.instance.deleteNotes(before: cutoffDate)
    }
}

enum DataError: Error {
    case incompatibleVersion
    case importFailed(String)
    case backupFailed(String)
    case restoreFailed(String)
}
