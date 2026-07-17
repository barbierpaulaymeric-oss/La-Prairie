import JardinCore
import SwiftUI

public struct TagChipsView: View {
    let tags: [String]

    public init(tags: [String]) {
        self.tags = tags
    }

    public var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text("#\(tag)")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.accentContainer, in: Capsule())
                    .foregroundStyle(Theme.onAccentContainer)
            }
        }
    }
}

/// Sélecteur de tags avec presets et saisie libre.
public struct TagPickerView: View {
    @Binding var selection: [String]
    @State private var customTag = ""

    public init(selection: Binding<[String]>) {
        _selection = selection
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FlowLayout(spacing: 6) {
                ForEach(ObservationTags.presets + selection.filter { !ObservationTags.presets.contains($0) },
                        id: \.self) { tag in
                    let isOn = selection.contains(tag)
                    Button {
                        if isOn { selection.removeAll { $0 == tag } } else { selection.append(tag) }
                    } label: {
                        Text("#\(tag)")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(isOn ? Theme.accent : Theme.accentContainer, in: Capsule())
                            .foregroundStyle(isOn ? .white : Theme.onAccentContainer)
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                TextField("Nouveau tag…", text: $customTag)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addCustomTag)
                Button("Ajouter", action: addCustomTag)
                    .disabled(customTag.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func addCustomTag() {
        let tag = customTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !tag.isEmpty, !selection.contains(tag) else { return }
        selection.append(tag)
        customTag = ""
    }
}

/// Disposition en lignes qui replient (pour les chips).
public struct FlowLayout: Layout {
    let spacing: CGFloat

    public init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in arrangement.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                                  proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, x - spacing)
        }
        return (CGSize(width: totalWidth, height: y + rowHeight), positions)
    }
}

public struct ConfidenceBar: View {
    let value: Double

    public init(value: Double) {
        self.value = value
    }

    public var body: some View {
        HStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.accent.opacity(0.15))
                    Capsule()
                        .fill(Theme.confidenceColor(value))
                        .frame(width: geo.size.width * value)
                }
            }
            .frame(height: 7)
            Text("\(Int(value * 100)) %")
                .font(Theme.dataS)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 42, alignment: .trailing)
        }
    }
}

public struct HealthBadge: View {
    let score: Double

    public init(score: Double) {
        self.score = score
    }

    public var body: some View {
        Label(score < 0 ? "—" : "\(Int(score * 100)) %",
              systemImage: score < 0 ? "questionmark.circle" : (score >= 0.75 ? "leaf.fill" : "exclamationmark.triangle.fill"))
            .font(Theme.dataS)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.healthColor(score).opacity(0.15), in: Capsule())
            .foregroundStyle(Theme.healthColor(score))
            .accessibilityLabel(score < 0 ? "Santé inconnue" : "Score de santé \(Int(score * 100)) pour cent")
    }
}

public struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    public init(systemImage: String, title: String, message: String) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
    }

    public var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        }
    }
}

/// Affiche une photo stockée (Data JPEG) sans retenir l'image décodée plus que nécessaire.
public struct StoredPhotoView: View {
    let data: Data?
    var cornerRadius: CGFloat = 10

    public init(data: Data?, cornerRadius: CGFloat = 10) {
        self.data = data
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        if let data, let image = ImageUtils.platformImage(from: data) {
            platformImage(image)
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Theme.subtleBackground)
                .overlay(Image(systemName: "leaf").foregroundStyle(Theme.secondaryTint.opacity(0.5)))
        }
    }

    private func platformImage(_ image: PlatformImage) -> Image {
        #if canImport(UIKit)
        return Image(uiImage: image)
        #else
        return Image(nsImage: image)
        #endif
    }
}

public extension View {
    func cardStyle() -> some View {
        padding(Theme.Metrics.cardPadding)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius))
            .shadow(color: .black.opacity(0.10), radius: 3, y: 1)
    }
}

/// En-tête de section du design system : capitales, chasse élargie, action à droite.
public struct SectionHeaderView: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    public init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.footnote.weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(Theme.textTertiary)
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}
