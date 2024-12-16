import SwiftUI

struct Conversation: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    var title: String
    var messages: [ChatMessage]
    
    init(id: UUID = UUID(), 
         timestamp: Date = Date(), 
         title: String = "New Conversation", 
         messages: [ChatMessage] = []) {
        self.id = id
        self.timestamp = timestamp
        self.title = title
        self.messages = messages
    }
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    let content: String
    var imageData: Data?  // Store image as Data for Codable
    
    enum MessageRole: String, Codable {
        case user
        case assistant
    }
    
    var image: UIImage? {
        get {
            if let data = imageData {
                return UIImage(data: data)
            }
            return nil
        }
        set {
            imageData = newValue?.jpegData(compressionQuality: 0.8)
        }
    }
} 