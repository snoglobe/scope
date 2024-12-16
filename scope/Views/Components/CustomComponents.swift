import SwiftUI

// MARK: - Loading Views
struct LoadingView: View {
    let message: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Theme.primary)
            Text(message)
                .titleStyle()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.backgroundGradient(for: colorScheme))
    }
}

// MARK: - Empty State Views
struct NoDataView: View {
    let message: String
    let icon: String
    
    init(message: String, icon: String = "chart.bar.xaxis") {
        self.message = message
        self.icon = icon
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Theme.primary)
            
            Text("No Data Available")
                .titleStyle()
                .multilineTextAlignment(.center)
            
            Text(message)
                .subtitleStyle()
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        // .cardStyle()
    }
}

// MARK: - Progress Views
struct CircularProgressView: View {
    let progress: Double
    let color: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                
                VStack {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(subtitle)
                        .font(.title2)
                        .bold()
                }
            }
            .frame(width: 120, height: 120)
        }
        .cardStyle()
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        return computeSize(rows: rows, proposal: proposal)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        placeRows(rows, in: bounds)
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        var rows: [[LayoutSubviews.Element]] = [[]]
        var currentRow = 0
        var remainingWidth = proposal.width ?? 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentRow == 0 || size.width <= remainingWidth {
                rows[currentRow].append(subview)
                remainingWidth -= size.width + spacing
            } else {
                currentRow += 1
                rows.append([subview])
                remainingWidth = (proposal.width ?? 0) - size.width - spacing
            }
        }
        
        return rows
    }
    
    private func computeSize(rows: [[LayoutSubviews.Element]], proposal: ProposedViewSize) -> CGSize {
        var height: CGFloat = 0
        var maxWidth: CGFloat = 0
        
        for row in rows {
            var rowWidth: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                rowWidth += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
            
            maxWidth = max(maxWidth, rowWidth)
            height += rowHeight + spacing
        }
        
        return CGSize(width: maxWidth - spacing, height: height - spacing)
    }
    
    private func placeRows(_ rows: [[LayoutSubviews.Element]], in bounds: CGRect) {
        var y = bounds.minY
        
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            
            y += rowHeight + spacing
        }
    }
}

// MARK: - Buttons
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
        }
        .buttonStyle(Theme.PrimaryButtonStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
        }
        .buttonStyle(Theme.SecondaryButtonStyle())
    }
}

// MARK: - Cards
struct InfoCard<Content: View>: View {
    let title: String
    let icon: String?
    let content: Content
    
    @Environment(\.colorScheme) var colorScheme
    
    init(title: String, icon: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(Theme.primary)
                }
                Text(title)
                    .font(.title2)
                    .bold()
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 1)
            }
            content
        }
        .cardStyle()
    }
}

// MARK: - Charts
struct ChartLegend: View {
    let items: [(String, Color)]
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(items, id: \.0) { item in
                HStack(spacing: 4) {
                    Circle()
                        .fill(item.1)
                        .frame(width: 8, height: 8)
                    Text(item.0)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
} 
