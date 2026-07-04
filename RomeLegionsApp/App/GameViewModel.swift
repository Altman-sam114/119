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

    var id: String { summary.id }
    var unitID: String { summary.unit.id }
    var kind: AIIntentKind { summary.intent.kind }
    var originPosition: Position { summary.originPosition }
    var destinationPosition: Position { summary.destinationPosition }
    var targetPosition: Position? { summary.targetPosition }
    var targetLabel: String { summary.targetLabel }
    var impactLabel: String { summary.impactLabel }
    var routeSegments: [EnemyIntentRouteSegment] { summary.routeSegments }
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

@MainActor
final class GameViewModel: ObservableObject {
    @Published var state = GameState.newCampaign()
    @Published var selectedMode: GameMode = .campaign
    @Published var selectedUnitID: String?
    @Published var selectedCityID: String?
    @Published var selectedPosition: Position?
    @Published var selectedTechnology: Technology?
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

    func enemyIntentSummary(for unitID: String) -> EnemyIntentSummary? {
        enemyIntentSummaries.first { $0.unit.id == unitID }
    }

    var enemyIntentMapOverlays: [EnemyIntentMapOverlay] {
        enemyIntentMapOverlays(for: enemyIntentSummaries)
    }

    func enemyIntentMapOverlays(for summaries: [EnemyIntentSummary]) -> [EnemyIntentMapOverlay] {
        summaries.prefix(4).map { EnemyIntentMapOverlay(summary: $0) }
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

    var selectedGeneralSkillButtonDetail: String? {
        guard let preview = selectedGeneralSkillPreview else { return nil }
        if preview.cooldownRemaining > 0 {
            return preview.cooldownText
        }

        return preview.blockedReason ?? "\(preview.summary) · \(preview.cooldownText)"
    }

    var selectedGeneralSkillCooldownDetail: String? {
        selectedGeneralSkillPreview?.cooldownText
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
        isShowingMenu = false
        bannerMessage = "\(mode.displayName)开始：控制罗马军团扩张疆域。"
    }

    func openMenu() {
        isShowingMenu = true
    }

    func selectTile(_ position: Position) {
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
        guard let selectedCityID = selectedCityID else { return }

        apply {
            try state.recruit(kind, at: selectedCityID)
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
