import SwiftUI
import Security

struct AISettingsView: View {
    @AppStorage("aiModel") private var selectedModel = "claude-3-5-sonnet-latest"
    @AppStorage("autoAnalyze") private var autoAnalyze = true
    @AppStorage("analysisPrompt") private var customPrompt = ""
    @Environment(\.colorScheme) var colorScheme
    
    let availableModels = [
        "claude-3-opus-latest",
        "claude-3-5-sonnet-latest",
        "claude-3-5-haiku-latest"
    ]
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker("Model", selection: $selectedModel) {
                            ForEach(availableModels, id: \.self) { model in
                                Text(model)
                                    .foregroundColor(Theme.primary)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 8)
                    }
                }
                .listRowBackground(Color(.systemBackground))
                
                Section {
                    Toggle("Auto-Analyze New Notes", isOn: $autoAnalyze)
                        .tint(Theme.primary)
                } footer: {
                    Text("Automatically analyze notes using AI when they are created")
                        .subtitleStyle()
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom Analysis Prompt")
                            .titleStyle()
                        
                        TextEditor(text: $customPrompt)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                } footer: {
                    Text("Leave blank to use the default prompt. Use placeholders: {content}, {quicklog}, {medications}")
                        .subtitleStyle()
                }
                
                Section {
                    NavigationLink {
                        APIKeySettingsView()
                    } label: {
                        Label("API Key Settings", systemImage: "key.fill")
                            .foregroundColor(Theme.primary)
                    }
                }
            }
        }
        .navigationTitle("AI Settings")
    }
}

struct APIKeySettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var apiKey = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            Form {
                Section {
                    SecureField("API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .padding(.vertical, 8)
                } footer: {
                    Text("Enter your Anthropic API key. This will be stored securely in the keychain.")
                        .subtitleStyle()
                }
                
                Section {
                    Button("Save API Key") {
                        saveAPIKey()
                    }
                    .buttonStyle(Theme.PrimaryButtonStyle())
                    .disabled(apiKey.isEmpty)
                }
            }
        }
        .navigationTitle("API Key")
        .alert("API Key", isPresented: $showingAlert) {
            Button("OK") {
                if !alertMessage.contains("Error") {
                    dismiss()
                }
            }
            .buttonStyle(Theme.PrimaryButtonStyle())
        } message: {
            Text(alertMessage)
                .subtitleStyle()
        }
    }
    
    private func saveAPIKey() {
        do {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "AnthropicAPIKey",
                kSecValueData as String: apiKey.data(using: .utf8)!
            ]
            
            let status = SecItemAdd(query as CFDictionary, nil)
            if status == errSecDuplicateItem {
                let updateQuery: [String: Any] = [
                    kSecValueData as String: apiKey.data(using: .utf8)!
                ]
                SecItemUpdate(query as CFDictionary, updateQuery as CFDictionary)
            }
            
            alertMessage = "API key saved successfully"
            showingAlert = true
            HapticManager.shared.success()
        } catch {
            alertMessage = "Error saving API key: \(error.localizedDescription)"
            showingAlert = true
            HapticManager.shared.error()
        }
    }
} 
