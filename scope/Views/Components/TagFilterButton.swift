import SwiftUI

struct TagFilterButton: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
        }) {
            Text(tag)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Theme.primary : Color(.systemGray6).opacity(0.25))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .frame(height: 32)
    }
} 
