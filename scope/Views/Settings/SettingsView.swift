import SwiftUI
import HealthKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var dataManager: HealthDataManager
    @State private var showingExport = false
    @State private var showingImport = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            Form {
                Section {
                    NavigationLink {
                        AISettingsView()
                    } label: {
                        SettingsRow(
                            icon: "brain",
                            title: "AI Configuration",
                            color: Theme.primary
                        )
                    }
                }
                
                Section {
                    NavigationLink {
                        QuickLogSettingsView()
                    } label: {
                        SettingsRow(
                            icon: "list.bullet",
                            title: "Quick Log Types",
                            color: Theme.accent
                        )
                    }
                }
                
                Section {
                    NavigationLink {
                        DataPrivacyView()
                    } label: {
                        SettingsRow(
                            icon: "lock.shield",
                            title: "Privacy & Security",
                            color: Theme.success
                        )
                    }
                    
                    NavigationLink {
                        BackupRestoreView()
                    } label: {
                        SettingsRow(
                            icon: "arrow.clockwise",
                            title: "Backup & Restore",
                            color: Theme.warning
                        )
                    }
                }
                
                Section {
                    Button {
                        showingExport = true
                    } label: {
                        SettingsRow(
                            icon: "square.and.arrow.up",
                            title: "Export Data",
                            color: Theme.primary
                        )
                    }
                    
                    Button {
                        showingImport = true
                    } label: {
                        SettingsRow(
                            icon: "square.and.arrow.down",
                            title: "Import Data",
                            color: Theme.primary
                        )
                    }
                }
                
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        SettingsRow(
                            icon: "info.circle",
                            title: "About",
                            color: Theme.accent
                        )
                    }
                }
                
                #if DEBUG
                Section {
                    NavigationLink {
                        DebugMenuView()
                    } label: {
                        SettingsRow(
                            icon: "hammer.fill",
                            title: "Debug Menu",
                            color: Theme.warning
                        )
                    }
                }
                #endif
            }
        }
        .navigationTitle("Settings")
        .fileExporter(
            isPresented: $showingExport,
            document: JSONDocument(data: try? DataManager.shared.exportData()),
            contentType: .json,
            defaultFilename: "scope_export_\(Date().ISO8601Format()).json"
        ) { result in
            switch result {
            case .success:
                HapticManager.shared.success()
            case .failure(let error):
                ErrorHandler.handle(error)
            }
        }
        .fileImporter(
            isPresented: $showingImport,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                do {
                    let data = try Data(contentsOf: url)
                    try DataManager.shared.importData(data)
                    HapticManager.shared.success()
                } catch {
                    ErrorHandler.handle(error)
                }
            case .failure(let error):
                ErrorHandler.handle(error)
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(title)
        }
    }
}

struct HealthKitSettingsView: View {
    let metrics: [(String, HKQuantityTypeIdentifier)]
    @State private var authorizedTypes: Set<HKQuantityTypeIdentifier> = []
    
    var body: some View {
        List {
            ForEach(metrics, id: \.0) { name, identifier in
                HStack {
                    Text(name)
                    Spacer()
                    if authorizedTypes.contains(identifier) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .navigationTitle("HealthKit Access")
        .onAppear {
            checkAuthorization()
        }
    }
    
    private func checkAuthorization() {
        let healthStore = HKHealthStore()
        for (_, identifier) in metrics {
            if let type = HKQuantityType.quantityType(forIdentifier: identifier),
               healthStore.authorizationStatus(for: type) == .sharingAuthorized {
                authorizedTypes.insert(identifier)
            }
        }
    }
}

struct QuickLogSettingsView: View {
    @EnvironmentObject var dataManager: HealthDataManager
    @State private var showingNewType = false
    
    var body: some View {
        List {
            ForEach(dataManager.quickLogTypes) { type in
                NavigationLink {
                    QuickLogTypeEditorView(type: type)
                } label: {
                    HStack {
                        Image(systemName: type.icon)
                            .foregroundColor(Color(hex: type.color) ?? .accentColor)
                        Text(type.name)
                    }
                }
            }
            .onDelete { indexSet in
                dataManager.quickLogTypes.remove(atOffsets: indexSet)
                dataManager.saveData()
            }
        }
        .navigationTitle("Quick Log Types")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingNewType = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewType) {
            QuickLogTypeEditorView()
        }
    }
}

struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var data: Data?
    
    init(data: Data?) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.data = data
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data ?? Data())
    }
} 
