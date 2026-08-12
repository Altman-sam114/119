import Foundation
import SwiftUI

struct FactionSituation: Identifiable {
    var faction: Faction
    var unitCount: Int
    var cityCount: Int
    var income: EmpireResources
    var relationToRome: DiplomaticStatus

    var id: Faction { faction }
}

struct EnemyIntentRouteSegment: Identifiable {
    var id: String
    var from: Position
    var to: Position
    var kind: AIIntentKind
    var isTargetLeg: Bool
    var isHighThreat: Bool
}

enum EnemyCommanderThreatMapRole: String, CaseIterable, Identifiable {
    case origin
    case range
    case affected
    case target
    case destination

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .origin:
            return "敌将起点"
        case .range:
            return "技能范围"
        case .affected:
            return "影响区"
        case .target:
            return "威胁目标"
        case .destination:
            return "意图落点"
        }
    }

    var systemImage: String {
        switch self {
        case .origin:
            return "crown.fill"
        case .range:
            return "circle.dashed"
        case .affected:
            return "burst.fill"
        case .target:
            return "scope"
        case .destination:
            return "flag.fill"
        }
    }
}

struct EnemyCommanderThreatRouteSegment: Identifiable {
    var id: String
    var from: Position
    var to: Position
    var isTargetLeg: Bool
}

struct EnemyCommanderThreatPositionOverlay: Identifiable {
    var threatID: String
    var role: EnemyCommanderThreatMapRole
    var position: Position
    var isFocused: Bool
    var label: String
    var accessibilityLabel: String

    var id: String {
        "\(threatID)-\(role.rawValue)-\(position.x)-\(position.y)"
    }

    var stageLabel: String {
        role.displayName
    }
}

struct EnemyCommanderThreatMapOverlay: Identifiable {
    var summary: EnemyCommanderThreatSummary
    var isFocused: Bool

    var id: String { summary.id }
    var threatID: String { summary.id }
    var position: Position { summary.report.position }
    var commanderPosition: Position { summary.report.position }
    var targetPosition: Position { summary.targetPosition }
    var destination: Position? { summary.report.destination }
    var destinationPosition: Position? { destination }
    var rangePositions: [Position] { summary.report.rangePositions }
    var affectedPositions: [Position] { summary.report.affectedPositions }
    var commanderLabel: String { summary.commanderLabel }
    var skillName: String { summary.skillName }
    var skillLabel: String { skillName }
    var targetLabel: String { summary.targetLabel }
    var rangeLabel: String { summary.rangeLabel }
    var impactLabel: String { summary.impactLabel }
    var statusLabel: String { summary.statusLabel }

    var routeSegments: [EnemyCommanderThreatRouteSegment] {
        var segments: [EnemyCommanderThreatRouteSegment] = []
        let origin = position

        if let destination,
           destination != origin {
            segments.append(
                EnemyCommanderThreatRouteSegment(
                    id: "\(id)-move",
                    from: origin,
                    to: destination,
                    isTargetLeg: false
                )
            )
        }

        let routeOrigin = destination ?? origin
        if targetPosition != routeOrigin || segments.isEmpty {
            segments.append(
                EnemyCommanderThreatRouteSegment(
                    id: "\(id)-target",
                    from: routeOrigin,
                    to: targetPosition,
                    isTargetLeg: true
                )
            )
        }

        return segments
    }

    var positionOverlays: [EnemyCommanderThreatPositionOverlay] {
        var overlays: [EnemyCommanderThreatPositionOverlay] = []

        func append(_ role: EnemyCommanderThreatMapRole, _ position: Position, _ label: String) {
            overlays.append(
                EnemyCommanderThreatPositionOverlay(
                    threatID: id,
                    role: role,
                    position: position,
                    isFocused: isFocused,
                    label: label,
                    accessibilityLabel: "敌将\(commanderLabel)，\(role.displayName)\(position.description)，\(label)"
                )
            )
        }

        append(.origin, position, "\(skillName)起点")

        for rangePosition in sortedPositions(rangePositions) {
            append(.range, rangePosition, "\(skillName)可覆盖")
        }

        if affectedPositions.isEmpty {
            // Keep the empty-impact state in the summary; do not invent map positions.
        } else {
            for affectedPosition in sortedPositions(affectedPositions) {
                append(.affected, affectedPosition, "技能影响")
            }
        }

        append(.target, targetPosition, "\(summary.targetLabel) · \(impactLabel)")
        if let destination {
            append(.destination, destination, "\(summary.intentLabel)落点")
        }

        return overlays
    }

    var chainLabel: String {
        let rangeLabel = summary.rangeLabel
        let affectedLabel = affectedPositions.isEmpty ? "无直接影响位置" : "影响 \(affectedPositions.count) 格"
        let destinationLabel = destination.map { "落点\($0.description)" } ?? "无意图落点"
        return "起点\(position.description) · \(rangeLabel) · \(affectedLabel) · 目标\(targetPosition.description) · \(destinationLabel)"
    }

    var accessibilityLabel: String {
        "敌将威胁，\(commanderLabel)，\(skillName)，\(chainLabel)，\(impactLabel)，\(statusLabel)"
    }

    func references(_ candidate: EnemyCommanderThreatSummary) -> Bool {
        candidate.id == id
    }

    func references(_ candidate: EnemyCommanderThreatReport) -> Bool {
        candidate.id == id
    }

    private func sortedPositions(_ positions: [Position]) -> [Position] {
        positions.sorted {
            if $0.x == $1.x {
                return $0.y < $1.y
            }
            return $0.x < $1.x
        }
    }
}

enum MapOverlayLegendKind: String, Identifiable {
    case enemyRoute
    case enemyTarget
    case enemyCommanderThreat
    case threatHeat
    case mapControl
    case tacticalPath
    case maneuverOption
    case battleObjective
    case countermeasure
    case reachable
    case attackTarget
    case skillRange

    var id: String { rawValue }
}

enum MapReconPerspectiveKind: String, CaseIterable, Identifiable {
    case enemyIntent
    case countermeasure
    case objective
    case terrainPressure

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .enemyIntent:
            return "敌路"
        case .countermeasure:
            return "反制"
        case .objective:
            return "目标线"
        case .terrainPressure:
            return "热区"
        }
    }

    var shortLabel: String {
        switch self {
        case .enemyIntent:
            return "敌路"
        case .countermeasure:
            return "反制"
        case .objective:
            return "目标"
        case .terrainPressure:
            return "热区"
        }
    }

    var systemImage: String {
        switch self {
        case .enemyIntent:
            return "arrow.right.circle.fill"
        case .countermeasure:
            return "shield.lefthalf.filled"
        case .objective:
            return "point.topleft.down.curvedto.point.bottomright.up.fill"
        case .terrainPressure:
            return "flame.fill"
        }
    }
}

struct MapOverlayLegendItem: Identifiable {
    var kind: MapOverlayLegendKind
    var symbol: String
    var title: String
    var detail: String
    var accessibilityLabel: String

    var id: MapOverlayLegendKind { kind }
}

struct EnemyIntentSummary: Identifiable {
    var intent: AIIntent
    var unit: ArmyUnit
    var targetUnit: ArmyUnit?
    var targetCity: City?

    var id: String { intent.id }

    var title: String {
        switch intent.kind {
        case .attack, .advanceAttack:
            if let targetUnit {
                return "\(intent.kind.displayName) \(targetUnit.kind.displayName)"
            }
            return intent.kind.displayName

        case .captureCity:
            if let targetCity {
                return "夺取\(targetCity.name)"
            }
            return intent.kind.displayName

        case .advance:
            if let targetCity {
                return "逼近\(targetCity.name)"
            }
            return intent.kind.displayName

        case .defend:
            if let targetCity {
                return "固守\(targetCity.name)"
            }
            return intent.kind.displayName

        case .regroup:
            return "休整补给"

        case .useSkill:
            let skillName = unit.resolvedGeneralTrait?.skillName ?? intent.kind.displayName
            if let targetCity {
                return "\(skillName) \(targetCity.name)"
            }
            if let targetUnit {
                return "\(skillName) \(targetUnit.kind.displayName)"
            }
            return skillName
        }
    }

    var detail: String {
        var parts = [actorLabel, routeDetail, impactLabel]

        if targetPosition != nil {
            parts.insert(targetLabel, at: 2)
        }

        if let generalName = unit.generalName {
            parts.append(generalName)
        }

        if intent.tacticalOrder != .balanced {
            parts.append(intent.tacticalOrder.displayName)
        }

        return parts.joined(separator: " · ")
    }

    var shortTitle: String {
        switch intent.kind {
        case .attack:
            return "攻击"
        case .advanceAttack:
            return "接敌"
        case .captureCity:
            return "夺城"
        case .advance:
            return "推进"
        case .defend:
            return "固守"
        case .regroup:
            return "整备"
        case .useSkill:
            return "技能"
        }
    }

    var badgeText: String {
        if let projectedDamage = intent.projectedDamage {
            return "-\(projectedDamage)"
        }

        switch intent.kind {
        case .attack:
            return "攻"
        case .advanceAttack:
            return "接"
        case .captureCity:
            return "城"
        case .advance:
            return "进"
        case .defend:
            return "守"
        case .regroup:
            return "整"
        case .useSkill:
            return "技"
        }
    }

    var threatLabel: String {
        isHighThreat ? "高威胁" : "监视"
    }

    var actorLabel: String {
        "\(unit.faction.displayName)\(unit.kind.displayName)"
    }

    var originPosition: Position {
        unit.position
    }

    var originLabel: String {
        "起点\(originPosition.description)"
    }

    var destinationPosition: Position {
        intent.destination ?? unit.position
    }

    var destinationLabel: String {
        if destinationPosition == originPosition {
            return "原地\(destinationPosition.description)"
        }

        return "目的地\(destinationPosition.description)"
    }

    var targetPosition: Position? {
        targetUnit?.position ?? targetCity?.position
    }

    var targetLabel: String {
        if let targetUnit {
            return "目标\(targetUnit.faction.displayName)\(targetUnit.kind.displayName)"
        }

        if let targetCity {
            return "目标\(targetCity.name)"
        }

        return "无目标"
    }

    var impactLabel: String {
        if let projectedDamage = intent.projectedDamage {
            return "预计伤害\(projectedDamage)"
        }

        switch intent.kind {
        case .attack, .advanceAttack:
            return "压制目标"
        case .captureCity:
            return targetCity.map { "夺取\($0.name)" } ?? "夺取城市"
        case .advance:
            return targetCity.map { "逼近\($0.name)" } ?? "逼近战线"
        case .defend:
            return targetCity.map { "固守\($0.name)" } ?? "原地固守"
        case .regroup:
            return "整备恢复"
        case .useSkill:
            if let targetCity {
                return "技能压制\(targetCity.name)"
            }
            if let targetUnit {
                return "技能支援\(targetUnit.faction.displayName)\(targetUnit.kind.displayName)"
            }
            return "准备技能"
        }
    }

    var routeDetail: String {
        if let targetPosition {
            return "\(originLabel) -> \(destinationLabel) -> 目标\(targetPosition.description)"
        }

        return "\(originLabel) -> \(destinationLabel)"
    }

    var routeSegments: [EnemyIntentRouteSegment] {
        var segments: [EnemyIntentRouteSegment] = []

        if originPosition != destinationPosition {
            segments.append(
                EnemyIntentRouteSegment(
                    id: "\(id)-move",
                    from: originPosition,
                    to: destinationPosition,
                    kind: intent.kind,
                    isTargetLeg: false,
                    isHighThreat: isHighThreat
                )
            )
        }

        if let targetPosition, targetPosition != destinationPosition {
            segments.append(
                EnemyIntentRouteSegment(
                    id: "\(id)-target",
                    from: destinationPosition,
                    to: targetPosition,
                    kind: intent.kind,
                    isTargetLeg: true,
                    isHighThreat: isHighThreat
                )
            )
        }

        return segments
    }

    var isHighThreat: Bool {
        intent.kind == .attack ||
            intent.kind == .advanceAttack ||
            intent.kind == .captureCity ||
            intent.threatScore >= 420
    }
}

struct EnemyIntentMapOverlay: Identifiable {
    var summary: EnemyIntentSummary
    var routeSegments: [EnemyIntentRouteSegment]

    init(summary: EnemyIntentSummary, routeSegments: [EnemyIntentRouteSegment]? = nil) {
        self.summary = summary
        self.routeSegments = routeSegments ?? summary.routeSegments
    }

    var id: String { summary.id }
    var unitID: String { summary.unit.id }
    var kind: AIIntentKind { summary.intent.kind }
    var originPosition: Position { summary.originPosition }
    var destinationPosition: Position { summary.destinationPosition }
    var targetPosition: Position? { summary.targetPosition }
    var targetLabel: String { summary.targetLabel }
    var impactLabel: String { summary.impactLabel }
    var isHighThreat: Bool { summary.isHighThreat }

    var showsDestinationMarker: Bool {
        destinationPosition != originPosition ||
            kind == .advanceAttack ||
            kind == .advance ||
            kind == .captureCity
    }

    var accessibilityLabel: String {
        "\(summary.actorLabel)，\(summary.routeDetail)，\(summary.targetLabel)，\(summary.impactLabel)"
    }
}

struct TacticalRecommendationRouteSegment: Identifiable {
    var id: String
    var from: Position
    var to: Position
    var isTargetLeg: Bool
    var risk: TacticalRecommendationRisk
}

struct CountermeasureRouteSegment: Identifiable {
    var id: String
    var from: Position
    var to: Position
    var isTargetLeg: Bool
    var kind: CountermeasureKind
    var priority: CountermeasurePriority
}

enum CountermeasureMapRole: String, Identifiable {
    case response
    case destination
    case target

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .response: return "回应"
        case .destination: return "落点"
        case .target: return "目标"
        }
    }

    var stageNumber: Int {
        switch self {
        case .response: return 1
        case .destination: return 2
        case .target: return 3
        }
    }

    var stageLabel: String {
        "\(stageNumber) \(displayName)"
    }
}

struct CountermeasurePositionOverlay: Identifiable {
    var summary: CountermeasureSummary
    var role: CountermeasureMapRole
    var position: Position

    var id: String {
        "\(summary.id)-\(role.rawValue)-\(position.x)-\(position.y)"
    }

    var stageLabel: String {
        role.stageLabel
    }

    var focusLabel: String {
        switch role {
        case .response:
            return "\(stageLabel) \(summary.unitLabel)"
        case .destination:
            return "\(stageLabel) \(position.description)"
        case .target:
            return "\(stageLabel) \(summary.targetLabel)"
        }
    }

    var chainLabel: String {
        summary.countermeasureChainLabel
    }

    var accessibilityLabel: String {
        "\(stageLabel)反制\(role.displayName)\(position.description)，\(summary.kindLabel)，\(chainLabel)"
    }
}

struct CountermeasureMapOverlay: Identifiable {
    var summary: CountermeasureSummary

    var id: String { summary.id }
    var kind: CountermeasureKind { summary.kind }
    var priority: CountermeasurePriority { summary.priority }
    var responsePosition: Position { summary.responsePosition }
    var destination: Position { summary.destination }
    var targetPosition: Position { summary.targetPosition }
    var routeSegments: [CountermeasureRouteSegment] { summary.routeSegments }

    var positionOverlays: [CountermeasurePositionOverlay] {
        [
            CountermeasurePositionOverlay(summary: summary, role: .response, position: responsePosition),
            CountermeasurePositionOverlay(summary: summary, role: .destination, position: destination),
            CountermeasurePositionOverlay(summary: summary, role: .target, position: targetPosition)
        ]
    }

    var chainLabel: String {
        summary.countermeasureChainLabel
    }

    var accessibilityLabel: String {
        "反制路线，\(chainLabel)"
    }
}

struct CountermeasureCommandStep: Identifiable {
    var id: String
    var symbol: String
    var title: String
    var detail: String
    var isReady: Bool
}

struct CountermeasureCommandPreview: Identifiable {
    var summary: CountermeasureSummary
    var responseUnit: ArmyUnit?
    var targetUnit: ArmyUnit?
    var targetCity: City?
    var recommendedOrder: TacticalOrder
    var destination: Position
    var targetPosition: Position
    var canFocus: Bool
    var canSetOrder: Bool
    var canMoveToDestination: Bool
    var canAttackCurrentTarget: Bool
    var isExecutableNow: Bool
    var blockingReasons: [String]
    var steps: [CountermeasureCommandStep]

    var id: String { summary.id }

    var title: String {
        "反制指令：\(summary.kindLabel)"
    }

    var statusLabel: String {
        if isExecutableNow {
            return "可立即推进"
        }

        if canFocus {
            return "需确认步骤"
        }

        return blockingReasons.first ?? "暂不可执行"
    }

    var orderLabel: String {
        "姿态 \(recommendedOrder.displayName)"
    }

    var destinationLabel: String {
        if let responseUnit,
           destination == responseUnit.position {
            return "原地 \(destination.description)"
        }

        return "落点 \(destination.description)"
    }

    var targetLabel: String {
        if let targetUnit {
            return "\(targetUnit.faction.displayName)\(targetUnit.kind.displayName)"
        }

        if let targetCity {
            return targetCity.name
        }

        return targetPosition.description
    }

    var nextStepLabel: String {
        if let firstBlockingReason = blockingReasons.first {
            return firstBlockingReason
        }

        if canAttackCurrentTarget {
            return "可直接攻击 \(targetLabel)"
        }

        if let responseUnit,
           destination == responseUnit.position {
            return "已在落点，确认目标"
        }

        if canMoveToDestination {
            return "先移动至 \(destination.description)"
        }

        if canSetOrder {
            return "先切换\(recommendedOrder.displayName)"
        }

        return summary.commandLabel
    }

    var commandChainLabel: String {
        if let blockedReason {
            return "反制受阻：\(blockedReason)"
        }

        if canAttackCurrentTarget {
            return "反制攻击目标"
        }

        if let responseUnit,
           destination == responseUnit.position {
            return "已在落点，确认目标"
        }

        if canMoveToDestination {
            return "先移动到反制落点"
        }

        if canSetOrder {
            return "先切换\(recommendedOrder.displayName)"
        }

        return summary.commandLabel
    }

    var blockedReason: String? {
        blockingReasons.first
    }

    var recommendedOrderCueLabel: String {
        if responseUnit?.resolvedTacticalOrder == recommendedOrder {
            return "反制姿态已就绪"
        }

        if canSetOrder {
            return "反制建议：切换\(recommendedOrder.displayName)"
        }

        return "反制姿态受限"
    }

    var movementCueLabel: String {
        if let responseUnit,
           destination == responseUnit.position {
            return "反制落点已占位"
        }

        if canMoveToDestination {
            return "反制落点可移动"
        }

        return blockedReason ?? "反制落点暂不可达"
    }

    var attackCueLabel: String {
        if canAttackCurrentTarget {
            return "反制目标可攻击"
        }

        if targetUnit != nil {
            return "反制目标未入攻击范围"
        }

        return "反制目标需占位确认"
    }

    var chainSummaryLabel: String {
        summary.countermeasureChainLabel
    }

    var targetStageCueLabel: String {
        "\(CountermeasureMapRole.target.stageLabel) · \(attackCueLabel)"
    }

    func isRecommendedOrder(_ order: TacticalOrder) -> Bool {
        recommendedOrder == order
    }

    func isAttackTarget(_ unit: ArmyUnit) -> Bool {
        targetUnit?.id == unit.id
    }

    func isMapOverlayTarget(_ overlay: CountermeasurePositionOverlay) -> Bool {
        overlay.summary.id == summary.id &&
            overlay.role == .target &&
            overlay.position == targetPosition
    }

    var buttonTitle: String {
        canFocus ? "定位回应" : "无法定位"
    }

    var buttonDetail: String {
        if canFocus {
            return "\(summary.unitLabel) · \(destinationLabel)"
        }

        return blockedReason ?? "回应军团不可用"
    }

    var accessibilityLabel: String {
        [
            title,
            statusLabel,
            orderLabel,
            chainSummaryLabel,
            destinationLabel,
            "目标\(targetLabel)",
            commandChainLabel,
            nextStepLabel
        ].joined(separator: "，")
    }
}

struct CountermeasureCommandContextReadout: Identifiable {
    var countermeasureID: String
    var reportID: String
    var previewID: String
    var overlayID: String
    var sourceID: String
    var focusedCountermeasureID: String?
    var isFocused: Bool
    var isPrimaryFallback: Bool
    var selectedPerspective: MapReconPerspectiveKind
    var responseUnitID: String
    var responseUnitLabel: String
    var responseKindLabel: String
    var responseCommanderLabel: String
    var responseIdentityLabel: String
    var responsePosition: Position
    var recommendedOrder: TacticalOrder
    var destination: Position
    var targetUnitID: String?
    var targetCityID: String?
    var targetPosition: Position
    var targetLabel: String
    var kind: CountermeasureKind
    var priority: CountermeasurePriority
    var kindLabel: String
    var priorityLabel: String
    var threatLabel: String
    var commandLabel: String
    var impactLabel: String
    var riskLabel: String
    var commandChainLabel: String
    var nextStepLabel: String
    var steps: [CountermeasureCommandStep]
    var blockingReasons: [String]
    var routeSegments: [CountermeasureRouteSegment]
    var canFocus: Bool
    var canConfirmOrder: Bool
    var canConfirmMovement: Bool
    var canLockTarget: Bool

    var id: String { "\(sourceID)-command-context" }
    var isReadOnlyPreview: Bool { true }
    var isSingleStepConfirmation: Bool { true }
    var hasExecutableCommand: Bool {
        canConfirmOrder || canConfirmMovement || canLockTarget
    }

    var focusStateLabel: String {
        if isFocused { return "当前定位回应" }
        if isPrimaryFallback { return "焦点失效 · 回退首要反制" }
        return "全局首要反制"
    }

    var sourceLabel: String { "反制源 \(sourceID)" }
    var responsePositionLabel: String { "当前位置 \(responsePosition.description)" }
    var destinationLabel: String { "落点 \(destination.description)" }
    var targetPositionLabel: String { "目标格 \(targetPosition.description)" }
    var orderLabel: String { "建议姿态 \(recommendedOrder.displayName)" }
    var responseDetailLabel: String {
        "\(responseKindLabel) · \(responseCommanderLabel) · \(responsePositionLabel)"
    }

    var orderBlockingReason: String? {
        canConfirmOrder ? nil : "姿态已就绪或当前不可切换"
    }

    var movementBlockingReason: String? {
        canConfirmMovement ? nil : "已在落点或落点当前不可达"
    }

    var targetBlockingReason: String? {
        canLockTarget ? nil : "目标尚未进入现有攻击窗口"
    }

    var orderConfirmationLabel: String { "确认\(recommendedOrder.displayName)姿态" }
    var movementConfirmationLabel: String { "前往\(destination.description)" }
    var targetConfirmationLabel: String { "锁定\(targetLabel)" }

    var commandAvailabilityLabel: String {
        let available = [
            canConfirmOrder ? "确认姿态" : nil,
            canConfirmMovement ? "前往落点" : nil,
            canLockTarget ? "锁定目标" : nil
        ].compactMap { $0 }
        return available.isEmpty ? (blockingReasons.first ?? "当前没有可确认步骤") : available.joined(separator: " · ")
    }

    var compactLabel: String {
        "\(focusStateLabel) · \(responseUnitLabel) · \(nextStepLabel)"
    }

    var detailLabel: String {
        "\(sourceLabel) · \(orderLabel) · \(destinationLabel) · 目标\(targetLabel) \(targetPosition.description) · \(impactLabel) · 风险\(riskLabel)"
    }

    var mapFocusLabel: String {
        "\(sourceLabel) · 回应\(responsePosition.description) → 落点\(destination.description) → 目标\(targetPosition.description)"
    }

    var routeStageLabel: String {
        steps.map { "\($0.title)：\($0.detail)" }.joined(separator: " · ")
    }

    var accessibilityLabel: String {
        [
            "反制身份\(sourceID)",
            focusStateLabel,
            "回应\(responseIdentityLabel)",
            orderLabel,
            destinationLabel,
            "目标\(targetLabel)，\(targetPositionLabel)",
            commandChainLabel,
            nextStepLabel,
            impactLabel,
            "风险\(riskLabel)",
            commandAvailabilityLabel,
            "确认姿态、前往落点、锁定目标是分开的现有入口，不会自动执行后续步骤"
        ].joined(separator: "，")
    }

    func references(preview: CountermeasureCommandPreview) -> Bool {
        previewID == preview.id &&
            reportID == preview.summary.report.id &&
            sourceID == preview.summary.id
    }

    func references(overlay: CountermeasureMapOverlay) -> Bool {
        overlayID == overlay.id &&
            sourceID == overlay.summary.id &&
            responsePosition == overlay.responsePosition &&
            destination == overlay.destination &&
            targetPosition == overlay.targetPosition
    }
}

struct BattleObjectiveStageCommandStep: Identifiable {
    var id: String
    var symbol: String
    var title: String
    var detail: String
    var isReady: Bool
}

struct BattleObjectiveStageCommandPreview: Identifiable {
    var chain: BattleObjectiveChainSummary
    var role: BattleObjectiveMapRole
    var position: Position
    var sourceSummaryID: String
    var commandUnit: ArmyUnit?
    var targetUnit: ArmyUnit?
    var targetCity: City?
    var recommendedOrder: TacticalOrder?
    var destination: Position?
    var targetPosition: Position
    var commandEntryLabel: String
    var canFocus: Bool
    var canSetOrder: Bool
    var canMoveToDestination: Bool
    var canAttackCurrentTarget: Bool
    var canUseGeneralSkill: Bool
    var isExecutableNow: Bool
    var blockingReasons: [String]
    var steps: [BattleObjectiveStageCommandStep]

    var id: String {
        "\(chain.id)-\(role.rawValue)-command"
    }

    var chainID: String {
        chain.id
    }

    var stageLabel: String {
        role.stageLabel
    }

    var focusLabel: String {
        switch role {
        case .focus: return chain.focusStageLabel
        case .synergy: return chain.synergyStageLabel
        case .maneuver: return chain.maneuverStageLabel
        case .recommendation: return chain.recommendationStageLabel
        }
    }

    var chainLabel: String {
        chain.chainLabel
    }

    var title: String {
        "目标线\(stageLabel)指令"
    }

    var statusLabel: String {
        if isExecutableNow {
            return "可推进"
        }

        if canFocus {
            return "需确认"
        }

        return blockingReasons.first ?? "仅提示"
    }

    var orderCueLabel: String {
        guard let recommendedOrder else {
            return "姿态按当前军令"
        }

        if commandUnit?.resolvedTacticalOrder == recommendedOrder {
            return "姿态已是\(recommendedOrder.displayName)"
        }

        if canSetOrder {
            return "建议切换\(recommendedOrder.displayName)"
        }

        return "建议\(recommendedOrder.displayName)"
    }

    var movementCueLabel: String {
        guard let destination else {
            return "无需移动落点"
        }

        if commandUnit?.position == destination {
            return "已在\(destination.description)"
        }

        if canMoveToDestination {
            return "可移动至\(destination.description)"
        }

        return "暂不可达\(destination.description)"
    }

    var attackCueLabel: String {
        if canAttackCurrentTarget {
            return "目标可攻击"
        }

        if targetUnit != nil {
            return "目标未入攻击范围"
        }

        if targetCity != nil {
            return "目标为城市"
        }

        return "目标待确认"
    }

    var skillCueLabel: String {
        if canUseGeneralSkill {
            return "将领技能可用"
        }

        if role == .synergy {
            return "将令需确认"
        }

        return "技能非主入口"
    }

    var commandEntryCueLabel: String {
        "\(stageLabel) · \(commandEntryLabel)"
    }

    var recommendedOrderStageCueLabel: String {
        "\(stageLabel) · \(orderCueLabel)"
    }

    var attackStageCueLabel: String {
        "\(stageLabel) · \(attackCueLabel)"
    }

    var skillStageCueLabel: String {
        "\(stageLabel) · \(skillCueLabel)"
    }

    var shouldHighlightSkillEntry: Bool {
        role == .synergy && canUseGeneralSkill
    }

    var targetLabel: String {
        if let targetUnit {
            return "\(targetUnit.faction.displayName)\(targetUnit.kind.displayName)"
        }

        if let targetCity {
            return targetCity.name
        }

        return targetPosition.description
    }

    var unitLabel: String {
        if let commandUnit {
            return "\(commandUnit.faction.displayName)\(commandUnit.kind.displayName)"
        }

        return "无罗马执行单位"
    }

    var nextStepLabel: String {
        if let firstBlockingReason = blockingReasons.first {
            return firstBlockingReason
        }

        if canAttackCurrentTarget {
            return "可攻击\(targetLabel)"
        }

        if canUseGeneralSkill {
            return "可发动将领技能"
        }

        if canMoveToDestination,
           let destination,
           commandUnit?.position != destination {
            return "先移动至\(destination.description)"
        }

        if canSetOrder,
           let recommendedOrder {
            return "先切换\(recommendedOrder.displayName)"
        }

        return commandEntryLabel
    }

    var buttonTitle: String {
        canFocus ? "定位\(role.displayName)" : "无法定位"
    }

    var buttonDetail: String {
        if canFocus {
            return "\(unitLabel) · \(nextStepLabel)"
        }

        return blockingReasons.first ?? "阶段仅提示"
    }

    var accessibilityLabel: String {
        [
            title,
            statusLabel,
            focusLabel,
            "入口\(commandEntryLabel)",
            "执行\(unitLabel)",
            "目标\(targetLabel)",
            orderCueLabel,
            movementCueLabel,
            attackCueLabel,
            skillCueLabel,
            nextStepLabel
        ].joined(separator: "，")
    }

    func isRecommendedOrder(_ order: TacticalOrder) -> Bool {
        recommendedOrder == order
    }

    func isAttackTarget(_ unit: ArmyUnit) -> Bool {
        targetUnit?.id == unit.id
    }

    func isCommandUnit(_ unit: ArmyUnit) -> Bool {
        commandUnit?.id == unit.id
    }

    func isStage(_ candidate: BattleObjectiveMapRole) -> Bool {
        role == candidate
    }
}

struct TacticalRecommendationSummary: Identifiable {
    var report: TacticalRecommendationReport
    var unit: ArmyUnit?
    var targetUnit: ArmyUnit?
    var targetCity: City?

    var id: String { report.id }
    var kind: TacticalRecommendationKind { report.kind }
    var risk: TacticalRecommendationRisk { report.risk }
    var targetPosition: Position { report.targetPosition }
    var destination: Position { report.destination }

    var title: String {
        "\(report.kind.displayName)建议"
    }

    var kindLabel: String {
        report.kind.displayName
    }

    var riskLabel: String {
        report.risk.displayName
    }

    var priorityLabel: String {
        "优先 \(report.priority)"
    }

    var targetLabel: String {
        if let targetUnit {
            return "\(targetUnit.faction.displayName)\(targetUnit.kind.displayName)"
        }

        if let targetCity {
            return targetCity.name
        }

        return "坐标 \(report.targetPosition.description)"
    }

    var pathLabel: String {
        if report.destination == report.targetPosition {
            return "目标 \(report.targetPosition.description)"
        }

        if let unit,
           report.destination == unit.position {
            return "原地 -> \(report.targetPosition.description)"
        }

        return "至 \(report.destination.description) · 距 \(report.supportDistance ?? report.destination.hexDistance(to: report.targetPosition))"
    }

    var damageLabel: String? {
        report.projectedDamage.map { "预计伤害 \($0)" }
    }

    var detail: String {
        [
            targetLabel,
            pathLabel,
            damageLabel,
            "姿态 \(report.recommendedOrder.displayName)",
            riskLabel
        ].compactMap { $0 }.joined(separator: " · ")
    }

    var objectiveCueLabel: String {
        "4 军议 \(kindLabel) -> \(targetLabel)"
    }

    var accessibilityLabel: String {
        "\(title)，\(objectiveCueLabel)，目标\(targetLabel)，\(pathLabel)，\(priorityLabel)，风险\(riskLabel)，\(report.command)"
    }

    var routeSegments: [TacticalRecommendationRouteSegment] {
        var segments = zip(report.path, report.path.dropFirst()).enumerated().map { index, pair in
            TacticalRecommendationRouteSegment(
                id: "\(report.id)-path-\(index)",
                from: pair.0,
                to: pair.1,
                isTargetLeg: false,
                risk: report.risk
            )
        }

        if report.destination != report.targetPosition,
           (report.path.last ?? report.destination) != report.targetPosition {
            segments.append(
                TacticalRecommendationRouteSegment(
                    id: "\(report.id)-target",
                    from: report.destination,
                    to: report.targetPosition,
                    isTargetLeg: true,
                    risk: report.risk
                )
            )
        }

        return segments
    }
}

struct ManeuverOptionSummary: Identifiable {
    var report: ManeuverOptionReport
    var unit: ArmyUnit?
    var targetUnit: ArmyUnit?
    var targetCity: City?

    var id: String { report.id }
    var kind: ManeuverOptionKind { report.kind }
    var risk: TacticalRecommendationRisk { report.risk }
    var destination: Position { report.destination }
    var targetPosition: Position { report.targetPosition }

    var title: String {
        report.title
    }

    var compactTitle: String {
        "\(kindLabel) \(impactLabel)"
    }

    var kindLabel: String {
        report.kind.displayName
    }

    var riskLabel: String {
        report.risk.displayName
    }

    var unitLabel: String {
        if let unit {
            return "\(unit.faction.displayName)\(unit.kind.displayName)"
        }

        return "\(report.faction.displayName)军团"
    }

    var targetLabel: String {
        if let targetUnit {
            return "\(targetUnit.faction.displayName)\(targetUnit.kind.displayName)"
        }

        if let targetCity {
            return targetCity.name
        }

        return "坐标 \(report.targetPosition.description)"
    }

    var destinationLabel: String {
        "落点 \(report.destination.description)"
    }

    var pathLabel: String {
        "路径 \(max(0, report.path.count - 1))"
    }

    var impactLabel: String {
        if let projectedDamage = report.projectedDamage {
            return "伤害 \(projectedDamage)"
        }

        if let supportDistance = report.supportDistance {
            return "补线距 \(supportDistance)"
        }

        if let objectiveDistance = report.objectiveDistance {
            return "目标距 \(objectiveDistance)"
        }

        return report.controlState.displayName
    }

    var modifierLabel: String {
        let parts = [
            report.supportBonus > 0 ? "援+\(report.supportBonus)" : nil,
            report.flankingBonus > 0 ? "夹+\(report.flankingBonus)" : nil,
            report.commandBonus > 0 ? "令+\(report.commandBonus)" : nil
        ].compactMap { $0 }

        return parts.isEmpty ? "无修正" : parts.joined(separator: " ")
    }

    var controlLabel: String {
        "\(report.controlState.displayName) · 热区\(report.threatLevel.displayName)"
    }

    var influenceLabel: String {
        "友\(report.friendlyInfluence)/敌\(report.enemyInfluence)"
    }

    var scoreLabel: String {
        "机动 \(report.score)"
    }

    var detail: String {
        report.detail
    }

    var objectiveCueLabel: String {
        "3 机动 \(destination.description) -> \(targetLabel)"
    }

    var accessibilityLabel: String {
        "\(title)，\(objectiveCueLabel)，执行单位\(unitLabel)，\(destinationLabel)，目标\(targetLabel)，\(impactLabel)，\(controlLabel)，风险\(riskLabel)，建议\(report.recommendedOrder.displayName)，\(detail)"
    }
}

struct CommanderSynergyStepReadout: Identifiable {
    var step: CommanderSynergyStepReport
    var unit: ArmyUnit?

    var id: String { step.id }
    var role: CommanderSynergyRole { step.role }
    var tacticalOrder: TacticalOrder { step.tacticalOrder }

    var roleLabel: String {
        step.role.displayName
    }

    var unitLabel: String {
        if let generalName = unit?.generalName {
            return generalName
        }

        if let unit {
            return "\(unit.faction.displayName)\(unit.kind.displayName)"
        }

        return "\(step.faction.displayName)军团"
    }

    var positionLabel: String {
        step.position.description
    }

    var targetLabel: String {
        step.targetPosition.description
    }

    var orderLabel: String {
        step.tacticalOrder.displayName
    }

    var compactLabel: String {
        "\(roleLabel)\(unitLabel) \(orderLabel)"
    }

    var routeLabel: String {
        "\(positionLabel) -> \(targetLabel)"
    }

    var detailLabel: String {
        "\(step.summary) · \(step.detail)"
    }

    var accessibilityLabel: String {
        "\(roleLabel)，\(unitLabel)，姿态\(orderLabel)，位置\(positionLabel)，目标\(targetLabel)，\(step.summary)，\(step.detail)"
    }
}

struct CommanderSynergySummary: Identifiable {
    var report: CommanderSynergyReport
    var unit: ArmyUnit?
    var commanderUnit: ArmyUnit?
    var targetUnit: ArmyUnit?
    var targetCity: City?
    var supportingUnits: [ArmyUnit]
    var beneficiaryUnits: [ArmyUnit]

    var id: String { report.id }
    var kind: CommanderSynergyKind { report.kind }
    var targetPosition: Position { report.targetPosition }

    var title: String {
        report.title
    }

    var compactTitle: String {
        "\(kindLabel) \(impactLabel)"
    }

    var kindLabel: String {
        report.kind.displayName
    }

    var unitLabel: String {
        if let unit {
            return "\(unit.faction.displayName)\(unit.kind.displayName)"
        }

        return "\(report.faction.displayName)军团"
    }

    var commanderLabel: String? {
        if let commanderUnit,
           let generalName = commanderUnit.generalName {
            return generalName
        }

        return nil
    }

    var targetLabel: String {
        if let targetUnit {
            return "\(targetUnit.faction.displayName)\(targetUnit.kind.displayName)"
        }

        if let targetCity {
            return targetCity.name
        }

        return report.targetPosition.description
    }

    var supportLabel: String {
        guard !supportingUnits.isEmpty else {
            return "无额外支援"
        }

        let labels = supportingUnits.prefix(3).map { unit in
            if let generalName = unit.generalName {
                return "\(generalName)"
            }

            return unit.kind.displayName
        }
        return supportingUnits.count > 3 ? "\(labels.joined(separator: "、"))等 \(supportingUnits.count) 支" : labels.joined(separator: "、")
    }

    var beneficiaryLabel: String {
        guard !beneficiaryUnits.isEmpty else {
            return supportLabel
        }

        let labels = beneficiaryUnits.prefix(3).map { "\($0.kind.displayName)" }
        return beneficiaryUnits.count > 3 ? "\(labels.joined(separator: "、"))等 \(beneficiaryUnits.count) 支" : labels.joined(separator: "、")
    }

    var readinessLabel: String {
        report.formationReadiness.displayName
    }

    var riskLabel: String {
        report.risk.displayName
    }

    var statusLabel: String {
        report.isExecutable ? "可执行" : (report.blockedReason ?? "仅提示")
    }

    var modifierLabel: String {
        let parts = [
            report.supportBonus > 0 ? "支援 +\(report.supportBonus)" : nil,
            report.flankingBonus > 0 ? "包夹 +\(report.flankingBonus)" : nil,
            report.commandBonus > 0 ? "指挥 +\(report.commandBonus)" : nil
        ].compactMap { $0 }

        return parts.isEmpty ? statusLabel : parts.joined(separator: " · ")
    }

    var impactLabel: String {
        if let projectedDamage = report.projectedDamage {
            return "预计伤害 \(projectedDamage)"
        }

        if report.projectedRecoveredHealth > 0 {
            return "恢复 \(report.projectedRecoveredHealth)"
        }

        if report.projectedFortificationReduction > 0 {
            return "削城防 \(report.projectedFortificationReduction)"
        }

        return "\(report.steps.count) 步"
    }

    var stepReadouts: [CommanderSynergyStepReadout] {
        report.steps.map { step in
            CommanderSynergyStepReadout(
                step: step,
                unit: ([unit, commanderUnit].compactMap { $0 } + supportingUnits + beneficiaryUnits)
                    .first(where: { $0.id == step.unitID })
            )
        }
    }

    var stepLabel: String {
        report.steps.prefix(3).map { "\($0.role.displayName)\($0.summary)" }.joined(separator: "、")
    }

    var stepSequenceLabel: String {
        let labels = stepReadouts.prefix(3).map(\.compactLabel)
        return labels.isEmpty ? beneficiaryLabel : labels.joined(separator: " -> ")
    }

    var stepAccessibilityLabel: String {
        stepReadouts.map(\.accessibilityLabel).joined(separator: "；")
    }

    var detail: String {
        report.detail
    }

    var objectiveCueLabel: String {
        "2 将令 \(kindLabel) -> \(targetLabel)"
    }

    var accessibilityLabel: String {
        var parts = [
            "\(kindLabel)将令",
            objectiveCueLabel,
            "执行\(unitLabel)",
            "目标\(targetLabel)",
            impactLabel,
            "支援\(supportLabel)",
            "战备\(readinessLabel)",
            "风险\(riskLabel)",
            statusLabel,
            detail,
            stepAccessibilityLabel
        ]

        if let commanderLabel {
            parts.insert("将领\(commanderLabel)", at: 2)
        }

        return parts.joined(separator: "，")
    }
}

struct BattlefieldFocusSummary: Identifiable {
    var report: BattlefieldFocusReport
    var unit: ArmyUnit?
    var targetUnit: ArmyUnit?
    var targetCity: City?
    var relatedUnits: [ArmyUnit]

    var id: String { report.id }
    var kind: BattlefieldFocusKind { report.kind }
    var severity: BattlefieldFocusSeverity { report.severity }
    var targetPosition: Position { report.position }

    var title: String {
        report.title
    }

    var compactTitle: String {
        "\(kindLabel) \(severityLabel)"
    }

    var kindLabel: String {
        report.kind.displayName
    }

    var severityLabel: String {
        report.severity.displayName
    }

    var targetLabel: String {
        if let targetUnit {
            return "\(targetUnit.faction.displayName)\(targetUnit.kind.displayName)"
        }

        if let targetCity {
            return targetCity.name
        }

        return "坐标 \(report.position.description)"
    }

    var unitLabel: String {
        if let unit {
            return "\(unit.faction.displayName)\(unit.kind.displayName)"
        }

        return "未指定军团"
    }

    var scoreLabel: String {
        "焦点 \(report.score)"
    }

    var relatedLabel: String {
        guard !relatedUnits.isEmpty else {
            return "相关 \(report.relatedUnitIDs.count) 支"
        }

        let labels = relatedUnits.prefix(3).map { "\($0.faction.displayName)\($0.kind.displayName)" }
        if relatedUnits.count > 3 {
            return "\(labels.joined(separator: "、"))等 \(relatedUnits.count) 支"
        }

        return labels.joined(separator: "、")
    }

    var detail: String {
        report.detail
    }

    var objectiveCueLabel: String {
        "1 焦点 \(kindLabel) -> \(targetLabel)"
    }

    var accessibilityLabel: String {
        "\(title)，\(objectiveCueLabel)，\(kindLabel)，\(severityLabel)，目标\(targetLabel)，执行单位\(unitLabel)，建议\(report.recommendedOrder.displayName)，\(detail)"
    }
}

struct BattleObjectiveChainSummary: Identifiable {
    var focus: BattlefieldFocusSummary
    var synergy: CommanderSynergySummary?
    var maneuver: ManeuverOptionSummary?
    var recommendation: TacticalRecommendationSummary?

    var id: String {
        [
            focus.id,
            synergy?.id,
            maneuver?.id,
            recommendation?.id
        ].compactMap { $0 }.joined(separator: "-")
    }

    var title: String {
        "战场目标线"
    }

    var focusStageLabel: String {
        focus.objectiveCueLabel
    }

    var synergyStageLabel: String {
        synergy?.objectiveCueLabel ?? "2 将令 待确认"
    }

    var maneuverStageLabel: String {
        maneuver?.objectiveCueLabel ?? "3 机动 待确认"
    }

    var recommendationStageLabel: String {
        recommendation?.objectiveCueLabel ?? "4 军议 待确认"
    }

    var stageLabels: [String] {
        [
            focusStageLabel,
            synergyStageLabel,
            maneuverStageLabel,
            recommendationStageLabel
        ]
    }

    var chainLabel: String {
        stageLabels.joined(separator: " -> ")
    }

    var compactLabel: String {
        "\(focus.targetLabel) -> \(maneuver?.destination.description ?? focus.targetPosition.description) -> \(recommendation?.targetLabel ?? focus.targetLabel)"
    }

    var priorityLabel: String {
        "\(focus.severityLabel) · \(recommendation?.riskLabel ?? maneuver?.riskLabel ?? focus.kindLabel)"
    }

    var accessibilityLabel: String {
        "\(title)，\(chainLabel)，优先级\(priorityLabel)"
    }

    func references(focus candidate: BattlefieldFocusSummary) -> Bool {
        focus.id == candidate.id
    }

    func references(synergy candidate: CommanderSynergySummary) -> Bool {
        synergy?.id == candidate.id
    }

    func references(maneuver candidate: ManeuverOptionSummary) -> Bool {
        maneuver?.id == candidate.id
    }

    func references(recommendation candidate: TacticalRecommendationSummary) -> Bool {
        recommendation?.id == candidate.id
    }
}

enum BattlefieldConvergenceRole: String, Identifiable, CaseIterable {
    case objective
    case countermeasure
    case stage
    case synergy
    case maneuver
    case threatHeat
    case mapControl

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .objective: return "目标"
        case .countermeasure: return "反制"
        case .stage: return "阶段"
        case .synergy: return "将令"
        case .maneuver: return "机动"
        case .threatHeat: return "热区"
        case .mapControl: return "控区"
        }
    }
}

struct BattlefieldConvergenceSignal: Identifiable {
    var role: BattlefieldConvergenceRole
    var title: String
    var detail: String
    var position: Position?
    var sourceID: String?
    var nextStepLabel: String?

    var id: String {
        [
            role.rawValue,
            sourceID,
            position?.description,
            title
        ].compactMap { $0 }.joined(separator: "-")
    }

    var accessibilityLabel: String {
        var parts = [
            role.displayName,
            title,
            detail
        ]

        if let position {
            parts.append("位置\(position.description)")
        }

        if let nextStepLabel {
            parts.append(nextStepLabel)
        }

        return parts.joined(separator: "，")
    }
}

struct BattlefieldConvergenceSummary: Identifiable {
    var objectiveChain: BattleObjectiveChainSummary?
    var countermeasure: CountermeasureSummary?
    var countermeasurePreview: CountermeasureCommandPreview?
    var stagePreview: BattleObjectiveStageCommandPreview?
    var synergy: CommanderSynergySummary?
    var maneuver: ManeuverOptionSummary?
    var threatHeat: ThreatHeatZoneSummary?
    var mapControl: MapControlSummary?

    var id: String {
        [
            objectiveChain?.id,
            countermeasure?.id,
            countermeasurePreview?.id,
            stagePreview?.id,
            synergy?.id,
            maneuver?.id,
            threatHeat?.id,
            mapControl?.id
        ].compactMap { $0 }.joined(separator: "-")
    }

    var title: String {
        "战场态势交汇"
    }

    var compactLabel: String {
        let label = [
            objectiveChain?.focus.targetLabel,
            countermeasure?.kindLabel,
            threatHeat?.levelLabel ?? mapControl?.levelLabel
        ].compactMap { $0 }.joined(separator: " · ")

        return label.isEmpty ? title : label
    }

    var priorityLabel: String {
        countermeasure?.priorityLabel ??
            objectiveChain?.priorityLabel ??
            threatHeat?.levelLabel ??
            mapControl?.levelLabel ??
            "态势待确认"
    }

    var objectiveLabel: String {
        objectiveChain?.compactLabel ??
            stagePreview?.focusLabel ??
            "暂无目标线"
    }

    var responseLabel: String {
        if let countermeasurePreview {
            return "\(countermeasurePreview.summary.kindLabel) · \(countermeasurePreview.nextStepLabel)"
        }

        if let countermeasure {
            return "\(countermeasure.kindLabel) · \(countermeasure.responseLabel)"
        }

        return "暂无反制建议"
    }

    var spaceLabel: String {
        if let threatHeat {
            return "\(threatHeat.levelLabel) · \(threatHeat.impactLabel)"
        }

        if let mapControl {
            return "\(mapControl.controlLabel) · \(mapControl.impactLabel)"
        }

        if let maneuver {
            return "\(maneuver.destinationLabel) · \(maneuver.controlLabel)"
        }

        return "空间态势待确认"
    }

    var nextStepLabel: String {
        stagePreview?.nextStepLabel ??
            countermeasurePreview?.nextStepLabel ??
            maneuver?.objectiveCueLabel ??
            synergy?.objectiveCueLabel ??
            objectiveChain?.focusStageLabel ??
            "等待选择军团"
    }

    var riskLabel: String {
        countermeasure?.riskLabel ??
            maneuver?.riskLabel ??
            synergy?.riskLabel ??
            threatHeat?.levelLabel ??
            mapControl?.levelLabel ??
            "风险待确认"
    }

    var signals: [BattlefieldConvergenceSignal] {
        var values: [BattlefieldConvergenceSignal] = []

        if let objectiveChain {
            values.append(
                BattlefieldConvergenceSignal(
                    role: .objective,
                    title: objectiveChain.title,
                    detail: objectiveChain.chainLabel,
                    position: objectiveChain.focus.targetPosition,
                    sourceID: objectiveChain.id,
                    nextStepLabel: objectiveChain.priorityLabel
                )
            )
        }

        if let countermeasure {
            values.append(
                BattlefieldConvergenceSignal(
                    role: .countermeasure,
                    title: countermeasure.kindLabel,
                    detail: countermeasure.countermeasureChainLabel,
                    position: countermeasure.targetPosition,
                    sourceID: countermeasure.id,
                    nextStepLabel: countermeasure.commandLabel
                )
            )
        }

        if let stagePreview {
            values.append(
                BattlefieldConvergenceSignal(
                    role: .stage,
                    title: stagePreview.stageLabel,
                    detail: stagePreview.commandEntryCueLabel,
                    position: stagePreview.position,
                    sourceID: stagePreview.sourceSummaryID,
                    nextStepLabel: stagePreview.nextStepLabel
                )
            )
        }

        if let synergy {
            values.append(
                BattlefieldConvergenceSignal(
                    role: .synergy,
                    title: synergy.kindLabel,
                    detail: synergy.impactLabel,
                    position: synergy.targetPosition,
                    sourceID: synergy.id,
                    nextStepLabel: synergy.statusLabel
                )
            )
        }

        if let maneuver {
            values.append(
                BattlefieldConvergenceSignal(
                    role: .maneuver,
                    title: maneuver.kindLabel,
                    detail: "\(maneuver.destinationLabel) · \(maneuver.impactLabel)",
                    position: maneuver.destination,
                    sourceID: maneuver.id,
                    nextStepLabel: maneuver.riskLabel
                )
            )
        }

        if let threatHeat {
            values.append(
                BattlefieldConvergenceSignal(
                    role: .threatHeat,
                    title: threatHeat.levelLabel,
                    detail: "\(threatHeat.sourceLabel) · \(threatHeat.impactLabel)",
                    position: threatHeat.targetPosition,
                    sourceID: threatHeat.id,
                    nextStepLabel: threatHeat.controlLabel
                )
            )
        }

        if let mapControl {
            values.append(
                BattlefieldConvergenceSignal(
                    role: .mapControl,
                    title: mapControl.controlLabel,
                    detail: "\(mapControl.sourceLabel) · \(mapControl.impactLabel)",
                    position: mapControl.position,
                    sourceID: mapControl.id,
                    nextStepLabel: mapControl.levelLabel
                )
            )
        }

        return values
    }

    var hasSignals: Bool {
        !signals.isEmpty
    }

    var accessibilityLabel: String {
        [
            title,
            "优先级\(priorityLabel)",
            "目标\(objectiveLabel)",
            "回应\(responseLabel)",
            "空间\(spaceLabel)",
            "下一步\(nextStepLabel)",
            "风险\(riskLabel)"
        ].joined(separator: "，")
    }

    func references(objectiveChain candidate: BattleObjectiveChainSummary) -> Bool {
        objectiveChain?.id == candidate.id
    }

    func references(countermeasure candidate: CountermeasureSummary) -> Bool {
        countermeasure?.id == candidate.id
    }

    func references(countermeasurePreview candidate: CountermeasureCommandPreview) -> Bool {
        countermeasurePreview?.id == candidate.id
    }

    func references(stagePreview candidate: BattleObjectiveStageCommandPreview) -> Bool {
        stagePreview?.id == candidate.id
    }

    func references(synergy candidate: CommanderSynergySummary) -> Bool {
        synergy?.id == candidate.id
    }

    func references(maneuver candidate: ManeuverOptionSummary) -> Bool {
        maneuver?.id == candidate.id
    }

    func references(threatHeat candidate: ThreatHeatZoneSummary) -> Bool {
        threatHeat?.id == candidate.id
    }

    func references(mapControl candidate: MapControlSummary) -> Bool {
        mapControl?.id == candidate.id
    }
}

enum EnemyEngagementLoopSignalKind: String {
    case intentRoute
    case frontline
    case enemyCommander
    case countermeasure
    case counterCommand
    case responseCommander
    case convergence

    var displayName: String {
        switch self {
        case .intentRoute:
            return "敌路"
        case .frontline:
            return "压力"
        case .enemyCommander:
            return "敌将"
        case .countermeasure:
            return "反制"
        case .counterCommand:
            return "指令"
        case .responseCommander:
            return "回应"
        case .convergence:
            return "交汇"
        }
    }
}

struct EnemyEngagementLoopSignal: Identifiable {
    var kind: EnemyEngagementLoopSignalKind
    var title: String
    var detail: String
    var position: Position?
    var sourceID: String

    var id: String {
        [
            kind.rawValue,
            sourceID,
            position?.description,
            title
        ].compactMap { $0 }.joined(separator: "-")
    }

    var accessibilityLabel: String {
        var parts = [
            kind.displayName,
            title,
            detail
        ]

        if let position {
            parts.append("位置\(position.description)")
        }

        return parts.joined(separator: "，")
    }
}

struct EnemyEngagementLoopReadout {
    var title: String
    var statusLabel: String
    var intentLabel: String
    var pressureLabel: String
    var enemyCommanderLabel: String
    var countermeasureLabel: String
    var responseLabel: String
    var nextStepLabel: String
    var riskLabel: String
    var compactLabel: String
    var signals: [EnemyEngagementLoopSignal]
    var intentID: String?
    var pressureID: String?
    var enemyCommanderThreatID: String?
    var countermeasureID: String?
    var countermeasurePreviewID: String?
    var responseCommanderChainUnitID: String?
    var convergenceID: String?

    var hasSignals: Bool {
        !signals.isEmpty
    }

    var accessibilityLabel: String {
        [
            title,
            "状态\(statusLabel)",
            "敌路\(intentLabel)",
            "压力\(pressureLabel)",
            "敌将\(enemyCommanderLabel)",
            "反制\(countermeasureLabel)",
            "回应\(responseLabel)",
            "下一步\(nextStepLabel)",
            "风险\(riskLabel)"
        ].joined(separator: "，")
    }

    func references(intent candidate: EnemyIntentMapOverlay) -> Bool {
        intentID == candidate.id
    }

    func references(pressure candidate: FrontlinePressureSummary) -> Bool {
        pressureID == candidate.id
    }

    func references(enemyCommanderThreat candidate: EnemyCommanderThreatSummary) -> Bool {
        enemyCommanderThreatID == candidate.id
    }

    func references(countermeasure candidate: CountermeasureSummary) -> Bool {
        countermeasureID == candidate.id
    }

    func references(countermeasurePreview candidate: CountermeasureCommandPreview) -> Bool {
        countermeasurePreviewID == candidate.id
    }

    func references(responseCommanderChain candidate: SelectedCommanderChainReadout) -> Bool {
        responseCommanderChainUnitID == candidate.unitID
    }

    func references(convergence candidate: BattlefieldConvergenceSummary) -> Bool {
        convergenceID == candidate.id
    }
}

enum MapReconPerspectiveSignalKind: String {
    case enemyIntent
    case enemyCommander
    case engagementLoop
    case countermeasure
    case counterCommand
    case objectiveChain
    case objectiveStage
    case threatHeat
    case mapControl
    case convergence

    var displayName: String {
        switch self {
        case .enemyIntent:
            return "敌路"
        case .enemyCommander:
            return "敌将"
        case .engagementLoop:
            return "闭环"
        case .countermeasure:
            return "反制"
        case .counterCommand:
            return "指令"
        case .objectiveChain:
            return "目标线"
        case .objectiveStage:
            return "阶段"
        case .threatHeat:
            return "热区"
        case .mapControl:
            return "控区"
        case .convergence:
            return "交汇"
        }
    }
}

struct MapReconPerspectiveSignal: Identifiable {
    var kind: MapReconPerspectiveSignalKind
    var title: String
    var detail: String
    var position: Position?
    var sourceID: String

    var id: String {
        [
            kind.rawValue,
            sourceID,
            position?.description,
            title
        ].compactMap { $0 }.joined(separator: "-")
    }

    var accessibilityLabel: String {
        var parts = [
            kind.displayName,
            title,
            detail
        ]

        if let position {
            parts.append("位置\(position.description)")
        }

        return parts.joined(separator: "，")
    }
}

struct MapReconPerspectiveHUDReadout {
    var selectedKind: MapReconPerspectiveKind
    var availableKinds: [MapReconPerspectiveKind]
    var title: String
    var statusLabel: String
    var compactLabel: String
    var detailLabel: String
    var nextStepLabel: String
    var riskLabel: String
    var signals: [MapReconPerspectiveSignal]
    var intentID: String?
    var enemyCommanderThreatID: String?
    var engagementLoopID: String?
    var countermeasureID: String?
    var countermeasurePreviewID: String?
    var objectiveChainID: String?
    var objectiveStagePreviewID: String?
    var threatHeatID: String?
    var mapControlID: String?
    var convergenceID: String?

    var hasSignals: Bool {
        !signals.isEmpty
    }

    var selectorLabel: String {
        availableKinds.map(\.shortLabel).joined(separator: "/")
    }

    var accessibilityLabel: String {
        [
            title,
            "视角\(selectedKind.displayName)",
            "状态\(statusLabel)",
            detailLabel,
            "下一步\(nextStepLabel)",
            "风险\(riskLabel)"
        ].joined(separator: "，")
    }

    func references(intent candidate: EnemyIntentMapOverlay) -> Bool {
        intentID == candidate.id
    }

    func references(threat candidate: EnemyCommanderThreatMapOverlay) -> Bool {
        enemyCommanderThreatID == candidate.id
    }

    func references(threat candidate: EnemyCommanderThreatSummary) -> Bool {
        enemyCommanderThreatID == candidate.id
    }

    func references(engagementLoop candidate: EnemyEngagementLoopReadout) -> Bool {
        engagementLoopID == candidate.compactLabel
    }

    func references(countermeasure candidate: CountermeasureSummary) -> Bool {
        countermeasureID == candidate.id
    }

    func references(countermeasurePreview candidate: CountermeasureCommandPreview) -> Bool {
        countermeasurePreviewID == candidate.id
    }

    func references(objectiveChain candidate: BattleObjectiveChainSummary) -> Bool {
        objectiveChainID == candidate.id
    }

    func references(stagePreview candidate: BattleObjectiveStageCommandPreview) -> Bool {
        objectiveStagePreviewID == candidate.id
    }

    func references(threatHeat candidate: ThreatHeatZoneSummary) -> Bool {
        threatHeatID == candidate.id
    }

    func references(mapControl candidate: MapControlSummary) -> Bool {
        mapControlID == candidate.id
    }

    func references(convergence candidate: BattlefieldConvergenceSummary) -> Bool {
        convergenceID == candidate.id
    }
}

enum CampaignAdvanceSignalKind: String {
    case mission
    case progress
    case frontline
    case objectiveChain
    case objectiveStage
    case recon
    case convergence

    var displayName: String {
        switch self {
        case .mission:
            return "任务"
        case .progress:
            return "进度"
        case .frontline:
            return "战线"
        case .objectiveChain:
            return "目标线"
        case .objectiveStage:
            return "阶段"
        case .recon:
            return "侦察"
        case .convergence:
            return "交汇"
        }
    }
}

struct CampaignAdvanceSignal: Identifiable {
    var kind: CampaignAdvanceSignalKind
    var title: String
    var detail: String
    var position: Position?
    var sourceID: String?

    var id: String {
        [
            kind.rawValue,
            sourceID,
            position?.description,
            title
        ].compactMap { $0 }.joined(separator: "-")
    }

    var accessibilityLabel: String {
        var parts = [
            kind.displayName,
            title,
            detail
        ]

        if let position {
            parts.append("位置\(position.description)")
        }

        return parts.joined(separator: "，")
    }
}

struct CampaignAdvanceReadout {
    var title: String
    var statusLabel: String
    var missionTitle: String
    var missionObjectiveLabel: String
    var progressLabel: String
    var frontlineLabel: String
    var objectiveLineLabel: String
    var mapCueLabel: String
    var nextStepLabel: String
    var riskLabel: String
    var compactLabel: String
    var signals: [CampaignAdvanceSignal]
    var missionID: String?
    var progressText: String?
    var frontlineID: String?
    var objectiveChainID: String?
    var objectiveStagePreviewID: String?
    var reconPerspectiveID: String?
    var convergenceID: String?

    var hasSignals: Bool {
        !signals.isEmpty
    }

    var accessibilityLabel: String {
        [
            title,
            "状态\(statusLabel)",
            "任务\(missionTitle)",
            "目标\(missionObjectiveLabel)",
            "进度\(progressLabel)",
            "战线\(frontlineLabel)",
            "目标线\(objectiveLineLabel)",
            "地图\(mapCueLabel)",
            "下一步\(nextStepLabel)",
            "风险\(riskLabel)"
        ].joined(separator: "，")
    }

    func references(mission candidate: Mission) -> Bool {
        missionID == candidate.id
    }

    func references(pressure candidate: FrontlinePressureSummary) -> Bool {
        frontlineID == candidate.id
    }

    func references(objectiveChain candidate: BattleObjectiveChainSummary) -> Bool {
        objectiveChainID == candidate.id
    }

    func references(stagePreview candidate: BattleObjectiveStageCommandPreview) -> Bool {
        objectiveStagePreviewID == candidate.id
    }

    func references(recon candidate: MapReconPerspectiveHUDReadout) -> Bool {
        reconPerspectiveID == candidate.selectedKind.rawValue
    }

    func references(convergence candidate: BattlefieldConvergenceSummary) -> Bool {
        convergenceID == candidate.id
    }
}

struct BattleObjectiveRouteSegment: Identifiable {
    var id: String
    var from: Position
    var to: Position
    var fromRole: BattleObjectiveMapRole
    var toRole: BattleObjectiveMapRole
    var isTargetLeg: Bool
}

enum BattleObjectiveMapRole: String, Identifiable {
    case focus
    case synergy
    case maneuver
    case recommendation

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .focus: return "焦点"
        case .synergy: return "将令"
        case .maneuver: return "机动"
        case .recommendation: return "军议"
        }
    }

    var stageNumber: Int {
        switch self {
        case .focus: return 1
        case .synergy: return 2
        case .maneuver: return 3
        case .recommendation: return 4
        }
    }

    var stageLabel: String {
        "\(stageNumber) \(displayName)"
    }
}

struct BattleObjectivePositionOverlay: Identifiable {
    var chain: BattleObjectiveChainSummary
    var role: BattleObjectiveMapRole
    var position: Position

    var id: String {
        "\(chain.id)-\(role.rawValue)-\(position.x)-\(position.y)"
    }

    var stageLabel: String {
        role.stageLabel
    }

    var focusLabel: String {
        switch role {
        case .focus:
            return chain.focusStageLabel
        case .synergy:
            return chain.synergyStageLabel
        case .maneuver:
            return chain.maneuverStageLabel
        case .recommendation:
            return chain.recommendationStageLabel
        }
    }

    var chainLabel: String {
        chain.chainLabel
    }

    var accessibilityLabel: String {
        "\(stageLabel)目标线\(position.description)，\(focusLabel)，\(chainLabel)"
    }
}

struct BattleObjectiveMapOverlay: Identifiable {
    var chain: BattleObjectiveChainSummary

    var id: String { chain.id }
    var chainLabel: String { chain.chainLabel }

    var positionOverlays: [BattleObjectivePositionOverlay] {
        var overlays = [
            BattleObjectivePositionOverlay(
                chain: chain,
                role: .focus,
                position: chain.focus.targetPosition
            )
        ]

        if let synergy = chain.synergy {
            overlays.append(
                BattleObjectivePositionOverlay(
                    chain: chain,
                    role: .synergy,
                    position: synergy.targetPosition
                )
            )
        }

        if let maneuver = chain.maneuver {
            overlays.append(
                BattleObjectivePositionOverlay(
                    chain: chain,
                    role: .maneuver,
                    position: maneuver.destination
                )
            )
        }

        if let recommendation = chain.recommendation {
            overlays.append(
                BattleObjectivePositionOverlay(
                    chain: chain,
                    role: .recommendation,
                    position: recommendation.targetPosition
                )
            )
        }

        return overlays
    }

    var routeSegments: [BattleObjectiveRouteSegment] {
        let overlays = positionOverlays
        var segments: [BattleObjectiveRouteSegment] = []

        for (index, pair) in zip(overlays, overlays.dropFirst()).enumerated() {
            guard pair.0.position != pair.1.position else { continue }
            segments.append(
                BattleObjectiveRouteSegment(
                    id: "\(id)-objective-\(index)",
                    from: pair.0.position,
                    to: pair.1.position,
                    fromRole: pair.0.role,
                    toRole: pair.1.role,
                    isTargetLeg: pair.1.role == .recommendation
                )
            )
        }

        if segments.isEmpty,
           let first = overlays.first {
            segments.append(
                BattleObjectiveRouteSegment(
                    id: "\(id)-objective-focus",
                    from: first.position,
                    to: first.position,
                    fromRole: first.role,
                    toRole: first.role,
                    isTargetLeg: true
                )
            )
        }

        return segments
    }

    var accessibilityLabel: String {
        "战场目标线地图叠层，\(chainLabel)"
    }

    func references(chain candidate: BattleObjectiveChainSummary) -> Bool {
        chain.id == candidate.id
    }
}
