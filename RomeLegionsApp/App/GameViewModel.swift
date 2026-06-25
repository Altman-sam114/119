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
            return unit.resolvedGeneralTrait?.skillName ?? intent.kind.displayName
        }
    }

    var detail: String {
        var parts = ["\(unit.faction.displayName)\(unit.kind.displayName)"]

        if let generalName = unit.generalName {
            parts.append(generalName)
        }

        if let projectedDamage = intent.projectedDamage {
            parts.append("伤害\(projectedDamage)")
        } else if let destination = intent.destination, destination != unit.position {
            parts.append("前往\(destination.description)")
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

    var isHighThreat: Bool {
        intent.kind == .attack ||
            intent.kind == .advanceAttack ||
            intent.kind == .captureCity ||
            intent.threatScore >= 420
    }
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

    var primaryMission: Mission? {
        state.missions.first { !$0.isCompleted } ?? state.missions.first
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
        guard let selectedUnitID = selectedUnitID else { return [] }
        return state.reachablePositions(for: selectedUnitID)
    }

    var attackTargets: [ArmyUnit] {
        guard let selectedUnitID = selectedUnitID else { return [] }
        return state.attackTargets(for: selectedUnitID)
    }

    func attackPreview(for defenderID: String) -> CombatPreview? {
        guard let selectedUnitID = selectedUnitID else { return nil }
        return try? state.attackPreview(attackerID: selectedUnitID, defenderID: defenderID)
    }

    var canSkipSelectedUnit: Bool {
        guard let selectedUnit else { return false }
        return selectedUnit.faction == state.activeFaction && (!selectedUnit.hasMoved || !selectedUnit.hasActed)
    }

    var canUseSelectedGeneralSkill: Bool {
        guard let selectedUnit else { return false }
        return selectedUnit.faction == state.activeFaction &&
            selectedUnit.generalName != nil &&
            selectedUnit.resolvedGeneralTrait != nil &&
            !selectedUnit.hasActed
    }

    func canSetSelectedTacticalOrder(_ order: TacticalOrder) -> Bool {
        guard let selectedUnit else { return false }
        return selectedUnit.faction == state.activeFaction &&
            selectedUnit.resolvedTacticalOrder != order &&
            !selectedUnit.hasMoved &&
            !selectedUnit.hasActed
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
        var messages = state.endTurn()

        while state.activeFaction != .rome {
            messages.append(contentsOf: state.performSimpleAI(for: state.activeFaction))
            messages.append(contentsOf: state.endTurn())
        }

        selectedUnitID = nil
        selectedCityID = nil
        selectedPosition = nil
        bannerMessage = messages.last ?? "新的罗马回合开始。"
    }

    private func apply(_ operation: () throws -> [String]) {
        do {
            let messages = try operation()
            bannerMessage = messages.last ?? "命令已执行。"
        } catch {
            if let ruleError = error as? GameRuleError {
                bannerMessage = ruleError.displayMessage
            } else {
                bannerMessage = error.localizedDescription
            }
        }
    }
}
