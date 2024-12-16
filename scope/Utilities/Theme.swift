import SwiftUI

enum Theme {
    // Colors
    static let primary = Color(hex: "#d43fd1")!
    static let secondary = Color(hex: "#e860f7")!
    static let accent = Color(hex: "#7c60f7")!
    static let success = Color(hex: "#60f763")!
    static let warning = Color(hex: "#f7e860")!
    static let error = Color(hex: "#f76860")!
    
    @ViewBuilder
    static func backgroundGradient(for colorScheme: ColorScheme) -> some View {
        LinearGradient(
            colors: colorScheme == .dark ? 
                [Color(hex: "#7b219c")!, Color(hex: "#390a4a")!] :
                [Color(hex: "#e5beed")!, Color(hex: "#dc85ed")!],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // Card Styles
    struct CardStyle: ViewModifier {
        @Environment(\.colorScheme) var colorScheme
        
        func body(content: Content) -> some View {
            content
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(colorScheme == .dark ? .systemGray6 : .systemBackground).opacity(0.1))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                )
        }
    }
    
    // Button Styles
    struct PrimaryButtonStyle: ButtonStyle {
        @Environment(\.colorScheme) var colorScheme
        @Environment(\.isEnabled) var isEnabled
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .foregroundColor(isEnabled ?
                                    (colorScheme == .dark
                                    ? Color.white.opacity(configuration.isPressed ? 0.8 : 1)
                                    : Color.black.opacity(configuration.isPressed ? 0.8 : 1))
                                 : Color.gray)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
        }
    }
    
    struct SecondaryButtonStyle: ButtonStyle {
        @Environment(\.isEnabled) var isEnabled
        @Environment(\.colorScheme) var colorScheme
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .foregroundColor(isEnabled ?
                                    (colorScheme == .dark
                                    ? Color.white.opacity(configuration.isPressed ? 0.8 : 1)
                                    : Color.black.opacity(configuration.isPressed ? 0.8 : 1))
                                 : Color.gray)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
        }
    }
    
    // Text Styles
    struct TitleStyle: ViewModifier {
        @Environment(\.colorScheme) var colorScheme
        
        func body(content: Content) -> some View {
            content
                .font(.title2)
                .bold()
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 1)
        }
    }
    
    struct TitleStyleLeading: ViewModifier {
        @Environment(\.colorScheme) var colorScheme
        
        func body(content: Content) -> some View {
            content
                .font(.title2)
                .bold()
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 1)
        }
    }
    
    struct SubtitleStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    struct SubtitleStyleLeading: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // Chart Styles
    struct ChartStyle: ViewModifier {
        @Environment(\.colorScheme) var colorScheme
        
        func body(content: Content) -> some View {
            content
                .frame(height: 200)
                .padding()
                .background(Color(colorScheme == .dark ? .systemGray6 : .systemBackground))
                .cornerRadius(12)
        }
    }
    
    // Text Field Style
    struct TransparentTextFieldStyle: TextFieldStyle {
        func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .textFieldStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
        }
    }
}

// View Extensions
extension View {
    func cardStyle() -> some View {
        modifier(Theme.CardStyle())
    }
    
    func titleStyle() -> some View {
        modifier(Theme.TitleStyle())
    }
    
    func titleStyleLeading() -> some View {
        modifier(Theme.TitleStyleLeading())
    }
    
    func subtitleStyle() -> some View {
        modifier(Theme.SubtitleStyle())
    }
    
    func subtitleStyleLeading() -> some View {
        modifier(Theme.SubtitleStyleLeading())
    }
    
    func chartStyle() -> some View {
        modifier(Theme.ChartStyle())
    }
    
    func transparentTextField() -> some View {
        self.textFieldStyle(Theme.TransparentTextFieldStyle())
    }
} 
