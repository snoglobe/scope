import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    @Published var isProcessing = false
    
    private let aiManager = AIManager.shared
    private let storageManager = StorageManager()
    
    init() {
        loadConversations()
    }
    
    func loadConversations() {
        conversations = storageManager.load("conversations.json") ?? []
    }
    
    func saveConversations() {
        storageManager.save(conversations, to: "conversations.json")
    }
    
    func startNewConversation() {
        currentConversation = Conversation()
    }
    
    func deleteConversation(_ conversation: Conversation) {
        conversations.removeAll { $0.id == conversation.id }
        if currentConversation?.id == conversation.id {
            currentConversation = nil
        }
        saveConversations()
    }
    
    func sendMessage(_ message: ChatMessage) {
        if currentConversation == nil {
            startNewConversation()
        }
        
        guard var conversation = currentConversation else { return }
        conversation.messages.append(message)
        currentConversation = conversation
        
        isProcessing = true
        
        Task {
            do {
                // Build context from app data
                let context = buildContext()
                
                // Create message content array
                var content: [[String: Any]] = [
                    [
                        "type": "text",
                        "text": """
                        Context:
                        \(context)
                        
                        User Message: \(message.content)
                        """
                    ]
                ]
                
                // If there's an image, add it to the content array
                if let image = message.image,
                   let jpegData = image.jpegData(compressionQuality: 0.8) {
                    content.append([
                        "type": "image",
                        "source": [
                            "type": "base64",
                            "media_type": "image/jpeg",
                            "data": jpegData.base64EncodedString()
                        ] as [String: Any]
                    ])
                }
                
                // Create message with content array
                let aiMessage = Message(
                    role: "user",
                    content: content
                )
                
                let response = try await aiManager.chat(aiMessage)
                
                await MainActor.run {
                    let assistantMessage = ChatMessage(
                        id: UUID(),
                        role: .assistant,
                        content: response
                    )
                    
                    if var conversation = currentConversation {
                        conversation.messages.append(assistantMessage)
                        currentConversation = conversation
                        
                        // Update title if it's the first message
                        if conversation.messages.count == 2 {
                            conversation.title = String(conversation.messages[0].content.prefix(50))
                        }
                        
                        // Save to conversations list
                        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                            conversations[index] = conversation
                        } else {
                            conversations.append(conversation)
                        }
                        saveConversations()
                    }
                    
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        id: UUID(),
                        role: .assistant,
                        content: "I apologize, but I encountered an error: \(error.localizedDescription)"
                    )
                    
                    if var conversation = currentConversation {
                        conversation.messages.append(errorMessage)
                        currentConversation = conversation
                    }
                    
                    isProcessing = false
                }
            }
        }
    }
    
    private func buildContext() -> String {
        let notes = HealthDataManager.instance.notes
        let quickLogTypes = HealthDataManager.instance.quickLogTypes
        
        return """
        User Health Data:
        - Total Notes: \(notes.count)
        - Tracking Metrics: \(quickLogTypes.map { $0.name }.joined(separator: ", "))
        
        Recent Notes:
        \(notes.prefix(5).map { "- \($0.content)" }.joined(separator: "\n"))
        """
    }
} 
