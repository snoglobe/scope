import SwiftUI

struct RecentNotesSection: View {
    @EnvironmentObject var dataManager: HealthDataManager
    
    var recentNotes: [HealthNote] {
        Array(dataManager.notes.prefix(5))
            .sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Notes")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                NavigationLink {
                    JournalView()
                } label: {
                    Text("See All")
                        .font(.subheadline)
                }
            }
            
            if recentNotes.isEmpty {
                NoteEmptyStateView()
            } else {
                ForEach(recentNotes) { note in
                    RecentNoteCard(note: note)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct RecentNoteCard: View {
    let note: HealthNote
    
    var body: some View {
        NavigationLink(destination: NoteDetailView(note: note)) {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Text(note.timestamp, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if !note.tags.isEmpty {
                        Text(note.tags.first ?? "")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                // Content Preview
                if !note.content.isEmpty {
                    Text(note.content)
                        .lineLimit(2)
                        .font(.body)
                }
                
                // Metadata Icons
                HStack(spacing: 12) {
                    if !note.images.isEmpty {
                        Label("\(note.images.count)", systemImage: "photo")
                    }
                    
                    if !note.quickLogData.isEmpty {
                        Label("\(note.quickLogData.count)", systemImage: "list.bullet")
                    }
                    
                    if note.analysisResults != nil {
                        Label("AI Analysis", systemImage: "brain")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}
