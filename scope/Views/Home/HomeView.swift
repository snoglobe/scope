import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataManager: HealthDataManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showingNewNote = false
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Actions
                    InfoCard(title: "Quick Actions", icon: "bolt.fill") {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 100))
                        ], spacing: 12) {
                            ForEach(dataManager.quickLogTypes) { type in
                                QuickLogButton(type: type)
                            }
                        }
                    }
                    
                    // Recent Notes
                    InfoCard(title: "Recent Notes", icon: "note.text") {
                        if dataManager.notes.isEmpty {
                            NoteEmptyStateView()
                        } else {
                            ForEach(Array(dataManager.notes.prefix(5))) { note in
                                RecentNoteCard(note: note)
                                    .padding(.bottom, 8)
                            }
                            
                            NavigationLink {
                                JournalView()
                            } label: {
                                Text("See All Notes")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.primary)
                            }
                        }
                    }
                    
                    // Health Summary
                    InfoCard(title: "Health Summary", icon: "heart.text.square") {
                        HealthSummaryView()
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Scope")
        .toolbar {
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
    }
}

struct NoteEmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundColor(Theme.primary)
            
            Text("No Notes Yet")
                .titleStyle()
            
            Text("Start by adding your first health note")
                .subtitleStyle()
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
