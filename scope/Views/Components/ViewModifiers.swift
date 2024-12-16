import SwiftUI

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

struct SlideInModifier: ViewModifier {
    let edge: Edge
    @State private var offset: CGFloat = 100
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: edge == .leading ? offset : (edge == .trailing ? -offset : 0),
                   y: edge == .top ? offset : (edge == .bottom ? -offset : 0))
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring()) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}

extension View {
    func shake(animatableData: CGFloat) -> some View {
        modifier(ShakeEffect(animatableData: animatableData))
    }
    
    func slideIn(from edge: Edge) -> some View {
        modifier(SlideInModifier(edge: edge))
    }
}

struct GlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(12)
    }
}

extension View {
    func glassBackground() -> some View {
        modifier(GlassBackground())
    }
} 
