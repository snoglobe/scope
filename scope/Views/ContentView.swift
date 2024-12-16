import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: HealthDataManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var selectedTab = 0
    @State private var showingNewNote = false
    @State private var showingSearch = false
    @AppStorage("biometricLock") private var biometricLock = false
    @State private var isUnlocked = false
    @State private var isLoading = true
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            Group {
                if isLoading {
                    LoadingView(message: "Loading your health data...")
                } else if biometricLock && !isUnlocked {
                    LockScreenView(isUnlocked: $isUnlocked)
                } else {
                    mainInterface
                }
            }
        }
        .onAppear {
            Task {
                await healthKitManager.requestAuthorization()
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                isLoading = false
            }
        }
    }
    
    var mainInterface: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
                    .navigationTitle("Health Journal")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingSearch = true
                            } label: {
                                Image(systemName: "magnifyingglass")
                            }
                            .buttonStyle(Theme.SecondaryButtonStyle())
                            .padding(.top, 5)
                        }
                    }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            NavigationStack {
                JournalView()
            }
            .tabItem {
                Label("Journal", systemImage: "book.fill")
            }
            .tag(1)
            
            NavigationStack {
                ChatView()
            }
            .tabItem {
                Label("Chat", systemImage: "message.fill")
            }
            .tag(2)
            
            NavigationStack {
                AnalyticsView()
            }
            .tabItem {
                Label("Analytics", systemImage: "chart.bar.fill")
            }
            .tag(3)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(4)
        }
        .sheet(isPresented: $showingNewNote) {
            NewNoteView()
        }
        .sheet(isPresented: $showingSearch) {
            GlobalSearchView()
        }
        .tint(Theme.primary)
    }
}

struct LockScreenView: View {
    @Binding var isUnlocked: Bool
    @State private var showingBiometricPrompt = true
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 64))
                .foregroundColor(Theme.primary)
            
            Text("Health Journal")
                .titleStyle()
            
            Button {
                authenticate()
            } label: {
                Label("Unlock with Face ID", systemImage: "faceid")
            }
            .buttonStyle(Theme.PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.backgroundGradient(for: colorScheme))
        .onAppear {
            if showingBiometricPrompt {
                authenticate()
            }
        }
    }
    
    private func authenticate() {
        Task {
            do {
                isUnlocked = try await BiometricAuth.shared.authenticate()
            } catch {
                print("Authentication failed: \(error)")
            }
        }
    }
}

struct QuickActionsView: View {
    @EnvironmentObject var dataManager: HealthDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.title2)
                .bold()
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100))
            ], spacing: 12) {
                ForEach(dataManager.quickLogTypes) { type in
                    QuickLogButton(type: type)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct HealthSummaryView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var healthData: [HealthNote.HealthKitDataPoint] = []
    
    var body: some View {
        if healthData.isEmpty {
            Text("No health data available")
                .foregroundColor(.secondary)
                .onAppear {
                    healthKitManager.fetchRecentData { data in
                        healthData = data
                    }
                }
        } else {
            ForEach(healthData) { dataPoint in
                HealthMetricRow(dataPoint: dataPoint)
            }
            .onAppear {
                healthKitManager.fetchRecentData { data in
                    healthData = data
                }
            }
        }
    }
}

struct HealthMetricRow: View {
    let dataPoint: HealthNote.HealthKitDataPoint
    
    var body: some View {
        HStack {
            Text(dataPoint.type.replacingOccurrences(of: "HKQuantityTypeIdentifier", with: ""))
                .font(.headline)
            Spacer()
            Text("\(dataPoint.value, specifier: "%.1f") \(dataPoint.unit)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
