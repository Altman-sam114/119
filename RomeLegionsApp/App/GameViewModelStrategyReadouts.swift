import Foundation
import SwiftUI

struct MapControlSummary: Identifiable {
    var report: MapControlReport
    var city: City?
    var occupant: ArmyUnit?
    var friendlyUnits: [ArmyUnit]
    var enemyUnits: [ArmyUnit]

    var id: String { report.id }
    var position: Position { report.position }
    var controlState: MapControlState { report.controlState }
    var threatLevel: ThreatHeatLevel { report.threatLevel }

    var title: String {
        if let city {
            return "\(city.name) \(controlLabel)"
        }

        if let occupant {
            return "\(occupant.faction.displayName)\(occupant.kind.displayName) \(controlLabel)"
        }

        return "\(position.description) \(controlLabel)"
    }

    var compactTitle: String {
        "\(controlLabel) \(levelLabel)"
    }

    var controlLabel: String {
        report.controlState.displayName
    }

    var levelLabel: String {
        report.threatLevel.displayName
    }

    var sourceLabel: String {
        if !enemyUnits.isEmpty {
            let labels = enemyUnits.prefix(3).map { "\($0.faction.displayName)\($0.kind.displayName)" }
            return enemyUnits.count > 3 ? "\(labels.joined(separator: "、"))等 \(enemyUnits.count) 支" : labels.joined(separator: "、")
        }

        if !friendlyUnits.isEmpty {
            let labels = friendlyUnits.prefix(3).map { "\($0.faction.displayName)\($0.kind.displayName)" }
            return friendlyUnits.count > 3 ? "\(labels.joined(separator: "、"))等 \(friendlyUnits.count) 支" : labels.joined(separator: "、")
        }

        return city?.name ?? "无单位覆盖"
    }

    var impactLabel: String {
        if report.pressureScore > 0 {
            return "压力 \(report.pressureScore)"
        }

        return "友\(report.friendlyInfluence)/敌\(report.enemyInfluence)"
    }

    var detail: String {
        report.detail
    }

    var accessibilityLabel: String {
        "\(title)，\(levelLabel)，来源\(sourceLabel)，\(detail)"
    }
}

struct ThreatHeatZoneSummary: Identifiable {
    var report: ThreatHeatZoneReport
    var sourceUnits: [ArmyUnit]
    var cities: [City]

    var id: String { report.id }
    var targetPosition: Position { report.center }
    var threatLevel: ThreatHeatLevel { report.threatLevel }

    var title: String {
        report.title
    }

    var compactTitle: String {
        "\(levelLabel) \(impactLabel)"
    }

    var levelLabel: String {
        report.threatLevel.displayName
    }

    var controlLabel: String {
        report.controlState.displayName
    }

    var sourceLabel: String {
        guard !sourceUnits.isEmpty else {
            return cities.first?.name ?? "敌方覆盖"
        }

        let labels = sourceUnits.prefix(3).map { "\($0.faction.displayName)\($0.kind.displayName)" }
        return sourceUnits.count > 3 ? "\(labels.joined(separator: "、"))等 \(sourceUnits.count) 支" : labels.joined(separator: "、")
    }

    var impactLabel: String {
        if report.captureIntentCount > 0 {
            return "\(report.captureIntentCount) 路夺城"
        }

        if report.projectedDamageTotal > 0 {
            return "预计伤害 \(report.projectedDamageTotal)"
        }

        return "威胁 \(report.score)"
    }

    var detail: String {
        report.detail
    }

    var accessibilityLabel: String {
        "\(title)，热区\(levelLabel)，\(controlLabel)，来源\(sourceLabel)，\(impactLabel)，\(detail)"
    }
}

struct AIOperationalPlanTimelineStepReadout: Identifiable {
    var sequence: Int
    var step: AIPlanStepReport
    var unit: ArmyUnit?
    var targetUnit: ArmyUnit?
    var targetCity: City?

    var id: String { "\(sequence)-\(step.id)" }
    var role: AIPlanCoordinationRole { step.coordinationRole }

    var roleLabel: String {
        step.coordinationRole.displayName
    }

    var unitLabel: String {
        if let generalName = step.generalName, !generalName.isEmpty {
            return generalName
        }

        if let generalName = unit?.generalName {
            return generalName
        }

        if let unit {
            return "\(unit.faction.displayName)\(unit.kind.displayName)"
        }

        return "\(step.faction.displayName)军团"
    }

    var intentLabel: String {
        step.intentKind.displayName
    }

    var originLabel: String {
        "起点\(step.origin.description)"
    }

    var destinationLabel: String {
        step.destination == step.origin ? "原地\(step.destination.description)" : "目的\(step.destination.description)"
    }

    var targetLabel: String {
        if let targetUnit {
            return "目标\(targetUnit.faction.displayName)\(targetUnit.kind.displayName)"
        }

        if let targetCity {
            return "目标\(targetCity.name)"
        }

        return "目标\(step.targetPosition.description)"
    }

    var orderLabel: String {
        step.tacticalOrder.displayName
    }

    var impactLabel: String {
        if let projectedDamage = step.projectedDamage, projectedDamage > 0 {
            return "预计伤害 \(projectedDamage)"
        }

        if let skillSummary = step.skillSummary, !skillSummary.isEmpty {
            return "预计技能 \(skillSummary)"
        }

        return "预计威胁 \(step.threatScore)"
    }

    var routeLabel: String {
        "\(originLabel) -> \(destinationLabel) -> \(targetLabel)"
    }

    var compactLabel: String {
        "\(sequence). \(roleLabel)\(unitLabel) \(intentLabel)"
    }

    var detailLabel: String {
        step.detail
    }

    var accessibilityLabel: String {
        "队列\(sequence)，角色\(roleLabel)，\(unitLabel)，意图\(intentLabel)，\(originLabel)，\(destinationLabel)，\(targetLabel)，姿态\(orderLabel)，\(impactLabel)，\(detailLabel)"
    }
}

struct AIOperationalPlanSummary: Identifiable {
    var report: AIOperationalPlanReport
    var targetUnit: ArmyUnit?
    var targetCity: City?
    var sourceUnits: [ArmyUnit]
    var commanderUnits: [ArmyUnit]
    var timelineSteps: [AIOperationalPlanTimelineStepReadout]

    var id: String { report.id }
    var kind: AIOperationalPlanKind { report.kind }
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

    var factionLabel: String {
        report.faction.displayName
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

    var sourceLabel: String {
        guard !sourceUnits.isEmpty else {
            return "敌方行动"
        }

        let labels = sourceUnits.prefix(3).map { "\($0.faction.displayName)\($0.kind.displayName)" }
        return sourceUnits.count > 3 ? "\(labels.joined(separator: "、"))等 \(sourceUnits.count) 支" : labels.joined(separator: "、")
    }

    var commanderLabel: String? {
        let names = commanderUnits.compactMap(\.generalName)
        guard !names.isEmpty else {
            return nil
        }

        return names.joined(separator: "、")
    }

    var pressureLabel: String {
        report.pressureLevel?.displayName ?? "无集中压力"
    }

    var heatLabel: String {
        report.threatHeatLevel?.displayName ?? "无热区"
    }

    var impactLabel: String {
        if report.projectedDamageTotal > 0 {
            return "预计伤害 \(report.projectedDamageTotal)"
        }

        return "\(report.steps.count) 步"
    }

    var stepLabel: String {
        let labels = report.steps.prefix(3).map { "\($0.coordinationRole.displayName)\($0.intentKind.displayName)" }
        return labels.joined(separator: "、")
    }

    var timelineLabel: String {
        let labels = timelineSteps.prefix(3).map(\.compactLabel)
        return labels.joined(separator: " -> ")
    }

    var timelineAccessibilityLabel: String {
        let labels = timelineSteps.map(\.accessibilityLabel)
        return "时间线，\(labels.joined(separator: "，"))"
    }

    var detail: String {
        report.detail
    }

    var accessibilityLabel: String {
        var parts = [
            "\(factionLabel)\(kindLabel)",
            "目标\(targetLabel)",
            "来源\(sourceLabel)",
            impactLabel,
            "压力\(pressureLabel)",
            "热区\(heatLabel)",
            timelineAccessibilityLabel,
            detail
        ]

        if let commanderLabel {
            parts.insert("将领\(commanderLabel)", at: 3)
        }

        return parts.joined(separator: "，")
    }
}

struct EnemyCommanderThreatSummary: Identifiable {
    var report: EnemyCommanderThreatReport
    var commanderUnit: ArmyUnit?
    var targetUnit: ArmyUnit?
    var targetCity: City?
    var affectedUnits: [ArmyUnit]
    var affectedCities: [City]

    var id: String { report.id }
    var level: EnemyCommanderThreatLevel { report.threatLevel }
    var trait: GeneralTrait { report.generalTrait }
    var targetPosition: Position { report.targetPosition }

    var originPosition: Position {
        report.position
    }

    var originLabel: String {
        "起点\(originPosition.description)"
    }

    var targetPositionLabel: String {
        "目标位置\(targetPosition.description)"
    }

    var destinationPosition: Position? {
        report.destination
    }

    var destinationLabel: String {
        guard let destinationPosition else { return "无意图落点" }
        return "落点\(destinationPosition.description)"
    }

    var title: String {
        report.title
    }

    var compactTitle: String {
        "\(level.displayName) \(impactLabel)"
    }

    var factionLabel: String {
        report.faction.displayName
    }

    var commanderLabel: String {
        report.generalName
    }

    var traitLabel: String {
        trait.displayName
    }

    var skillName: String {
        trait.skillName
    }

    var intentLabel: String {
        report.intentKind?.displayName ?? "将领待机"
    }

    var levelLabel: String {
        level.displayName
    }

    var targetLabel: String {
        if let targetUnit {
            return "\(targetUnit.faction.displayName)\(targetUnit.kind.displayName)"
        }

        if let targetCity {
            return targetCity.name
        }

        if let city = affectedCities.first {
            return city.name
        }

        return report.targetPosition.description
    }

    var rangeLabel: String {
        report.rangePositions.isEmpty ? "无技能范围" : "范围 \(report.rangePositions.count) 格"
    }

    var impactLabel: String {
        report.impact
    }

    var statusLabel: String {
        report.skillReady ? "技能就绪" : (report.skillBlockedReason ?? "技能暂不可用")
    }

    var scoreLabel: String {
        "威胁 \(report.score)"
    }

    var detail: String {
        report.detail
    }

    var affectedLabel: String {
        if !affectedUnits.isEmpty {
            let labels = affectedUnits.prefix(2).map { "\($0.faction.displayName)\($0.kind.displayName)" }
            return affectedUnits.count > 2 ? "\(labels.joined(separator: "、"))等 \(affectedUnits.count) 支" : labels.joined(separator: "、")
        }

        if !affectedCities.isEmpty {
            let labels = affectedCities.prefix(2).map(\.name)
            return affectedCities.count > 2 ? "\(labels.joined(separator: "、"))等 \(affectedCities.count) 城" : labels.joined(separator: "、")
        }

        return targetLabel
    }

    var affectedPositionLabel: String {
        if report.affectedPositions.isEmpty {
            return "无直接影响位置"
        }

        let positions = report.affectedPositions.prefix(4).map { $0.description }
        let suffix = report.affectedPositions.count > positions.count ? "等 \(report.affectedPositions.count) 格" : ""
        return "影响位置\(positions.joined(separator: "、"))\(suffix)"
    }

    var spaceChainLabel: String {
        [originLabel, rangeLabel, affectedPositionLabel, targetPositionLabel, destinationLabel]
            .joined(separator: " · ")
    }

    var accessibilityLabel: String {
        [
            "敌方将领\(commanderLabel)",
            traitLabel,
            "等级\(levelLabel)",
            "意图\(intentLabel)",
            originLabel,
            rangeLabel,
            affectedPositionLabel,
            targetPositionLabel,
            destinationLabel,
            "目标\(targetLabel)",
            impactLabel,
            statusLabel,
            scoreLabel,
            detail
        ].joined(separator: "，")
    }
}

/// v0.66 当前敌将上下文的唯一只读来源。
///
/// 这个 readout 同时承载 active summary 和由同一 summary 构造的地图 overlay
/// 的身份字段，供地图、底部命令坞和敌情卡共享。它不持有命令闭包，也不把敌将
/// 转成 selectedUnit/selectedCity；`hasExecutableCommand` 永远为 false。
struct EnemyCommanderThreatFocusReadout {
    var threatID: String
    var overlayID: String
    var commanderLabel: String
    var factionLabel: String
    var traitLabel: String
    var skillName: String
    var skillSymbol: String
    var title: String
    var compactTitle: String
    var levelLabel: String
    var scoreLabel: String
    var intentLabel: String
    var impactLabel: String
    var statusLabel: String
    var targetLabel: String
    var originPosition: Position
    var targetPosition: Position
    var destinationPosition: Position?
    var rangePositions: [Position]
    var affectedPositions: [Position]
    var originLabel: String
    var targetPositionLabel: String
    var destinationLabel: String
    var rangeLabel: String
    var affectedLabel: String
    var affectedPositionLabel: String
    var spaceChainLabel: String
    var routeLabel: String
    var routeSegments: [EnemyCommanderThreatRouteSegment]
    var isFocused: Bool
    var isPrimaryFallback: Bool
    var focusStateLabel: String
    var selectedPerspective: MapReconPerspectiveKind
    var compactLabel: String
    var detailLabel: String
    var commandAvailabilityLabel: String
    var hasExecutableCommand: Bool
    var accessibilityLabel: String

    init(
        summary: EnemyCommanderThreatSummary,
        overlay: EnemyCommanderThreatMapOverlay,
        focusedThreatID: String?,
        selectedPerspective: MapReconPerspectiveKind
    ) {
        threatID = summary.id
        overlayID = overlay.id
        commanderLabel = summary.commanderLabel
        factionLabel = summary.factionLabel
        traitLabel = summary.traitLabel
        skillName = summary.skillName
        skillSymbol = summary.trait.systemImage
        title = summary.title
        compactTitle = summary.compactTitle
        levelLabel = summary.levelLabel
        scoreLabel = summary.scoreLabel
        intentLabel = summary.intentLabel
        impactLabel = summary.impactLabel
        statusLabel = summary.statusLabel
        targetLabel = summary.targetLabel
        originPosition = summary.originPosition
        targetPosition = summary.targetPosition
        destinationPosition = summary.destinationPosition
        rangePositions = overlay.rangePositions
        affectedPositions = overlay.affectedPositions
        originLabel = summary.originLabel
        targetPositionLabel = summary.targetPositionLabel
        destinationLabel = summary.destinationLabel
        rangeLabel = summary.rangeLabel
        affectedLabel = summary.affectedLabel
        affectedPositionLabel = summary.affectedPositionLabel
        spaceChainLabel = summary.spaceChainLabel
        routeLabel = overlay.chainLabel
        routeSegments = overlay.routeSegments
        isFocused = focusedThreatID == summary.id
        isPrimaryFallback = focusedThreatID != nil && !isFocused
        focusStateLabel = isFocused
            ? "已定位"
            : (isPrimaryFallback ? "焦点失效 · 显示首要威胁" : "首要威胁")
        self.selectedPerspective = selectedPerspective
        compactLabel = "\(commanderLabel) · \(levelLabel) · \(skillName)"
        detailLabel = "\(focusStateLabel) · \(skillName) · \(targetLabel) · \(spaceChainLabel)"
        commandAvailabilityLabel = "仅侦察，不执行敌将命令"
        hasExecutableCommand = false
        accessibilityLabel = [
            "\(focusStateLabel)敌将\(commanderLabel)",
            factionLabel,
            "特性\(traitLabel)",
            "技能\(skillName)",
            "威胁\(levelLabel)",
            scoreLabel,
            "目标\(targetLabel)",
            originLabel,
            rangeLabel,
            affectedPositionLabel,
            destinationLabel,
            "路线\(routeLabel)",
            commandAvailabilityLabel,
            "威胁身份\(threatID)"
        ].joined(separator: "，")
    }

    func references(summary: EnemyCommanderThreatSummary) -> Bool {
        threatID == summary.id
    }

    func references(overlay: EnemyCommanderThreatMapOverlay) -> Bool {
        overlayID == overlay.id && threatID == overlay.threatID
    }
}

struct CountermeasureSummary: Identifiable {
    var report: CountermeasureReport
    var responseUnit: ArmyUnit?
    var targetUnit: ArmyUnit?
    var targetCity: City?

    var id: String { report.id }
    var kind: CountermeasureKind { report.kind }
    var priority: CountermeasurePriority { report.priority }
    var targetPosition: Position { report.targetPosition }
    var responsePosition: Position { report.responsePosition }
    var destination: Position { report.destination }

    var title: String {
        report.title
    }

    var compactTitle: String {
        "\(priorityLabel) \(kindLabel)"
    }

    var kindLabel: String {
        report.kind.displayName
    }

    var priorityLabel: String {
        report.priority.displayName
    }

    var threatLabel: String {
        report.threatTitle
    }

    var responseLabel: String {
        "\(unitLabel) \(report.recommendedOrder.displayName)"
    }

    var unitLabel: String {
        if let responseUnit {
            if let generalName = responseUnit.generalName {
                return "\(generalName) \(responseUnit.kind.displayName)"
            }
            return "\(responseUnit.faction.displayName)\(responseUnit.kind.displayName)"
        }

        return report.responseUnitID
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

    var impactLabel: String {
        var parts: [String] = []
        if let damage = report.projectedDamageDealt,
           damage > 0 {
            parts.append("反击 \(damage)")
        }
        if let prevented = report.projectedDamagePrevented,
           prevented > 0 {
            parts.append("止损 \(prevented)")
        }
        if let recovery = report.projectedRecovery,
           recovery > 0 {
            parts.append("恢复 \(recovery)")
        }

        return parts.isEmpty ? "收益待确认" : parts.joined(separator: " · ")
    }

    var riskLabel: String {
        report.risk.displayName
    }

    var commandLabel: String {
        report.command
    }

    var countermeasureChainLabel: String {
        "\(CountermeasureMapRole.response.stageLabel) \(unitLabel) → \(CountermeasureMapRole.destination.stageLabel) \(destination.description) → \(CountermeasureMapRole.target.stageLabel) \(targetLabel)"
    }

    var detail: String {
        report.detail
    }

    var reasonLabel: String {
        report.reasons.prefix(2).joined(separator: " · ")
    }

    var accessibilityLabel: String {
        [
            "反制\(kindLabel)",
            "优先级\(priorityLabel)",
            "威胁\(threatLabel)",
            "回应\(responseLabel)",
            countermeasureChainLabel,
            "目标\(targetLabel)",
            impactLabel,
            "风险\(riskLabel)",
            commandLabel
        ].joined(separator: "，")
    }

    var routeSegments: [CountermeasureRouteSegment] {
        var segments: [CountermeasureRouteSegment] = []

        if responsePosition != destination {
            segments.append(
                CountermeasureRouteSegment(
                    id: "\(id)-response",
                    from: responsePosition,
                    to: destination,
                    isTargetLeg: false,
                    kind: kind,
                    priority: priority
                )
            )
        }

        if destination != targetPosition {
            segments.append(
                CountermeasureRouteSegment(
                    id: "\(id)-target",
                    from: destination,
                    to: targetPosition,
                    isTargetLeg: true,
                    kind: kind,
                    priority: priority
                )
            )
        }

        if segments.isEmpty {
            segments.append(
                CountermeasureRouteSegment(
                    id: "\(id)-focus",
                    from: responsePosition,
                    to: targetPosition,
                    isTargetLeg: true,
                    kind: kind,
                    priority: priority
                )
            )
        }

        return segments
    }
}

struct FrontlinePressureSummary: Identifiable {
    var report: FrontlinePressureReport
    var targetUnit: ArmyUnit?
    var targetCity: City?
    var sourceUnits: [ArmyUnit]

    var id: String { report.id }
    var level: FrontlinePressureLevel { report.level }
    var targetPosition: Position { report.targetPosition }

    var targetLabel: String {
        if let targetUnit {
            return "\(targetUnit.faction.displayName)\(targetUnit.kind.displayName)"
        }

        if let targetCity {
            return targetCity.name
        }

        return "\(report.targetKind.displayName)\(report.targetID)"
    }

    var shortLabel: String {
        if let targetCity {
            return targetCity.name
        }

        if let targetUnit {
            return targetUnit.kind.displayName
        }

        return report.targetKind.displayName
    }

    var pressureLabel: String {
        level.displayName
    }

    var sourceLabel: String {
        guard !sourceUnits.isEmpty else {
            return report.sourceFactions.map(\.displayName).joined(separator: "、")
        }

        let labels = sourceUnits.prefix(3).map { "\($0.faction.displayName)\($0.kind.displayName)" }
        if sourceUnits.count > 3 {
            return "\(labels.joined(separator: "、"))等 \(sourceUnits.count) 支"
        }

        return labels.joined(separator: "、")
    }

    var intentMixLabel: String {
        var parts: [String] = []
        if report.attackIntentCount > 0 {
            parts.append("\(report.attackIntentCount) 路攻击")
        }
        if report.captureIntentCount > 0 {
            parts.append("\(report.captureIntentCount) 路夺城")
        }

        let skillCount = report.intentKinds.filter { $0 == .useSkill }.count
        if skillCount > 0 {
            parts.append("\(skillCount) 路技能")
        }

        let regroupCount = report.intentKinds.filter { $0 == .regroup }.count
        if regroupCount > 0 {
            parts.append("\(regroupCount) 路整备")
        }

        let defendCount = report.intentKinds.filter { $0 == .defend }.count
        if defendCount > 0 {
            parts.append("\(defendCount) 路固守")
        }

        let counted = report.attackIntentCount + report.captureIntentCount + skillCount + regroupCount + defendCount
        let advanceCount = max(0, report.intentCount - counted)
        if advanceCount > 0 {
            parts.append("\(advanceCount) 路推进")
        }

        return parts.isEmpty ? "\(report.intentCount) 路动向" : parts.joined(separator: " · ")
    }

    var impactLabel: String {
        if report.captureIntentCount > 0 {
            return "夺城压力"
        }

        if report.projectedDamageTotal > 0 {
            return "预计伤害 \(report.projectedDamageTotal)"
        }

        return "威胁 \(report.maxThreatScore)"
    }

    var title: String {
        "\(targetLabel) \(pressureLabel)"
    }

    var compactTitle: String {
        "\(shortLabel) \(pressureLabel)"
    }

    var detail: String {
        "\(sourceLabel) · \(intentMixLabel) · \(impactLabel)"
    }

    var accessibilityLabel: String {
        "\(targetLabel)，战线压力\(pressureLabel)，来源\(sourceLabel)，\(intentMixLabel)，\(impactLabel)"
    }
}

enum SelectedUnitSituationSignalKind: String {
    case pressure
    case threatHeat
    case mapControl
    case formation
    case recommendation
    case maneuver
    case synergy

    var displayName: String {
        switch self {
        case .pressure:
            return "压力"
        case .threatHeat:
            return "热区"
        case .mapControl:
            return "控区"
        case .formation:
            return "编制"
        case .recommendation:
            return "军议"
        case .maneuver:
            return "机动"
        case .synergy:
            return "将令"
        }
    }
}

struct SelectedUnitSituationSignal: Identifiable {
    var kind: SelectedUnitSituationSignalKind
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
        [
            kind.displayName,
            title,
            detail,
            position.map { "坐标 \($0.description)" }
        ].compactMap { $0 }.joined(separator: "，")
    }
}

enum SelectedUnitSituationCommandEntryKind: String {
    case countermeasure
    case objectiveStage
    case commanderAction
    case maneuver
    case recommendation
    case tacticalOrder

    var displayName: String {
        switch self {
        case .countermeasure:
            return "反制"
        case .objectiveStage:
            return "目标线"
        case .commanderAction:
            return "将领"
        case .maneuver:
            return "机动"
        case .recommendation:
            return "军议"
        case .tacticalOrder:
            return "姿态"
        }
    }
}

struct SelectedUnitSituationCommandEntry: Identifiable {
    var kind: SelectedUnitSituationCommandEntryKind
    var title: String
    var detail: String
    var cueLabel: String
    var position: Position?
    var sourceID: String?
    var isPrimary: Bool

    var id: String {
        [
            kind.rawValue,
            sourceID,
            position?.description,
            title
        ].compactMap { $0 }.joined(separator: "-")
    }

    var accessibilityLabel: String {
        [
            kind.displayName,
            title,
            cueLabel,
            detail,
            position.map { "坐标 \($0.description)" }
        ].compactMap { $0 }.joined(separator: "，")
    }
}

struct SelectedUnitSituationReadout {
    var unitID: String
    var position: Position
    var title: String
    var statusLabel: String
    var pressureLabel: String
    var spaceLabel: String
    var opportunityLabel: String
    var nextStepLabel: String
    var riskLabel: String
    var signals: [SelectedUnitSituationSignal]
    var commandEntries: [SelectedUnitSituationCommandEntry]
    var pressureID: String?
    var threatHeatID: String?
    var mapControlID: String?
    var formationID: String?
    var recommendationID: String?
    var maneuverID: String?
    var synergyID: String?
    var countermeasurePreviewID: String?
    var battleObjectiveStagePreviewID: String?
    var commanderActionID: String?
    var tacticalOrderID: String?

    var primaryCommandEntry: SelectedUnitSituationCommandEntry? {
        commandEntries.first { $0.isPrimary } ?? commandEntries.first
    }

    var primaryCommandEntryLabel: String {
        primaryCommandEntry?.cueLabel ?? nextStepLabel
    }

    var commandEntrySummaryLabel: String {
        guard let primaryCommandEntry else { return nextStepLabel }
        return "\(primaryCommandEntry.kind.displayName) · \(primaryCommandEntry.cueLabel)"
    }

    var compactLabel: String {
        "\(statusLabel) · \(primaryCommandEntryLabel)"
    }

    var accessibilityLabel: String {
        [
            title,
            "位置 \(position.description)",
            "状态 \(statusLabel)",
            "压力 \(pressureLabel)",
            "空间 \(spaceLabel)",
            "机会 \(opportunityLabel)",
            "下一步 \(nextStepLabel)",
            "入口 \(commandEntrySummaryLabel)",
            "风险 \(riskLabel)"
        ].joined(separator: "，")
    }

    func references(pressure candidate: FrontlinePressureSummary) -> Bool {
        pressureID == candidate.id
    }

    func references(threatHeat candidate: ThreatHeatZoneSummary) -> Bool {
        threatHeatID == candidate.id
    }

    func references(mapControl candidate: MapControlSummary) -> Bool {
        mapControlID == candidate.id
    }

    func references(formation candidate: LegionFormationSummary) -> Bool {
        formationID == candidate.id
    }

    func references(recommendation candidate: TacticalRecommendationSummary) -> Bool {
        recommendationID == candidate.id
    }

    func references(maneuver candidate: ManeuverOptionSummary) -> Bool {
        maneuverID == candidate.id
    }

    func references(synergy candidate: CommanderSynergySummary) -> Bool {
        synergyID == candidate.id
    }

    func references(countermeasurePreview candidate: CountermeasureCommandPreview) -> Bool {
        countermeasurePreviewID == candidate.id ||
            commandEntries.contains { $0.kind == .countermeasure && $0.sourceID == candidate.id }
    }

    func references(stagePreview candidate: BattleObjectiveStageCommandPreview) -> Bool {
        battleObjectiveStagePreviewID == candidate.id ||
            commandEntries.contains { $0.kind == .objectiveStage && $0.sourceID == candidate.id }
    }

    func references(commandEntryKind kind: SelectedUnitSituationCommandEntryKind, sourceID: String?) -> Bool {
        commandEntries.contains { $0.kind == kind && $0.sourceID == sourceID }
    }

    func references(recommendedOrder order: TacticalOrder) -> Bool {
        tacticalOrderID == order.rawValue ||
            commandEntries.contains { $0.kind == .tacticalOrder && $0.sourceID == order.rawValue }
    }
}
