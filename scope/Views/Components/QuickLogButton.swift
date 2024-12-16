import SwiftUI

struct QuickLogButton: View {
    let type: QuickLogType
    var onEntry: ((HealthNote.QuickLogEntry) -> Void)? = nil
    @State private var showingInput = false
    
    var body: some View {
        Button {
            showingInput = true
        } label: {
            VStack {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: type.color) ?? .accentColor)
                    .padding()
                Text(type.name)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .cornerRadius(12)
        }
        .sheet(isPresented: $showingInput) {
            QuickLogInputView(type: type) { value in
                let entry = HealthNote.QuickLogEntry(
                    id: UUID().uuidString,
                    type: type.name,
                    value: value,
                    unit: type.unit
                )
                onEntry?(entry)
                showingInput = false
            }
        }
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
} 
