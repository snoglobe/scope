import SwiftUI
import PhotosUI

struct NewNoteView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataManager: HealthDataManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var speechManager: SpeechManager
    
    @State private var note = HealthNote()
    @State private var showingImagePicker = false
    @State private var showingMedicationPicker = false
    @State private var showingQuickLogPicker = false
    @State private var showingTagEditor = false
    @State private var newTag = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Content Section
                        VStack(alignment: .leading, spacing: 8) {
                            TextEditor(text: $note.content)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                            
                            HStack {
                                Button {
                                    try? speechManager.startRecording()
                                } label: {
                                    Label("Start Dictation", systemImage: "mic.fill")
                                }
                                .buttonStyle(Theme.SecondaryButtonStyle())
                                .disabled(speechManager.isRecording)
                                
                                if speechManager.isRecording {
                                    Button {
                                        speechManager.stopRecording()
                                        note.content += speechManager.transcribedText
                                    } label: {
                                        Label("Stop", systemImage: "stop.fill")
                                    }
                                    .buttonStyle(Theme.PrimaryButtonStyle())
                                    .tint(Theme.error)
                                }
                            }
                        }
                        .cardStyle()
                        
                        // Data Entry Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Add Data")
                                .titleStyleLeading()
                            
                            HStack(spacing: 16) {
                                DataEntryButton(
                                    title: "Images",
                                    icon: "photo",
                                    action: { showingImagePicker = true }
                                )
                                
                                DataEntryButton(
                                    title: "Meds",
                                    icon: "pills",
                                    action: { showingMedicationPicker = true }
                                )
                                
                                DataEntryButton(
                                    title: "Health Data",
                                    icon: "heart.fill",
                                    action: fetchHealthKitData
                                )
                                
                                DataEntryButton(
                                    title: "Quick Log",
                                    icon: "list.bullet",
                                    action: { showingQuickLogPicker = true }
                                )
                            }
                        }
                        .cardStyle()
                        
                        // Preview Sections
                        if !note.images.isEmpty {
                            ImagePreviewSection(images: note.images)
                                .cardStyle()
                        }
                        
                        if !note.quickLogData.isEmpty {
                            QuickLogPreviewSection(entries: note.quickLogData)
                                .cardStyle()
                        }
                        
                        if !note.healthKitData.isEmpty {
                            HealthDataPreviewSection(dataPoints: note.healthKitData)
                                .cardStyle()
                        }
                        
                        // Tags Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .titleStyleLeading()
                            
                            HStack {
                                TextField("Add Tag", text: $newTag)
                                    .transparentTextField()
                                    .textFieldStyle(.roundedBorder)
                                    .background(Color.secondary.opacity(0.1))
                                
                                if !newTag.isEmpty {
                                    Button {
                                        note.tags.insert(newTag)
                                        newTag = ""
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                    }
                                    .buttonStyle(Theme.PrimaryButtonStyle())
                                }
                            }
                            
                            if !note.tags.isEmpty {
                                FlowLayout(spacing: 8) {
                                    ForEach(Array(note.tags), id: \.self) { tag in
                                        TagView(tag: tag) {
                                            note.tags.remove(tag)
                                        }
                                    }
                                }
                            }
                        }
                        .cardStyle()
                    }
                    .padding()
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(Theme.SecondaryButtonStyle())
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dataManager.addNote(note)
                        dismiss()
                    }
                    .buttonStyle(Theme.PrimaryButtonStyle())
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(note: $note)
            }
            .sheet(isPresented: $showingQuickLogPicker) {
                QuickLogPickerView(note: $note)
            }
        }
    }
    
    private func fetchHealthKitData() {
        healthKitManager.fetchRecentData { dataPoints in
            note.healthKitData = dataPoints
        }
    }
}

struct DataEntryButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .resizable()
                    .aspectRatio(1.2/1, contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .font(.title2)
                    .padding(.vertical, 4)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(Theme.SecondaryButtonStyle())
    }
}

struct HealthDataPreviewSection: View {
    let dataPoints: [HealthNote.HealthKitDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Health Data")
                .titleStyleLeading()
            
            ForEach(dataPoints) { point in
                HStack {
                    Text(point.type.replacingOccurrences(of: "HKQuantityTypeIdentifier", with: ""))
                    Spacer()
                    Text("\(point.value, specifier: "%.1f") \(point.unit)")
                        .subtitleStyle()
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// Preview Sections
struct ImagePreviewSection: View {
    let images: [HealthNote.ImageData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Images")
                .titleStyle()
            
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(images) { image in
                        VStack {
                            Image(uiImage: UIImage(data: image.imageData) ?? UIImage())
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .cornerRadius(8)
                            
                            if let caption = image.caption {
                                Text(caption)
                                    .subtitleStyle()
                            }
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
}

struct QuickLogPreviewSection: View {
    let entries: [HealthNote.QuickLogEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Log")
                .titleStyleLeading()
            
            ForEach(entries) { entry in
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
}

struct TagView: View {
    let tag: String
    let onDelete: () -> Void
    
    var body: some View {
        Text(tag)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.primary.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, -4),
                alignment: .trailing
            )
    }
}

struct QuickLogPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataManager: HealthDataManager
    @Binding var note: HealthNote
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 120))
                    ], spacing: 16) {
                        ForEach(dataManager.quickLogTypes) { type in
                            QuickLogButton(type: type) { entry in
                                note.quickLogData.append(entry)
                                dismiss()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Quick Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(Theme.SecondaryButtonStyle())
                }
            }
        }
    }
}
