import SwiftUI

struct QuickLogTypeEditorView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: HealthDataManager
    
    let type: QuickLogType?
    
    @State private var name: String = ""
    @State private var unit: String = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = Color.accentColor
    
    init(type: QuickLogType? = nil) {
        self.type = type
        _name = State(initialValue: type?.name ?? "")
        _unit = State(initialValue: type?.unit ?? "")
        _selectedIcon = State(initialValue: type?.icon ?? "star.fill")
        _selectedColor = State(initialValue: Color(hex: type?.color ?? "#000000") ?? .accentColor)
    }
    
    let icons = [
        "star.fill", "heart.fill", "flame.fill", "bolt.fill",
        "drop.fill", "pills.fill", "cross.fill", "waveform.path.ecg",
        "face.smiling", "moon.fill", "sun.max.fill", "thermometer",
        "brain.head.profile", "lungs.fill", "bed.double.fill"
    ]
    
    var isValid: Bool {
        !name.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: $name)
                    TextField("Unit (optional)", text: $unit)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? selectedColor : .gray)
                                    .padding(8)
                                    .background(selectedIcon == icon ? selectedColor.opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .id(icon)
                        }
                    }
                }
                
                Section("Color") {
                    ColorPicker("Select Color", selection: $selectedColor)
                }
            }
            .navigationTitle(type == nil ? "New Quick Log" : "Edit Quick Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(Theme.SecondaryButtonStyle())
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(type == nil ? "Add" : "Save") {
                        saveQuickLogType()
                    }
                    .buttonStyle(Theme.PrimaryButtonStyle())
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func saveQuickLogType() {
        let id = if let type {
            UUID(uuidString: type.id)!
        } else { UUID() }
        let quickLogType = QuickLogType(
            id: id,
            name: name,
            unit: unit.isEmpty ? nil : unit,
            icon: selectedIcon,
            color: selectedColor.toHex() ?? "#000000"
        )
        
        if let type = type,
           let index = dataManager.quickLogTypes.firstIndex(where: { $0.id == type.id }) {
            dataManager.quickLogTypes[index] = quickLogType
        } else {
            dataManager.quickLogTypes.append(quickLogType)
        }
        
        dataManager.saveData()
        HapticManager.shared.success()
        dismiss()
    }
}

extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
} 
