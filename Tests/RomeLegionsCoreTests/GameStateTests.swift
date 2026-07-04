import Foundation
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
        ArmyUnit(id: "carthage-hunter", kind: .cavalry, faction: .carthage, position: Position(x: 7, y: 2)),
        ArmyUnit(id: "carthage-support-north", kind: .legion, faction: .carthage, position: Position(x: 3, y: 1), hasMoved: true, hasActed: true),
        ArmyUnit(id: "carthage-support-east", kind: .legion, faction: .carthage, position: Position(x: 5, y: 4), hasMoved: true, hasActed: true),
        ArmyUnit(id: "carthage-support-south", kind: .legion, faction: .carthage, position: Position(x: 2, y: 4), hasMoved: true, hasActed: true)
    ]
    state.activeFaction = .carthage

    _ = state.performSimpleAI(for: .carthage)

    let hunter = state.unit(withID: "carthage-hunter")
    #expect(hunter?.hasActed == true)
    #expect(hunter?.position.hexDistance(to: Position(x: 3, y: 3)) == 1)
    #expect((state.unit(withID: "rome-target")?.health ?? UnitKind.legion.maxHealth) < UnitKind.legion.maxHealth)
}

@Test func aiIntentForecastPredictsDirectAttackWithoutMutatingState() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-target", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "carthage-hunter", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3), hasMoved: true, hasActed: true)
    ]
    state.activeFaction = .rome
    let before = state

    let intents = state.aiIntents(for: .carthage, limit: 1)
    let intent = intents.first

    #expect(intent?.kind == .attack)
    #expect(intent?.unitID == "carthage-hunter")
    #expect(intent?.targetUnitID == "rome-target")
    #expect((intent?.projectedDamage ?? 0) > 0)
    #expect(intent?.tacticalOrder == .assault)

    if let intent {
        var previewState = state
        previewState.activeFaction = .carthage
        let hunterIndex = previewState.units.firstIndex { $0.id == "carthage-hunter" }
        #expect(hunterIndex != nil)
        if let hunterIndex {
            previewState.units[hunterIndex].hasMoved = false
            previewState.units[hunterIndex].hasActed = false
            previewState.units[hunterIndex].tacticalOrder = intent.tacticalOrder == .balanced ? nil : intent.tacticalOrder
        }
        let preview = try previewState.attackPreview(attackerID: "carthage-hunter", defenderID: "rome-target")
        #expect(intent.projectedDamage == preview.damage)
    }

    #expect(state == before)
}

@Test func aiIntentAdvanceAttackDamageMatchesPreviewAndResolution() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-target", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "carthage-hunter", kind: .cavalry, faction: .carthage, position: Position(x: 7, y: 2)),
        ArmyUnit(id: "carthage-support-north", kind: .legion, faction: .carthage, position: Position(x: 3, y: 1), hasMoved: true, hasActed: true),
        ArmyUnit(id: "carthage-support-east", kind: .legion, faction: .carthage, position: Position(x: 5, y: 4), hasMoved: true, hasActed: true),
        ArmyUnit(id: "carthage-support-south", kind: .legion, faction: .carthage, position: Position(x: 2, y: 4), hasMoved: true, hasActed: true)
    ]
    for index in state.cities.indices where state.cities[index].owner != .rome {
        state.cities[index].owner = .carthage
    }
    if let romeIndex = state.cities.firstIndex(where: { $0.id == "rome" }) {
        state.cities[romeIndex].position = Position(x: 0, y: 0)
    }
    state.resources[.carthage] = .zero
    state.activeFaction = .rome
    let beforeIntentForecast = state

    let intent = state.aiIntents(for: .carthage, limit: 4).first { $0.unitID == "carthage-hunter" }

    #expect(intent?.kind == .advanceAttack)
    #expect(intent?.unitID == "carthage-hunter")
    #expect(intent?.targetUnitID == "rome-target")
    #expect(intent?.destination != nil)
    #expect((intent?.projectedDamage ?? 0) > 0)

    guard let intent, let destination = intent.destination else {
        return
    }

    var previewState = state
    previewState.activeFaction = .carthage
    let hunterIndex = previewState.units.firstIndex { $0.id == "carthage-hunter" }
    #expect(hunterIndex != nil)
    if let hunterIndex {
        previewState.units[hunterIndex].position = destination
        previewState.units[hunterIndex].hasMoved = true
        previewState.units[hunterIndex].hasActed = false
        previewState.units[hunterIndex].tacticalOrder = intent.tacticalOrder == .balanced ? nil : intent.tacticalOrder
    }
    let preview = try previewState.attackPreview(attackerID: "carthage-hunter", defenderID: "rome-target")

    #expect(preview.supportBonus > 0)
    #expect(intent.projectedDamage == preview.damage)
    #expect(state == beforeIntentForecast)

    var aiState = state
    aiState.activeFaction = .carthage
    let beforeHealth = aiState.unit(withID: "rome-target")?.health ?? 0

    _ = aiState.performSimpleAI(for: .carthage)

    #expect(aiState.unit(withID: "carthage-hunter")?.position == destination)
    #expect(aiState.unit(withID: "carthage-hunter")?.hasActed == true)
    #expect(aiState.unit(withID: "rome-target")?.health == beforeHealth - preview.damage)
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

@Test func missionRequirementCompletesAndPaysRewardOnce() throws {
    var state = GameState.newCampaign()
    let beforeGold = state.resources[.rome]?.gold ?? 0

    _ = try state.recruit(.archer, at: "rome")
    let completionMessages = try state.recruit(.archer, at: "rome")

    #expect(state.missions.first { $0.id == "raise-legions" }?.isCompleted == true)
    #expect(completionMessages.contains { $0.contains("任务完成：扩充军团") })
    #expect((state.resources[.rome]?.gold ?? 0) == beforeGold - UnitKind.archer.recruitmentCost.gold * 2 + 40)

    let beforeExtraRecruitmentGold = state.resources[.rome]?.gold ?? 0
    let repeatMessages = try state.recruit(.archer, at: "rome")

    #expect(!repeatMessages.contains { $0.contains("任务完成：扩充军团") })
    #expect((state.resources[.rome]?.gold ?? 0) == beforeExtraRecruitmentGold - UnitKind.archer.recruitmentCost.gold)
}

@Test func completingAllCampaignObjectivesCreatesRomanVictory() throws {
    var state = GameState.newCampaign()
    for index in state.cities.indices where ["syracuse", "carthage"].contains(state.cities[index].id) {
        state.cities[index].owner = .rome
    }
    state.units.append(ArmyUnit(id: "rome-extra-legion", kind: .legion, faction: .rome, position: Position(x: 1, y: 1)))

    let messages = try state.recruit(.archer, at: "rome")

    #expect(state.campaignStatus.kind == .romanVictory)
    #expect(state.campaignStatus.isGameOver)
    #expect(state.missions.allSatisfy { $0.isCompleted })
    #expect(messages.contains { $0.contains("任务完成：夺取西西里") })
    #expect(messages.contains { $0.contains("任务完成：压制迦太基") })
    #expect(messages.contains { $0.contains("战役胜利") })
}

@Test func campaignVictoryRequiresCurrentRequirements() {
    var state = GameState.newCampaign()
    for index in state.cities.indices where ["syracuse", "carthage"].contains(state.cities[index].id) {
        state.cities[index].owner = .rome
    }
    state.units.append(ArmyUnit(id: "rome-extra-legion", kind: .legion, faction: .rome, position: Position(x: 1, y: 1)))
    state.units.append(ArmyUnit(id: "rome-extra-archer", kind: .archer, faction: .rome, position: Position(x: 1, y: 2)))
    for index in state.missions.indices {
        state.missions[index].isCompleted = true
    }
    if let syracuseIndex = state.cities.firstIndex(where: { $0.id == "syracuse" }) {
        state.cities[syracuseIndex].owner = .carthage
    }

    #expect(state.campaignStatus.kind == .ongoing)
    #expect(state.campaignStatus.primaryMissionID == "secure-sicily")
}

@Test func losingAllRomanCitiesCreatesRomanDefeat() {
    var state = GameState.newCampaign()
    for index in state.cities.indices where state.cities[index].owner == .rome {
        state.cities[index].owner = .carthage
    }

    #expect(state.campaignStatus.kind == .romanDefeat)
    #expect(state.campaignStatus.isGameOver)
}

@Test func campaignEndBlocksMutatingPlayerCommands() throws {
    var state = GameState.newCampaign()
    for index in state.cities.indices where ["syracuse", "carthage"].contains(state.cities[index].id) {
        state.cities[index].owner = .rome
    }
    state.units.append(ArmyUnit(id: "rome-extra-legion", kind: .legion, faction: .rome, position: Position(x: 1, y: 1)))
    _ = try state.recruit(.archer, at: "rome")

    let before = state

    #expect(throws: GameRuleError.campaignAlreadyEnded) {
        try state.moveUnit(id: "rome-legion-1", to: Position(x: 5, y: 2))
    }
    #expect(throws: GameRuleError.campaignAlreadyEnded) {
        try state.recruit(.archer, at: "rome")
    }

    let endTurnMessages = state.endTurn()
    #expect(endTurnMessages == [GameRuleError.campaignAlreadyEnded.displayMessage])
    #expect(state == before)
}

@Test func aiDoesNotAdvanceAfterCampaignEnds() {
    var state = GameState.newCampaign()
    state.activeFaction = .carthage
    for index in state.cities.indices where state.cities[index].owner == .rome {
        state.cities[index].owner = .carthage
    }
    let before = state

    let messages = state.performSimpleAI(for: .carthage)

    #expect(messages.isEmpty)
    #expect(state == before)
}

@Test func campaignStateCodableKeepsMissionRequirementsAndReadsLegacyMissions() throws {
    let state = GameState.newCampaign()
    let data = try JSONEncoder().encode(state)
    let decoded = try JSONDecoder().decode(GameState.self, from: data)

    #expect(decoded.missions.first { $0.id == "secure-sicily" }?.requirement == .controlCity(cityID: "syracuse", faction: .rome))
    #expect(decoded.campaignStatus.kind == state.campaignStatus.kind)

    let legacyMissionJSON = """
    {
      "id": "secure-sicily",
      "title": "夺取西西里",
      "objective": "占领叙拉古",
      "reward": {
        "gold": 80,
        "grain": 30,
        "iron": 25,
        "science": 10,
        "prestige": 2
      },
      "isCompleted": false
    }
    """
    let legacyMission = try JSONDecoder().decode(Mission.self, from: Data(legacyMissionJSON.utf8))

    #expect(legacyMission.requirement == nil)
}
