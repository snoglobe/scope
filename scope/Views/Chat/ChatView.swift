import SwiftUI

struct ChatView: View {
    @EnvironmentObject var dataManager: HealthDataManager
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingConversationList = false
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Chat Messages
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.currentConversation?.messages ?? []) { message in
                            MessageRow(message: message)
                            Divider()
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical)
                }
                
                // Selected Image Preview
                if let image = selectedImage {
                    HStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                            .cornerRadius(8)
                        
                        Button {
                            selectedImage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Input Area
                VStack(spacing: 8) {
                    if viewModel.isProcessing {
                        ProgressView()
                            .padding(.vertical, 4)
                    }
                    
                    HStack(spacing: 12) {
                        // Image Attachment Button
                        Button {
                            showingImagePicker = true
                        } label: {
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                        }
                        .buttonStyle(Theme.SecondaryButtonStyle())
                        
                        // Text Input
                        TextField("Ask me anything...", text: $messageText)
                            .transparentTextField()
                        
                        // Send Button
                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 24))
                        }
                        .buttonStyle(Theme.PrimaryButtonStyle())
                        .disabled(messageText.isEmpty && selectedImage == nil)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                }
            }
        }
        .navigationTitle(viewModel.currentConversation?.title ?? "New Chat")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingConversationList = true
                } label: {
                    Image(systemName: "list.bullet")
                }
                .buttonStyle(Theme.SecondaryButtonStyle())
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.startNewConversation()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .buttonStyle(Theme.PrimaryButtonStyle())
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingConversationList) {
            ConversationListView(viewModel: viewModel)
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty || selectedImage != nil else { return }
        
        let userMessage = ChatMessage(
            id: UUID(),
            role: .user,
            content: messageText,
            imageData: selectedImage?.jpegData(compressionQuality: 0.8)
        )
        
        viewModel.sendMessage(userMessage)
        messageText = ""
        selectedImage = nil
    }
}

struct ConversationListView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: ChatViewModel
    @State private var showingDeleteConfirmation = false
    @State private var conversationToDelete: Conversation?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.conversations.isEmpty {
                    NoDataView(message: "No conversations yet", icon: "message")
                } else {
                    List {
                        ForEach(viewModel.conversations) { conversation in
                            Button {
                                viewModel.currentConversation = conversation
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(conversation.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(conversation.timestamp.formatted())
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    conversationToDelete = conversation
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Conversations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(Theme.PrimaryButtonStyle())
                }
            }
            .alert("Delete Conversation", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let conversation = conversationToDelete {
                        viewModel.deleteConversation(conversation)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this conversation? This action cannot be undone.")
            }
        }
    }
}

struct MessageRow: View {
    let message: ChatMessage
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Role indicator
            Text(message.role == .user ? "You" : "Assistant")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Message content
            VStack(alignment: .leading, spacing: 12) {
                if let image = message.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                }
                
                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.body)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(message.role == .user ? 
                Color(.systemGray6).opacity(0.5) : Color.clear)
        }
        .padding(.vertical, 8)
    }
} 
