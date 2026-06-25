import Testing
@testable import RomeLegionsCore

@Test func reachablePositionsRespectTerrainAndOccupation() {
    let state = GameState.newCampaign()

    let reachable = state.reachablePositions(for: "rome-legion-1")

    #expect(reachable.contains(Position(x: 5, y: 2)))
    #expect(!reachable.contains(Position(x: 2, y: 6)))
    #expect(!reachable.contains(Position(x: 4, y: 4)))
}

@Test func movingIntoNeutralCityCapturesIt() throws {
    var state = GameState.newCampaign()

    let messages = try state.moveUnit(id: "rome-legion-1", to: Position(x: 5, y: 2))

    #expect(state.city(withID: "massilia")?.owner == .rome)
    #expect(messages.contains { $0.contains("占领马赛") })
}

@Test func attackMarksAttackerAndDamagesEnemy() throws {
    var state = GameState.newCampaign()
    state.units.append(ArmyUnit(id: "test-carthage", kind: .archer, faction: .carthage, position: Position(x: 4, y: 3)))

    _ = try state.attack(attackerID: "rome-legion-1", defenderID: "test-carthage")

    #expect(state.unit(withID: "rome-legion-1")?.hasActed == true)
    #expect((state.unit(withID: "test-carthage")?.health ?? 0) < UnitKind.archer.maxHealth)
}

@Test func combatPreviewMatchesAttackResolution() throws {
    var state = GameState.newCampaign()
    state.units.append(ArmyUnit(id: "preview-carthage", kind: .archer, faction: .carthage, position: Position(x: 4, y: 3), health: 60))

    let attackerHealth = state.unit(withID: "rome-legion-1")?.health ?? 0
    let preview = try state.attackPreview(attackerID: "rome-legion-1", defenderID: "preview-carthage")

    _ = try state.attack(attackerID: "rome-legion-1", defenderID: "preview-carthage")

    #expect(preview.damage > 0)
    #expect(preview.retaliation >= 0)
    #expect(state.unit(withID: "preview-carthage")?.health == preview.defenderRemainingHealth)
    #expect(state.unit(withID: "rome-legion-1")?.health == attackerHealth - preview.retaliation)
}

@Test func recruitmentSpendsResourcesAndCreatesUnit() throws {
    var state = GameState.newCampaign()
    state.units.removeAll { $0.position == Position(x: 3, y: 3) }
    let before = state.resources[.rome]?.gold ?? 0

    _ = try state.recruit(.legion, at: "rome")

    #expect(state.units.contains { $0.faction == .rome && $0.kind == .legion && $0.position == Position(x: 3, y: 3) })
    #expect((state.resources[.rome]?.gold ?? 0) == before - UnitKind.legion.recruitmentCost.gold)
}

@Test func recruitmentUsesAdjacentTileWhenCityIsOccupied() throws {
    var state = GameState.newCampaign()
    let before = state.units.count

    _ = try state.recruit(.archer, at: "rome")

    let created = state.units.last
    #expect(state.units.count == before + 1)
    #expect(created?.kind == .archer)
    #expect(created?.position != Position(x: 3, y: 3))
    #expect(created?.position.hexDistance(to: Position(x: 3, y: 3)) == 1)
}

@Test func technologyCannotBeResearchedTwice() throws {
    var state = GameState.newCampaign()

    _ = try state.research(.marchingDrill)

    #expect(throws: GameRuleError.technologyAlreadyResearched) {
        try state.research(.marchingDrill)
    }
}

@Test func cityDevelopmentIncreasesIncomeAndFortification() throws {
    var state = GameState.newCampaign()
    let beforeCity = state.city(withID: "rome")
    let beforeGold = state.resources[.rome]?.gold ?? 0

    _ = try state.developCity(id: "rome")

    let afterCity = state.city(withID: "rome")
    #expect((afterCity?.production.gold ?? 0) == (beforeCity?.production.gold ?? 0) + 10)
    #expect((afterCity?.fortification ?? 0) == (beforeCity?.fortification ?? 0) + 3)
    #expect((state.resources[.rome]?.gold ?? 0) == beforeGold - 70)
}

@Test func trainingUnitCostsPrestigeAndAddsExperience() throws {
    var state = GameState.newCampaign()
    let beforePrestige = state.resources[.rome]?.prestige ?? 0
    let beforeExperience = state.unit(withID: "rome-archer-1")?.experience ?? 0

    _ = try state.trainUnit(id: "rome-archer-1")

    #expect((state.unit(withID: "rome-archer-1")?.experience ?? 0) == beforeExperience + 1)
    #expect((state.resources[.rome]?.prestige ?? 0) == beforePrestige - 1)
}

@Test func appointingGeneralAssignsNameAndExperience() throws {
    var state = GameState.newCampaign()

    _ = try state.appointGeneral(unitID: "rome-archer-1")

    #expect(state.unit(withID: "rome-archer-1")?.generalName != nil)
    #expect(state.unit(withID: "rome-archer-1")?.resolvedGeneralTrait != nil)
    #expect((state.unit(withID: "rome-archer-1")?.experience ?? 0) == 2)
}

@Test func generalTraitChangesEffectiveStats() {
    let state = GameState.newCampaign()
    let cavalry = state.unit(withID: "rome-cavalry-1")!
    let gaul = state.unit(withID: "gaul-legion-1")!

    #expect(state.effectiveMovement(for: cavalry) == UnitKind.cavalry.movement + 1)
    #expect(state.effectiveDefense(for: gaul) == UnitKind.legion.defense + 6)
}

@Test func tacticalOrdersChangeMovementAndCombatPreview() throws {
    var state = GameState.newCampaign()
    state.units.append(ArmyUnit(id: "near-carthage", kind: .archer, faction: .carthage, position: Position(x: 4, y: 3), health: 60))
    let balancedMovement = state.effectiveMovement(for: state.unit(withID: "rome-legion-1")!)
    let balancedPreview = try state.attackPreview(attackerID: "rome-legion-1", defenderID: "near-carthage")

    _ = try state.setTacticalOrder(unitID: "rome-legion-1", order: .assault)
    let assaultPreview = try state.attackPreview(attackerID: "rome-legion-1", defenderID: "near-carthage")

    _ = try state.setTacticalOrder(unitID: "rome-legion-1", order: .forcedMarch)

    #expect(assaultPreview.damage == balancedPreview.damage + TacticalOrder.assault.attackBonus)
    #expect(state.effectiveMovement(for: state.unit(withID: "rome-legion-1")!) == balancedMovement + TacticalOrder.forcedMarch.movementBonus)
}

@Test func tacticalOrderMustBeSetBeforeUnitActs() throws {
    var state = GameState.newCampaign()

    _ = try state.moveUnit(id: "rome-legion-1", to: Position(x: 5, y: 2))

    #expect(throws: GameRuleError.unitAlreadyMoved) {
        try state.setTacticalOrder(unitID: "rome-legion-1", order: .defensive)
    }
}

@Test func tacticalOrdersResetWhenFactionStartsTurn() throws {
    var state = GameState.newCampaign()
    let carthageIndex = state.units.firstIndex { $0.id == "carthage-legion-1" }
    #expect(carthageIndex != nil)
    state.units[carthageIndex!].tacticalOrder = .defensive

    _ = state.endTurn()

    #expect(state.activeFaction == .carthage)
    #expect(state.unit(withID: "carthage-legion-1")?.resolvedTacticalOrder == .balanced)
}

@Test func combatPreviewIncludesSupportFlankingCommandAndDefenderSupport() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-attacker", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), experience: 1, generalName: "凯撒", generalTrait: .eagleStandard),
        ArmyUnit(id: "rome-support", kind: .legion, faction: .rome, position: Position(x: 2, y: 3)),
        ArmyUnit(id: "rome-flanker", kind: .cavalry, faction: .rome, position: Position(x: 4, y: 3)),
        ArmyUnit(id: "rome-second-flanker", kind: .archer, faction: .rome, position: Position(x: 3, y: 4)),
        ArmyUnit(id: "carthage-defender", kind: .archer, faction: .carthage, position: Position(x: 4, y: 4), health: 60),
        ArmyUnit(id: "carthage-support", kind: .legion, faction: .carthage, position: Position(x: 5, y: 4))
    ]

    let preview = try state.attackPreview(attackerID: "rome-attacker", defenderID: "carthage-defender")

    #expect(preview.supportBonus == 4)
    #expect(preview.flankingBonus == 6)
    #expect(preview.commandBonus == 2)
    #expect(preview.defenderSupportBonus == 3)
    #expect(preview.totalAttackModifier == 12)

    _ = try state.attack(attackerID: "rome-attacker", defenderID: "carthage-defender")

    #expect(state.unit(withID: "carthage-defender")?.health == preview.defenderRemainingHealth)
}

@Test func eagleStandardSkillRestoresAlliesAndConsumesAction() throws {
    var state = GameState.newCampaign()
    let damagedArcherIndex = state.units.firstIndex { $0.id == "rome-archer-1" }
    #expect(damagedArcherIndex != nil)
    state.units[damagedArcherIndex!].position = Position(x: 4, y: 3)
    state.units[damagedArcherIndex!].health = 30

    let beforeExperience = state.unit(withID: "rome-legion-1")?.experience ?? 0
    let messages = try state.useGeneralSkill(unitID: "rome-legion-1")

    #expect((state.unit(withID: "rome-archer-1")?.health ?? 0) == 42)
    #expect((state.unit(withID: "rome-legion-1")?.experience ?? 0) == beforeExperience + 1)
    #expect(state.unit(withID: "rome-legion-1")?.hasActed == true)
    #expect(messages.contains { $0.contains("鹰旗鼓舞") })
}

@Test func siegeEngineerSkillReducesEnemyCityFortification() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "test-siege", kind: .legion, faction: .rome, position: Position(x: 7, y: 2), generalName: "苏拉", generalTrait: .siegeEngineer)
    ]
    let before = state.city(withID: "alesia")?.fortification ?? 0

    _ = try state.useGeneralSkill(unitID: "test-siege")

    #expect((state.city(withID: "alesia")?.fortification ?? 0) == before - 4)
    #expect(state.unit(withID: "test-siege")?.hasActed == true)
}

@Test func envoyCanCreateTreatyAndBlockAttack() throws {
    var state = GameState.newCampaign()
    state.units.append(ArmyUnit(id: "near-carthage", kind: .archer, faction: .carthage, position: Position(x: 4, y: 3)))

    _ = try state.sendEnvoy(to: .carthage)

    #expect(state.diplomaticStatus(between: .rome, and: .carthage) == .truce)
    #expect(throws: GameRuleError.protectedByTreaty) {
        try state.attack(attackerID: "rome-legion-1", defenderID: "near-carthage")
    }
}

@Test func endTurnCollectsIncomeAndAdvancesFaction() {
    var state = GameState.newCampaign()
    let before = state.resources[.rome]?.gold ?? 0

    _ = state.endTurn()

    #expect(state.activeFaction == .carthage)
    #expect((state.resources[.rome]?.gold ?? 0) == before + state.income(for: .rome).gold)
}

@Test func skippingUnitConsumesMovementAndAction() throws {
    var state = GameState.newCampaign()

    _ = try state.skipUnit(id: "rome-legion-1")

    #expect(state.unit(withID: "rome-legion-1")?.hasMoved == true)
    #expect(state.unit(withID: "rome-legion-1")?.hasActed == true)
    #expect(!state.reachablePositions(for: "rome-legion-1").contains(Position(x: 4, y: 3)))
    #expect(state.attackTargets(for: "rome-legion-1").isEmpty)
}

@Test func aiMovesIntoRangeThenAttacks() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-target", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "carthage-hunter", kind: .cavalry, faction: .carthage, position: Position(x: 7, y: 2))
    ]
    state.activeFaction = .carthage

    _ = state.performSimpleAI(for: .carthage)

    let hunter = state.unit(withID: "carthage-hunter")
    #expect(hunter?.hasActed == true)
    #expect(hunter?.position.hexDistance(to: Position(x: 3, y: 3)) == 1)
    #expect((state.unit(withID: "rome-target")?.health ?? UnitKind.legion.maxHealth) < UnitKind.legion.maxHealth)
}

@Test func aiIntentForecastPredictsDirectAttackWithoutMutatingState() {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-target", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "carthage-hunter", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3), hasMoved: true, hasActed: true)
    ]
    state.activeFaction = .rome

    let intents = state.aiIntents(for: .carthage, limit: 1)
    let intent = intents.first

    #expect(intent?.kind == .attack)
    #expect(intent?.unitID == "carthage-hunter")
    #expect(intent?.targetUnitID == "rome-target")
    #expect((intent?.projectedDamage ?? 0) > 0)
    #expect(intent?.tacticalOrder == .assault)
    #expect(state.activeFaction == .rome)
    #expect(state.unit(withID: "carthage-hunter")?.hasActed == true)
}

@Test func aiIntentForecastPredictsCityCapture() {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "carthage-capturer", kind: .cavalry, faction: .carthage, position: Position(x: 6, y: 2))
    ]
    for index in state.cities.indices where state.cities[index].id != "massilia" {
        state.cities[index].owner = .carthage
    }

    let intents = state.aiIntents(for: .carthage, limit: 1)
    let intent = intents.first

    #expect(intent?.kind == .captureCity)
    #expect(intent?.unitID == "carthage-capturer")
    #expect(intent?.targetCityID == "massilia")
    #expect(intent?.destination == Position(x: 5, y: 2))
}

@Test func aiRecruitsWhenBelowTargetForce() {
    var state = GameState.newCampaign()
    state.activeFaction = .gaul
    state.units.removeAll { $0.faction == .gaul }
    let before = state.units.count

    _ = state.performSimpleAI(for: .gaul)

    #expect(state.units.count > before)
    #expect(state.units.contains { $0.faction == .gaul })
}
