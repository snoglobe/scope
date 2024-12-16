import SwiftUI
import Charts

struct JournalView: View {
    @EnvironmentObject var dataManager: HealthDataManager
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    @State private var selectedTags: Set<String> = []
    @State private var timeFilter: TimeFilter = .all
    @State private var showingNewNote = false
    @State private var showingFilters = false
    @State private var sortOrder: SortOrder = .newest
    
    enum TimeFilter: String, CaseIterable {
        case all = "All Time"
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case year = "This Year"
    }
    
    enum SortOrder {
        case newest, oldest
        
        var title: String {
            switch self {
            case .newest: return "Newest First"
            case .oldest: return "Oldest First"
            }
        }
    }
    
    var filteredNotes: [HealthNote] {
        var notes = dataManager.notes
        
        // Apply search filter
        if !searchText.isEmpty {
            notes = notes.filter { note in
                note.content.localizedCaseInsensitiveContains(searchText) ||
                note.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply tag filter
        if !selectedTags.isEmpty {
            notes = notes.filter { !$0.tags.isDisjoint(with: selectedTags) }
        }
        
        // Apply time filter
        let calendar = Calendar.current
        notes = notes.filter { note in
            switch timeFilter {
            case .all:
                return true
            case .today:
                return calendar.isDateInToday(note.timestamp)
            case .week:
                return calendar.isDate(note.timestamp, equalTo: Date(), toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(note.timestamp, equalTo: Date(), toGranularity: .month)
            case .year:
                return calendar.isDate(note.timestamp, equalTo: Date(), toGranularity: .year)
            }
        }
        
        // Apply sort order
        return notes.sorted { first, second in
            switch sortOrder {
            case .newest: return first.timestamp > second.timestamp
            case .oldest: return first.timestamp < second.timestamp
            }
        }
    }
    
    var groupedNotes: [(String, [HealthNote])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        return Dictionary(grouping: filteredNotes) { note in
            formatter.string(from: note.timestamp)
        }
        .sorted { first, second in
            switch sortOrder {
            case .newest:
                return first.key > second.key
            case .oldest:
                return first.key < second.key
            }
        }
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Filter Bar - Always at top
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Menu {
                            Picker("Time Filter", selection: $timeFilter) {
                                ForEach(TimeFilter.allCases, id: \.self) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                        } label: {
                            HStack {
                                Text(timeFilter.rawValue)
                                Image(systemName: "chevron.down")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        ForEach(Array(getAllTags()), id: \.self) { tag in
                            TagFilterButton(
                                tag: tag,
                                isSelected: selectedTags.contains(tag),
                                action: {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .scrollContentBackground(.hidden)
                
                // Content Area
                if filteredNotes.isEmpty {
                    VStack {
                        Spacer()
                        NoDataView(message: "No notes match your filters")
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(groupedNotes, id: \.0) { date, notes in
                            Section(date) {
                                ForEach(notes) { note in
                                    NavigationLink(destination: NoteDetailView(note: note)) {
                                        JournalNoteRow(note: note)
                                            .cardStyle()
                                    }
                                    .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                                }
                                .onDelete { indexSet in
                                    deleteNotes(at: indexSet, in: notes)
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Journal")
        .searchable(text: $searchText, prompt: "Search notes")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Sort Order", selection: $sortOrder) {
                        Text("Newest First").tag(SortOrder.newest)
                        Text("Oldest First").tag(SortOrder.oldest)
                    }
                    
                    Button {
                        showingFilters = true
                    } label: {
                        Label("Advanced Filters", systemImage: "line.3.horizontal.decrease.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .padding(.top, 2.5)
                        .foregroundColor(colorScheme == .dark
                                          ? Color.white
                                          : Color.black)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingNewNote = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .buttonStyle(Theme.PrimaryButtonStyle())
            }
        }
        .sheet(isPresented: $showingNewNote) {
            NewNoteView()
        }
        .sheet(isPresented: $showingFilters) {
            AdvancedFiltersView(selectedTags: $selectedTags)
        }
    }
    
    private func getAllTags() -> [String] {
        Array(Set(dataManager.notes.flatMap { $0.tags })).sorted()
    }
    
    private func deleteNotes(at indexSet: IndexSet, in notes: [HealthNote]) {
        for index in indexSet {
            if let noteIndex = dataManager.notes.firstIndex(where: { $0.id == notes[index].id }) {
                dataManager.notes.remove(at: noteIndex)
            }
        }
    }
}

struct JournalNoteRow: View {
    let note: HealthNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Content Preview
            if !note.content.isEmpty {
                Text(note.content)
                    .lineLimit(2)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            // Metadata Row
            HStack(alignment: .center) {
                // Timestamp
                Text(note.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Attachments
                if !note.images.isEmpty || !note.quickLogData.isEmpty {
                    HStack(spacing: 8) {
                        if !note.images.isEmpty {
                            Label("\(note.images.count)", systemImage: "photo")
                        }
                        
                        if !note.quickLogData.isEmpty {
                            Label("\(note.quickLogData.count)", systemImage: "list.bullet")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Tags
                if !note.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(Array(note.tags.prefix(2)), id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.primary.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        if note.tags.count > 2 {
                            Text("+\(note.tags.count - 2)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
} 

