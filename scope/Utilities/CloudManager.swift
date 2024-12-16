import Foundation

class CloudManager {
    static let shared = CloudManager()
    private let fileManager = FileManager.default
    
    func uploadBackup(_ data: Data, filename: String) async throws {
        guard let containerURL = fileManager.url(forUbiquityContainerIdentifier: nil) else {
            throw CloudError.iCloudNotAvailable
        }
        
        let backupsURL = containerURL.appendingPathComponent("Backups", isDirectory: true)
        try fileManager.createDirectory(at: backupsURL, withIntermediateDirectories: true)
        
        let fileURL = backupsURL.appendingPathComponent(filename)
        try data.write(to: fileURL)
    }
    
    func listBackups() async throws -> [URL] {
        guard let containerURL = fileManager.url(forUbiquityContainerIdentifier: nil) else {
            throw CloudError.iCloudNotAvailable
        }
        
        let backupsURL = containerURL.appendingPathComponent("Backups")
        let contents = try fileManager.contentsOfDirectory(
            at: backupsURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        )
        
        return contents.filter { $0.pathExtension == "json" }
            .sorted { (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date() >
                     (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date() }
    }
    
    func downloadBackup(at url: URL) async throws -> Data {
        try Data(contentsOf: url)
    }
}

enum CloudError: Error {
    case iCloudNotAvailable
    case uploadFailed(String)
    case downloadFailed(String)
} 