import Foundation

extension StorageManager {
    func saveBackup(_ data: Data, to filename: String) throws {
        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let backupURL = documentsURL.appendingPathComponent("Backups", isDirectory: true)
        try fileManager.createDirectory(at: backupURL, withIntermediateDirectories: true, attributes: nil)
        let fileURL = backupURL.appendingPathComponent(filename)
        try data.write(to: fileURL)
    }
} 
