import SwiftUI

struct DebugMenuView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataManager: HealthDataManager
    @State private var isGeneratingData = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                List {
                    Section("Data Management") {
                        Button {
                            generateMockData()
                        } label: {
                            HStack {
                                if isGeneratingData {
                                    ProgressView()
                                        .padding(.trailing, 8)
                                }
                                Text(isGeneratingData ? "Generating..." : "Generate Mock Data")
                            }
                        }
                        .disabled(isGeneratingData)
                        
                        Button(role: .destructive) {
                            clearAllData()
                        } label: {
                            Text("Clear All Data")
                        }
                    }
                    
                    Section("Debug Info") {
                        LabeledContent("Notes Count", value: "\(dataManager.notes.count)")
                        LabeledContent("Quick Log Types", value: "\(dataManager.quickLogTypes.count)")
                    }
                }
            }
            .navigationTitle("Debug Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Debug Action", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func generateMockData() {
        isGeneratingData = true
        
        Task {
            do {
                let prompt = """
                Generate a minified JSON dataset for a health journaling app with the following structure:
                {
                    "version": "1.0",
                    "exportDate": "2024-03-19T12:00:00Z",
                    "notes": [
                        {
                            "id": "UUID string",
                            "timestamp": "ISO8601 date",
                            "content": "note content",
                            "images": [],
                            "quickLogData": [
                                {
                                    "id": "UUID string",
                                    "type": "Pain Level/Mood/Energy/Sleep Quality",
                                    "value": number between 1-10,
                                    "unit": "optional unit string"
                                }
                            ],
                            "healthKitData": [],
                            "customMeasurements": [],
                            "tags": ["tag1", "tag2"],
                            "analysisResults": null
                        }
                    ],
                    "quickLogTypes": [
                        {
                            "id": "UUID string",
                            "name": "type name",
                            "unit": "optional unit",
                            "icon": "SFSymbol name",
                            "color": "hex color"
                        }
                    ],
                    "settings": {
                        "aiModel": "claude-3-sonnet-latest",
                        "autoAnalyze": true,
                        "retentionPeriod": 365
                    }
                }

                Generate 20 realistic health journal entries over the past month with varied quick log data and tags.
                Include common health-related tags and realistic journal entries about symptoms, wellness activities, and general health observations.
                Return ONLY valid JSON data - no other text or analysis.
                """
                
                let aiMessage = Message(
                    role: "user",
                    content: [[
                        "type": "text",
                        "text": prompt
                    ]]
                )
                
                let response = try await AIManager.shared.chat(aiMessage)
                
                // Clean the response to ensure we only have JSON
                let cleanedResponse = response
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                print("Cleaned response: \(cleanedResponse)")
                
                if let jsonData = cleanedResponse.data(using: .utf8) {
                    try DataManager.shared.importData(jsonData)
                    
                    await MainActor.run {
                        alertMessage = "Successfully generated and imported mock data"
                        showingAlert = true
                        isGeneratingData = false
                        HapticManager.shared.success()
                    }
                } else {
                    throw AppError.dataLoadFailed
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to generate mock data: \(error.localizedDescription)"
                    showingAlert = true
                    isGeneratingData = false
                    HapticManager.shared.error()
                }
            }
        }
    }
    
    private func clearAllData() {
        dataManager.notes = []
        dataManager.quickLogTypes = []
        dataManager.saveData()
        alertMessage = "All data cleared"
        showingAlert = true
        HapticManager.shared.success()
    }
} 
