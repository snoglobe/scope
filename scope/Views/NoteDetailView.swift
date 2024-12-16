import SwiftUI

struct NoteDetailView: View {
    @EnvironmentObject var dataManager: HealthDataManager
    @Environment(\.colorScheme) var colorScheme
    let note: HealthNote
    @State private var showingDeleteConfirmation = false
    @State private var isAnalyzing = false
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Content
                    if !note.content.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note")
                                .titleStyleLeading()
                            
                            Text(note.content)
                                .font(.body)
                        }
                        .cardStyle()
                    }
                    
                    // Images
                    if !note.images.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Images")
                                .titleStyleLeading()
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(note.images) { image in
                                        VStack {
                                            Image(uiImage: UIImage(data: image.imageData) ?? UIImage())
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 200)
                                                .cornerRadius(12)
                                            
                                            if let caption = image.caption {
                                                Text(caption)
                                                    .subtitleStyle()
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .cardStyle()
                    }
                    
                    // Quick Log Data
                    if !note.quickLogData.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quick Logs")
                                .titleStyleLeading()
                            
                            ForEach(note.quickLogData) { entry in
                                HStack {
                                    Text(entry.type)
                                    Spacer()
                                    Text("\(entry.value, specifier: "%.1f")")
                                        .font(.headline)
                                    if let unit = entry.unit {
                                        Text(unit)
                                            .subtitleStyle()
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .cardStyle()
                    }
                    
                    // AI Analysis
                    if let analysis = note.analysisResults {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI Analysis")
                                .titleStyleLeading()
                            
                            // Categories in ScrollView
                            if !analysis.categories.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Categories")
                                        .font(.headline)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(analysis.categories, id: \.self) { category in
                                                Text(category)
                                                    .font(.caption)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Theme.primary.opacity(0.1))
                                                    .cornerRadius(8)
                                            }
                                        }
                                        .padding(.horizontal, 4)
                                    }
                                }
                            }
                            
                            // Insights
                            if !analysis.insights.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Insights")
                                        .font(.headline)
                                    
                                    ForEach(analysis.insights, id: \.self) { insight in
                                        Text("• \(insight)")
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                        .cardStyle()
                    } else {
                        Button {
                            analyzeNote()
                        } label: {
                            HStack {
                                if isAnalyzing {
                                    ProgressView()
                                        .tint(.white)
                                        .padding(.trailing, 4)
                                }
                                Text(isAnalyzing ? "Analyzing..." : "Analyze with AI")
                                Image(systemName: "brain")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isAnalyzing)
                        .cardStyle()
                    }
                    
                    // Tags
                    if !note.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .titleStyleLeading()
                            
                            FlowLayout(spacing: 8) {
                                ForEach(Array(note.tags), id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Theme.primary.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .cardStyle()
                    }
                }
                .padding()
            }
        }
        .navigationTitle(note.timestamp.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
            }
        }
        .alert("Delete Note", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteNote()
            }
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
    }
    
    private func analyzeNote() {
        isAnalyzing = true
        
        Task {
            do {
                let analysisResults = try await AIManager.shared.analyzeHealthNote(note)
                
                // Update the note in the data manager
                if let index = dataManager.notes.firstIndex(where: { $0.id == note.id }) {
                    var updatedNote = note
                    updatedNote.analysisResults = analysisResults
                    dataManager.notes[index] = updatedNote
                    dataManager.saveData()
                }
                
                HapticManager.shared.success()
            } catch {
                ErrorHandler.handle(error)
                HapticManager.shared.error()
            }
            
            isAnalyzing = false
        }
    }
    
    private func deleteNote() {
        if let index = dataManager.notes.firstIndex(where: { $0.id == note.id }) {
            dataManager.notes.remove(at: index)
            dataManager.saveData()
        }
    }
} 
