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

enum MapOverlayLegendKind: String, Identifiable {
    case enemyRoute
    case enemyTarget
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

    var stepLabel: String {
        report.steps.prefix(3).map { "\($0.role.displayName)\($0.summary)" }.joined(separator: "、")
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
            detail
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

struct AIOperationalPlanSummary: Identifiable {
    var report: AIOperationalPlanReport
    var targetUnit: ArmyUnit?
    var targetCity: City?
    var sourceUnits: [ArmyUnit]
    var commanderUnits: [ArmyUnit]

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

    var accessibilityLabel: String {
        [
            "敌方将领\(commanderLabel)",
            traitLabel,
            "等级\(levelLabel)",
            "意图\(intentLabel)",
            "目标\(targetLabel)",
            impactLabel,
            statusLabel,
            scoreLabel,
            detail
        ].joined(separator: "，")
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
    var pressureID: String?
    var threatHeatID: String?
    var mapControlID: String?
    var formationID: String?
    var recommendationID: String?
    var maneuverID: String?
    var synergyID: String?

    var compactLabel: String {
        "\(statusLabel) · \(nextStepLabel)"
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
}

struct LegionFormationSummary: Identifiable {
    var report: LegionFormationReport
    var unit: ArmyUnit?

    var id: String { report.id }

    var title: String {
        if let unit {
            return "\(unit.faction.displayName)\(unit.kind.displayName)"
        }

        return "\(report.faction.displayName)\(report.kind.displayName)"
    }

    var shortUnitLabel: String {
        unit?.kind.displayName ?? report.kind.displayName
    }

    var roleLabel: String {
        report.role.displayName
    }

    var readinessLabel: String {
        report.readiness.displayName
    }

    var compactTitle: String {
        "\(shortUnitLabel) \(readinessLabel)"
    }

    var commandLabel: String {
        if let generalName = report.generalName {
            return "\(generalName) · \(report.rankName)"
        }

        return "\(report.rankName) · 无将领"
    }

    var statsLabel: String {
        "攻 \(report.attack) · 防 \(report.defense) · 移 \(report.movement)"
    }

    var supportLabel: String {
        "友军 \(report.adjacentAllyCount)/\(report.nearbyAllyCount) · 近敌 \(report.nearbyEnemyCount)"
    }

    var integrityLabel: String {
        "完整度 \(report.formationIntegrityScore)"
    }

    var orderLabel: String {
        if report.recommendedOrder == report.tacticalOrder {
            return "维持\(report.tacticalOrder.displayName)"
        }

        return "建议\(report.recommendedOrder.displayName)"
    }

    var skillLabel: String {
        if report.skillReady {
            return report.skillSummary.map { "技能就绪 · \($0)" } ?? "技能就绪"
        }

        if report.hasGeneral {
            return report.skillSummary.map { "技能观察 · \($0)" } ?? "技能观察"
        }

        return "无将领技能"
    }

    var detail: String {
        "\(roleLabel) · \(commandLabel) · \(statsLabel) · \(supportLabel)"
    }

    var recommendationLabel: String {
        "\(orderLabel) · \(report.commandSuggestion)"
    }

    var accessibilityLabel: String {
        "\(title)，编制职责\(roleLabel)，战备\(readinessLabel)，\(commandLabel)，\(statsLabel)，\(supportLabel)，\(recommendationLabel)"
    }
}

enum UnitDevelopmentDecisionKind: String, Identifiable {
    case training
    case appointment

    var id: String { rawValue }
}

struct UnitDevelopmentDecisionOption: Identifiable {
    var kind: UnitDevelopmentDecisionKind
    var title: String
    var symbol: String
    var costLabel: String
    var shortCostLabel: String
    var impactLabel: String
    var statusLabel: String
    var buttonDetail: String
    var canExecute: Bool
    var accessibilityLabel: String

    var id: UnitDevelopmentDecisionKind { kind }
}

struct UnitDevelopmentDecisionSummary: Identifiable {
    var unitID: String
    var unitTitle: String
    var trainingPreview: TrainingPreview?
    var appointmentPreview: GeneralAppointmentPreview?
    var trainingOption: UnitDevelopmentDecisionOption?
    var appointmentOption: UnitDevelopmentDecisionOption?

    var id: String { unitID }

    var options: [UnitDevelopmentDecisionOption] {
        [trainingOption, appointmentOption].compactMap { $0 }
    }

    var title: String {
        "\(unitTitle)成长"
    }

    var accessibilityLabel: String {
        ([title] + options.map(\.accessibilityLabel)).joined(separator: "，")
    }
}

struct UnitDevelopmentRecommendationSummary: Identifiable {
    var report: UnitDevelopmentRecommendationReport
    var unit: ArmyUnit?
    var statusLabel: String

    var id: String { report.id }
    var kind: UnitDevelopmentRecommendationKind { report.kind }
    var priority: UnitDevelopmentRecommendationPriority { report.priority }

    var title: String {
        report.title
    }

    var compactTitle: String {
        "\(kindLabel) \(priorityLabel)"
    }

    var kindLabel: String {
        report.kind.displayName
    }

    var priorityLabel: String {
        report.priority.displayName
    }

    var unitLabel: String {
        if let unit {
            return "\(unit.faction.displayName)\(unit.kind.displayName)"
        }

        return "\(report.faction.displayName)\(report.unitKind.displayName)"
    }

    var rankLabel: String {
        if report.currentRankName == report.projectedRankName {
            return "\(report.projectedRankName) · 伤害 +\(report.projectedDamageBonus)"
        }

        return "\(report.currentRankName)→\(report.projectedRankName)"
    }

    var reasonLabel: String {
        report.reasons.prefix(2).joined(separator: " · ")
    }

    var impactLabel: String {
        report.impact
    }

    var scoreLabel: String {
        "成长 \(report.score)"
    }

    var detail: String {
        report.detail
    }

    var accessibilityLabel: String {
        "\(title)，\(kindLabel)，\(priorityLabel)，单位\(unitLabel)，\(statusLabel)，\(rankLabel)，\(impactLabel)，理由\(detail)"
    }
}

struct GeneralPassiveContribution: Identifiable {
    var id: String
    var label: String
    var value: String
    var detail: String
}

struct SelectedCommanderBrief {
    var unitID: String
    var title: String
    var generalName: String?
    var traitName: String?
    var passiveContributions: [GeneralPassiveContribution]
    var skillName: String?
    var skillSummary: String?
    var skillDetail: String?
    var skillStatusLabel: String
    var skillBlockedReason: String?
    var skillEffectLabel: String?
    var warMeritSummary: String?
    var warMeritProgressLabel: String?
    var accessibilityLabel: String
}

struct CommanderActionGuidance {
    var title: String
    var stageCueLabel: String?
    var skillCueLabel: String
    var buttonDetailPrefix: String?
    var statusLabel: String
    var isLinkedToBattleObjectiveStage: Bool
    var accessibilityLabel: String
}

struct GeneralSkillTargetReadoutTarget: Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var position: Position
    var effectLabel: String
    var accessibilityLabel: String
}

struct SelectedGeneralSkillTargetReadout {
    var title: String
    var effectLabel: String
    var targetCountLabel: String
    var targetLabels: [String]
    var mapCueLabel: String
    var statusLabel: String
    var targets: [GeneralSkillTargetReadoutTarget]
    var accessibilityLabel: String
}

struct SelectedTacticalOrderPreview: Identifiable {
    var order: TacticalOrder
    var attack: Int
    var defense: Int
    var movement: Int
    var attackDelta: Int
    var defenseDelta: Int
    var movementDelta: Int
    var isCurrent: Bool
    var canSwitch: Bool
    var blockedReason: String?
    var detail: String
    var accessibilityLabel: String

    var id: TacticalOrder { order }
}

struct CityRecruitmentOptionPreview: Identifiable {
    var kind: UnitKind
    var statsLabel: String
    var costLabel: String
    var shortCostLabel: String
    var deploymentLabel: String
    var shortStatusLabel: String
    var canRecruit: Bool
    var blockedReason: String?
    var accessibilityLabel: String

    var id: UnitKind { kind }
}

struct SelectedCityBrief {
    var cityID: String
    var title: String
    var ownerLabel: String
    var positionLabel: String
    var fortificationLabel: String
    var productionLabel: String
    var ownerIncomeLabel: String
    var romanResourceLabel: String
    var deploymentSummary: String
    var developmentPreview: CityDevelopmentPreview?
    var developmentCostLabel: String
    var developmentGainLabel: String
    var developmentStatusLabel: String
    var canDevelop: Bool
    var recruitmentOptions: [CityRecruitmentOptionPreview]
    var availableRecruitmentCount: Int
    var accessibilityLabel: String
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published var state = GameState.newCampaign()
    @Published var selectedMode: GameMode = .campaign
    @Published var selectedUnitID: String?
    @Published var selectedCityID: String?
    @Published var selectedPosition: Position?
    @Published var selectedTechnology: Technology?
    @Published var focusedCountermeasureID: String?
    @Published var focusedBattleObjectiveRole: BattleObjectiveMapRole?
    @Published var bannerMessage = "元老院等待你的命令。"
    @Published var isShowingMenu = true

    init() {
        let arguments = ProcessInfo.processInfo.arguments

        if arguments.contains("--start-battle") || arguments.contains("--attack-demo") {
            isShowingMenu = false
        }

        if arguments.contains("--attack-demo") {
            state.units.removeAll { $0.id == "debug-carthage-adjacent" }
            state.units.append(
                ArmyUnit(
                    id: "debug-carthage-adjacent",
                    kind: .archer,
                    faction: .carthage,
                    position: Position(x: 4, y: 3),
                    health: 60
                )
            )
            selectedUnitID = "rome-legion-1"
            selectedPosition = Position(x: 3, y: 3)
            bannerMessage = "调试战斗：选择敌军头顶徽标发起攻击。"
        }
    }

    var selectedUnit: ArmyUnit? {
        guard let selectedUnitID = selectedUnitID else { return nil }
        return state.unit(withID: selectedUnitID)
    }

    var selectedCity: City? {
        guard let selectedCityID = selectedCityID else { return nil }
        return state.city(withID: selectedCityID)
    }

    var commandCity: City? {
        if let selectedCity = selectedCity {
            return selectedCity
        }

        guard let selectedUnit = selectedUnit else {
            return nil
        }

        return state.city(at: selectedUnit.position)
    }

    var selectedCityBrief: SelectedCityBrief? {
        guard let selectedCity else { return nil }
        return cityBrief(for: selectedCity)
    }

    var commandCityBrief: SelectedCityBrief? {
        guard let commandCity else { return nil }
        return cityBrief(for: commandCity)
    }

    var commandCityRecruitmentOptions: [CityRecruitmentOptionPreview] {
        commandCityBrief?.recruitmentOptions ?? []
    }

    var focusedPosition: Position? {
        selectedPosition ?? selectedUnit?.position ?? selectedCity?.position
    }

    var selectedTile: Tile? {
        guard let position = focusedPosition else { return nil }
        return state.tile(at: position)
    }

    var campaignStatus: CampaignStatus {
        state.campaignStatus
    }

    var isCampaignOver: Bool {
        campaignStatus.isGameOver
    }

    var campaignStatusTitle: String {
        campaignStatus.title
    }

    var campaignStatusDetail: String {
        campaignStatus.detail
    }

    var primaryMission: Mission? {
        if let primaryMissionID = campaignStatus.primaryMissionID,
           let mission = state.missions.first(where: { $0.id == primaryMissionID }) {
            return mission
        }

        return state.missions.first { !$0.isCompleted } ?? state.missions.first
    }

    var readyRomanUnitCount: Int {
        state.units.filter { $0.faction == .rome && (!$0.hasMoved || !$0.hasActed) }.count
    }

    var romanUnitCount: Int {
        state.units.filter { $0.faction == .rome }.count
    }

    var hostileUnitCount: Int {
        state.units.filter { unit in
            unit.faction != .rome &&
                unit.faction != .neutral &&
                state.diplomaticStatus(between: .rome, and: unit.faction) == .war
        }.count
    }

    var romanCityCount: Int {
        state.cities.filter { $0.owner == .rome }.count
    }

    var hostileCityCount: Int {
        state.cities.filter { city in
            city.owner != .rome &&
                city.owner != .neutral &&
                state.diplomaticStatus(between: .rome, and: city.owner) == .war
        }.count
    }

    var warPressureLabel: String {
        let romanScore = romanUnitCount * 2 + romanCityCount
        let hostileScore = hostileUnitCount * 2 + hostileCityCount

        if romanScore >= hostileScore + 3 {
            return "优势"
        }

        if hostileScore >= romanScore + 3 {
            return "受压"
        }

        return "均势"
    }

    var factionSituations: [FactionSituation] {
        Faction.turnOrder.map { faction in
            FactionSituation(
                faction: faction,
                unitCount: state.units.filter { $0.faction == faction }.count,
                cityCount: state.cities.filter { $0.owner == faction }.count,
                income: state.income(for: faction),
                relationToRome: state.diplomaticStatus(between: .rome, and: faction)
            )
        }
    }

    var enemyIntentSummaries: [EnemyIntentSummary] {
        Faction.turnOrder
            .filter { faction in
                faction != .rome &&
                    state.diplomaticStatus(between: .rome, and: faction) == .war
            }
            .flatMap { faction in
                state.aiIntents(for: faction, limit: 2)
            }
            .compactMap { intent -> EnemyIntentSummary? in
                guard let unit = state.unit(withID: intent.unitID) else {
                    return nil
                }

                return EnemyIntentSummary(
                    intent: intent,
                    unit: unit,
                    targetUnit: intent.targetUnitID.flatMap { state.unit(withID: $0) },
                    targetCity: intent.targetCityID.flatMap { state.city(withID: $0) }
                )
            }
            .sorted { left, right in
                if left.intent.threatScore == right.intent.threatScore {
                    return left.unit.id < right.unit.id
                }
                return left.intent.threatScore > right.intent.threatScore
            }
            .prefix(5)
            .map { $0 }
    }

    var primaryEnemyIntent: EnemyIntentSummary? {
        enemyIntentSummaries.first
    }

    var aiOperationalPlanSummaries: [AIOperationalPlanSummary] {
        state.aiOperationalPlanReports(against: .rome, perFactionLimit: 4, limit: 5)
            .map(aiOperationalPlanSummary(for:))
    }

    var primaryAIOperationalPlanSummary: AIOperationalPlanSummary? {
        aiOperationalPlanSummaries.first
    }

    var enemyCommanderThreatSummaries: [EnemyCommanderThreatSummary] {
        state.enemyCommanderThreatReports(against: .rome, limit: 5)
            .map(enemyCommanderThreatSummary(for:))
    }

    var primaryEnemyCommanderThreatSummary: EnemyCommanderThreatSummary? {
        enemyCommanderThreatSummaries.first
    }

    var countermeasureSummaries: [CountermeasureSummary] {
        state.countermeasureReports(for: .rome, limit: 5)
            .map(countermeasureSummary(for:))
    }

    var primaryCountermeasureSummary: CountermeasureSummary? {
        countermeasureSummaries.first
    }

    var countermeasureCommandPreviews: [CountermeasureCommandPreview] {
        countermeasureSummaries.map(countermeasureCommandPreview(for:))
    }

    var primaryCountermeasureCommandPreview: CountermeasureCommandPreview? {
        primaryCountermeasureSummary.map(countermeasureCommandPreview(for:))
    }

    var selectedCountermeasureCommandPreview: CountermeasureCommandPreview? {
        guard let selectedUnitID else { return nil }
        let previews = countermeasureCommandPreviews
        if let focusedCountermeasureID,
           let focusedPreview = previews.first(where: {
               $0.id == focusedCountermeasureID &&
                   $0.summary.report.responseUnitID == selectedUnitID
           }) {
            return focusedPreview
        }

        return previews.first { $0.summary.report.responseUnitID == selectedUnitID }
    }

    var primaryCountermeasureMapOverlay: CountermeasureMapOverlay? {
        primaryCountermeasureSummary.map { CountermeasureMapOverlay(summary: $0) }
    }

    var countermeasureRouteSegments: [CountermeasureRouteSegment] {
        primaryCountermeasureMapOverlay?.routeSegments ?? []
    }

    var countermeasureOverlaysByPosition: [Position: CountermeasurePositionOverlay] {
        guard let overlay = primaryCountermeasureMapOverlay else { return [:] }

        return overlay.positionOverlays.reduce(into: [Position: CountermeasurePositionOverlay]()) { result, positionOverlay in
            result[positionOverlay.position] = positionOverlay
        }
    }

    var countermeasureOverlayPositions: Set<Position> {
        Set(countermeasureOverlaysByPosition.keys)
    }

    var mapControlSummaries: [MapControlSummary] {
        state.mapControlReports(for: .rome)
            .map(mapControlSummary(for:))
    }

    var primaryMapControlSummary: MapControlSummary? {
        mapControlSummaries.first { $0.threatLevel != .quiet && $0.report.enemyInfluence > 0 } ??
            selectedMapControlSummary ??
            mapControlSummaries.first
    }

    var selectedMapControlSummary: MapControlSummary? {
        guard let position = focusedPosition,
              let report = state.mapControlReport(at: position, for: .rome) else {
            return nil
        }

        return mapControlSummary(for: report)
    }

    var threatHeatZoneSummaries: [ThreatHeatZoneSummary] {
        state.threatHeatZoneReports(for: .rome, limit: 5)
            .map(threatHeatZoneSummary(for:))
    }

    var primaryThreatHeatZoneSummary: ThreatHeatZoneSummary? {
        threatHeatZoneSummaries.first
    }

    var threatHeatZoneOverlaysByPosition: [Position: ThreatHeatZoneSummary] {
        var values: [Position: ThreatHeatZoneSummary] = [:]
        for summary in threatHeatZoneSummaries {
            for position in summary.report.positions {
                let current = values[position]
                if current == nil || summary.report.score > (current?.report.score ?? 0) {
                    values[position] = summary
                }
            }
        }
        return values
    }

    var threatHeatOverlayPositions: Set<Position> {
        Set(threatHeatZoneOverlaysByPosition.keys)
    }

    var mapControlOverlayPositions: Set<Position> {
        Set(mapControlSummaries.filter { $0.controlState == .contested || $0.threatLevel != .quiet }.map(\.position))
    }

    var battlefieldFocusSummaries: [BattlefieldFocusSummary] {
        state.battlefieldFocusReports(for: .rome, limit: 5)
            .map(battlefieldFocusSummary(for:))
    }

    var primaryBattlefieldFocusSummary: BattlefieldFocusSummary? {
        battlefieldFocusSummaries.first
    }

    var commanderSynergySummaries: [CommanderSynergySummary] {
        state.commanderSynergyReports(for: .rome, limit: 5)
            .map(commanderSynergySummary(for:))
    }

    var primaryCommanderSynergySummary: CommanderSynergySummary? {
        commanderSynergySummaries.first
    }

    var primaryBattleObjectiveChainSummary: BattleObjectiveChainSummary? {
        guard let focus = primaryBattlefieldFocusSummary else {
            return nil
        }

        return BattleObjectiveChainSummary(
            focus: focus,
            synergy: selectedCommanderSynergySummary ?? primaryCommanderSynergySummary,
            maneuver: primaryManeuverOptionSummary,
            recommendation: selectedTacticalRecommendationSummary
        )
    }

    var primaryBattleObjectiveMapOverlay: BattleObjectiveMapOverlay? {
        primaryBattleObjectiveChainSummary.map { BattleObjectiveMapOverlay(chain: $0) }
    }

    var battleObjectiveRouteSegments: [BattleObjectiveRouteSegment] {
        primaryBattleObjectiveMapOverlay?.routeSegments ?? []
    }

    var battleObjectiveOverlaysByPosition: [Position: [BattleObjectivePositionOverlay]] {
        guard let overlay = primaryBattleObjectiveMapOverlay else { return [:] }

        return overlay.positionOverlays.reduce(into: [Position: [BattleObjectivePositionOverlay]]()) { result, positionOverlay in
            result[positionOverlay.position, default: []].append(positionOverlay)
        }
    }

    var battleObjectiveOverlayPositions: Set<Position> {
        Set(battleObjectiveOverlaysByPosition.keys)
    }

    var focusedBattleObjectiveOverlay: BattleObjectivePositionOverlay? {
        guard let focusedBattleObjectiveRole else { return nil }

        return primaryBattleObjectiveMapOverlay?.positionOverlays.first { overlay in
            overlay.role == focusedBattleObjectiveRole
        }
    }

    var battleObjectiveStageCommandPreviews: [BattleObjectiveStageCommandPreview] {
        guard let overlay = primaryBattleObjectiveMapOverlay else { return [] }

        return overlay.positionOverlays.compactMap { positionOverlay in
            battleObjectiveStageCommandPreview(for: positionOverlay)
        }
    }

    var focusedBattleObjectiveStageCommandPreview: BattleObjectiveStageCommandPreview? {
        guard let focusedBattleObjectiveRole else { return nil }

        return battleObjectiveStageCommandPreviews.first { preview in
            preview.role == focusedBattleObjectiveRole
        }
    }

    var selectedBattleObjectiveStageCommandPreview: BattleObjectiveStageCommandPreview? {
        guard let selectedUnitID else { return nil }

        let previews = battleObjectiveStageCommandPreviews
        if let focusedBattleObjectiveRole,
           let focusedPreview = previews.first(where: {
               $0.role == focusedBattleObjectiveRole &&
                   $0.commandUnit?.id == selectedUnitID
           }) {
            return focusedPreview
        }

        return previews.first { preview in
            preview.commandUnit?.id == selectedUnitID
        }
    }

    var primaryBattleObjectiveStageCommandPreview: BattleObjectiveStageCommandPreview? {
        focusedBattleObjectiveStageCommandPreview ?? battleObjectiveStageCommandPreviews.first
    }

    var activeBattleObjectiveStageCommandPreview: BattleObjectiveStageCommandPreview? {
        focusedBattleObjectiveStageCommandPreview ??
            selectedBattleObjectiveStageCommandPreview ??
            primaryBattleObjectiveStageCommandPreview
    }

    var activeBattleObjectiveStageRole: BattleObjectiveMapRole? {
        activeBattleObjectiveStageCommandPreview?.role
    }

    var primaryBattlefieldConvergenceSummary: BattlefieldConvergenceSummary? {
        let summary = BattlefieldConvergenceSummary(
            objectiveChain: primaryBattleObjectiveChainSummary,
            countermeasure: primaryCountermeasureSummary,
            countermeasurePreview: primaryCountermeasureCommandPreview,
            stagePreview: activeBattleObjectiveStageCommandPreview,
            synergy: selectedCommanderSynergySummary ?? primaryCommanderSynergySummary,
            maneuver: primaryManeuverOptionSummary,
            threatHeat: primaryThreatHeatZoneSummary,
            mapControl: selectedMapControlSummary ?? primaryMapControlSummary
        )

        return summary.hasSignals ? summary : nil
    }

    var frontlinePressureSummaries: [FrontlinePressureSummary] {
        state.frontlinePressureReports(against: .rome, perFactionLimit: 4, limit: 4)
            .map { report in
                let targetUnit = report.targetKind == .unit ? state.unit(withID: report.targetID) : nil
                let targetCity = report.targetKind == .city ? state.city(withID: report.targetID) : nil
                let sourceUnits = report.sourceUnitIDs.compactMap { state.unit(withID: $0) }
                return FrontlinePressureSummary(
                    report: report,
                    targetUnit: targetUnit,
                    targetCity: targetCity,
                    sourceUnits: sourceUnits
                )
            }
    }

    var primaryFrontlinePressureSummary: FrontlinePressureSummary? {
        frontlinePressureSummaries.first
    }

    var selectedUnitSituationReadout: SelectedUnitSituationReadout? {
        guard let selectedUnit else { return nil }

        let pressure = frontlinePressureSummaries.first { summary in
            summary.report.targetKind == .unit &&
                summary.report.targetID == selectedUnit.id
        }
        let threatHeat = threatHeatZoneOverlaysByPosition[selectedUnit.position] ??
            threatHeatZoneSummaries.first { summary in
                summary.report.positions.contains(selectedUnit.position)
            }
        let mapControl = state.mapControlReport(at: selectedUnit.position, for: .rome)
            .map { mapControlSummary(for: $0) }
        let formation = selectedLegionFormationSummary
        let recommendation = selectedTacticalRecommendationSummary
        let maneuver = primaryManeuverOptionSummary
        let synergy = selectedCommanderSynergySummary
        var signals: [SelectedUnitSituationSignal] = []

        if let pressure {
            signals.append(
                SelectedUnitSituationSignal(
                    kind: .pressure,
                    title: pressure.pressureLabel,
                    detail: "\(pressure.sourceLabel) · \(pressure.impactLabel)",
                    position: pressure.targetPosition,
                    sourceID: pressure.id
                )
            )
        }

        if let threatHeat {
            signals.append(
                SelectedUnitSituationSignal(
                    kind: .threatHeat,
                    title: threatHeat.levelLabel,
                    detail: "\(threatHeat.sourceLabel) · \(threatHeat.impactLabel)",
                    position: selectedUnit.position,
                    sourceID: threatHeat.id
                )
            )
        }

        if let mapControl {
            signals.append(
                SelectedUnitSituationSignal(
                    kind: .mapControl,
                    title: mapControl.compactTitle,
                    detail: mapControl.detail,
                    position: mapControl.position,
                    sourceID: mapControl.id
                )
            )
        }

        if let formation {
            signals.append(
                SelectedUnitSituationSignal(
                    kind: .formation,
                    title: formation.readinessLabel,
                    detail: formation.recommendationLabel,
                    position: selectedUnit.position,
                    sourceID: formation.id
                )
            )
        }

        if let recommendation {
            signals.append(
                SelectedUnitSituationSignal(
                    kind: .recommendation,
                    title: recommendation.kindLabel,
                    detail: recommendation.report.command,
                    position: recommendation.destination,
                    sourceID: recommendation.id
                )
            )
        }

        if let maneuver {
            signals.append(
                SelectedUnitSituationSignal(
                    kind: .maneuver,
                    title: maneuver.kindLabel,
                    detail: "\(maneuver.destinationLabel) · \(maneuver.impactLabel)",
                    position: maneuver.destination,
                    sourceID: maneuver.id
                )
            )
        }

        if let synergy {
            signals.append(
                SelectedUnitSituationSignal(
                    kind: .synergy,
                    title: synergy.kindLabel,
                    detail: "\(synergy.impactLabel) · \(synergy.statusLabel)",
                    position: synergy.targetPosition,
                    sourceID: synergy.id
                )
            )
        }

        if signals.isEmpty {
            signals.append(
                SelectedUnitSituationSignal(
                    kind: .formation,
                    title: "待命",
                    detail: "暂无本方处境信号",
                    position: selectedUnit.position,
                    sourceID: selectedUnit.id
                )
            )
        }

        let pressureLabel: String
        if let pressure {
            pressureLabel = "\(pressure.pressureLabel) · \(pressure.impactLabel)"
        } else if let threatHeat {
            pressureLabel = "\(threatHeat.levelLabel) · \(threatHeat.impactLabel)"
        } else {
            pressureLabel = formation?.supportLabel ?? "暂无直接压力"
        }

        let spaceLabel: String
        if let mapControl {
            spaceLabel = "\(mapControl.controlLabel) · \(mapControl.levelLabel) · \(mapControl.sourceLabel)"
        } else if let threatHeat {
            spaceLabel = "\(threatHeat.controlLabel) · \(threatHeat.sourceLabel)"
        } else {
            spaceLabel = "空间待确认"
        }

        let opportunityLabel = synergy?.impactLabel ??
            maneuver?.impactLabel ??
            recommendation?.kindLabel ??
            formation?.roleLabel ??
            "维持阵线"
        let nextStepLabel = recommendation?.report.command ??
            maneuver.map { "\($0.destinationLabel) · \($0.report.recommendedOrder.displayName)" } ??
            formation?.recommendationLabel ??
            "保持\(selectedUnit.resolvedTacticalOrder.displayName)"
        let riskLabel = recommendation?.riskLabel ??
            maneuver?.riskLabel ??
            synergy?.riskLabel ??
            pressure?.pressureLabel ??
            threatHeat?.levelLabel ??
            "低"
        let statusLabel = pressure?.pressureLabel ??
            threatHeat?.levelLabel ??
            mapControl?.levelLabel ??
            formation?.readinessLabel ??
            "待命"

        return SelectedUnitSituationReadout(
            unitID: selectedUnit.id,
            position: selectedUnit.position,
            title: "\(selectedUnit.kind.displayName)处境",
            statusLabel: statusLabel,
            pressureLabel: pressureLabel,
            spaceLabel: spaceLabel,
            opportunityLabel: opportunityLabel,
            nextStepLabel: nextStepLabel,
            riskLabel: riskLabel,
            signals: signals,
            pressureID: pressure?.id,
            threatHeatID: threatHeat?.id,
            mapControlID: mapControl?.id,
            formationID: formation?.id,
            recommendationID: recommendation?.id,
            maneuverID: maneuver?.id,
            synergyID: synergy?.id
        )
    }

    var legionFormationSummaries: [LegionFormationSummary] {
        state.legionFormationReports(for: .rome, limit: 5)
            .map(legionFormationSummary(for:))
    }

    var primaryLegionFormationSummary: LegionFormationSummary? {
        legionFormationSummaries.first
    }

    var selectedLegionFormationSummary: LegionFormationSummary? {
        guard let selectedUnitID,
              let report = try? state.legionFormationReport(unitID: selectedUnitID) else {
            return nil
        }

        return legionFormationSummary(for: report)
    }

    var selectedUnitDevelopmentDecisionSummary: UnitDevelopmentDecisionSummary? {
        guard let selectedUnit else { return nil }
        return unitDevelopmentDecisionSummary(for: selectedUnit)
    }

    var unitDevelopmentRecommendationSummaries: [UnitDevelopmentRecommendationSummary] {
        state.unitDevelopmentRecommendationReports(for: .rome, limit: 6)
            .map(unitDevelopmentRecommendationSummary(for:))
    }

    var primaryUnitDevelopmentRecommendationSummary: UnitDevelopmentRecommendationSummary? {
        unitDevelopmentRecommendationSummaries.first
    }

    var selectedCommanderSynergySummary: CommanderSynergySummary? {
        guard let selectedUnitID,
              let report = try? state.commanderSynergyReport(unitID: selectedUnitID) else {
            return nil
        }

        return commanderSynergySummary(for: report)
    }

    var selectedManeuverOptionSummaries: [ManeuverOptionSummary] {
        guard let selectedUnitID,
              let reports = try? state.maneuverOptionReports(unitID: selectedUnitID, limit: 5) else {
            return []
        }

        return reports.map(maneuverOptionSummary(for:))
    }

    var primaryManeuverOptionSummary: ManeuverOptionSummary? {
        selectedManeuverOptionSummaries.first
    }

    var maneuverOptionOverlaysByPosition: [Position: ManeuverOptionSummary] {
        var values: [Position: ManeuverOptionSummary] = [:]
        for summary in selectedManeuverOptionSummaries {
            let current = values[summary.destination]
            if current == nil || summary.report.score > (current?.report.score ?? 0) {
                values[summary.destination] = summary
            }
        }
        return values
    }

    var maneuverOptionOverlayPositions: Set<Position> {
        Set(maneuverOptionOverlaysByPosition.keys)
    }

    var activeMapOverlayLegendItems: [MapOverlayLegendItem] {
        var items: [MapOverlayLegendItem] = []
        var insertedKinds = Set<MapOverlayLegendKind>()

        func append(
            _ kind: MapOverlayLegendKind,
            symbol: String,
            title: String,
            detail: String
        ) {
            guard insertedKinds.insert(kind).inserted else { return }
            items.append(
                MapOverlayLegendItem(
                    kind: kind,
                    symbol: symbol,
                    title: title,
                    detail: detail,
                    accessibilityLabel: "\(title)，\(detail)"
                )
            )
        }

        let intentOverlays = enemyIntentMapOverlays
        if intentOverlays.contains(where: { !$0.routeSegments.isEmpty }) {
            append(.enemyRoute, symbol: "arrow.right", title: "敌路", detail: "红线为敌军计划路线")
        }

        if !enemyIntentDestinationOverlays(for: intentOverlays).isEmpty ||
            !enemyIntentTargetOverlays(for: intentOverlays).isEmpty {
            append(.enemyTarget, symbol: "scope", title: "敌标", detail: "准星标出敌军目标")
        }

        if !threatHeatOverlayPositions.isEmpty {
            append(.threatHeat, symbol: "flame.fill", title: "热区", detail: "火焰提示高危威胁")
        }

        if !mapControlOverlayPositions.isEmpty {
            append(.mapControl, symbol: "shield.fill", title: "控区", detail: "底色显示争夺与控制")
        }

        if !selectedTacticalRecommendationPathPositions.isEmpty ||
            selectedTacticalRecommendationTargetPosition != nil {
            append(.tacticalPath, symbol: "arrow.turn.up.right", title: "军议", detail: "蓝线为本方建议路径")
        }

        if !maneuverOptionOverlayPositions.isEmpty {
            append(.maneuverOption, symbol: "figure.run", title: "机动", detail: "虚线点提示推荐落点")
        }

        if primaryBattleObjectiveMapOverlay != nil,
           !battleObjectiveOverlayPositions.isEmpty {
            append(.battleObjective, symbol: "point.topleft.down.curvedto.point.bottomright.up.fill", title: "目标线", detail: "金线串联焦点将令机动军议")
        }

        if primaryCountermeasureMapOverlay != nil,
           !countermeasureOverlayPositions.isEmpty {
            append(.countermeasure, symbol: "shield.lefthalf.filled", title: "反制", detail: "青线连接回应落点与目标")
        }

        if !reachablePositions.isEmpty {
            append(.reachable, symbol: "arrow.up.right.circle", title: "可达", detail: "黄圈为本回合可移动")
        }

        if !attackTargets.isEmpty {
            append(.attackTarget, symbol: "bolt.fill", title: "攻击", detail: "红环为可攻击目标")
        }

        if !selectedGeneralSkillRangePositions.isEmpty ||
            !selectedGeneralSkillTargetPositions.isEmpty ||
            !selectedGeneralSkillTargetUnitIDs.isEmpty ||
            !selectedGeneralSkillTargetCityIDs.isEmpty {
            append(.skillRange, symbol: "sparkles", title: "技能", detail: "紫光为将领技能范围")
        }

        return items
    }

    var selectedTacticalRecommendationSummary: TacticalRecommendationSummary? {
        guard let selectedUnitID,
              let report = try? state.tacticalRecommendation(unitID: selectedUnitID) else {
            return nil
        }

        return TacticalRecommendationSummary(
            report: report,
            unit: state.unit(withID: report.unitID),
            targetUnit: report.targetUnitID.flatMap { state.unit(withID: $0) },
            targetCity: report.targetCityID.flatMap { state.city(withID: $0) }
        )
    }

    var selectedTacticalRecommendationPathPositions: Set<Position> {
        guard let summary = selectedTacticalRecommendationSummary else { return [] }
        return Set(summary.report.path)
    }

    var selectedTacticalRecommendationTargetPosition: Position? {
        selectedTacticalRecommendationSummary?.targetPosition
    }

    private func legionFormationSummary(for report: LegionFormationReport) -> LegionFormationSummary {
        LegionFormationSummary(
            report: report,
            unit: state.unit(withID: report.unitID)
        )
    }

    private func unitDevelopmentDecisionSummary(for unit: ArmyUnit) -> UnitDevelopmentDecisionSummary {
        let trainingPreview = try? state.trainingPreview(unitID: unit.id)
        let appointmentPreview = try? state.generalAppointmentPreview(unitID: unit.id)
        let unitTitle = "\(unit.faction.displayName)\(unit.kind.displayName)"

        return UnitDevelopmentDecisionSummary(
            unitID: unit.id,
            unitTitle: unitTitle,
            trainingPreview: trainingPreview,
            appointmentPreview: appointmentPreview,
            trainingOption: trainingPreview.map(trainingDecisionOption(for:)),
            appointmentOption: appointmentPreview.map(appointmentDecisionOption(for:))
        )
    }

    private func unitDevelopmentRecommendationSummary(
        for report: UnitDevelopmentRecommendationReport
    ) -> UnitDevelopmentRecommendationSummary {
        let statusLabel: String
        if report.canExecute {
            statusLabel = "可执行"
        } else if report.blockedReason == GameRuleError.insufficientResources.displayMessage,
                  let shortageLabel = resourceShortageLabel(for: report.cost) {
            statusLabel = shortageLabel
        } else {
            statusLabel = report.blockedReason ?? "暂不可用"
        }

        return UnitDevelopmentRecommendationSummary(
            report: report,
            unit: state.unit(withID: report.unitID),
            statusLabel: statusLabel
        )
    }

    private func trainingDecisionOption(for preview: TrainingPreview) -> UnitDevelopmentDecisionOption {
        let costLabel = resourceLabel(preview.cost, signed: false, includeZero: false)
        let shortCostLabel = shortResourceLabel(preview.cost)
        let blockedReason = decisionBlockedReason(error: preview.blockingError, fallback: preview.blockedReason, cost: preview.cost)
        let statusLabel = preview.canTrain ? "可训练" : (blockedReason ?? "不可训练")
        let impactLabel = "\(preview.summary) · \(preview.detail)"
        let buttonDetail = preview.canTrain ? "\(preview.summary) · \(shortCostLabel)" : statusLabel
        let accessibilityParts = [
            "训练",
            "成本\(costLabel)",
            preview.summary,
            preview.detail,
            statusLabel
        ]

        return UnitDevelopmentDecisionOption(
            kind: .training,
            title: "训练",
            symbol: "figure.walk",
            costLabel: costLabel,
            shortCostLabel: shortCostLabel,
            impactLabel: impactLabel,
            statusLabel: statusLabel,
            buttonDetail: buttonDetail,
            canExecute: preview.canTrain,
            accessibilityLabel: accessibilityParts.joined(separator: "，")
        )
    }

    private func appointmentDecisionOption(for preview: GeneralAppointmentPreview) -> UnitDevelopmentDecisionOption {
        let costLabel = resourceLabel(preview.cost, signed: false, includeZero: false)
        let shortCostLabel = shortResourceLabel(preview.cost)
        let blockedReason = decisionBlockedReason(error: preview.blockingError, fallback: preview.blockedReason, cost: preview.cost)
        let statusLabel = preview.canAppoint ? "可任命" : (blockedReason ?? "不可任命")
        let candidateLabel: String
        if let candidateName = preview.candidateName,
           let trait = preview.candidateTrait {
            candidateLabel = "\(candidateName) · \(trait.displayName)"
        } else {
            candidateLabel = "暂无候选"
        }
        let impactLabel = "\(candidateLabel) · \(preview.detail)"
        let buttonDetail = preview.canAppoint ? "\(candidateLabel) · \(shortCostLabel)" : statusLabel
        let accessibilityParts = [
            "任命",
            "成本\(costLabel)",
            candidateLabel,
            preview.detail,
            statusLabel
        ]

        return UnitDevelopmentDecisionOption(
            kind: .appointment,
            title: "任命",
            symbol: "person.crop.circle.badge.plus",
            costLabel: costLabel,
            shortCostLabel: shortCostLabel,
            impactLabel: impactLabel,
            statusLabel: statusLabel,
            buttonDetail: buttonDetail,
            canExecute: preview.canAppoint,
            accessibilityLabel: accessibilityParts.joined(separator: "，")
        )
    }

    private func decisionBlockedReason(
        error: GameRuleError?,
        fallback: String?,
        cost: EmpireResources
    ) -> String? {
        if error == .insufficientResources,
           let shortageLabel = resourceShortageLabel(for: cost) {
            return shortageLabel
        }

        return fallback
    }

    private func battlefieldFocusSummary(for report: BattlefieldFocusReport) -> BattlefieldFocusSummary {
        BattlefieldFocusSummary(
            report: report,
            unit: report.unitID.flatMap { state.unit(withID: $0) },
            targetUnit: report.targetUnitID.flatMap { state.unit(withID: $0) },
            targetCity: report.targetCityID.flatMap { state.city(withID: $0) },
            relatedUnits: report.relatedUnitIDs.compactMap { state.unit(withID: $0) }
        )
    }

    private func commanderSynergySummary(for report: CommanderSynergyReport) -> CommanderSynergySummary {
        CommanderSynergySummary(
            report: report,
            unit: state.unit(withID: report.unitID),
            commanderUnit: report.commanderUnitID.flatMap { state.unit(withID: $0) },
            targetUnit: report.targetUnitID.flatMap { state.unit(withID: $0) },
            targetCity: report.targetCityID.flatMap { state.city(withID: $0) },
            supportingUnits: report.supportingUnitIDs.compactMap { state.unit(withID: $0) },
            beneficiaryUnits: report.beneficiaryUnitIDs.compactMap { state.unit(withID: $0) }
        )
    }

    private func maneuverOptionSummary(for report: ManeuverOptionReport) -> ManeuverOptionSummary {
        ManeuverOptionSummary(
            report: report,
            unit: state.unit(withID: report.unitID),
            targetUnit: report.targetUnitID.flatMap { state.unit(withID: $0) },
            targetCity: report.targetCityID.flatMap { state.city(withID: $0) }
        )
    }

    private func mapControlSummary(for report: MapControlReport) -> MapControlSummary {
        MapControlSummary(
            report: report,
            city: report.cityID.flatMap { state.city(withID: $0) },
            occupant: report.occupantUnitID.flatMap { state.unit(withID: $0) },
            friendlyUnits: report.friendlyUnitIDs.compactMap { state.unit(withID: $0) },
            enemyUnits: report.enemyUnitIDs.compactMap { state.unit(withID: $0) }
        )
    }

    private func threatHeatZoneSummary(for report: ThreatHeatZoneReport) -> ThreatHeatZoneSummary {
        ThreatHeatZoneSummary(
            report: report,
            sourceUnits: report.sourceUnitIDs.compactMap { state.unit(withID: $0) },
            cities: report.cityIDs.compactMap { state.city(withID: $0) }
        )
    }

    private func aiOperationalPlanSummary(for report: AIOperationalPlanReport) -> AIOperationalPlanSummary {
        AIOperationalPlanSummary(
            report: report,
            targetUnit: report.targetUnitID.flatMap { state.unit(withID: $0) },
            targetCity: report.targetCityID.flatMap { state.city(withID: $0) },
            sourceUnits: report.sourceUnitIDs.compactMap { state.unit(withID: $0) },
            commanderUnits: report.commanderUnitIDs.compactMap { state.unit(withID: $0) }
        )
    }

    private func enemyCommanderThreatSummary(for report: EnemyCommanderThreatReport) -> EnemyCommanderThreatSummary {
        EnemyCommanderThreatSummary(
            report: report,
            commanderUnit: state.unit(withID: report.unitID),
            targetUnit: report.targetUnitID.flatMap { state.unit(withID: $0) },
            targetCity: report.targetCityID.flatMap { state.city(withID: $0) },
            affectedUnits: report.affectedUnitIDs.compactMap { state.unit(withID: $0) },
            affectedCities: report.affectedCityIDs.compactMap { state.city(withID: $0) }
        )
    }

    private func countermeasureSummary(for report: CountermeasureReport) -> CountermeasureSummary {
        CountermeasureSummary(
            report: report,
            responseUnit: state.unit(withID: report.responseUnitID),
            targetUnit: report.targetUnitID.flatMap { state.unit(withID: $0) },
            targetCity: report.targetCityID.flatMap { state.city(withID: $0) }
        )
    }

    func countermeasureCommandPreview(for summary: CountermeasureSummary) -> CountermeasureCommandPreview {
        let responseUnit = state.unit(withID: summary.report.responseUnitID)
        let targetUnit = summary.report.targetUnitID.flatMap { state.unit(withID: $0) }
        let targetCity = summary.report.targetCityID.flatMap { state.city(withID: $0) }
        let recommendedOrder = summary.report.recommendedOrder
        let destination = summary.destination
        let targetPosition = summary.targetPosition
        var blockingReasons: [String] = []
        var steps: [CountermeasureCommandStep] = []

        guard let responseUnit else {
            return CountermeasureCommandPreview(
                summary: summary,
                responseUnit: nil,
                targetUnit: targetUnit,
                targetCity: targetCity,
                recommendedOrder: recommendedOrder,
                destination: destination,
                targetPosition: targetPosition,
                canFocus: false,
                canSetOrder: false,
                canMoveToDestination: false,
                canAttackCurrentTarget: false,
                isExecutableNow: false,
                blockingReasons: ["回应单位不存在"],
                steps: [
                    CountermeasureCommandStep(
                        id: "\(summary.id)-missing-unit",
                        symbol: "questionmark.circle.fill",
                        title: "回应",
                        detail: "回应单位不存在",
                        isReady: false
                    )
                ]
            )
        }

        if isCampaignOver {
            blockingReasons.append("战役已结束")
        }

        if responseUnit.faction != .rome {
            blockingReasons.append("回应单位不属罗马")
        }

        if responseUnit.faction != state.activeFaction {
            blockingReasons.append("非当前阵营")
        }

        let orderBlockedReason = tacticalOrderBlockedReason(recommendedOrder, for: responseUnit)
        let orderReady = orderBlockedReason == nil || orderBlockedReason == "当前姿态"
        let canSetOrder = orderBlockedReason == nil && responseUnit.resolvedTacticalOrder != recommendedOrder
        if let orderBlockedReason,
           orderBlockedReason != "当前姿态" {
            blockingReasons.append(orderBlockedReason)
        }
        steps.append(
            CountermeasureCommandStep(
                id: "\(summary.id)-order",
                symbol: tacticalOrderCommandSymbol(recommendedOrder),
                title: "姿态",
                detail: orderBlockedReason == "当前姿态" ? "已是\(recommendedOrder.displayName)" : "建议\(recommendedOrder.displayName)",
                isReady: orderReady
            )
        )

        let reachable = state.reachablePositions(for: responseUnit.id)
        let isAtDestination = responseUnit.position == destination
        let canMoveToDestination = isAtDestination || reachable.contains(destination)
        if !canMoveToDestination {
            blockingReasons.append(responseUnit.hasMoved ? "已移动，无法抵达落点" : "落点暂不可达")
        }
        steps.append(
            CountermeasureCommandStep(
                id: "\(summary.id)-destination",
                symbol: isAtDestination ? "location.fill" : "arrow.up.right.circle.fill",
                title: "落点",
                detail: isAtDestination ? "已在 \(destination.description)" : (canMoveToDestination ? "可达 \(destination.description)" : "不可达 \(destination.description)"),
                isReady: canMoveToDestination
            )
        )

        let attackableTargets = state.attackTargets(for: responseUnit.id)
        let canAttackCurrentTarget = targetUnit.map { target in
            attackableTargets.contains { $0.id == target.id }
        } ?? false
        let targetDetail: String
        if let targetUnit {
            targetDetail = canAttackCurrentTarget ? "可直接攻击 \(targetUnit.kind.displayName)" : "距目标 \(responseUnit.position.hexDistance(to: targetUnit.position))"
        } else if let targetCity {
            targetDetail = "目标 \(targetCity.name)"
        } else {
            targetDetail = "目标 \(targetPosition.description)"
        }
        steps.append(
            CountermeasureCommandStep(
                id: "\(summary.id)-target",
                symbol: canAttackCurrentTarget ? "bolt.fill" : "scope",
                title: "目标",
                detail: targetDetail,
                isReady: canAttackCurrentTarget || targetUnit == nil
            )
        )

        let canFocus = responseUnit.faction == .rome
        let canAdvanceNow = canSetOrder || (!isAtDestination && canMoveToDestination) || canAttackCurrentTarget
        let isExecutableNow = canFocus &&
            blockingReasons.isEmpty &&
            canAdvanceNow

        return CountermeasureCommandPreview(
            summary: summary,
            responseUnit: responseUnit,
            targetUnit: targetUnit,
            targetCity: targetCity,
            recommendedOrder: recommendedOrder,
            destination: destination,
            targetPosition: targetPosition,
            canFocus: canFocus,
            canSetOrder: canSetOrder,
            canMoveToDestination: canMoveToDestination,
            canAttackCurrentTarget: canAttackCurrentTarget,
            isExecutableNow: isExecutableNow,
            blockingReasons: blockingReasons,
            steps: steps
        )
    }

    private func battleObjectiveStageCommandPreview(for overlay: BattleObjectivePositionOverlay) -> BattleObjectiveStageCommandPreview? {
        let chain = overlay.chain
        let commandUnit = battleObjectiveFocusUnit(for: overlay)
        let sourceSummaryID: String
        let targetUnit: ArmyUnit?
        let targetCity: City?
        let recommendedOrder: TacticalOrder?
        let destination: Position?
        let targetPosition: Position
        let commandEntryLabel: String
        let sourceStatusLabel: String

        switch overlay.role {
        case .focus:
            sourceSummaryID = chain.focus.id
            targetUnit = chain.focus.targetUnit
            targetCity = chain.focus.targetCity
            recommendedOrder = chain.focus.report.recommendedOrder
            destination = chain.focus.targetPosition
            targetPosition = chain.focus.targetPosition
            commandEntryLabel = "定位焦点"
            sourceStatusLabel = "\(chain.focus.kindLabel) · \(chain.focus.severityLabel)"
        case .synergy:
            guard let synergy = chain.synergy else { return nil }
            sourceSummaryID = synergy.id
            targetUnit = synergy.targetUnit
            targetCity = synergy.targetCity
            recommendedOrder = synergy.report.recommendedOrder
            destination = commandUnit?.position
            targetPosition = synergy.targetPosition
            commandEntryLabel = synergy.kind == .commanderSkill ? "将领技能" : "将令协同"
            sourceStatusLabel = synergy.statusLabel
        case .maneuver:
            guard let maneuver = chain.maneuver else { return nil }
            sourceSummaryID = maneuver.id
            targetUnit = maneuver.targetUnit
            targetCity = maneuver.targetCity
            recommendedOrder = maneuver.report.recommendedOrder
            destination = maneuver.destination
            targetPosition = maneuver.targetPosition
            commandEntryLabel = "移动落点"
            sourceStatusLabel = maneuver.report.isExecutable ? "可机动" : (maneuver.report.blockedReason ?? maneuver.riskLabel)
        case .recommendation:
            guard let recommendation = chain.recommendation else { return nil }
            sourceSummaryID = recommendation.id
            targetUnit = recommendation.targetUnit
            targetCity = recommendation.targetCity
            recommendedOrder = recommendation.report.recommendedOrder
            destination = recommendation.destination
            targetPosition = recommendation.targetPosition
            commandEntryLabel = "军令执行"
            sourceStatusLabel = recommendation.riskLabel
        }

        var blockingReasons: [String] = []
        var steps: [BattleObjectiveStageCommandStep] = []

        if isCampaignOver {
            blockingReasons.append("战役已结束")
        }

        guard let commandUnit else {
            return BattleObjectiveStageCommandPreview(
                chain: chain,
                role: overlay.role,
                position: overlay.position,
                sourceSummaryID: sourceSummaryID,
                commandUnit: nil,
                targetUnit: targetUnit,
                targetCity: targetCity,
                recommendedOrder: recommendedOrder,
                destination: destination,
                targetPosition: targetPosition,
                commandEntryLabel: commandEntryLabel,
                canFocus: false,
                canSetOrder: false,
                canMoveToDestination: false,
                canAttackCurrentTarget: false,
                canUseGeneralSkill: false,
                isExecutableNow: false,
                blockingReasons: ["无罗马执行单位"],
                steps: [
                    BattleObjectiveStageCommandStep(
                        id: "\(chain.id)-\(overlay.role.rawValue)-missing-unit",
                        symbol: "questionmark.circle.fill",
                        title: overlay.role.displayName,
                        detail: "阶段仅可定位观察",
                        isReady: false
                    )
                ]
            )
        }

        if commandUnit.faction != .rome {
            blockingReasons.append("执行单位不属罗马")
        }

        if commandUnit.faction != state.activeFaction {
            blockingReasons.append("非当前阵营")
        }

        steps.append(
            BattleObjectiveStageCommandStep(
                id: "\(chain.id)-\(overlay.role.rawValue)-entry",
                symbol: "target",
                title: "入口",
                detail: "\(commandEntryLabel) · \(sourceStatusLabel)",
                isReady: commandUnit.faction == .rome
            )
        )

        let canSetOrder: Bool
        if let recommendedOrder {
            let orderBlockedReason = tacticalOrderBlockedReason(recommendedOrder, for: commandUnit)
            let orderReady = orderBlockedReason == nil || orderBlockedReason == "当前姿态"
            canSetOrder = orderBlockedReason == nil && commandUnit.resolvedTacticalOrder != recommendedOrder
            if let orderBlockedReason,
               orderBlockedReason != "当前姿态" {
                blockingReasons.append(orderBlockedReason)
            }
            steps.append(
                BattleObjectiveStageCommandStep(
                    id: "\(chain.id)-\(overlay.role.rawValue)-order",
                    symbol: tacticalOrderCommandSymbol(recommendedOrder),
                    title: "姿态",
                    detail: orderBlockedReason == "当前姿态" ? "已是\(recommendedOrder.displayName)" : "建议\(recommendedOrder.displayName)",
                    isReady: orderReady
                )
            )
        } else {
            canSetOrder = false
        }

        let canMoveToDestination: Bool
        if let destination {
            let isAtDestination = commandUnit.position == destination
            let reachable = state.reachablePositions(for: commandUnit.id)
            canMoveToDestination = isAtDestination || reachable.contains(destination)
            if !canMoveToDestination,
               overlay.role == .maneuver || overlay.role == .recommendation {
                blockingReasons.append(commandUnit.hasMoved ? "已移动，无法抵达落点" : "落点暂不可达")
            }
            steps.append(
                BattleObjectiveStageCommandStep(
                    id: "\(chain.id)-\(overlay.role.rawValue)-destination",
                    symbol: isAtDestination ? "location.fill" : "arrow.up.right.circle.fill",
                    title: "落点",
                    detail: isAtDestination ? "已在\(destination.description)" : (canMoveToDestination ? "可达\(destination.description)" : "不可达\(destination.description)"),
                    isReady: canMoveToDestination
                )
            )
        } else {
            canMoveToDestination = false
        }

        let attackableTargets = state.attackTargets(for: commandUnit.id)
        let canAttackCurrentTarget = targetUnit.map { target in
            attackableTargets.contains { $0.id == target.id }
        } ?? false
        let targetDetail: String
        if let targetUnit {
            targetDetail = canAttackCurrentTarget ? "可攻击\(targetUnit.kind.displayName)" : "距目标\(commandUnit.position.hexDistance(to: targetUnit.position))"
        } else if let targetCity {
            targetDetail = "目标\(targetCity.name)"
        } else {
            targetDetail = "目标\(targetPosition.description)"
        }
        steps.append(
            BattleObjectiveStageCommandStep(
                id: "\(chain.id)-\(overlay.role.rawValue)-target",
                symbol: canAttackCurrentTarget ? "bolt.fill" : "scope",
                title: "目标",
                detail: targetDetail,
                isReady: canAttackCurrentTarget || targetUnit == nil
            )
        )

        let skillPreview = try? state.generalSkillPreview(unitID: commandUnit.id)
        let canUseGeneralSkill = overlay.role == .synergy && (skillPreview?.isExecutable ?? false)
        if overlay.role == .synergy {
            steps.append(
                BattleObjectiveStageCommandStep(
                    id: "\(chain.id)-\(overlay.role.rawValue)-skill",
                    symbol: canUseGeneralSkill ? "sparkles" : "hourglass",
                    title: "技能",
                    detail: skillPreview.map { preview in
                        preview.isExecutable ? "\(preview.trait.skillName)可用" : (preview.blockedReason ?? preview.cooldownText)
                    } ?? "无主动技能",
                    isReady: canUseGeneralSkill
                )
            )
        }

        let canFocus = commandUnit.faction == .rome
        let shouldMove = destination.map { $0 != commandUnit.position } ?? false
        let canAdvanceNow = canSetOrder ||
            (shouldMove && canMoveToDestination) ||
            canAttackCurrentTarget ||
            canUseGeneralSkill
        let isExecutableNow = canFocus &&
            blockingReasons.isEmpty &&
            canAdvanceNow

        return BattleObjectiveStageCommandPreview(
            chain: chain,
            role: overlay.role,
            position: overlay.position,
            sourceSummaryID: sourceSummaryID,
            commandUnit: commandUnit,
            targetUnit: targetUnit,
            targetCity: targetCity,
            recommendedOrder: recommendedOrder,
            destination: destination,
            targetPosition: targetPosition,
            commandEntryLabel: commandEntryLabel,
            canFocus: canFocus,
            canSetOrder: canSetOrder,
            canMoveToDestination: canMoveToDestination,
            canAttackCurrentTarget: canAttackCurrentTarget,
            canUseGeneralSkill: canUseGeneralSkill,
            isExecutableNow: isExecutableNow,
            blockingReasons: blockingReasons,
            steps: steps
        )
    }

    func enemyIntentSummary(for unitID: String) -> EnemyIntentSummary? {
        enemyIntentSummaries.first { $0.unit.id == unitID }
    }

    var enemyIntentMapOverlays: [EnemyIntentMapOverlay] {
        enemyIntentMapOverlays(for: enemyIntentSummaries)
    }

    func enemyIntentMapOverlays(for summaries: [EnemyIntentSummary]) -> [EnemyIntentMapOverlay] {
        summaries.prefix(4).map { summary in
            EnemyIntentMapOverlay(
                summary: summary,
                routeSegments: enemyIntentRouteSegments(for: summary)
            )
        }
    }

    private func enemyIntentRouteSegments(for summary: EnemyIntentSummary) -> [EnemyIntentRouteSegment] {
        var segments = enemyIntentMovementRouteSegments(for: summary)

        if let targetPosition = summary.targetPosition,
           targetPosition != summary.destinationPosition {
            segments.append(
                EnemyIntentRouteSegment(
                    id: "\(summary.id)-target",
                    from: summary.destinationPosition,
                    to: targetPosition,
                    kind: summary.intent.kind,
                    isTargetLeg: true,
                    isHighThreat: summary.isHighThreat
                )
            )
        }

        return segments
    }

    private func enemyIntentMovementRouteSegments(for summary: EnemyIntentSummary) -> [EnemyIntentRouteSegment] {
        let origin = summary.originPosition
        let destination = summary.destinationPosition
        guard origin != destination else { return [] }

        guard let path = enemyIntentMovementPath(for: summary),
              path.count >= 2 else {
            return [
                EnemyIntentRouteSegment(
                    id: "\(summary.id)-move",
                    from: origin,
                    to: destination,
                    kind: summary.intent.kind,
                    isTargetLeg: false,
                    isHighThreat: summary.isHighThreat
                )
            ]
        }

        return zip(path, path.dropFirst()).enumerated().map { index, pair in
            EnemyIntentRouteSegment(
                id: "\(summary.id)-route-\(index)",
                from: pair.0,
                to: pair.1,
                kind: summary.intent.kind,
                isTargetLeg: false,
                isHighThreat: summary.isHighThreat
            )
        }
    }

    private func enemyIntentMovementPath(for summary: EnemyIntentSummary) -> [Position]? {
        let origin = summary.originPosition
        let destination = summary.destinationPosition
        guard origin != destination else { return [origin] }

        var planningUnit = summary.unit
        planningUnit.tacticalOrder = summary.intent.tacticalOrder == .balanced ? nil : summary.intent.tacticalOrder

        let movementLimit = state.effectiveMovement(for: planningUnit)
        var bestCost: [Position: Int] = [origin: 0]
        var previous: [Position: Position] = [:]
        var frontier = [origin]

        while !frontier.isEmpty {
            let currentIndex = frontier.indices.min { leftIndex, rightIndex in
                let left = frontier[leftIndex]
                let right = frontier[rightIndex]
                let leftCost = bestCost[left] ?? Int.max
                let rightCost = bestCost[right] ?? Int.max
                if leftCost != rightCost { return leftCost < rightCost }

                let leftDistance = left.hexDistance(to: destination)
                let rightDistance = right.hexDistance(to: destination)
                if leftDistance != rightDistance { return leftDistance < rightDistance }

                if left.y != right.y { return left.y < right.y }
                return left.x < right.x
            } ?? frontier.startIndex
            let current = frontier.remove(at: currentIndex)
            if current == destination {
                return reconstructEnemyIntentPath(to: destination, from: previous, origin: origin)
            }

            let currentCost = bestCost[current] ?? 0
            for neighbor in current.neighbors(width: state.width, height: state.height) {
                guard let tile = state.tile(at: neighbor),
                      planningUnit.kind.canEnter(tile.terrain),
                      state.unit(at: neighbor).map({ $0.id == planningUnit.id }) ?? true else {
                    continue
                }

                let nextCost = currentCost + tile.terrain.movementCost
                guard nextCost <= movementLimit else { continue }

                if nextCost < (bestCost[neighbor] ?? Int.max) {
                    bestCost[neighbor] = nextCost
                    previous[neighbor] = current
                    if !frontier.contains(neighbor) {
                        frontier.append(neighbor)
                    }
                }
            }
        }

        return nil
    }

    private func reconstructEnemyIntentPath(
        to destination: Position,
        from previous: [Position: Position],
        origin: Position
    ) -> [Position]? {
        var path = [destination]
        var current = destination

        while current != origin {
            guard let step = previous[current] else { return nil }
            current = step
            path.append(current)
        }

        return path.reversed()
    }

    func enemyIntentDestinationOverlays(for overlays: [EnemyIntentMapOverlay]) -> [Position: EnemyIntentMapOverlay] {
        overlays.reduce(into: [Position: EnemyIntentMapOverlay]()) { result, overlay in
            guard overlay.showsDestinationMarker else { return }
            if result[overlay.destinationPosition] == nil {
                result[overlay.destinationPosition] = overlay
            }
        }
    }

    func enemyIntentTargetOverlays(for overlays: [EnemyIntentMapOverlay]) -> [Position: EnemyIntentMapOverlay] {
        overlays.reduce(into: [Position: EnemyIntentMapOverlay]()) { result, overlay in
            guard let targetPosition = overlay.targetPosition else { return }
            if result[targetPosition] == nil {
                result[targetPosition] = overlay
            }
        }
    }

    private func cityBrief(for city: City) -> SelectedCityBrief {
        let developmentPreview = try? state.cityDevelopmentPreview(id: city.id)
        let recruitmentOptions = UnitKind.allCases.map { kind in
            cityRecruitmentOptionPreview(for: kind, at: city)
        }
        let productionLabel = resourceLabel(city.production, signed: true, includeZero: true)
        let ownerIncomeLabel = "\(city.owner.displayName)收入 \(resourceLabel(state.income(for: city.owner), signed: true, includeZero: false))"
        let romanResourceLabel = "罗马库存 \(resourceLabel(romanResources, signed: false, includeZero: false))"
        let developmentCostLabel = developmentPreview.map { resourceLabel($0.cost, signed: false, includeZero: false) } ?? "无"
        let developmentGainLabel = developmentPreview.map { preview in
            "\(resourceLabel(preview.productionIncrease, signed: true, includeZero: false)) · 城防 +\(preview.fortificationIncrease)"
        } ?? "无"
        let developmentStatusLabel = developmentPreview.map { preview in
            preview.canDevelop ? "扩建后城防 \(preview.projectedFortification)" : (preview.blockedReason ?? "不可扩建")
        } ?? "不可扩建"
        let deploymentSummary = cityDeploymentSummary(for: city, recruitmentOptions: recruitmentOptions)
        let availableRecruitmentCount = recruitmentOptions.filter { $0.canRecruit }.count
        let accessibilityParts = [
            city.name,
            city.owner.displayName,
            "位置\(city.position)",
            "城防\(city.fortification)",
            "本城产出\(productionLabel)",
            ownerIncomeLabel,
            deploymentSummary,
            "可招募\(availableRecruitmentCount)项"
        ]

        return SelectedCityBrief(
            cityID: city.id,
            title: city.name,
            ownerLabel: city.owner.displayName,
            positionLabel: "坐标 \(city.position.x),\(city.position.y)",
            fortificationLabel: "城防 \(city.fortification)",
            productionLabel: productionLabel,
            ownerIncomeLabel: ownerIncomeLabel,
            romanResourceLabel: romanResourceLabel,
            deploymentSummary: deploymentSummary,
            developmentPreview: developmentPreview,
            developmentCostLabel: developmentCostLabel,
            developmentGainLabel: developmentGainLabel,
            developmentStatusLabel: developmentStatusLabel,
            canDevelop: developmentPreview?.canDevelop ?? false,
            recruitmentOptions: recruitmentOptions,
            availableRecruitmentCount: availableRecruitmentCount,
            accessibilityLabel: accessibilityParts.joined(separator: "，")
        )
    }

    private func cityRecruitmentOptionPreview(for kind: UnitKind, at city: City) -> CityRecruitmentOptionPreview {
        let corePreview = try? state.recruitmentPreview(kind, at: city.id)
        let cost = corePreview?.cost ?? kind.recruitmentCost
        let shortageLabel = resourceShortageLabel(for: cost)
        let blockedReason: String?
        if corePreview?.blockingError == .insufficientResources, let shortageLabel {
            blockedReason = shortageLabel
        } else {
            blockedReason = corePreview?.blockedReason
        }
        let deploymentLabel = corePreview?.deploymentPosition.map { "部署 \($0)" } ?? (blockedReason ?? "不可部署")
        let shortStatusLabel = corePreview?.canRecruit == true ? "可征召" : (blockedReason ?? "受阻")
        let statsLabel = "攻 \(kind.attack) · 防 \(kind.defense) · 移 \(kind.movement) · 射 \(kind.range) · 兵 \(kind.maxHealth)"
        let costLabel = resourceLabel(cost, signed: false, includeZero: false)
        let accessibilityParts = [
            kind.displayName,
            statsLabel,
            "成本\(costLabel)",
            deploymentLabel,
            shortStatusLabel
        ]

        return CityRecruitmentOptionPreview(
            kind: kind,
            statsLabel: statsLabel,
            costLabel: costLabel,
            shortCostLabel: shortResourceLabel(cost),
            deploymentLabel: deploymentLabel,
            shortStatusLabel: shortStatusLabel,
            canRecruit: corePreview?.canRecruit ?? false,
            blockedReason: blockedReason,
            accessibilityLabel: accessibilityParts.joined(separator: "，")
        )
    }

    private func cityDeploymentSummary(
        for city: City,
        recruitmentOptions: [CityRecruitmentOptionPreview]
    ) -> String {
        let cityOccupant = state.unit(at: city.position).map { "\($0.faction.displayName)\($0.kind.displayName)" } ?? "空闲"
        let neighbors = city.position.neighbors(width: state.width, height: state.height)
        let openLandNeighbors = neighbors.filter { position in
            guard let tile = state.tile(at: position) else { return false }
            return tile.terrain != .water && state.unit(at: position) == nil
        }.count
        let openHarbors = neighbors.filter { position in
            state.tile(at: position)?.terrain == .water && state.unit(at: position) == nil
        }.count
        let canRecruitCount = recruitmentOptions.filter { $0.canRecruit }.count

        return "城内\(cityOccupant) · 陆军邻格 \(openLandNeighbors) · 港口 \(openHarbors) · 可招募 \(canRecruitCount)"
    }

    private func resourceLabel(
        _ resources: EmpireResources,
        signed: Bool,
        includeZero: Bool
    ) -> String {
        let values = resourcePairs(resources)
            .filter { includeZero || $0.value != 0 }
            .map { pair in
                let value = signed ? signedValue(pair.value) : "\(pair.value)"
                return "\(pair.label) \(value)"
            }

        return values.isEmpty ? "0" : values.joined(separator: " · ")
    }

    private func shortResourceLabel(_ resources: EmpireResources) -> String {
        let values = resourcePairs(resources)
            .filter { $0.value != 0 }
            .prefix(2)
            .map { "\($0.label)\($0.value)" }

        return values.isEmpty ? "0" : values.joined(separator: " ")
    }

    private func resourceShortageLabel(for cost: EmpireResources) -> String? {
        let pool = state.resources[state.activeFaction] ?? .zero
        let shortages = [
            ("金", max(0, cost.gold - pool.gold)),
            ("粮", max(0, cost.grain - pool.grain)),
            ("铁", max(0, cost.iron - pool.iron)),
            ("科", max(0, cost.science - pool.science)),
            ("威", max(0, cost.prestige - pool.prestige))
        ]
        .filter { $0.1 > 0 }
        .map { "缺\($0.0) \($0.1)" }

        return shortages.isEmpty ? nil : shortages.joined(separator: " · ")
    }

    private func resourcePairs(_ resources: EmpireResources) -> [(label: String, value: Int)] {
        [
            ("金", resources.gold),
            ("粮", resources.grain),
            ("铁", resources.iron),
            ("科", resources.science),
            ("威", resources.prestige)
        ]
    }

    var selectedSupplyLabel: String {
        guard let position = focusedPosition else { return "无" }

        if let city = state.city(at: position), city.owner != .neutral {
            return city.owner.displayName
        }

        if let owner = position
            .neighbors(width: state.width, height: state.height)
            .compactMap({ state.city(at: $0)?.owner })
            .first(where: { $0 != .neutral }) {
            return owner.displayName
        }

        return "无"
    }

    var romanResources: EmpireResources {
        state.resources[.rome] ?? .zero
    }

    var reachablePositions: Set<Position> {
        guard !isCampaignOver else { return [] }
        guard let selectedUnitID = selectedUnitID else { return [] }
        return state.reachablePositions(for: selectedUnitID)
    }

    var attackTargets: [ArmyUnit] {
        guard !isCampaignOver else { return [] }
        guard let selectedUnitID = selectedUnitID else { return [] }
        return state.attackTargets(for: selectedUnitID)
    }

    func attackPreview(for defenderID: String) -> CombatPreview? {
        guard let selectedUnitID = selectedUnitID else { return nil }
        return try? state.attackPreview(attackerID: selectedUnitID, defenderID: defenderID)
    }

    var selectedGeneralSkillPreview: GeneralSkillPreview? {
        guard let selectedUnitID = selectedUnitID else { return nil }
        return try? state.generalSkillPreview(unitID: selectedUnitID)
    }

    var selectedWarMeritStatus: WarMeritStatus? {
        guard let selectedUnit else { return nil }
        return state.warMeritStatus(for: selectedUnit)
    }

    var selectedGeneralSkillRangePositions: Set<Position> {
        Set(selectedGeneralSkillPreview?.rangePositions ?? [])
    }

    var selectedGeneralSkillTargetPositions: Set<Position> {
        Set(selectedGeneralSkillPreview?.affectedPositions ?? [])
    }

    var selectedGeneralSkillTargetUnitIDs: Set<String> {
        Set(selectedGeneralSkillPreview?.affectedUnitIDs ?? [])
    }

    var selectedGeneralSkillTargetCityIDs: Set<String> {
        Set(selectedGeneralSkillPreview?.affectedCityIDs ?? [])
    }

    var selectedGeneralSkillTargetReadout: SelectedGeneralSkillTargetReadout? {
        guard let preview = selectedGeneralSkillPreview else { return nil }

        let unitTargets = preview.affectedUnitIDs.compactMap { unitID -> GeneralSkillTargetReadoutTarget? in
            guard let unit = state.unit(withID: unitID) else { return nil }
            let effect = preview.projectedRecoveredHealth > 0 ? "恢复 \(preview.trait.recoveryAmount)" : preview.summary
            let title = "\(unit.faction.displayName)\(unit.kind.displayName)"
            let subtitle = "\(unit.position.description) · 生命 \(unit.health)/\(unit.kind.maxHealth)"
            return GeneralSkillTargetReadoutTarget(
                id: "unit-\(unit.id)",
                title: title,
                subtitle: subtitle,
                position: unit.position,
                effectLabel: effect,
                accessibilityLabel: "\(title)，\(subtitle)，\(effect)"
            )
        }
        let cityTargets = preview.affectedCityIDs.compactMap { cityID -> GeneralSkillTargetReadoutTarget? in
            guard let city = state.city(withID: cityID) else { return nil }
            let effect = preview.projectedFortificationReduction > 0 ? "城防 -\(preview.trait.fortificationReductionAmount)" : preview.summary
            let title = city.name
            let subtitle = "\(city.position.description) · \(city.owner.displayName)"
            return GeneralSkillTargetReadoutTarget(
                id: "city-\(city.id)",
                title: title,
                subtitle: subtitle,
                position: city.position,
                effectLabel: effect,
                accessibilityLabel: "\(title)，\(subtitle)，\(effect)"
            )
        }
        let targets = unitTargets + cityTargets
        let totalTargetCount = preview.affectedUnitIDs.count + preview.affectedCityIDs.count
        let targetKindLabel = preview.trait == .siegeEngineer ? "敌城" : "友军"
        let targetCountLabel = totalTargetCount > 0 ? "目标 \(totalTargetCount) \(targetKindLabel)" : "暂无目标 · 0"
        let effectLabel: String
        if preview.projectedFortificationReduction > 0 {
            effectLabel = "削城防 \(preview.projectedFortificationReduction)"
        } else if preview.projectedRecoveredHealth > 0 {
            effectLabel = "恢复 \(preview.projectedRecoveredHealth)"
        } else {
            effectLabel = preview.summary
        }
        let visibleTargetLabels = targets.prefix(3).map(\.title)
        let hiddenCount = max(0, totalTargetCount - visibleTargetLabels.count)
        let targetLabels = hiddenCount > 0 ? visibleTargetLabels + ["等 \(hiddenCount) 个"] : visibleTargetLabels
        let mapCueLabel = preview.affectedPositions.isEmpty ? "地图暂无目标标记" : "地图紫标 \(preview.affectedPositions.count) 处"
        let statusLabel = preview.blockedReason ?? (preview.isExecutable ? "可发动" : preview.summary)
        let accessibilityLabel = [
            preview.trait.skillName,
            targetCountLabel,
            effectLabel,
            mapCueLabel,
            statusLabel,
            selectedCommanderActionGuidance?.stageCueLabel,
            targets.map(\.accessibilityLabel).joined(separator: "，")
        ].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "，")

        return SelectedGeneralSkillTargetReadout(
            title: "\(preview.trait.skillName)目标",
            effectLabel: effectLabel,
            targetCountLabel: targetCountLabel,
            targetLabels: targetLabels,
            mapCueLabel: mapCueLabel,
            statusLabel: statusLabel,
            targets: targets,
            accessibilityLabel: accessibilityLabel
        )
    }

    var selectedGeneralSkillButtonDetail: String? {
        guard let preview = selectedGeneralSkillPreview else { return nil }
        if preview.cooldownRemaining > 0 {
            return preview.cooldownText
        }

        return preview.blockedReason ?? "\(preview.summary) · \(preview.cooldownText)"
    }

    var selectedGeneralSkillCommandButtonDetail: String? {
        let detail = [
            selectedCommanderActionGuidance?.buttonDetailPrefix,
            selectedGeneralSkillButtonDetail
        ].compactMap { $0 }.joined(separator: " · ")
        return detail.isEmpty ? nil : detail
    }

    var selectedGeneralSkillCooldownDetail: String? {
        selectedGeneralSkillPreview?.cooldownText
    }

    var selectedCommanderActionGuidance: CommanderActionGuidance? {
        guard let selectedUnit,
              selectedUnit.resolvedGeneralTrait != nil,
              let brief = selectedCommanderBrief,
              let skillPreview = selectedGeneralSkillPreview else {
            return nil
        }

        let synergySummary = selectedCommanderSynergySummary
        let stagePreview = selectedBattleObjectiveStageCommandPreview
        let isLinkedStage = stagePreview?.role == .synergy &&
            stagePreview?.isCommandUnit(selectedUnit) == true
        let stageCueLabel = isLinkedStage ? stagePreview?.skillStageCueLabel : nil
        let skillCueLabel = stageCueLabel ??
            (synergySummary?.kind == .commanderSkill ? "将令 · \(synergySummary?.statusLabel ?? brief.skillStatusLabel)" : brief.skillStatusLabel)
        let buttonDetailPrefix = stageCueLabel ??
            (synergySummary?.kind == .commanderSkill ? "将令 · \(brief.skillStatusLabel)" : nil)
        let statusLabel = skillPreview.isExecutable ? "技能入口就绪" : (skillPreview.blockedReason ?? brief.skillStatusLabel)
        let title = synergySummary.map { "将令行动 · \($0.targetLabel)" } ?? "将领行动"
        let accessibilityLabel = [
            title,
            stageCueLabel,
            "技能\(brief.skillName ?? "无主动技能")",
            skillCueLabel,
            "状态\(statusLabel)",
            synergySummary.map { "目标\($0.targetLabel)" }
        ].compactMap { $0 }.joined(separator: "，")

        return CommanderActionGuidance(
            title: title,
            stageCueLabel: stageCueLabel,
            skillCueLabel: skillCueLabel,
            buttonDetailPrefix: buttonDetailPrefix,
            statusLabel: statusLabel,
            isLinkedToBattleObjectiveStage: isLinkedStage,
            accessibilityLabel: accessibilityLabel
        )
    }

    var selectedCommanderBrief: SelectedCommanderBrief? {
        guard let selectedUnit else { return nil }

        let trait = selectedUnit.resolvedGeneralTrait
        let preview = selectedGeneralSkillPreview
        let warMeritStatus = selectedWarMeritStatus
        let passiveContributions = selectedGeneralPassiveContributions
        let skillStatusLabel: String

        if let preview {
            if preview.cooldownRemaining > 0 {
                skillStatusLabel = preview.cooldownText
            } else if preview.isExecutable {
                skillStatusLabel = "可发动"
            } else {
                skillStatusLabel = preview.blockedReason ?? "不可发动"
            }
        } else {
            skillStatusLabel = "无主动技能"
        }

        let skillEffectLabel = selectedSkillEffectLabel(preview)
        let warMeritProgressLabel = warMeritStatus.map { status in
            if let nextRankName = status.nextRankName,
               let nextRankExperience = status.nextRankExperience {
                return "战功 \(status.experience)/\(nextRankExperience) · 下一军阶 \(nextRankName)"
            }

            return "战功 \(status.experience) · 最高军阶"
        }

        let generalName = selectedUnit.generalName
        let traitName = trait?.displayName
        let accessibilityParts = [
            "\(selectedUnit.faction.displayName)\(selectedUnit.kind.displayName)",
            generalName.map { "将领\($0)" },
            traitName,
            passiveContributions.isEmpty ? "无被动贡献" : passiveContributions.map { "\($0.label)\($0.value)" }.joined(separator: "，"),
            preview.map { "\($0.trait.skillName)\(skillStatusLabel)" },
            warMeritStatus?.summary
        ].compactMap { $0 }

        return SelectedCommanderBrief(
            unitID: selectedUnit.id,
            title: "\(selectedUnit.faction.displayName) \(selectedUnit.kind.displayName)",
            generalName: generalName,
            traitName: traitName,
            passiveContributions: passiveContributions,
            skillName: trait?.skillName,
            skillSummary: preview?.summary,
            skillDetail: trait?.skillDetail,
            skillStatusLabel: skillStatusLabel,
            skillBlockedReason: preview?.blockedReason,
            skillEffectLabel: skillEffectLabel,
            warMeritSummary: warMeritStatus?.summary,
            warMeritProgressLabel: warMeritProgressLabel,
            accessibilityLabel: accessibilityParts.joined(separator: "，")
        )
    }

    var selectedGeneralPassiveContributions: [GeneralPassiveContribution] {
        guard let trait = selectedUnit?.resolvedGeneralTrait else { return [] }
        var contributions: [GeneralPassiveContribution] = []

        if trait.attackBonus != 0 {
            contributions.append(
                GeneralPassiveContribution(
                    id: "attack",
                    label: "攻击",
                    value: signedValue(trait.attackBonus),
                    detail: "普通战斗攻击"
                )
            )
        }

        if trait.siegeAttackBonus != 0 {
            contributions.append(
                GeneralPassiveContribution(
                    id: "siege",
                    label: "攻城",
                    value: signedValue(trait.siegeAttackBonus),
                    detail: "对城市伤害"
                )
            )
        }

        if trait.defenseBonus != 0 {
            contributions.append(
                GeneralPassiveContribution(
                    id: "defense",
                    label: "防御",
                    value: signedValue(trait.defenseBonus),
                    detail: "受击减伤"
                )
            )
        }

        if trait.movementBonus != 0 {
            contributions.append(
                GeneralPassiveContribution(
                    id: "movement",
                    label: "机动",
                    value: signedValue(trait.movementBonus),
                    detail: "移动范围"
                )
            )
        }

        return contributions
    }

    var selectedTacticalOrderPreviews: [SelectedTacticalOrderPreview] {
        guard let selectedUnit else { return [] }
        let currentAttack = state.effectiveAttack(for: selectedUnit)
        let currentDefense = state.effectiveDefense(for: selectedUnit)
        let currentMovement = state.effectiveMovement(for: selectedUnit)

        return TacticalOrder.allCases.map { order in
            var previewUnit = selectedUnit
            previewUnit.tacticalOrder = order == .balanced ? nil : order
            let attack = state.effectiveAttack(for: previewUnit)
            let defense = state.effectiveDefense(for: previewUnit)
            let movement = state.effectiveMovement(for: previewUnit)
            let isCurrent = order == selectedUnit.resolvedTacticalOrder
            let blockedReason = tacticalOrderBlockedReason(order, for: selectedUnit)
            let canSwitch = canSetSelectedTacticalOrder(order)
            let detail = "攻 \(attack) \(deltaLabel(attack - currentAttack)) · 防 \(defense) \(deltaLabel(defense - currentDefense)) · 移 \(movement) \(deltaLabel(movement - currentMovement))"

            return SelectedTacticalOrderPreview(
                order: order,
                attack: attack,
                defense: defense,
                movement: movement,
                attackDelta: attack - currentAttack,
                defenseDelta: defense - currentDefense,
                movementDelta: movement - currentMovement,
                isCurrent: isCurrent,
                canSwitch: canSwitch,
                blockedReason: blockedReason,
                detail: detail,
                accessibilityLabel: "\(order.displayName)，攻击\(attack)，防御\(defense)，机动\(movement)，\(isCurrent ? "当前姿态" : (blockedReason ?? "可切换"))"
            )
        }
    }

    func selectedTacticalOrderPreview(for order: TacticalOrder) -> SelectedTacticalOrderPreview? {
        selectedTacticalOrderPreviews.first { $0.order == order }
    }

    var canSkipSelectedUnit: Bool {
        guard !isCampaignOver else { return false }
        guard let selectedUnit else { return false }
        return selectedUnit.faction == state.activeFaction && (!selectedUnit.hasMoved || !selectedUnit.hasActed)
    }

    var canUseSelectedGeneralSkill: Bool {
        guard !isCampaignOver else { return false }
        guard selectedUnit != nil,
              let preview = selectedGeneralSkillPreview else { return false }
        return preview.isExecutable
    }

    var canTrainSelectedUnit: Bool {
        guard !isCampaignOver else { return false }
        return selectedUnitDevelopmentDecisionSummary?.trainingOption?.canExecute ?? false
    }

    var canAppointGeneralToSelectedUnit: Bool {
        guard !isCampaignOver else { return false }
        return selectedUnitDevelopmentDecisionSummary?.appointmentOption?.canExecute ?? false
    }

    var selectedTrainingButtonDetail: String? {
        selectedUnitDevelopmentDecisionSummary?.trainingOption?.buttonDetail
    }

    var selectedAppointmentButtonDetail: String? {
        selectedUnitDevelopmentDecisionSummary?.appointmentOption?.buttonDetail
    }

    func canSetSelectedTacticalOrder(_ order: TacticalOrder) -> Bool {
        guard !isCampaignOver else { return false }
        guard let selectedUnit else { return false }
        return selectedUnit.faction == state.activeFaction &&
            selectedUnit.resolvedTacticalOrder != order &&
            !selectedUnit.hasMoved &&
            !selectedUnit.hasActed
    }

    private func tacticalOrderBlockedReason(_ order: TacticalOrder, for unit: ArmyUnit) -> String? {
        if order == unit.resolvedTacticalOrder {
            return "当前姿态"
        }

        if isCampaignOver {
            return "战役已结束"
        }

        if unit.faction != state.activeFaction {
            return "非当前阵营"
        }

        if unit.hasMoved || unit.hasActed {
            return "已行动"
        }

        return nil
    }

    private func tacticalOrderCommandSymbol(_ order: TacticalOrder) -> String {
        switch order {
        case .balanced: return "circle.grid.cross.fill"
        case .assault: return "bolt.fill"
        case .defensive: return "shield.fill"
        case .forcedMarch: return "figure.walk.motion"
        }
    }

    private func selectedSkillEffectLabel(_ preview: GeneralSkillPreview?) -> String? {
        guard let preview else { return nil }

        if preview.projectedFortificationReduction > 0 {
            return "城防 -\(preview.projectedFortificationReduction) · 目标 \(preview.affectedCityIDs.count)"
        }

        if preview.projectedRecoveredHealth > 0 {
            return "恢复 \(preview.projectedRecoveredHealth) · 友军 \(preview.affectedUnitIDs.count)"
        }

        return preview.summary
    }

    private func signedValue(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }

    private func deltaLabel(_ value: Int) -> String {
        value == 0 ? "±0" : signedValue(value)
    }

    func start(mode: GameMode) {
        selectedMode = mode
        state = GameState.newCampaign(mode: mode)
        selectedUnitID = nil
        selectedCityID = nil
        selectedPosition = nil
        selectedTechnology = nil
        focusedCountermeasureID = nil
        focusedBattleObjectiveRole = nil
        isShowingMenu = false
        bannerMessage = "\(mode.displayName)开始：控制罗马军团扩张疆域。"
    }

    func openMenu() {
        isShowingMenu = true
    }

    func selectTile(_ position: Position) {
        focusedBattleObjectiveRole = nil

        if let unit = state.unit(at: position) {
            if let target = attackTargets.first(where: { $0.id == unit.id }) {
                selectedPosition = position
                attack(target.id)
                return
            }

            selectedUnitID = unit.id
            selectedCityID = state.city(at: position)?.id
            selectedPosition = position
            if let city = state.city(at: position) {
                bannerMessage = "\(unit.faction.displayName)\(unit.kind.displayName)驻守\(city.name)。"
            } else {
                bannerMessage = "\(unit.faction.displayName)\(unit.kind.displayName) \(unit.health)/\(unit.kind.maxHealth)"
            }
            return
        }

        if let unit = selectedUnit, reachablePositions.contains(position) {
            apply {
                try state.moveUnit(id: unit.id, to: position)
            }
            selectedCityID = state.city(at: position)?.id
            selectedPosition = position
            return
        }

        if let city = state.city(at: position) {
            selectedCityID = city.id
            selectedUnitID = nil
            selectedPosition = position
            bannerMessage = "\(city.name)：\(city.owner.displayName)控制。"
            return
        }

        selectedUnitID = nil
        selectedCityID = nil
        selectedPosition = position
        if let tile = state.tile(at: position) {
            bannerMessage = "\(tile.terrain.displayName)地块：移动 \(tile.terrain.movementCost)，防御 +\(tile.terrain.defenseBonus)。"
        } else {
            bannerMessage = "战场边界外。"
        }
    }

    func focusPrimaryCountermeasure() {
        guard let summary = primaryCountermeasureSummary else { return }
        focusCountermeasure(summary.id)
    }

    func focusCountermeasure(_ id: String) {
        guard let preview = countermeasureCommandPreviews.first(where: { $0.id == id }),
              let responseUnit = preview.responseUnit,
              preview.canFocus else {
            bannerMessage = "反制回应单位暂不可定位。"
            return
        }

        selectedUnitID = responseUnit.id
        selectedCityID = state.city(at: responseUnit.position)?.id
        selectedPosition = responseUnit.position
        focusedCountermeasureID = preview.id
        focusedBattleObjectiveRole = nil
        bannerMessage = "\(preview.summary.unitLabel)反制：\(preview.nextStepLabel)。\(preview.destinationLabel)，目标\(preview.targetLabel)。"
    }

    func focusPrimaryBattleObjectiveStage(_ role: BattleObjectiveMapRole) {
        guard let overlay = primaryBattleObjectiveMapOverlay?.positionOverlays.first(where: { $0.role == role }) else {
            bannerMessage = "\(role.stageLabel)目标线阶段暂不可定位。"
            return
        }

        selectedPosition = overlay.position
        focusedBattleObjectiveRole = role
        focusedCountermeasureID = nil

        selectedUnitID = battleObjectiveFocusUnit(for: overlay)?.id
        if let city = state.city(at: overlay.position) {
            selectedCityID = city.id
        } else if let selectedUnitID,
                  let unit = state.unit(withID: selectedUnitID) {
            selectedCityID = state.city(at: unit.position)?.id
        } else {
            selectedCityID = nil
        }

        bannerMessage = "目标线\(overlay.stageLabel)：\(overlay.focusLabel)。位置\(overlay.position.description)。"
    }

    private func battleObjectiveFocusUnit(for overlay: BattleObjectivePositionOverlay) -> ArmyUnit? {
        let unit: ArmyUnit?

        switch overlay.role {
        case .focus:
            unit = overlay.chain.focus.unit
        case .synergy:
            unit = overlay.chain.synergy?.unit ?? overlay.chain.synergy?.commanderUnit
        case .maneuver:
            unit = overlay.chain.maneuver?.unit
        case .recommendation:
            unit = overlay.chain.recommendation?.unit
        }

        return unit?.faction == .rome ? unit : nil
    }

    func attack(_ defenderID: String) {
        guard let selectedUnitID = selectedUnitID else { return }
        let defenderPosition = state.unit(withID: defenderID)?.position

        apply {
            try state.attack(attackerID: selectedUnitID, defenderID: defenderID)
        }

        if state.unit(withID: selectedUnitID) == nil || state.unit(withID: defenderID) == nil {
            self.selectedUnitID = nil
        }

        if let attacker = state.unit(withID: selectedUnitID) {
            selectedPosition = attacker.position
        } else if let defender = state.unit(withID: defenderID) {
            selectedPosition = defender.position
        } else {
            selectedPosition = defenderPosition
        }
    }

    func skipSelectedUnit() {
        guard let selectedUnitID = selectedUnitID else { return }

        apply {
            try state.skipUnit(id: selectedUnitID)
        }

        let nextReadyUnit = state.nextReadyUnit(for: .rome)
        self.selectedUnitID = nextReadyUnit?.id
        self.selectedCityID = nextReadyUnit.flatMap { state.city(at: $0.position)?.id }
        self.selectedPosition = nextReadyUnit?.position
    }

    func recruit(_ kind: UnitKind) {
        guard let cityID = commandCity?.id else { return }

        apply {
            try state.recruit(kind, at: cityID)
        }
    }

    func developCommandCity() {
        guard let city = commandCity else { return }

        apply {
            try state.developCity(id: city.id)
        }
    }

    func trainSelectedUnit() {
        guard let selectedUnitID = selectedUnitID else { return }

        apply {
            try state.trainUnit(id: selectedUnitID)
        }
    }

    func appointGeneralToSelectedUnit() {
        guard let selectedUnitID = selectedUnitID else { return }

        apply {
            try state.appointGeneral(unitID: selectedUnitID)
        }
    }

    func useSelectedGeneralSkill() {
        guard let selectedUnitID = selectedUnitID else { return }

        apply {
            try state.useGeneralSkill(unitID: selectedUnitID)
        }

        if let unit = state.unit(withID: selectedUnitID) {
            selectedPosition = unit.position
        }
    }

    func setSelectedTacticalOrder(_ order: TacticalOrder) {
        guard let selectedUnitID = selectedUnitID else { return }

        apply {
            try state.setTacticalOrder(unitID: selectedUnitID, order: order)
        }

        if let unit = state.unit(withID: selectedUnitID) {
            selectedPosition = unit.position
        }
    }

    func restSelectedUnit() {
        guard let selectedUnitID = selectedUnitID else { return }

        apply {
            try state.restUnit(id: selectedUnitID)
        }
    }

    func sendEnvoy(to faction: Faction) {
        apply {
            try state.sendEnvoy(to: faction)
        }
    }

    func research(_ technology: Technology) {
        apply {
            try state.research(technology)
        }
    }

    func endTurn() {
        guard !isCampaignOver else {
            bannerMessage = "\(campaignStatusTitle)：\(campaignStatusDetail)"
            return
        }

        var messages = state.endTurn()

        while state.activeFaction != .rome && !state.campaignStatus.isGameOver {
            messages.append(contentsOf: state.performSimpleAI(for: state.activeFaction))
            guard !state.campaignStatus.isGameOver else {
                break
            }
            messages.append(contentsOf: state.endTurn())
        }

        selectedUnitID = nil
        selectedCityID = nil
        selectedPosition = nil
        if state.campaignStatus.isGameOver {
            bannerMessage = messages.last ?? "\(campaignStatusTitle)：\(campaignStatusDetail)"
        } else {
            bannerMessage = messages.last ?? "新的罗马回合开始。"
        }
    }

    private func apply(_ operation: () throws -> [String]) {
        do {
            let messages = try operation()
            let fallback = state.campaignStatus.isGameOver ? "\(campaignStatusTitle)：\(campaignStatusDetail)" : "命令已执行。"
            bannerMessage = messages.last ?? fallback
        } catch {
            if let ruleError = error as? GameRuleError {
                bannerMessage = ruleError.displayMessage
            } else {
                bannerMessage = error.localizedDescription
            }
        }
    }
}
