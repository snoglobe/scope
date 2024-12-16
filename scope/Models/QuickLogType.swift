import Foundation

struct QuickLogType: Identifiable, Codable {
    let id: String  // Changed from UUID to String
    let name: String
    let unit: String?
    let icon: String
    let color: String
    
    init(id: UUID = UUID(), name: String, unit: String? = nil, icon: String, color: String) {
        self.id = id.uuidString
        self.name = name
        self.unit = unit
        self.icon = icon
        self.color = color
    }
} 