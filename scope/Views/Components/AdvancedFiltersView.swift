import SwiftUI

struct AdvancedFiltersView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataManager: HealthDataManager
    @Binding var selectedTags: Set<String>
    @State private var searchText = ""
    
    var filteredTags: [String] {
        let allTags = Array(Set(dataManager.notes.flatMap { $0.tags }))
        if searchText.isEmpty {
            return allTags.sorted()
        }
        return allTags.filter { $0.localizedCaseInsensitiveContains(searchText) }.sorted()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    SearchBar(text: $searchText)
                        .padding()
                    
                    // Tags List
                    List {
                        ForEach(filteredTags, id: \.self) { tag in
                            TagRow(
                                tag: tag,
                                isSelected: selectedTags.contains(tag),
                                onToggle: {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                }
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Filter by Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(Theme.PrimaryButtonStyle())
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear All") {
                        selectedTags.removeAll()
                    }
                    .disabled(selectedTags.isEmpty)
                    .buttonStyle(Theme.SecondaryButtonStyle())
                }
            }
        }
    }
}

struct TagRow: View {
    let tag: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Text(tag)
                .foregroundColor(.primary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(Theme.primary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                onToggle()
            }
        }
        .listRowBackground(Color(.systemBackground))
        .animation(nil, value: isSelected)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search tags", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
} 
