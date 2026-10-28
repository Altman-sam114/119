import SwiftUI
import ImageIO

/// Resource lookup and bounded decoding are shared; caches remain catalog-owned.
/// Only the macOS cloud renderer can opt into a source directory.
enum BattleArtworkLoader {
    static let resourceSubdirectory = "BattleUnitArt"

    static func resourceURL(named name: String) -> URL? {
        if let bundled = Bundle.main.url(
            forResource: name, withExtension: "png", subdirectory: resourceSubdirectory
        ) {
            return bundled
        }
        #if os(macOS)
        if let directory = ProcessInfo.processInfo.environment["ROMELEGIONS_ART_ROOT"], !directory.isEmpty {
            return URL(fileURLWithPath: directory, isDirectory: true)
                .appendingPathComponent(name).appendingPathExtension("png")
        }
        #endif
        return nil
    }

    static func decode(named name: String, maximumSize: Int) -> CGImage? {
        guard let url = resourceURL(named: name),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumSize,
            kCGImageSourceShouldCacheImmediately: true
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}

enum BattleUnitArtwork {
    static let maximumDecodeSize = 384

    static func resourceURL(for kind: UnitKind) -> URL? {
        BattleArtworkLoader.resourceURL(named: kind.rawValue)
    }

    private static let images: [String: CGImage] = {
        var result: [String: CGImage] = [:]
        for kind in UnitKind.allCases {
            guard let image = BattleArtworkLoader.decode(named: kind.rawValue, maximumSize: maximumDecodeSize) else { continue }
            result[kind.rawValue] = image
        }
        return result
    }()

    static func image(for kind: UnitKind) -> CGImage? {
        images[kind.rawValue]
    }
}

enum BattleSceneryKind: String, CaseIterable, Hashable {
    case ground, water, city, forest, hills

    var isSurface: Bool { self == .ground || self == .water }
    var maximumDecodeSize: Int { isSurface ? 768 : 384 }
}

enum BattleSceneryArtwork {
    private static let images: [BattleSceneryKind: CGImage] = {
        var result: [BattleSceneryKind: CGImage] = [:]
        for kind in BattleSceneryKind.allCases {
            result[kind] = BattleArtworkLoader.decode(named: kind.rawValue, maximumSize: kind.maximumDecodeSize)
        }
        return result
    }()

    static func image(for kind: BattleSceneryKind) -> CGImage? { images[kind] }
}

enum UnitTokenPresentation: Equatable {
    case map
    case compact
    case inspection

    var artSize: CGSize {
        switch self {
        case .map: return CGSize(width: 54, height: 46)
        case .compact: return CGSize(width: 40, height: 31)
        case .inspection: return CGSize(width: 86, height: 68)
        }
    }

    var strengthWidth: CGFloat {
        switch self {
        case .map: return 42
        case .compact: return 36
        case .inspection: return 58
        }
    }

    var strengthHeight: CGFloat { self == .inspection ? 8 : 6 }
}

enum BattleMapChromeMetrics {
    static func intelligenceHeight(isNarrow: Bool) -> CGFloat { isNarrow ? 78 : 56 }
    static func bottomClearance(isNarrow: Bool) -> CGFloat {
        intelligenceHeight(isNarrow: isNarrow) + 20
    }
}

/// Shared Roman command-deck palette. Keeping chrome colors in one place makes
/// the map, drawers and order dock feel like one instrument panel while the
/// ViewModel remains the only source of game state.
enum BattlePalette {
    static let canvas = Color(red: 0.055, green: 0.062, blue: 0.064)
    static let panel = Color(red: 0.105, green: 0.098, blue: 0.086)
    static let panelRaised = Color(red: 0.155, green: 0.135, blue: 0.105)
    static let parchment = Color(red: 0.78, green: 0.73, blue: 0.58)
    static let mapMist = Color(red: 0.72, green: 0.78, blue: 0.66)
    static let brass = Color(red: 0.84, green: 0.66, blue: 0.32)
    static let brassBright = Color(red: 0.96, green: 0.78, blue: 0.40)
    static let brassDim = Color(red: 0.52, green: 0.38, blue: 0.18)
    static let ivory = Color(red: 0.96, green: 0.93, blue: 0.84)
    static let muted = Color(red: 0.68, green: 0.66, blue: 0.60)
    static let danger = Color(red: 0.78, green: 0.16, blue: 0.12)
    static let signal = Color(red: 0.24, green: 0.76, blue: 0.72)
    static let romanRed = Color(red: 0.56, green: 0.10, blue: 0.08)
}

struct CommandButtonLabel: View {
    var symbol: String
    var text: String
    var detail: String? = nil
    var textLineLimit: Int = 1

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(textLineLimit)
                    .minimumScaleFactor(textLineLimit > 1 ? 0.64 : 0.72)
                if let detail {
                    Text(detail)
                        .font(.caption2.monospacedDigit().weight(.bold))
                        .foregroundStyle(.white.opacity(0.76))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: detail == nil ? (textLineLimit > 1 ? 48 : 38) : (textLineLimit > 1 ? 64 : 50))
        .padding(.horizontal, 10)
    }
}

struct CommandIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? BattlePalette.brassBright : BattlePalette.ivory)
            .background(configuration.isPressed ? BattlePalette.brass.opacity(0.22) : .white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(BattlePalette.brass.opacity(configuration.isPressed ? 0.74 : 0.22), lineWidth: 1)
            }
    }
}

struct BattleMetalButtonStyle: ButtonStyle {
    var isSelected = false
    var diameter: CGFloat = 36

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color(red: 0.22, green: 0.23, blue: 0.18))
            .frame(width: diameter, height: diameter)
            .background {
                Circle()
                    .fill(LinearGradient(
                        colors: isSelected
                            ? [BattlePalette.brassBright, BattlePalette.brass, BattlePalette.brassDim]
                            : [BattlePalette.ivory, BattlePalette.parchment, Color(red: 0.43, green: 0.44, blue: 0.34)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
            }
            .clipShape(Circle())
            .overlay {
                Circle().stroke(Color(red: 0.27, green: 0.28, blue: 0.22), lineWidth: 1.5)
                Circle().stroke(BattlePalette.ivory.opacity(0.52), lineWidth: 0.7).padding(2.5)
            }
            .shadow(color: .black.opacity(0.30), radius: 2, y: 2)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(configuration.isPressed ? Color.red.opacity(0.72) : Color(red: 0.60, green: 0.10, blue: 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? BattlePalette.ivory : .white.opacity(0.86))
            .background(configuration.isPressed ? BattlePalette.brass.opacity(0.20) : .black.opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(BattlePalette.brass.opacity(configuration.isPressed ? 0.58 : 0.18), lineWidth: 1)
            }
    }
}

struct MapViewportState: Equatable {
    static let minimumScale: CGFloat = 1
    static let maximumScale: CGFloat = 1.8
    static let focusScale: CGFloat = 1.34

    private(set) var scale: CGFloat = minimumScale
    private(set) var offset: CGSize = .zero

    var isDefault: Bool {
        abs(scale - Self.minimumScale) < 0.001 &&
            abs(offset.width) < 0.001 &&
            abs(offset.height) < 0.001
    }

    mutating func setScale(_ proposedScale: CGFloat, in container: CGSize) {
        scale = min(Self.maximumScale, max(Self.minimumScale, proposedScale))
        offset = clampedOffset(offset, in: container)
    }

    mutating func pan(by translation: CGSize, in container: CGSize) {
        offset = clampedOffset(
            CGSize(
                width: offset.width + translation.width,
                height: offset.height + translation.height
            ),
            in: container
        )
    }

    mutating func focus(
        on point: CGPoint,
        in container: CGSize,
        viewportCenter: CGPoint? = nil
    ) {
        setScale(max(scale, Self.focusScale), in: container)
        let transformCenter = CGPoint(x: container.width / 2, y: container.height / 2)
        let destination = viewportCenter ?? transformCenter
        let proposedOffset = CGSize(
            width: destination.x - transformCenter.x - (point.x - transformCenter.x) * scale,
            height: destination.y - transformCenter.y - (point.y - transformCenter.y) * scale
        )
        offset = clampedOffset(proposedOffset, in: container)
    }

    mutating func reset() {
        scale = Self.minimumScale
        offset = .zero
    }

    func applying(
        magnification: CGFloat,
        translation: CGSize,
        in container: CGSize
    ) -> MapViewportState {
        var result = self
        result.setScale(scale * magnification, in: container)
        result.pan(by: translation, in: container)
        return result
    }

    func maximumOffset(in container: CGSize) -> CGSize {
        CGSize(
            width: max(0, container.width * (scale - 1) / 2),
            height: max(0, container.height * (scale - 1) / 2)
        )
    }

    private func clampedOffset(_ proposedOffset: CGSize, in container: CGSize) -> CGSize {
        let limit = maximumOffset(in: container)
        return CGSize(
            width: min(limit.width, max(-limit.width, proposedOffset.width)),
            height: min(limit.height, max(-limit.height, proposedOffset.height))
        )
    }
}

struct HexMetrics {
    let tileWidth: CGFloat
    let tileHeight: CGFloat
    let origin: CGPoint
    let actionScale: CGFloat
    let tileScale: CGFloat
    let mapSize: CGSize
    let tileAspect: CGFloat

    init(mapWidth: Int, mapHeight: Int, container: CGSize, topClearance: CGFloat = 0) {
        let horizontalUnits = CGFloat(mapWidth) + (mapHeight > 1 ? 0.5 : 0)
        let verticalUnits = CGFloat(max(0, mapHeight - 1)) * 0.75 + 1
        let isShortLandscape = container.width > container.height * 2
        let isLandscape = container.width > container.height

        let horizontalInset = min(18, max(8, container.width * 0.018))
        let topInset = max(topClearance, isLandscape ? 54 : 70)
        let bottomInset = BattleMapChromeMetrics.bottomClearance(isNarrow: container.width < 620)
        let availableWidth = max(1, container.width - horizontalInset * 2)
        let availableHeight = max(1, container.height - topInset - bottomInset)
        tileAspect = isShortLandscape ? 0.50 : (isLandscape ? 0.72 : 1.14)
        let widthBased = availableWidth / horizontalUnits
        let heightBased = availableHeight / (verticalUnits * tileAspect)
        let fittedTileWidth = min(widthBased, heightBased)

        tileWidth = max(18, min(82, fittedTileWidth))
        tileHeight = tileWidth * tileAspect
        tileScale = min(1.12, max(0.72, tileWidth / 44))
        actionScale = min(1.15, max(0.72, tileWidth / 54))

        let totalWidth = tileWidth * horizontalUnits
        let totalHeight = tileHeight * verticalUnits
        mapSize = CGSize(width: totalWidth, height: totalHeight)
        let remainingVerticalSpace = max(0, availableHeight - totalHeight)
        let verticalBias: CGFloat = container.height > container.width * 1.25 ? 0.38 : 0.46
        origin = CGPoint(
            x: horizontalInset + (availableWidth - totalWidth) / 2 + tileWidth / 2,
            y: topInset + remainingVerticalSpace * verticalBias + tileHeight / 2
        )
    }

    func center(for position: Position) -> CGPoint {
        // Match Position.neighbors: odd rows, not odd columns, shift half a hex.
        CGPoint(
            x: origin.x + (CGFloat(position.x) + (position.y.isMultiple(of: 2) ? 0 : 0.5)) * tileWidth,
            y: origin.y + CGFloat(position.y) * tileHeight * 0.75
        )
    }

    func vertices(for position: Position) -> [CGPoint] {
        let center = center(for: position)
        return Hexagon.vertices(in: CGRect(
            x: center.x - tileWidth / 2, y: center.y - tileHeight / 2,
            width: tileWidth, height: tileHeight
        ))
    }

    func sharedEdge(from first: Position, to second: Position) -> [CGPoint] {
        let otherVertices = vertices(for: second)
        return vertices(for: first).filter { vertex in
            otherVertices.contains { abs(vertex.x - $0.x) < 0.001 && abs(vertex.y - $0.y) < 0.001 }
        }
    }
}

struct Hexagon: Shape {
    static func vertices(in rect: CGRect) -> [CGPoint] {
        [
            CGPoint(x: rect.midX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.25),
            CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.25),
            CGPoint(x: rect.midX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.25),
            CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.25)
        ]
    }

    func path(in rect: CGRect) -> Path {
        let points = Self.vertices(in: rect)
        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

struct TrianglePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

extension Faction {
    var factionColor: Color {
        switch self {
        case .rome: return Color(red: 0.72, green: 0.08, blue: 0.07)
        case .carthage: return Color(red: 0.50, green: 0.20, blue: 0.72)
        case .gaul: return Color(red: 0.08, green: 0.42, blue: 0.22)
        case .egypt: return Color(red: 0.86, green: 0.63, blue: 0.16)
        case .neutral: return Color(red: 0.52, green: 0.52, blue: 0.48)
        }
    }
}

extension DiplomaticStatus {
    var statusColor: Color {
        switch self {
        case .war: return Color(red: 0.86, green: 0.24, blue: 0.18)
        case .truce: return Color(red: 0.84, green: 0.66, blue: 0.32)
        case .alliance: return Color(red: 0.24, green: 0.66, blue: 0.34)
        }
    }
}

extension UnitDevelopmentDecisionKind {
    var tintColor: Color {
        switch self {
        case .training:
            return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .appointment:
            return Color(red: 0.36, green: 0.86, blue: 0.92)
        }
    }
}

extension UnitDevelopmentRecommendationKind {
    var systemImage: String {
        switch self {
        case .training:
            return "figure.walk"
        case .appointment:
            return "person.crop.circle.badge.plus"
        }
    }
}

extension UnitDevelopmentRecommendationPriority {
    var tintColor: Color {
        switch self {
        case .low:
            return Color(red: 0.52, green: 0.70, blue: 0.86)
        case .medium:
            return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .high:
            return Color(red: 0.92, green: 0.42, blue: 0.14)
        case .urgent:
            return Color(red: 0.84, green: 0.16, blue: 0.12)
        }
    }
}

extension CampaignStatusKind {
    var systemImage: String {
        switch self {
        case .ongoing: return "flag.fill"
        case .romanVictory: return "checkmark.seal.fill"
        case .romanDefeat: return "exclamationmark.triangle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .ongoing: return Color(red: 0.84, green: 0.66, blue: 0.32)
        case .romanVictory: return Color(red: 0.24, green: 0.72, blue: 0.38)
        case .romanDefeat: return Color(red: 0.86, green: 0.24, blue: 0.18)
        }
    }
}

extension FrontlinePressureLevel {
    var systemImage: String {
        switch self {
        case .watch: return "eye.fill"
        case .contested: return "flag.2.crossed.fill"
        case .threatened: return "exclamationmark.shield.fill"
        case .critical: return "flame.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .watch: return Color(red: 0.52, green: 0.70, blue: 0.86)
        case .contested: return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .threatened: return Color(red: 0.92, green: 0.42, blue: 0.14)
        case .critical: return Color(red: 0.84, green: 0.16, blue: 0.12)
        }
    }
}

extension EnemyCommanderThreatLevel {
    var systemImage: String {
        switch self {
        case .watch: return "eye.fill"
        case .dangerous: return "person.crop.circle.badge.exclamationmark"
        case .severe: return "bolt.shield.fill"
        case .critical: return "flame.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .watch: return Color(red: 0.52, green: 0.70, blue: 0.86)
        case .dangerous: return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .severe: return Color(red: 0.92, green: 0.42, blue: 0.14)
        case .critical: return Color(red: 0.84, green: 0.16, blue: 0.12)
        }
    }
}

extension CountermeasureKind {
    var systemImage: String {
        switch self {
        case .interruptCommander: return "hand.raised.fill"
        case .holdLine: return "shield.fill"
        case .reinforceCity: return "building.columns.fill"
        case .strikeThreat: return "bolt.fill"
        case .commanderAction: return "flag.2.crossed.fill"
        case .redeploy: return "figure.run"
        }
    }
}

extension CountermeasurePriority {
    var tintColor: Color {
        switch self {
        case .watch: return Color(red: 0.52, green: 0.70, blue: 0.86)
        case .useful: return Color(red: 0.28, green: 0.78, blue: 0.62)
        case .urgent: return Color(red: 0.92, green: 0.42, blue: 0.14)
        case .decisive: return Color(red: 0.84, green: 0.16, blue: 0.12)
        }
    }
}

extension BattlefieldConvergenceRole {
    var systemImage: String {
        switch self {
        case .objective: return "point.topleft.down.curvedto.point.bottomright.up.fill"
        case .countermeasure: return "shield.lefthalf.filled"
        case .stage: return "rectangle.and.hand.point.up.left.fill"
        case .synergy: return "flag.2.crossed.fill"
        case .maneuver: return "figure.run"
        case .threatHeat: return "flame.fill"
        case .mapControl: return "map.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .objective: return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .countermeasure: return Color(red: 0.36, green: 0.86, blue: 0.92)
        case .stage: return Color(red: 0.92, green: 0.46, blue: 0.20)
        case .synergy: return Color(red: 0.72, green: 0.48, blue: 0.92)
        case .maneuver: return Color(red: 0.70, green: 0.76, blue: 0.32)
        case .threatHeat: return Color(red: 0.84, green: 0.16, blue: 0.12)
        case .mapControl: return Color(red: 0.28, green: 0.78, blue: 0.62)
        }
    }
}

extension BattlefieldFocusKind {
    var systemImage: String {
        switch self {
        case .defense: return "exclamationmark.shield.fill"
        case .generalOpportunity: return "sparkles"
        case .attackOpportunity: return "bolt.fill"
        case .reinforce: return "arrow.triangle.branch"
        case .advance: return "arrow.up.right.circle.fill"
        case .recover: return "cross.case.fill"
        }
    }
}

extension CommanderSynergyKind {
    var systemImage: String {
        switch self {
        case .commanderSkill: return "flag.2.crossed.fill"
        case .coordinatedAttack: return "scope"
        case .reinforce: return "arrow.triangle.branch"
        case .advance: return "arrow.up.right.circle.fill"
        case .recover: return "cross.case.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .commanderSkill: return Color(red: 0.72, green: 0.48, blue: 0.92)
        case .coordinatedAttack: return Color(red: 0.92, green: 0.46, blue: 0.20)
        case .reinforce: return Color(red: 0.28, green: 0.78, blue: 0.62)
        case .advance: return Color(red: 0.70, green: 0.76, blue: 0.32)
        case .recover: return Color(red: 0.62, green: 0.76, blue: 0.46)
        }
    }
}

extension ManeuverOptionKind {
    var systemImage: String {
        switch self {
        case .strike: return "bolt.fill"
        case .capture: return "building.columns.fill"
        case .reinforce: return "arrow.triangle.branch"
        case .advance: return "arrow.up.right.circle.fill"
        case .secure: return "shield.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .strike: return Color(red: 0.92, green: 0.46, blue: 0.20)
        case .capture: return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .reinforce: return Color(red: 0.28, green: 0.78, blue: 0.62)
        case .advance: return Color(red: 0.70, green: 0.76, blue: 0.32)
        case .secure: return Color(red: 0.52, green: 0.70, blue: 0.86)
        }
    }
}

extension BattlefieldFocusSeverity {
    var tintColor: Color {
        switch self {
        case .watch: return Color(red: 0.52, green: 0.70, blue: 0.86)
        case .important: return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .urgent: return Color(red: 0.92, green: 0.42, blue: 0.14)
        case .critical: return Color(red: 0.84, green: 0.16, blue: 0.12)
        }
    }
}

extension ThreatHeatLevel {
    var systemImage: String {
        switch self {
        case .quiet: return "checkmark.seal.fill"
        case .watched: return "eye.fill"
        case .contested: return "flag.2.crossed.fill"
        case .danger: return "exclamationmark.shield.fill"
        case .critical: return "flame.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .quiet: return Color(red: 0.36, green: 0.70, blue: 0.44)
        case .watched: return Color(red: 0.52, green: 0.70, blue: 0.86)
        case .contested: return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .danger: return Color(red: 0.92, green: 0.42, blue: 0.14)
        case .critical: return Color(red: 0.84, green: 0.16, blue: 0.12)
        }
    }
}

extension MapControlState {
    var tintColor: Color {
        switch self {
        case .friendlyControlled: return Color(red: 0.32, green: 0.68, blue: 0.42)
        case .enemyControlled: return Color(red: 0.84, green: 0.16, blue: 0.12)
        case .contested: return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .neutral: return Color(red: 0.52, green: 0.56, blue: 0.54)
        }
    }
}

extension AIOperationalPlanKind {
    var systemImage: String {
        switch self {
        case .focusedAttack: return "scope"
        case .cityCapture: return "building.columns.fill"
        case .commanderSkill: return "sparkles"
        case .advance: return "arrow.up.right.circle.fill"
        case .defend: return "shield.lefthalf.filled"
        case .regroup: return "cross.case.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .focusedAttack: return Color(red: 0.84, green: 0.16, blue: 0.12)
        case .cityCapture: return Color(red: 0.92, green: 0.42, blue: 0.14)
        case .commanderSkill: return Color(red: 0.72, green: 0.48, blue: 0.92)
        case .advance: return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .defend: return Color(red: 0.52, green: 0.70, blue: 0.86)
        case .regroup: return Color(red: 0.36, green: 0.70, blue: 0.44)
        }
    }
}

extension LegionFormationRole {
    var systemImage: String {
        switch self {
        case .vanguard: return "chevron.up.circle.fill"
        case .line: return "shield.lefthalf.filled"
        case .command: return "flag.2.crossed.fill"
        case .support: return "scope"
        case .siege: return "hammer.fill"
        case .reserve: return "tray.full.fill"
        case .fleet: return "sailboat.fill"
        }
    }
}

extension LegionFormationReadiness {
    var systemImage: String {
        switch self {
        case .fresh: return "checkmark.seal.fill"
        case .steady: return "shield.fill"
        case .engaged: return "flag.2.crossed.fill"
        case .strained: return "exclamationmark.shield.fill"
        case .critical: return "flame.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .fresh: return Color(red: 0.28, green: 0.72, blue: 0.42)
        case .steady: return Color(red: 0.52, green: 0.70, blue: 0.86)
        case .engaged: return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .strained: return Color(red: 0.92, green: 0.42, blue: 0.14)
        case .critical: return Color(red: 0.84, green: 0.16, blue: 0.12)
        }
    }
}

extension TacticalRecommendationKind {
    var systemImage: String {
        switch self {
        case .attack: return "bolt.fill"
        case .reinforce: return "arrow.triangle.branch"
        case .advance: return "arrow.up.right.circle.fill"
        case .hold: return "shield.fill"
        case .recover: return "cross.case.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .attack: return Color(red: 0.92, green: 0.46, blue: 0.20)
        case .reinforce: return Color(red: 0.28, green: 0.78, blue: 0.62)
        case .advance: return Color(red: 0.70, green: 0.76, blue: 0.32)
        case .hold: return Color(red: 0.52, green: 0.70, blue: 0.86)
        case .recover: return Color(red: 0.62, green: 0.76, blue: 0.46)
        }
    }
}

extension TacticalRecommendationRisk {
    var tintColor: Color {
        switch self {
        case .low: return Color(red: 0.36, green: 0.76, blue: 0.44)
        case .guarded: return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .high: return Color(red: 0.92, green: 0.42, blue: 0.14)
        case .critical: return Color(red: 0.84, green: 0.16, blue: 0.12)
        }
    }
}

extension GeneralTrait {
    var systemImage: String {
        switch self {
        case .eagleStandard: return "flag.2.crossed.fill"
        case .siegeEngineer: return "hammer.fill"
        case .quartermaster: return "shippingbox.fill"
        case .shieldWall: return "shield.lefthalf.filled"
        }
    }
}

extension TacticalOrder {
    var systemImage: String {
        switch self {
        case .balanced: return "circle.grid.cross.fill"
        case .assault: return "bolt.fill"
        case .defensive: return "shield.fill"
        case .forcedMarch: return "figure.walk.motion"
        }
    }

    var tintColor: Color {
        switch self {
        case .balanced: return Color(red: 0.78, green: 0.72, blue: 0.62)
        case .assault: return Color(red: 0.92, green: 0.28, blue: 0.20)
        case .defensive: return Color(red: 0.30, green: 0.62, blue: 0.90)
        case .forcedMarch: return Color(red: 0.32, green: 0.74, blue: 0.42)
        }
    }
}

extension AIIntentKind {
    var systemImage: String {
        switch self {
        case .attack: return "bolt.fill"
        case .advanceAttack: return "arrow.up.right.circle.fill"
        case .captureCity: return "building.columns.fill"
        case .advance: return "arrow.up.forward.circle.fill"
        case .defend: return "shield.fill"
        case .regroup: return "cross.case.fill"
        case .useSkill: return "sparkles"
        }
    }

    var tintColor: Color {
        switch self {
        case .attack: return Color(red: 0.86, green: 0.18, blue: 0.12)
        case .advanceAttack: return Color(red: 0.92, green: 0.42, blue: 0.14)
        case .captureCity: return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .advance: return Color(red: 0.36, green: 0.70, blue: 0.88)
        case .defend: return Color(red: 0.30, green: 0.62, blue: 0.90)
        case .regroup: return Color(red: 0.36, green: 0.70, blue: 0.40)
        case .useSkill: return Color(red: 0.80, green: 0.50, blue: 0.92)
        }
    }
}

extension TerrainType {
    var materialProfile: TerrainMaterialProfile {
        switch self {
        case .plains:
            return TerrainMaterialProfile(signature: "continuous-field-relief-grass", layerCount: 3, landmarkOpacity: 0.10)
        case .forest:
            return TerrainMaterialProfile(signature: "canopy-trunk-shadow", layerCount: 3, landmarkOpacity: 0.13)
        case .hills:
            return TerrainMaterialProfile(signature: "ridge-contour-shadow", layerCount: 3, landmarkOpacity: 0.15)
        case .water:
            return TerrainMaterialProfile(signature: "continuous-sea-wave-depth", layerCount: 3, landmarkOpacity: 0.085)
        case .road:
            return TerrainMaterialProfile(signature: "neighbor-road-verge-stone", layerCount: 3, landmarkOpacity: 0.11)
        case .city:
            return TerrainMaterialProfile(signature: "settlement-ground-wall-roof", layerCount: 3, landmarkOpacity: 0.10)
        }
    }

    var systemImage: String {
        switch self {
        case .plains: return "leaf.fill"
        case .forest: return "tree.fill"
        case .hills: return "mountain.2.fill"
        case .water: return "water.waves"
        case .road: return "road.lanes"
        case .city: return "building.columns.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .plains: return Color(red: 0.68, green: 0.78, blue: 0.38)
        case .forest: return Color(red: 0.26, green: 0.64, blue: 0.34)
        case .hills: return Color(red: 0.72, green: 0.56, blue: 0.36)
        case .water: return Color(red: 0.36, green: 0.70, blue: 0.88)
        case .road: return Color(red: 0.80, green: 0.64, blue: 0.42)
        case .city: return Color(red: 0.86, green: 0.68, blue: 0.34)
        }
    }
}

extension UnitKind {
    var tokenSystemImage: String {
        switch self {
        case .legion: return "shield.fill"
        case .cavalry: return "bolt.fill"
        case .archer: return "target"
        case .navy: return "water.waves"
        }
    }

    var shortLabel: String {
        switch self {
        case .legion: return "步"
        case .cavalry: return "骑"
        case .archer: return "弓"
        case .navy: return "舰"
        }
    }
}

extension MapOverlayLegendKind {
    var legendTint: Color {
        switch self {
        case .enemyRoute, .enemyTarget: return .red
        case .enemyCommanderThreat: return .purple
        case .threatHeat: return .orange
        case .mapControl: return .cyan
        case .tacticalPath: return .blue
        case .maneuverOption: return .green
        case .battleObjective: return Color(red: 0.92, green: 0.70, blue: 0.28)
        case .countermeasure: return Color(red: 0.28, green: 0.78, blue: 0.76)
        case .reachable: return .yellow
        case .attackTarget: return .pink
        case .skillRange: return .purple
        }
    }
}
