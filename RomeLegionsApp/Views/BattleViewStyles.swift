import SwiftUI

struct CommandButtonLabel: View {
    var symbol: String
    var text: String
    var detail: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
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
        .frame(minHeight: detail == nil ? 38 : 50)
        .padding(.horizontal, 10)
    }
}

struct CommandIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(configuration.isPressed ? .white.opacity(0.18) : .white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 8))
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
            .foregroundStyle(.white)
            .background(configuration.isPressed ? .white.opacity(0.18) : .black.opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
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

    init(mapWidth: Int, mapHeight: Int, container: CGSize) {
        let horizontalUnits = CGFloat(mapWidth) * 0.76 + 0.24
        let verticalUnits = CGFloat(mapHeight) + 0.5
        let isShortLandscape = container.width > container.height * 2
        let isLandscape = container.width > container.height

        let horizontalInset = min(18, max(8, container.width * 0.018))
        let topInset = isLandscape
            ? min(38, max(28, container.height * 0.09))
            : min(50, max(40, container.height * 0.07))
        let bottomInset = isLandscape
            ? min(54, max(44, container.height * 0.13))
            : min(82, max(68, container.height * 0.11))
        let availableWidth = max(1, container.width - horizontalInset * 2)
        let availableHeight = max(1, container.height - topInset - bottomInset)
        tileAspect = isShortLandscape ? 0.68 : (isLandscape ? 0.78 : 0.86)
        let widthBased = availableWidth / horizontalUnits
        let heightBased = availableHeight / (verticalUnits * tileAspect)
        let fittedTileWidth = min(widthBased, heightBased)

        tileWidth = max(18, min(82, fittedTileWidth))
        tileHeight = tileWidth * tileAspect
        tileScale = min(1.12, max(0.72, tileWidth / 44))
        actionScale = min(1.15, max(0.72, tileWidth / 54))

        let totalWidth = tileWidth * (0.76 * CGFloat(mapWidth - 1) + 1)
        let totalHeight = tileHeight * (CGFloat(mapHeight) + 0.5)
        mapSize = CGSize(width: totalWidth, height: totalHeight)
        let remainingVerticalSpace = max(0, availableHeight - totalHeight)
        let verticalBias: CGFloat = container.height > container.width * 1.25 ? 0.16 : 0.46
        origin = CGPoint(
            x: horizontalInset + (availableWidth - totalWidth) / 2 + tileWidth / 2,
            y: topInset + remainingVerticalSpace * verticalBias + tileHeight / 2
        )
    }

    func center(for position: Position) -> CGPoint {
        CGPoint(
            x: origin.x + CGFloat(position.x) * tileWidth * 0.76,
            y: origin.y + CGFloat(position.y) * tileHeight + (position.x.isMultiple(of: 2) ? 0 : tileHeight * 0.5)
        )
    }
}

struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let points = [
            CGPoint(x: rect.midX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.25),
            CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.25),
            CGPoint(x: rect.midX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.25),
            CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.25)
        ]

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
            return TerrainMaterialProfile(signature: "field-furrow-grass", layerCount: 3, landmarkOpacity: 0.16)
        case .forest:
            return TerrainMaterialProfile(signature: "canopy-trunk-shadow", layerCount: 3, landmarkOpacity: 0.13)
        case .hills:
            return TerrainMaterialProfile(signature: "ridge-contour-shadow", layerCount: 3, landmarkOpacity: 0.15)
        case .water:
            return TerrainMaterialProfile(signature: "wave-current-depth", layerCount: 3, landmarkOpacity: 0.12)
        case .road:
            return TerrainMaterialProfile(signature: "road-bed-route-stone", layerCount: 4, landmarkOpacity: 0.11)
        case .city:
            return TerrainMaterialProfile(signature: "block-wall-street", layerCount: 3, landmarkOpacity: 0.10)
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
