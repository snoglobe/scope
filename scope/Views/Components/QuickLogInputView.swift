import SwiftUI

struct QuickLogInputView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataManager: HealthDataManager
    let type: QuickLogType
    let onSubmit: (Double) -> Void
    @State private var value = ""
    
    var isValid: Bool {
        Double(value) != nil
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: type.icon)
                        .font(.system(size: 48))
                        .foregroundColor(Color(hex: type.color) ?? Theme.primary)
                    
                    Text(type.name)
                        .titleStyle()
                }
                .padding(.top)
                
                // Input
                VStack(spacing: 8) {
                    TextField("Value", text: $value)
                        .transparentTextField()
                        .font(.system(size: 32, weight: .bold))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    if let unit = type.unit {
                        Text("Enter a value in \(unit)")
                            .subtitleStyle()
                    }
                }
                .cardStyle()
                
                Spacer()
                
                // Buttons
                HStack(spacing: 20) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(Theme.SecondaryButtonStyle())
                    
                    Button("Save") {
                        saveQuickLog()
                    }
                    .buttonStyle(Theme.PrimaryButtonStyle())
                    .disabled(!isValid)
                }
                .padding()
            }
            .padding()
            .background(Theme.backgroundGradient(for: colorScheme))
            .navigationBarHidden(true)
        }
    }
    
    private func saveQuickLog() {
        guard let value = Double(value) else { return }
        
        let entry = HealthNote.QuickLogEntry(
            id: UUID().uuidString,
            type: type.name,
            value: value,
            unit: type.unit
        )
        
        // Create a new note with just the quick log entry
        let note = HealthNote(
            quickLogData: [entry],
            tags: [type.name]
        )
        
        dataManager.addNote(note)
        HapticManager.shared.success()
        
        onSubmit(value)
        dismiss()
    }
} 
