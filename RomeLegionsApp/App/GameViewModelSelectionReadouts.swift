import Foundation
import SwiftUI

struct SelectedCombatForecast: Identifiable {
    var attacker: ArmyUnit
    var defender: ArmyUnit
    var preview: CombatPreview

    /// Stable identity formatting shared by map, command dock and forecast readouts.
    static func identityLabel(for unit: ArmyUnit) -> String {
        let commander = unit.generalName ?? "无将领"
        return "\(unit.faction.displayName)\(unit.kind.displayName) · \(commander) · \(unit.position.description)"
    }

    var id: String {
        "\(attacker.id)-\(defender.id)"
    }

    var attackerLabel: String {
        "\(attacker.faction.displayName)\(attacker.kind.displayName)"
    }

    var defenderLabel: String {
        "\(defender.faction.displayName)\(defender.kind.displayName)"
    }

    var attackerGeneralLabel: String {
        attacker.generalName ?? "无将领"
    }

    var defenderGeneralLabel: String {
        defender.generalName ?? "无将领"
    }

    var attackerPositionLabel: String {
        "位置\(attacker.position.description)"
    }

    var defenderPositionLabel: String {
        "位置\(defender.position.description)"
    }

    var attackerIdentityLabel: String {
        Self.identityLabel(for: attacker)
    }

    var defenderIdentityLabel: String {
        Self.identityLabel(for: defender)
    }

    var identityChainLabel: String {
        "\(attackerIdentityLabel) → \(defenderIdentityLabel)"
    }

    var positionChainLabel: String {
        "\(attackerPositionLabel) → \(defenderPositionLabel)"
    }

    var damageLabel: String {
        "伤害 \(preview.damage)"
    }

    var retaliationLabel: String {
        "反击 \(preview.retaliation)"
    }

    var healthLabel: String {
        "我方 \(preview.attackerRemainingHealth)/\(attacker.kind.maxHealth) · 敌方 \(preview.defenderRemainingHealth)/\(defender.kind.maxHealth)"
    }

    var modifierLabel: String {
        var parts: [String] = []

        if preview.supportBonus > 0 {
            parts.append("支援+\(preview.supportBonus)")
        }
        if preview.flankingBonus > 0 {
            parts.append("包夹+\(preview.flankingBonus)")
        }
        if preview.commandBonus > 0 {
            parts.append("指挥+\(preview.commandBonus)")
        }
        if preview.defenderSupportBonus > 0 {
            parts.append("守援-\(preview.defenderSupportBonus)")
        }

        return parts.isEmpty ? "无额外修正" : parts.joined(separator: " · ")
    }

    var outcomeLabel: String {
        if preview.defeatsDefender {
            return "预计歼灭"
        }
        if preview.attackerFalls {
            return "预计高风险"
        }
        return "预计交战"
    }

    var outcomeSymbol: String {
        if preview.defeatsDefender {
            return "flame.fill"
        }
        if preview.attackerFalls {
            return "exclamationmark.triangle.fill"
        }
        return "bolt.fill"
    }

    var isHighRisk: Bool {
        preview.attackerFalls
    }

    var compactLabel: String {
        "\(identityChainLabel) · 伤\(preview.damage) · 反\(preview.retaliation) · 我\(preview.attackerRemainingHealth) · 敌\(preview.defenderRemainingHealth)"
    }

    var confirmationTitle: String {
        preview.defeatsDefender ? "歼灭" : "确认"
    }

    var confirmationAccessibilityLabel: String {
        "确认攻击：\(identityChainLabel)，\(damageLabel)，\(retaliationLabel)，\(healthLabel)，\(modifierLabel)，\(outcomeLabel)"
    }

    var cancelAccessibilityLabel: String {
        "取消攻击目标锁定：\(identityChainLabel)，保留攻击者选择"
    }

    var detailLabel: String {
        "\(identityChainLabel) · \(damageLabel) · \(retaliationLabel) · \(healthLabel) · \(modifierLabel)"
    }

    var accessibilityLabel: String {
        "攻击预演：攻击者\(attackerIdentityLabel)，防守者\(defenderIdentityLabel)，\(damageLabel)，\(retaliationLabel)，\(healthLabel)，\(modifierLabel)，\(outcomeLabel)"
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

enum SelectedCommanderChainSignalKind: String {
    case passive
    case skillTarget
    case warMerit
    case guidance
    case synergy
    case objectiveStage
    case situationEntry

    var displayName: String {
        switch self {
        case .passive:
            return "被动"
        case .skillTarget:
            return "目标"
        case .warMerit:
            return "战功"
        case .guidance:
            return "将令"
        case .synergy:
            return "协同"
        case .objectiveStage:
            return "目标线"
        case .situationEntry:
            return "入口"
        }
    }
}

struct SelectedCommanderChainSignal: Identifiable {
    var kind: SelectedCommanderChainSignalKind
    var title: String
    var detail: String
    var sourceID: String?

    var id: String {
        [
            kind.rawValue,
            sourceID,
            title
        ].compactMap { $0 }.joined(separator: "-")
    }

    var accessibilityLabel: String {
        [
            kind.displayName,
            title,
            detail
        ].joined(separator: "，")
    }
}

struct SelectedCommanderChainReadout {
    var unitID: String
    var title: String
    var statusLabel: String
    var passiveLabel: String
    var skillTargetLabel: String
    var warMeritLabel: String
    var entryLabel: String
    var summaryLabel: String
    var signals: [SelectedCommanderChainSignal]
    var commanderBriefID: String?
    var skillTargetReadoutID: String?
    var warMeritID: String?
    var guidanceID: String?
    var synergyID: String?
    var stagePreviewID: String?
    var situationEntryID: String?

    var compactLabel: String {
        "\(passiveLabel) · \(skillTargetLabel) · \(entryLabel)"
    }

    var accessibilityLabel: String {
        [
            title,
            "状态 \(statusLabel)",
            "被动 \(passiveLabel)",
            "目标 \(skillTargetLabel)",
            "战功 \(warMeritLabel)",
            "将令 \(entryLabel)",
            "入口 \(summaryLabel)"
        ].joined(separator: "，")
    }

    func references(brief candidate: SelectedCommanderBrief) -> Bool {
        commanderBriefID == candidate.unitID
    }

    func references(skillTargetReadout candidate: SelectedGeneralSkillTargetReadout) -> Bool {
        skillTargetReadoutID == candidate.title
    }

    func references(warMerit candidate: WarMeritStatus) -> Bool {
        warMeritID == "\(candidate.experience)-\(candidate.rankName)"
    }

    func references(guidance candidate: CommanderActionGuidance, unitID: String) -> Bool {
        guidanceID == "\(unitID)-commander-action" &&
            signals.contains { $0.kind == .guidance && $0.sourceID == guidanceID && $0.detail == candidate.skillCueLabel }
    }

    func references(synergy candidate: CommanderSynergySummary) -> Bool {
        synergyID == candidate.id
    }

    func references(stagePreview candidate: BattleObjectiveStageCommandPreview) -> Bool {
        stagePreviewID == candidate.id
    }

    func references(situation candidate: SelectedUnitSituationReadout) -> Bool {
        situationEntryID == candidate.primaryCommandEntry?.id
    }
}

enum CommanderOpportunityBridgeSignalKind: String {
    case commanderBrief
    case commanderChain
    case skillWindow
    case guidance
    case synergy
    case enemyCommander
    case countermeasure
    case counterCommand
    case objectiveStage
    case engagementLoop

    var displayName: String {
        switch self {
        case .commanderBrief:
            return "将领"
        case .commanderChain:
            return "指挥链"
        case .skillWindow:
            return "技能"
        case .guidance:
            return "入口"
        case .synergy:
            return "战机"
        case .enemyCommander:
            return "敌将"
        case .countermeasure:
            return "反制"
        case .counterCommand:
            return "指令"
        case .objectiveStage:
            return "目标线"
        case .engagementLoop:
            return "敌情"
        }
    }
}

struct CommanderOpportunityBridgeSignal: Identifiable {
    var kind: CommanderOpportunityBridgeSignalKind
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

struct SelectedCommanderOpportunityBridgeReadout {
    var unitID: String
    var title: String
    var statusLabel: String
    var opportunityLabel: String
    var skillWindowLabel: String
    var enemyThreatLabel: String
    var counterLabel: String
    var entryLabel: String
    var nextStepLabel: String
    var riskLabel: String
    var compactLabel: String
    var signals: [CommanderOpportunityBridgeSignal]
    var commanderBriefID: String?
    var commanderChainUnitID: String?
    var skillTargetReadoutID: String?
    var guidanceID: String?
    var synergyID: String?
    var enemyCommanderThreatID: String?
    var countermeasureID: String?
    var countermeasurePreviewID: String?
    var stagePreviewID: String?
    var engagementLoopID: String?

    var hasSignals: Bool {
        !signals.isEmpty
    }

    var accessibilityLabel: String {
        [
            title,
            "状态\(statusLabel)",
            "战机\(opportunityLabel)",
            "技能窗口\(skillWindowLabel)",
            "敌将\(enemyThreatLabel)",
            "反制\(counterLabel)",
            "入口\(entryLabel)",
            "下一步\(nextStepLabel)",
            "风险\(riskLabel)"
        ].joined(separator: "，")
    }

    func references(brief candidate: SelectedCommanderBrief) -> Bool {
        commanderBriefID == candidate.unitID
    }

    func references(chain candidate: SelectedCommanderChainReadout) -> Bool {
        commanderChainUnitID == candidate.unitID
    }

    func references(skillTargetReadout candidate: SelectedGeneralSkillTargetReadout) -> Bool {
        skillTargetReadoutID == candidate.title
    }

    func references(guidance candidate: CommanderActionGuidance, unitID: String) -> Bool {
        guidanceID == "\(unitID)-commander-action" &&
            signals.contains { $0.kind == .guidance && $0.sourceID == guidanceID && $0.detail == candidate.skillCueLabel }
    }

    func references(synergy candidate: CommanderSynergySummary) -> Bool {
        synergyID == candidate.id
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

    func references(stagePreview candidate: BattleObjectiveStageCommandPreview) -> Bool {
        stagePreviewID == candidate.id
    }

    func references(engagementLoop candidate: EnemyEngagementLoopReadout) -> Bool {
        engagementLoopID == candidate.compactLabel
    }
}

enum SelectedUnitOrderWindowStepKind: String {
    case countermeasure
    case objectiveStage
    case commander
    case maneuver
    case recommendation
    case tacticalOrder
    case engagement
    case convergence

    var displayName: String {
        switch self {
        case .countermeasure:
            return "反制"
        case .objectiveStage:
            return "目标线"
        case .commander:
            return "将令"
        case .maneuver:
            return "机动"
        case .recommendation:
            return "军议"
        case .tacticalOrder:
            return "姿态"
        case .engagement:
            return "敌情"
        case .convergence:
            return "态势"
        }
    }
}

struct SelectedUnitOrderWindowStep: Identifiable {
    var kind: SelectedUnitOrderWindowStepKind
    var title: String
    var detail: String
    var cueLabel: String
    var position: Position?
    var sourceID: String
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
        var parts = [
            kind.displayName,
            title,
            cueLabel,
            detail
        ]

        if let position {
            parts.append("坐标\(position.description)")
        }

        return parts.joined(separator: "，")
    }
}

struct SelectedUnitOrderWindowReadout {
    var unitID: String
    var title: String
    var statusLabel: String
    var openingLabel: String
    var postureLabel: String
    var movementLabel: String
    var strikeLabel: String
    var commanderLabel: String
    var counterLabel: String
    var nextStepLabel: String
    var riskLabel: String
    var compactLabel: String
    var steps: [SelectedUnitOrderWindowStep]
    var situationID: String?
    var countermeasurePreviewID: String?
    var stagePreviewID: String?
    var commanderBridgeID: String?
    var commanderChainUnitID: String?
    var recommendationID: String?
    var maneuverID: String?
    var engagementLoopID: String?
    var convergenceID: String?
    var tacticalOrderID: String?

    var hasSteps: Bool {
        !steps.isEmpty
    }

    var primaryStep: SelectedUnitOrderWindowStep? {
        steps.first { $0.isPrimary } ?? steps.first
    }

    var accessibilityLabel: String {
        [
            title,
            "状态\(statusLabel)",
            "军令\(openingLabel)",
            "姿态\(postureLabel)",
            "机动\(movementLabel)",
            "打击\(strikeLabel)",
            "将令\(commanderLabel)",
            "反制\(counterLabel)",
            "下一步\(nextStepLabel)",
            "风险\(riskLabel)"
        ].joined(separator: "，")
    }

    func references(situation candidate: SelectedUnitSituationReadout) -> Bool {
        situationID == candidate.unitID
    }

    func references(countermeasurePreview candidate: CountermeasureCommandPreview) -> Bool {
        countermeasurePreviewID == candidate.id
    }

    func references(stagePreview candidate: BattleObjectiveStageCommandPreview) -> Bool {
        stagePreviewID == candidate.id
    }

    func references(commanderBridge candidate: SelectedCommanderOpportunityBridgeReadout) -> Bool {
        commanderBridgeID == "\(candidate.unitID)-\(candidate.compactLabel)"
    }

    func references(commanderChain candidate: SelectedCommanderChainReadout) -> Bool {
        commanderChainUnitID == candidate.unitID
    }

    func references(recommendation candidate: TacticalRecommendationSummary) -> Bool {
        recommendationID == candidate.id
    }

    func references(maneuver candidate: ManeuverOptionSummary) -> Bool {
        maneuverID == candidate.id
    }

    func references(engagementLoop candidate: EnemyEngagementLoopReadout) -> Bool {
        engagementLoopID == candidate.compactLabel
    }

    func references(convergence candidate: BattlefieldConvergenceSummary) -> Bool {
        convergenceID == candidate.id
    }

    func references(recommendedOrder candidate: SelectedTacticalOrderPreview) -> Bool {
        tacticalOrderID == candidate.order.rawValue
    }
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
