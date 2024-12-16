import SwiftUI

struct AboutView: View {
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            List {
                Section {
                    VStack(spacing: 12) {
                        Image("AppIcon")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .cornerRadius(20)
                        
                        Text("Health Journal")
                            .titleStyle()
                        
                        Text("Version \(appVersion) (\(buildNumber))")
                            .subtitleStyle()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                
                Section("Features") {
                    FeatureRow(icon: "note.text", title: "Health Notes", description: "Track your health journey with detailed notes")
                    FeatureRow(icon: "chart.bar", title: "Analytics", description: "Visualize your health trends and patterns")
                    FeatureRow(icon: "brain", title: "AI Analysis", description: "Get insights from your health data using AI")
                    FeatureRow(icon: "heart", title: "HealthKit", description: "Integrate with Apple Health data")
                }
                
                Section("Support") {
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "lock.shield")
                            .foregroundColor(Theme.primary)
                    }
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                            .foregroundColor(Theme.primary)
                    }
                    
                    Link(destination: URL(string: "mailto:support@example.com")!) {
                        Label("Contact Support", systemImage: "envelope")
                            .foregroundColor(Theme.primary)
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        Text("Made with ❤️ by Your Team")
                            .subtitleStyle()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("About")
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.primary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .subtitleStyle()
            }
        }
        .padding(.vertical, 8)
    }
} 
