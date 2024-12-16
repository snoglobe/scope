import SwiftUI

struct GlobalSearchView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataManager: HealthDataManager
    @State private var searchText = ""
    @State private var selectedFilter: SearchFilter = .all
    
    enum SearchFilter {
        case all, notes, quickLogs
        
        var title: String {
            switch self {
            case .all: return "All"
            case .notes: return "Notes"
            case .quickLogs: return "Quick Logs"
            }
        }
    }
    
    var filteredResults: [SearchResult] {
        let query = searchText.lowercased()
        if query.isEmpty { return [] }
        
        var results: [SearchResult] = []
        
        switch selectedFilter {
        case .all:
            results += searchNotes(query)
            results += searchQuickLogs(query)
        case .notes:
            results += searchNotes(query)
        case .quickLogs:
            results += searchQuickLogs(query)
        }
        
        return results.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach([SearchFilter.all, .notes, .quickLogs], id: \.self) { filter in
                                Button {
                                    selectedFilter = filter
                                } label: {
                                    Text(filter.title)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedFilter == filter ? 
                                                  Theme.primary : Color(.systemGray6))
                                        .foregroundColor(selectedFilter == filter ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemBackground))
                    
                    // Results List
                    if filteredResults.isEmpty && !searchText.isEmpty {
                        NoResultsView()
                    } else {
                        List {
                            ForEach(filteredResults) { result in
                                SearchResultRow(result: result)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search your health journal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func searchNotes(_ query: String) -> [SearchResult] {
        return dataManager.notes
            .filter { note in
                note.content.localizedCaseInsensitiveContains(query) ||
                note.tags.contains { $0.localizedCaseInsensitiveContains(query) }
            }
            .map { note in
                SearchResult(
                    id: UUID(uuidString: note.id)!,
                    type: .note,
                    title: note.content.prefix(50).description,
                    subtitle: note.tags.joined(separator: ", "),
                    date: note.timestamp,
                    note: note
                )
            }
    }
    
    private func searchQuickLogs(_ query: String) -> [SearchResult] {
        return dataManager.notes
            .flatMap { note in
                note.quickLogData
                    .filter { $0.type.localizedCaseInsensitiveContains(query) }
                    .map { entry in
                        SearchResult(
                            id: UUID(uuidString: note.id)!,
                            type: .quickLog,
                            title: entry.type,
                            subtitle: "\(entry.value) \(entry.unit ?? "")",
                            date: note.timestamp,
                            note: note
                        )
                    }
            }
    }
}

struct SearchResult: Identifiable {
    let id: UUID
    let type: ResultType
    let title: String
    let subtitle: String
    let date: Date
    let note: HealthNote
    
    enum ResultType {
        case note, medication, quickLog
        
        var icon: String {
            switch self {
            case .note: return "note.text"
            case .medication: return "pills"
            case .quickLog: return "list.bullet"
            }
        }
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    
    var body: some View {
        NavigationLink(destination: NoteDetailView(note: result.note)) {
            HStack(spacing: 12) {
                Image(systemName: result.type.icon)
                    .foregroundColor(Theme.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .lineLimit(1)
                    
                    HStack {
                        Text(result.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(result.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(Color(.systemBackground))
    }
}

struct NoResultsView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(Theme.primary)
            
            Text("No Results Found")
                .titleStyle()
            
            Text("Try adjusting your search or filters")
                .subtitleStyle()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
} 
