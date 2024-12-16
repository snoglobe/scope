import SwiftUI

struct BackupRestoreView: View {
    @EnvironmentObject var dataManager: HealthDataManager
    @State private var backups: [URL] = []
    @State private var isLoading = false
    @State private var showingImportPicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingBackupSuccess = false
    @State private var showingRestoreConfirmation = false
    @State private var selectedBackup: URL?
    
    var body: some View {
        List {
            Section {
                Button {
                    createBackup()
                } label: {
                    Label("Create New Backup", systemImage: "arrow.clockwise.circle")
                }
                
                Button {
                    showingImportPicker = true
                } label: {
                    Label("Import Backup", systemImage: "square.and.arrow.down")
                }
            }
            
            if !backups.isEmpty {
                Section("Available Backups") {
                    ForEach(backups, id: \.self) { backup in
                        BackupRow(url: backup) {
                            selectedBackup = backup
                            showingRestoreConfirmation = true
                        }
                    }
                }
            }
        }
        .navigationTitle("Backup & Restore")
        .task {
            await loadBackups()
        }
        .refreshable {
            await loadBackups()
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .background(Color(.systemBackground).opacity(0.8))
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showingBackupSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Backup created successfully")
        }
        .alert("Restore Backup", isPresented: $showingRestoreConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Restore", role: .destructive) {
                restoreBackup()
            }
        } message: {
            Text("Are you sure you want to restore this backup? Current data will be replaced.")
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
    }
    
    private func loadBackups() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            backups = try await CloudManager.shared.listBackups()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func createBackup() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await DataManager.shared.backupData()
                await loadBackups()
                showingBackupSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func restoreBackup() {
        guard let url = selectedBackup else { return }
        
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                let data = try await CloudManager.shared.downloadBackup(at: url)
                try DataManager.shared.importData(data)
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                try DataManager.shared.restoreFromBackup(url)
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

struct BackupRow: View {
    let url: URL
    let onRestore: () -> Void
    
    var backupDate: Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey])
            .contentModificationDate
    }
    
    var formattedDate: String {
        if let date = backupDate {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return "Unknown Date"
    }
    
    var body: some View {
        Button {
            onRestore()
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(url.lastPathComponent)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.clockwise.circle")
                    .foregroundColor(.accentColor)
            }
        }
    }
} 