import SwiftUI
import LocalAuthentication

struct DataPrivacyView: View {
    @AppStorage("biometricLock") private var biometricLock = false
    @AppStorage("autoBackup") private var autoBackup = false
    @AppStorage("retentionPeriod") private var retentionPeriod = 365
    @AppStorage("anonymizeExports") private var anonymizeExports = true
    @State private var showingDeleteConfirmation = false
    @Environment(\.colorScheme) var colorScheme
    
    let retentionOptions = [30, 90, 180, 365, 730]
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            Form {
                Section {
                    Toggle("Require Biometric Authentication", isOn: $biometricLock)
                        .onChange(of: biometricLock) { newValue in
                            if newValue {
                                authenticateUser()
                            }
                        }
                        .tint(Theme.primary)
                } footer: {
                    Text("Enable Face ID/Touch ID to protect your health data")
                        .subtitleStyle()
                }
                
                Section {
                    Toggle("Automatic Backup", isOn: $autoBackup)
                        .tint(Theme.primary)
                    
                    if autoBackup {
                        NavigationLink {
                            BackupSettingsView()
                        } label: {
                            Text("Configure Backup")
                                .foregroundColor(Theme.primary)
                        }
                    }
                } footer: {
                    Text("Automatically backup your data to iCloud")
                        .subtitleStyle()
                }
                
                Section {
                    Picker("Data Retention", selection: $retentionPeriod) {
                        ForEach(retentionOptions, id: \.self) { days in
                            Text("\(days) days").tag(days)
                        }
                    }
                    .tint(Theme.primary)
                } footer: {
                    Text("Automatically delete notes older than the selected period")
                        .subtitleStyle()
                }
                
                Section {
                    Toggle("Anonymize Exported Data", isOn: $anonymizeExports)
                        .tint(Theme.primary)
                } footer: {
                    Text("Remove personal information when exporting data")
                        .subtitleStyle()
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete All Data")
                        }
                    }
                } footer: {
                    Text("This action cannot be undone")
                        .subtitleStyle()
                }
            }
        }
        .navigationTitle("Privacy & Security")
        .alert("Delete All Data", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("Are you sure you want to delete all your health data? This action cannot be undone.")
        }
    }
    
    private func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                 localizedReason: "Authenticate to enable biometric lock") { success, error in
                if !success {
                    DispatchQueue.main.async {
                        biometricLock = false
                    }
                }
            }
        } else {
            biometricLock = false
        }
    }
    
    private func deleteAllData() {
        // Implementation for data deletion
        HapticManager.shared.success()
    }
}

struct BackupSettingsView: View {
    @AppStorage("backupFrequency") private var backupFrequency = 24
    @AppStorage("backupWiFiOnly") private var backupWiFiOnly = true
    @State private var lastBackupDate: Date?
    @State private var backupInProgress = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            Form {
                Section {
                    Picker("Backup Frequency", selection: $backupFrequency) {
                        Text("Every 6 hours").tag(6)
                        Text("Every 12 hours").tag(12)
                        Text("Every 24 hours").tag(24)
                        Text("Every 48 hours").tag(48)
                    }
                    .tint(Theme.primary)
                    
                    Toggle("WiFi Only", isOn: $backupWiFiOnly)
                        .tint(Theme.primary)
                }
                
                Section {
                    if let date = lastBackupDate {
                        LabeledContent {
                            Text(date, style: .relative)
                                .foregroundColor(.secondary)
                        } label: {
                            Text("Last Backup")
                        }
                    }
                    
                    Button {
                        backupNow()
                    } label: {
                        if backupInProgress {
                            Label("Backing up...", systemImage: "arrow.clockwise.circle")
                        } else {
                            Text("Backup Now")
                        }
                    }
                    .disabled(backupInProgress)
                    .foregroundColor(Theme.primary)
                }
            }
        }
        .navigationTitle("Backup Settings")
    }
    
    private func backupNow() {
        backupInProgress = true
        HapticManager.shared.success()
        // Implementation for backup
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            lastBackupDate = Date()
            backupInProgress = false
        }
    }
} 
