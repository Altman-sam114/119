import Foundation
import Testing
@testable import RomeLegionsCore

private func riskTestPriority(_ risk: TacticalRecommendationRisk) -> Int {
    switch risk {
    case .low: return 1
    case .guarded: return 2
    case .high: return 3
    case .critical: return 4
    }
}

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
    let beforePreview = state

    let preview = try state.recruitmentPreview(.legion, at: "rome")

    #expect(state == beforePreview)
    #expect(preview.canRecruit)
    #expect(preview.deploymentPosition == Position(x: 3, y: 3))
    #expect(preview.cost == UnitKind.legion.recruitmentCost)

    _ = try state.recruit(.legion, at: "rome")

    #expect(state.units.contains { $0.faction == .rome && $0.kind == .legion && $0.position == Position(x: 3, y: 3) })
    #expect((state.resources[.rome]?.gold ?? 0) == before - UnitKind.legion.recruitmentCost.gold)
}

@Test func recruitmentUsesAdjacentTileWhenCityIsOccupied() throws {
    var state = GameState.newCampaign()
    let before = state.units.count
    let preview = try state.recruitmentPreview(.archer, at: "rome")

    #expect(preview.canRecruit)
    #expect(preview.deploymentPosition != Position(x: 3, y: 3))
    #expect(preview.deploymentPosition?.hexDistance(to: Position(x: 3, y: 3)) == 1)

    _ = try state.recruit(.archer, at: "rome")

    let created = state.units.last
    #expect(state.units.count == before + 1)
    #expect(created?.kind == .archer)
    #expect(created?.position != Position(x: 3, y: 3))
    #expect(created?.position.hexDistance(to: Position(x: 3, y: 3)) == 1)
}

@Test func recruitmentPreviewReportsResourceAndHarborBlockersWithoutMutation() throws {
    var resourceState = GameState.newCampaign()
    resourceState.resources[.rome] = .zero
    let resourceBefore = resourceState

    let blockedLegion = try resourceState.recruitmentPreview(.legion, at: "rome")

    #expect(resourceState == resourceBefore)
    #expect(!blockedLegion.canRecruit)
    #expect(blockedLegion.blockingError == .insufficientResources)
    #expect(blockedLegion.blockedReason == GameRuleError.insufficientResources.displayMessage)

    let harborState = GameState.newCampaign()
    let harborBefore = harborState
    let blockedNavy = try harborState.recruitmentPreview(.navy, at: "rome")

    #expect(harborState == harborBefore)
    #expect(!blockedNavy.canRecruit)
    #expect(blockedNavy.blockedReason == "缺少相邻空港口")
}

@Test func navyRecruitmentPreviewUsesAdjacentHarbor() throws {
    var state = GameState.newCampaign()

    let preview = try state.recruitmentPreview(.navy, at: "neapolis")

    #expect(preview.canRecruit)
    #expect(preview.deploymentPosition == Position(x: 4, y: 5))

    _ = try state.recruit(.navy, at: "neapolis")

    #expect(state.units.contains { $0.faction == .rome && $0.kind == .navy && $0.position == preview.deploymentPosition })
}

@Test func navyRecruitmentPreviewReportsOccupiedHarbor() throws {
    var state = GameState.newCampaign()
    state.units.append(ArmyUnit(id: "occupied-harbor-west", kind: .navy, faction: .rome, position: Position(x: 3, y: 5)))
    state.units.append(ArmyUnit(id: "occupied-harbor-east", kind: .navy, faction: .rome, position: Position(x: 4, y: 5)))
    let before = state

    let preview = try state.recruitmentPreview(.navy, at: "neapolis")

    #expect(state == before)
    #expect(!preview.canRecruit)
    #expect(preview.blockingError == .occupiedTile)
    #expect(preview.blockedReason == "港口已被占用")
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
    let beforePreview = state

    let preview = try state.cityDevelopmentPreview(id: "rome")

    #expect(state == beforePreview)
    #expect(preview.canDevelop)
    #expect(preview.cost.gold == 70)
    #expect(preview.productionIncrease.gold == 10)
    #expect(preview.fortificationIncrease == 3)

    _ = try state.developCity(id: "rome")

    let afterCity = state.city(withID: "rome")
    #expect((afterCity?.production.gold ?? 0) == (beforeCity?.production.gold ?? 0) + preview.productionIncrease.gold)
    #expect((afterCity?.fortification ?? 0) == (beforeCity?.fortification ?? 0) + preview.fortificationIncrease)
    #expect((state.resources[.rome]?.gold ?? 0) == beforeGold - preview.cost.gold)
}

@Test func cityDevelopmentPreviewReportsBlockersWithoutMutation() throws {
    var state = GameState.newCampaign()
    state.resources[.rome] = .zero
    let before = state

    let preview = try state.cityDevelopmentPreview(id: "rome")

    #expect(state == before)
    #expect(!preview.canDevelop)
    #expect(preview.blockingError == .insufficientResources)
    #expect(preview.blockedReason == GameRuleError.insufficientResources.displayMessage)
}

@Test func trainingUnitCostsPrestigeAndAddsExperience() throws {
    var state = GameState.newCampaign()
    let archerIndex = try #require(state.units.firstIndex { $0.id == "rome-archer-1" })
    state.units[archerIndex].health = 52
    let before = state
    let beforeResources = state.resources[.rome]!

    let preview = try state.trainingPreview(unitID: "rome-archer-1")

    #expect(state == before)
    #expect(preview.canTrain)
    #expect(preview.currentExperience == 0)
    #expect(preview.projectedExperience == 1)
    #expect(preview.projectedRecoveredHealth == 18)
    #expect(preview.projectedHealth == 70)
    #expect(!preview.summary.isEmpty)
    #expect(!preview.detail.isEmpty)

    _ = try state.trainUnit(id: "rome-archer-1")

    let trainedUnit = state.unit(withID: "rome-archer-1")
    #expect(trainedUnit?.experience == preview.projectedExperience)
    #expect(trainedUnit?.health == preview.projectedHealth)
    #expect(trainedUnit?.hasActed == true)
    #expect(state.resources[.rome]?.gold == beforeResources.gold - preview.cost.gold)
    #expect(state.resources[.rome]?.grain == beforeResources.grain - preview.cost.grain)
    #expect(state.resources[.rome]?.iron == beforeResources.iron - preview.cost.iron)
    #expect(state.resources[.rome]?.prestige == beforeResources.prestige - preview.cost.prestige)

    var poorState = GameState.newCampaign()
    poorState.resources[.rome] = .zero
    let blockedPreview = try poorState.trainingPreview(unitID: "rome-archer-1")
    #expect(!blockedPreview.canTrain)
    #expect(blockedPreview.blockingError == .insufficientResources)
}

@Test func appointingGeneralAssignsNameAndExperience() throws {
    var state = GameState.newCampaign()
    let before = state
    let beforeResources = state.resources[.rome]!

    let preview = try state.generalAppointmentPreview(unitID: "rome-archer-1")

    #expect(state == before)
    #expect(preview.canAppoint)
    #expect(preview.candidateName == "庞培")
    #expect(preview.candidateTrait == .eagleStandard)
    #expect(preview.projectedExperience == 2)
    #expect(!preview.summary.isEmpty)
    #expect(!preview.detail.isEmpty)

    _ = try state.appointGeneral(unitID: "rome-archer-1")

    let appointedUnit = state.unit(withID: "rome-archer-1")
    #expect(appointedUnit?.generalName == preview.candidateName)
    #expect(appointedUnit?.resolvedGeneralTrait == preview.candidateTrait)
    #expect(appointedUnit?.experience == preview.projectedExperience)
    #expect(state.resources[.rome]?.gold == beforeResources.gold - preview.cost.gold)
    #expect(state.resources[.rome]?.science == beforeResources.science - preview.cost.science)
    #expect(state.resources[.rome]?.prestige == beforeResources.prestige - preview.cost.prestige)

    let alreadyAssignedPreview = try state.generalAppointmentPreview(unitID: "rome-archer-1")
    #expect(!alreadyAssignedPreview.canAppoint)
    #expect(alreadyAssignedPreview.blockingError == .generalAlreadyAssigned)

    var poorState = GameState.newCampaign()
    poorState.resources[.rome] = .zero
    let blockedPreview = try poorState.generalAppointmentPreview(unitID: "rome-archer-1")
    #expect(!blockedPreview.canAppoint)
    #expect(blockedPreview.blockingError == .insufficientResources)
}

@Test func unitDevelopmentRecommendationsReusePreviewsWithoutMutation() throws {
    var state = GameState.newCampaign()
    let archerIndex = try #require(state.units.firstIndex { $0.id == "rome-archer-1" })
    state.units[archerIndex].health = 44
    let before = state

    let reports = state.unitDevelopmentRecommendationReports(for: .rome, limit: 10)

    #expect(state == before)
    #expect(!reports.isEmpty)

    let trainingReport = try #require(reports.first { $0.unitID == "rome-archer-1" && $0.kind == .training })
    let trainingPreview = try state.trainingPreview(unitID: "rome-archer-1")
    #expect(trainingReport.cost == trainingPreview.cost)
    #expect(trainingReport.projectedRankName == trainingPreview.projectedRankName)
    #expect(trainingReport.projectedDamageBonus == trainingPreview.projectedDamageBonus)
    #expect(trainingReport.projectedHealth == trainingPreview.projectedHealth)
    #expect(!trainingReport.reasons.isEmpty)
    #expect(!trainingReport.impact.isEmpty)

    let appointmentReport = try #require(reports.first { $0.unitID == "rome-archer-1" && $0.kind == .appointment })
    let appointmentPreview = try state.generalAppointmentPreview(unitID: "rome-archer-1")
    #expect(appointmentReport.cost == appointmentPreview.cost)
    #expect(appointmentReport.candidateName == appointmentPreview.candidateName)
    #expect(appointmentReport.candidateTrait == appointmentPreview.candidateTrait)
    #expect(appointmentReport.projectedRankName == appointmentPreview.projectedRankName)
    #expect(!appointmentReport.detail.isEmpty)

    let selectedReport = try state.unitDevelopmentRecommendationReport(unitID: "rome-archer-1")
    #expect(selectedReport.unitID == "rome-archer-1")
    #expect(!selectedReport.summary.isEmpty)

    let assignedReport = try #require(reports.first { $0.unitID == "rome-legion-1" && $0.kind == .appointment })
    #expect(!assignedReport.canExecute)
    #expect(assignedReport.blockedReason == GameRuleError.generalAlreadyAssigned.displayMessage)

    var poorState = GameState.newCampaign()
    poorState.resources[.rome] = .zero
    let poorReports = poorState.unitDevelopmentRecommendationReports(for: .rome, limit: 10)
    let blockedTraining = try #require(poorReports.first { $0.kind == .training })
    #expect(!blockedTraining.canExecute)
    #expect(blockedTraining.blockedReason == GameRuleError.insufficientResources.displayMessage)
    #expect(!blockedTraining.summary.isEmpty)
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

    let beforePreview = state
    let preview = try state.generalSkillPreview(unitID: "rome-legion-1")
    #expect(state == beforePreview)
    #expect(preview.trait == .eagleStandard)
    #expect(preview.isExecutable)
    #expect(preview.rangePositions.contains(Position(x: 4, y: 3)))
    #expect(preview.affectedUnitIDs == ["rome-archer-1"])
    #expect(preview.projectedRecoveredHealth == 12)

    let beforeExperience = state.unit(withID: "rome-legion-1")?.experience ?? 0
    let messages = try state.useGeneralSkill(unitID: "rome-legion-1")

    #expect((state.unit(withID: "rome-archer-1")?.health ?? 0) == 30 + preview.projectedRecoveredHealth)
    #expect((state.unit(withID: "rome-legion-1")?.experience ?? 0) == beforeExperience + 1)
    #expect(state.unit(withID: "rome-legion-1")?.hasActed == true)
    #expect(messages.contains { $0.contains("鹰旗鼓舞") })
}

@Test func quartermasterAndShieldWallSkillPreviewsMatchRecovery() throws {
    var quartermasterState = GameState.newCampaign()
    quartermasterState.units = [
        ArmyUnit(id: "quartermaster", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), generalName: "阿格里帕", generalTrait: .quartermaster),
        ArmyUnit(id: "near-ally", kind: .cavalry, faction: .rome, position: Position(x: 5, y: 3), health: 40),
        ArmyUnit(id: "far-ally", kind: .archer, faction: .rome, position: Position(x: 7, y: 3), health: 20)
    ]

    let quartermasterPreview = try quartermasterState.generalSkillPreview(unitID: "quartermaster")
    #expect(quartermasterPreview.trait == .quartermaster)
    #expect(quartermasterPreview.affectedUnitIDs == ["near-ally"])
    #expect(quartermasterPreview.projectedRecoveredHealth == 22)

    _ = try quartermasterState.useGeneralSkill(unitID: "quartermaster")
    #expect(quartermasterState.unit(withID: "near-ally")?.health == 62)
    #expect(quartermasterState.unit(withID: "far-ally")?.health == 20)

    var shieldWallState = GameState.newCampaign()
    shieldWallState.units = [
        ArmyUnit(id: "shield", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), generalName: "马略", generalTrait: .shieldWall),
        ArmyUnit(id: "adjacent-ally", kind: .archer, faction: .rome, position: Position(x: 4, y: 3), health: 36)
    ]

    let shieldPreview = try shieldWallState.generalSkillPreview(unitID: "shield")
    #expect(shieldPreview.trait == .shieldWall)
    #expect(shieldPreview.affectedUnitIDs == ["adjacent-ally"])
    #expect(shieldPreview.projectedRecoveredHealth == 14)

    _ = try shieldWallState.useGeneralSkill(unitID: "shield")
    #expect(shieldWallState.unit(withID: "adjacent-ally")?.health == 50)
}

@Test func siegeEngineerSkillReducesEnemyCityFortification() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "test-siege", kind: .legion, faction: .rome, position: Position(x: 7, y: 2), generalName: "苏拉", generalTrait: .siegeEngineer)
    ]
    let before = state.city(withID: "alesia")?.fortification ?? 0
    let beforePreview = state

    let preview = try state.generalSkillPreview(unitID: "test-siege")

    #expect(state == beforePreview)
    #expect(preview.trait == .siegeEngineer)
    #expect(preview.isExecutable)
    #expect(preview.affectedCityIDs == ["alesia"])
    #expect(preview.projectedFortificationReduction == 4)

    _ = try state.useGeneralSkill(unitID: "test-siege")

    #expect((state.city(withID: "alesia")?.fortification ?? 0) == before - preview.projectedFortificationReduction)
    #expect(state.unit(withID: "test-siege")?.hasActed == true)
}

@Test func siegeEngineerPreviewReportsNoTargetWithoutChangingSkillError() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "test-siege", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), generalName: "苏拉", generalTrait: .siegeEngineer)
    ]

    for index in state.cities.indices where state.cities[index].owner != .rome {
        state.cities[index].fortification = 1
    }

    let preview = try state.generalSkillPreview(unitID: "test-siege")

    #expect(!preview.isExecutable)
    #expect(preview.blockedReason == "范围内没有可削弱敌城")
    #expect(preview.affectedCityIDs.isEmpty)
    #expect(preview.projectedFortificationReduction == 0)
    #expect(throws: GameRuleError.invalidTarget) {
        try state.useGeneralSkill(unitID: "test-siege")
    }
}

@Test func generalSkillStartsCooldownAndCoreBlocksReuse() throws {
    var state = GameState.newCampaign()
    let damagedArcherIndex = state.units.firstIndex { $0.id == "rome-archer-1" }
    #expect(damagedArcherIndex != nil)
    state.units[damagedArcherIndex!].position = Position(x: 4, y: 3)
    state.units[damagedArcherIndex!].health = 30

    _ = try state.useGeneralSkill(unitID: "rome-legion-1")

    #expect(state.unit(withID: "rome-legion-1")?.generalSkillCooldownRemaining == GeneralTrait.eagleStandard.skillCooldownTurns)

    let commanderIndex = state.units.firstIndex { $0.id == "rome-legion-1" }
    #expect(commanderIndex != nil)
    state.units[commanderIndex!].hasActed = false

    let cooldownPreview = try state.generalSkillPreview(unitID: "rome-legion-1")
    #expect(!cooldownPreview.isExecutable)
    #expect(cooldownPreview.cooldownRemaining == 2)
    #expect(cooldownPreview.blockedReason == "技能冷却中（2 回合）")
    #expect(throws: GameRuleError.generalSkillOnCooldown) {
        try state.useGeneralSkill(unitID: "rome-legion-1")
    }
}

@Test func generalSkillCooldownTicksOnlyWhenOwnerStartsTurn() throws {
    var state = GameState.newCampaign()
    _ = try state.useGeneralSkill(unitID: "rome-legion-1")

    _ = state.endTurn()
    #expect(state.activeFaction == .carthage)
    #expect(state.unit(withID: "rome-legion-1")?.generalSkillCooldownRemaining == 2)

    _ = state.endTurn()
    _ = state.endTurn()
    _ = state.endTurn()
    #expect(state.activeFaction == .rome)
    #expect(state.unit(withID: "rome-legion-1")?.generalSkillCooldownRemaining == 1)

    _ = state.endTurn()
    _ = state.endTurn()
    _ = state.endTurn()
    _ = state.endTurn()
    #expect(state.activeFaction == .rome)
    #expect(state.unit(withID: "rome-legion-1")?.generalSkillCooldownRemaining == 0)
}

@Test func generalSkillPreviewIsReadOnlyForCooldownState() throws {
    var state = GameState.newCampaign()
    let commanderIndex = state.units.firstIndex { $0.id == "rome-legion-1" }
    #expect(commanderIndex != nil)
    state.units[commanderIndex!].generalSkillCooldownRemaining = 2
    let before = state

    let preview = try state.generalSkillPreview(unitID: "rome-legion-1")

    #expect(!preview.isExecutable)
    #expect(preview.cooldownText == "冷却 2 回合")
    #expect(state == before)
}

@Test func aiUseSkillIntentTargetsGeneralSkillPreview() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-observer", kind: .legion, faction: .rome, position: Position(x: 0, y: 0)),
        ArmyUnit(id: "carthage-quartermaster", kind: .legion, faction: .carthage, position: Position(x: 6, y: 3), generalName: "阿格里帕", generalTrait: .quartermaster),
        ArmyUnit(id: "carthage-wounded", kind: .cavalry, faction: .carthage, position: Position(x: 5, y: 3), health: 30)
    ]
    state.activeFaction = .rome
    let before = state
    let preview = try state.generalSkillPreview(unitID: "carthage-quartermaster")

    let intent = state.aiIntents(for: .carthage, limit: 2).first { $0.unitID == "carthage-quartermaster" }

    #expect(intent?.kind == .useSkill)
    #expect(intent?.targetUnitID == "carthage-wounded")
    #expect(preview.affectedUnitIDs.contains(intent?.targetUnitID ?? ""))
    #expect(state == before)
}

@Test func aiSkillIntentAndResolutionRespectCooldown() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-observer", kind: .legion, faction: .rome, position: Position(x: 0, y: 0)),
        ArmyUnit(
            id: "carthage-quartermaster",
            kind: .legion,
            faction: .carthage,
            position: Position(x: 6, y: 3),
            generalName: "阿格里帕",
            generalTrait: .quartermaster,
            generalSkillCooldownRemaining: 2
        ),
        ArmyUnit(id: "carthage-wounded", kind: .cavalry, faction: .carthage, position: Position(x: 5, y: 3), health: 30)
    ]
    state.activeFaction = .rome
    let before = state

    let intent = state.aiIntents(for: .carthage, limit: 3).first { $0.unitID == "carthage-quartermaster" }

    #expect(intent?.kind != .useSkill)
    #expect(state == before)

    var aiState = state
    _ = aiState.endTurn()
    #expect(aiState.activeFaction == .carthage)
    #expect(aiState.unit(withID: "carthage-quartermaster")?.generalSkillCooldownRemaining == 1)
    let beforeHealth = aiState.unit(withID: "carthage-wounded")?.health

    _ = aiState.performSimpleAI(for: .carthage)

    #expect(aiState.unit(withID: "carthage-wounded")?.health == beforeHealth)
    #expect((aiState.unit(withID: "carthage-quartermaster")?.generalSkillCooldownRemaining ?? 0) > 0)
}

@Test func warMeritStatusMapsExperienceToRankDamageAndProgress() {
    let state = GameState.newCampaign()
    let unit = ArmyUnit(id: "veteran", kind: .legion, faction: .rome, position: Position(x: 1, y: 1), experience: 5)

    let status = state.warMeritStatus(for: unit)

    #expect(status.experience == 5)
    #expect(status.rankName == "百夫长")
    #expect(status.damageBonus == 15)
    #expect(status.nextRankName == "副将")
    #expect(status.nextRankExperience == 7)
    #expect(status.progress == 1)
    #expect(status.progressTarget == 3)
}

@Test func legionFormationReportSummarizesCommanderReadinessWithoutMutation() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-commander", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), experience: 4, generalName: "凯撒", generalTrait: .eagleStandard),
        ArmyUnit(id: "rome-support", kind: .archer, faction: .rome, position: Position(x: 4, y: 3)),
        ArmyUnit(id: "carthage-near", kind: .cavalry, faction: .carthage, position: Position(x: 3, y: 2))
    ]
    let before = state

    let report = try state.legionFormationReport(unitID: "rome-commander")

    #expect(report.unitID == "rome-commander")
    #expect(report.role == .command)
    #expect(report.readiness == .engaged)
    #expect(report.rankName == "百夫长")
    #expect(report.hasGeneral)
    #expect(report.generalTrait == .eagleStandard)
    #expect(report.adjacentAllyCount == 1)
    #expect(report.nearbyAllyCount == 1)
    #expect(report.nearbyEnemyCount == 1)
    #expect(report.nearbyEnemyFactionCount == 1)
    #expect(report.attack == state.effectiveAttack(for: state.unit(withID: "rome-commander")!))
    #expect(report.defense == state.effectiveDefense(for: state.unit(withID: "rome-commander")!))
    #expect(report.movement == state.effectiveMovement(for: state.unit(withID: "rome-commander")!))
    #expect(report.recommendedOrder == .balanced)
    #expect(report.formationIntegrityScore == 73)
    #expect(report.commandSuggestion.contains("指挥圈"))
    #expect(state == before)
}

@Test func legionFormationReportMarksDamagedIsolatedUnitCriticalWithoutMutation() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-isolated", kind: .cavalry, faction: .rome, position: Position(x: 3, y: 3), health: 22),
        ArmyUnit(id: "carthage-east", kind: .legion, faction: .carthage, position: Position(x: 4, y: 3)),
        ArmyUnit(id: "carthage-north", kind: .archer, faction: .carthage, position: Position(x: 3, y: 2))
    ]
    let before = state

    let reports = state.legionFormationReports(for: .rome, limit: 1)
    let report = reports.first

    #expect(report?.unitID == "rome-isolated")
    #expect(report?.role == .line)
    #expect(report?.readiness == .critical)
    #expect(report?.adjacentAllyCount == 0)
    #expect(report?.nearbyEnemyCount == 2)
    #expect(report?.recommendedOrder == .defensive)
    #expect((report?.formationIntegrityScore ?? 100) < 35)
    #expect(report?.commandSuggestion.contains("危急") == true)
    #expect(state == before)
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
    #expect(intent?.targetCityID == nil)
    #expect(intent?.destination == Position(x: 4, y: 3))
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
    #expect(intent?.targetCityID == nil)
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

@Test func aiExecutionPrioritizesHighestThreatIntent() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-target", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "carthage-low", kind: .archer, faction: .carthage, position: Position(x: 11, y: 0)),
        ArmyUnit(id: "carthage-hunter", kind: .cavalry, faction: .carthage, position: Position(x: 7, y: 2))
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

    let intents = state.aiIntents(for: .carthage, limit: 4)
    let topIntent = intents.first
    let lowIntent = intents.first { $0.unitID == "carthage-low" }

    #expect(topIntent?.unitID == "carthage-hunter")
    #expect(topIntent?.kind == .advanceAttack)
    #expect(topIntent?.targetUnitID == "rome-target")
    #expect(topIntent?.destination != nil)
    #expect((topIntent?.projectedDamage ?? 0) > 0)
    #expect(lowIntent != nil)
    #expect((topIntent?.threatScore ?? 0) > (lowIntent?.threatScore ?? 0))
    #expect(state == beforeIntentForecast)

    guard let topIntent, let destination = topIntent.destination else {
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
        previewState.units[hunterIndex].tacticalOrder = topIntent.tacticalOrder == .balanced ? nil : topIntent.tacticalOrder
    }
    let preview = try previewState.attackPreview(attackerID: "carthage-hunter", defenderID: "rome-target")

    var aiState = state
    aiState.activeFaction = .carthage
    let beforeHealth = aiState.unit(withID: "rome-target")?.health ?? 0

    let messages = aiState.performSimpleAI(for: .carthage)

    #expect(messages.first?.contains("骑兵") == true)
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
    let before = state

    let intents = state.aiIntents(for: .carthage, limit: 1)
    let intent = intents.first

    #expect(intent?.kind == .captureCity)
    #expect(intent?.unitID == "carthage-capturer")
    #expect(intent?.targetUnitID == nil)
    #expect(intent?.targetCityID == "massilia")
    #expect(intent?.destination == Position(x: 5, y: 2))
    #expect(state == before)
}

@Test func frontlinePressureAggregatesMultipleAttackIntentsWithoutMutation() {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-target", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "carthage-east", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3)),
        ArmyUnit(id: "carthage-north", kind: .legion, faction: .carthage, position: Position(x: 3, y: 2))
    ]
    state.activeFaction = .rome
    let before = state

    let intents = state.aiIntents(for: .carthage, limit: 4)
    let expectedDamage = intents
        .filter { $0.targetUnitID == "rome-target" }
        .reduce(0) { partial, intent in partial + (intent.projectedDamage ?? 0) }
    let reports = state.frontlinePressureReports(against: .rome, perFactionLimit: 4, limit: 3)
    let report = reports.first { $0.targetID == "rome-target" }

    #expect(report?.targetKind == .unit)
    #expect(report?.targetPosition == Position(x: 3, y: 3))
    #expect(Set(report?.sourceUnitIDs ?? []) == Set(["carthage-east", "carthage-north"]))
    #expect(report?.sourceFactions == [.carthage])
    #expect(report?.intentCount == 2)
    #expect(report?.attackIntentCount == 2)
    #expect(report?.captureIntentCount == 0)
    #expect(report?.projectedDamageTotal == expectedDamage)
    #expect((report?.maxThreatScore ?? 0) > 0)
    #expect(report?.level == .critical)
    #expect(state == before)
}

@Test func frontlinePressureReportsRomanCityCaptureThreat() {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "carthage-capturer", kind: .cavalry, faction: .carthage, position: Position(x: 6, y: 2))
    ]
    for index in state.cities.indices where state.cities[index].id != "massilia" {
        state.cities[index].owner = .carthage
    }
    if let massiliaIndex = state.cities.firstIndex(where: { $0.id == "massilia" }) {
        state.cities[massiliaIndex].owner = .rome
    }
    let before = state

    let reports = state.frontlinePressureReports(against: .rome, perFactionLimit: 3, limit: 2)
    let report = reports.first { $0.targetID == "massilia" }

    #expect(report?.targetKind == .city)
    #expect(report?.targetFaction == .rome)
    #expect(report?.targetPosition == Position(x: 5, y: 2))
    #expect(report?.sourceUnitIDs == ["carthage-capturer"])
    #expect(report?.intentKinds == [.captureCity])
    #expect(report?.captureIntentCount == 1)
    #expect(report?.level == .critical)
    #expect(state == before)
}

@Test func frontlinePressureIgnoresTreatyProtectedFactions() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-target", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "carthage-hunter", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3))
    ]
    _ = try state.sendEnvoy(to: .carthage)
    let before = state

    let reports = state.frontlinePressureReports(against: .rome, perFactionLimit: 4, limit: 3)

    #expect(reports.isEmpty)
    #expect(state == before)
}

@Test func tacticalRecommendationPrioritizesAvailableAttackWithoutMutation() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-striker", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), health: 82),
        ArmyUnit(id: "carthage-target", kind: .archer, faction: .carthage, position: Position(x: 4, y: 3), health: 24)
    ]
    state.activeFaction = .rome
    let before = state

    let report = try state.tacticalRecommendation(unitID: "rome-striker")

    #expect(report.kind == .attack)
    #expect(report.targetUnitID == "carthage-target")
    #expect(report.targetPosition == Position(x: 4, y: 3))
    #expect(report.destination == Position(x: 3, y: 3))
    #expect((report.projectedDamage ?? 0) > 0)
    #expect(TacticalOrder.allCases.contains(report.recommendedOrder))
    #expect(!report.path.isEmpty)
    #expect(report.command.contains("攻击") || report.command.contains("压制"))
    #expect(state == before)
}

@Test func tacticalRecommendationMovesReserveTowardPressedLineWithoutMutation() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-line", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "rome-reserve", kind: .legion, faction: .rome, position: Position(x: 1, y: 3)),
        ArmyUnit(id: "carthage-east", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3)),
        ArmyUnit(id: "carthage-north", kind: .legion, faction: .carthage, position: Position(x: 3, y: 2))
    ]
    state.activeFaction = .rome
    let before = state

    let report = try state.tacticalRecommendation(unitID: "rome-reserve")

    #expect(report.kind == .reinforce)
    #expect(report.targetUnitID == "rome-line")
    #expect(report.targetPosition == Position(x: 3, y: 3))
    #expect(report.destination.hexDistance(to: report.targetPosition) < Position(x: 1, y: 3).hexDistance(to: report.targetPosition))
    #expect(report.supportDistance != nil)
    #expect(report.path.first == Position(x: 1, y: 3))
    #expect(report.path.last == report.destination)
    #expect(report.command.contains("补线") || report.command.contains("战线"))
    #expect(state == before)
}

@Test func tacticalRecommendationDoesNotSuggestImmediateActionForSpentUnitWithoutMutation() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-spent", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), health: 40, hasMoved: true, hasActed: true)
    ]
    state.activeFaction = .rome
    let before = state

    let report = try state.tacticalRecommendation(unitID: "rome-spent")

    #expect(report.kind == .recover)
    #expect(report.destination == Position(x: 3, y: 3))
    #expect(report.targetPosition == Position(x: 3, y: 3))
    #expect(report.path == [Position(x: 3, y: 3)])
    #expect(report.projectedDamage == nil)
    #expect(report.command.contains("整备") || report.command.contains("恢复"))
    #expect(state == before)
}

@Test func maneuverOptionReportsSurfaceStrikeLandingWithoutMutation() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-striker", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "rome-support", kind: .legion, faction: .rome, position: Position(x: 3, y: 2)),
        ArmyUnit(id: "carthage-target", kind: .archer, faction: .carthage, position: Position(x: 5, y: 3), health: 45)
    ]
    state.activeFaction = .rome
    let before = state

    let reports = try state.maneuverOptionReports(unitID: "rome-striker", limit: 8)
    let report = try #require(reports.first { $0.kind == .strike && $0.targetUnitID == "carthage-target" })
    var projected = state
    let strikerIndex = try #require(projected.units.firstIndex { $0.id == "rome-striker" })
    projected.units[strikerIndex].position = report.destination
    let preview = try projected.attackPreview(attackerID: "rome-striker", defenderID: "carthage-target")

    #expect(report.origin == Position(x: 3, y: 3))
    #expect(report.path.first == Position(x: 3, y: 3))
    #expect(report.path.last == report.destination)
    #expect(report.destination.hexDistance(to: Position(x: 5, y: 3)) <= 1)
    #expect(report.projectedDamage == preview.damage)
    #expect(report.retaliation == preview.retaliation)
    #expect(report.supportBonus == preview.supportBonus)
    #expect(report.flankingBonus == preview.flankingBonus)
    #expect(report.commandBonus == preview.commandBonus)
    #expect(report.isExecutable)
    #expect(state == before)
}

@Test func maneuverOptionReportsSurfaceCaptureLandingWithoutMutation() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-cavalry", kind: .cavalry, faction: .rome, position: Position(x: 3, y: 3))
    ]
    let massiliaIndex = try #require(state.cities.firstIndex { $0.id == "massilia" })
    state.cities[massiliaIndex].owner = .carthage
    state.cities[massiliaIndex].fortification = 70
    state.activeFaction = .rome
    let before = state

    let reports = try state.maneuverOptionReports(unitID: "rome-cavalry", limit: 8)
    let report = try #require(reports.first { $0.kind == .capture && $0.targetCityID == "massilia" })

    #expect(report.destination == Position(x: 5, y: 2))
    #expect(report.targetPosition == Position(x: 5, y: 2))
    #expect(report.path.first == Position(x: 3, y: 3))
    #expect(report.path.last == report.destination)
    #expect(report.title.contains("马赛"))
    #expect(report.controlState == .friendlyControlled)
    #expect(report.friendlyInfluence > report.enemyInfluence)
    #expect(report.isExecutable)
    #expect(state == before)
}

@Test func maneuverOptionReportsIgnoreTreatyProtectedCaptureTargets() throws {
    var state = GameState.newCampaign()
    state.cities.append(
        City(id: "gaul-town", name: "高卢前哨", position: Position(x: 4, y: 3), owner: .gaul, production: .zero, fortification: 6)
    )
    state.units = [
        ArmyUnit(id: "rome-legion", kind: .legion, faction: .rome, position: Position(x: 3, y: 3))
    ]
    state.activeFaction = .rome
    _ = try state.sendEnvoy(to: .gaul)
    let before = state

    let reports = try state.maneuverOptionReports(unitID: "rome-legion", limit: 5)

    #expect(!reports.contains { $0.targetCityID == "gaul-town" })
    #expect(state == before)
}

@Test func maneuverOptionReportsRankSaferLandingAboveHotEmptyTileWithoutMutation() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-cavalry", kind: .cavalry, faction: .rome, position: Position(x: 3, y: 3), health: 88),
        ArmyUnit(id: "carthage-east", kind: .cavalry, faction: .carthage, position: Position(x: 7, y: 3))
    ]
    state.activeFaction = .rome
    let before = state

    let reports = try state.maneuverOptionReports(unitID: "rome-cavalry", limit: 8)
    let firstReport = try #require(reports.first)
    let hotReport = try #require(reports.first { $0.threatLevel == .danger || $0.threatLevel == .critical })

    #expect(riskTestPriority(firstReport.risk) <= riskTestPriority(hotReport.risk))
    #expect(firstReport.score >= hotReport.score)
    #expect(state == before)
}

@Test func maneuverOptionReportsReturnEmptyForSpentUnitWithoutMutation() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-spent", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), hasMoved: true)
    ]
    state.activeFaction = .rome
    let before = state

    let reports = try state.maneuverOptionReports(unitID: "rome-spent", limit: 5)
    let report = try state.maneuverOptionReport(unitID: "rome-spent")

    #expect(reports.isEmpty)
    #expect(report == nil)
    #expect(state == before)
}

@Test func commanderSynergySurfacesReadyCommanderSkillWithoutMutation() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-commander", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), generalName: "凯撒", generalTrait: .eagleStandard),
        ArmyUnit(id: "rome-wounded", kind: .archer, faction: .rome, position: Position(x: 4, y: 3), health: 30)
    ]
    state.activeFaction = .rome
    let before = state

    let report = try state.commanderSynergyReport(unitID: "rome-commander")

    #expect(report.kind == .commanderSkill)
    #expect(report.commanderUnitID == "rome-commander")
    #expect(report.targetUnitID == "rome-wounded")
    #expect(report.beneficiaryUnitIDs == ["rome-wounded"])
    #expect(report.projectedRecoveredHealth > 0)
    #expect(report.isExecutable)
    #expect(report.steps.contains { $0.role == .commander })
    #expect(report.steps.contains { $0.role == .beneficiary })
    #expect(report.title.contains("鹰旗鼓舞"))
    #expect(report.detail.contains("恢复"))
    #expect(state == before)
}

@Test func commanderSynergySkillTargetPositionMatchesTargetIDWithoutMutation() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-commander", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), generalName: "凯撒", generalTrait: .eagleStandard),
        ArmyUnit(id: "rome-south", kind: .archer, faction: .rome, position: Position(x: 4, y: 4), health: 30),
        ArmyUnit(id: "rome-north", kind: .legion, faction: .rome, position: Position(x: 3, y: 2), health: 40)
    ]
    state.activeFaction = .rome
    let before = state

    let preview = try state.generalSkillPreview(unitID: "rome-commander")
    let report = try state.commanderSynergyReport(unitID: "rome-commander")

    #expect(Position(x: 4, y: 4).hexDistance(to: Position(x: 3, y: 3)) == 1)
    #expect(Position(x: 3, y: 2).hexDistance(to: Position(x: 3, y: 3)) == 1)
    #expect(preview.affectedUnitIDs.first == "rome-south")
    #expect(preview.affectedPositions.first == Position(x: 3, y: 2))
    #expect(report.kind == .commanderSkill)
    #expect(report.targetUnitID == preview.affectedUnitIDs.first)
    #expect(report.targetPosition == Position(x: 4, y: 4))
    #expect(report.steps.first?.targetPosition == Position(x: 4, y: 4))
    #expect(state == before)
}

@Test func commanderSynergyExplainsCoordinatedAttackModifiersWithoutMutation() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-attacker", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), generalName: "凯撒", generalTrait: .eagleStandard),
        ArmyUnit(id: "rome-support", kind: .legion, faction: .rome, position: Position(x: 2, y: 3)),
        ArmyUnit(id: "rome-flanker", kind: .archer, faction: .rome, position: Position(x: 4, y: 2)),
        ArmyUnit(id: "carthage-target", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3), health: 70)
    ]
    state.activeFaction = .rome
    let before = state

    let report = try state.commanderSynergyReport(unitID: "rome-attacker")
    let preview = try state.attackPreview(attackerID: "rome-attacker", defenderID: "carthage-target")

    #expect(report.kind == .coordinatedAttack)
    #expect(report.targetUnitID == "carthage-target")
    #expect(report.projectedDamage == preview.damage)
    #expect(report.supportBonus == preview.supportBonus)
    #expect(report.flankingBonus == preview.flankingBonus)
    #expect(report.commandBonus == preview.commandBonus)
    #expect(report.supportBonus > 0)
    #expect(report.flankingBonus > 0)
    #expect(report.commandBonus > 0)
    #expect(Set(report.supportingUnitIDs).isSuperset(of: Set(["rome-support", "rome-flanker", "rome-attacker"])))
    #expect(report.detail.contains("支援"))
    #expect(state == before)
}

@Test func commanderSynergyReportsCooldownBlockerWithoutMutation() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-commander", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), generalName: "凯撒", generalTrait: .eagleStandard, generalSkillCooldownRemaining: 2),
        ArmyUnit(id: "rome-wounded", kind: .archer, faction: .rome, position: Position(x: 4, y: 3), health: 30)
    ]
    state.activeFaction = .rome
    let before = state

    let report = try state.commanderSynergyReport(unitID: "rome-commander")

    #expect(report.kind == .commanderSkill)
    #expect(!report.isExecutable)
    #expect(report.blockedReason?.contains("冷却") == true)
    #expect(report.projectedRecoveredHealth > 0)
    #expect(report.summary.contains("不可执行"))
    #expect(state == before)
}

@Test func commanderSynergyRanksExecutableActionAboveBlockedSkill() {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-commander", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), generalName: "凯撒", generalTrait: .eagleStandard, generalSkillCooldownRemaining: 2),
        ArmyUnit(id: "rome-wounded", kind: .archer, faction: .rome, position: Position(x: 4, y: 3), health: 30),
        ArmyUnit(id: "rome-reserve", kind: .legion, faction: .rome, position: Position(x: 1, y: 3))
    ]
    state.activeFaction = .rome
    let before = state

    let reports = state.commanderSynergyReports(for: .rome, limit: 3)
    let blockedCommander = reports.first { $0.unitID == "rome-commander" }

    #expect(blockedCommander?.kind == .commanderSkill)
    #expect(blockedCommander?.isExecutable == false)
    #expect(reports.first?.unitID != "rome-commander")
    #expect(reports.first?.isExecutable == true)
    #expect(reports.prefix { $0.unitID != "rome-commander" }.allSatisfy { $0.isExecutable })
    #expect(state == before)
}

@Test func commanderSynergyIgnoresTreatyProtectedAttackTargets() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-attacker", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "carthage-target", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3), health: 70)
    ]
    _ = try state.sendEnvoy(to: .carthage)
    let before = state

    let report = try state.commanderSynergyReport(unitID: "rome-attacker")

    #expect(report.kind != .coordinatedAttack)
    #expect(report.targetUnitID != "carthage-target")
    #expect(state == before)
}

@Test func commanderSynergyReportsSortHighestOpportunityFirst() {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-commander", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), generalName: "凯撒", generalTrait: .eagleStandard),
        ArmyUnit(id: "rome-wounded", kind: .archer, faction: .rome, position: Position(x: 4, y: 3), health: 30),
        ArmyUnit(id: "rome-reserve", kind: .legion, faction: .rome, position: Position(x: 1, y: 3))
    ]
    state.activeFaction = .rome
    let before = state

    let reports = state.commanderSynergyReports(for: .rome, limit: 3)

    #expect(reports.first?.kind == .commanderSkill)
    #expect(reports.first?.unitID == "rome-commander")
    #expect((reports.first?.score ?? 0) >= (reports.dropFirst().first?.score ?? 0))
    #expect(reports.contains { $0.unitID == "rome-reserve" })
    #expect(state == before)
}

@Test func battlefieldFocusPrioritizesCriticalFrontlinePressureWithoutMutation() {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-target", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "rome-reserve", kind: .legion, faction: .rome, position: Position(x: 1, y: 3)),
        ArmyUnit(id: "carthage-east", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3)),
        ArmyUnit(id: "carthage-north", kind: .legion, faction: .carthage, position: Position(x: 3, y: 2))
    ]
    state.activeFaction = .rome
    let before = state

    let reports = state.battlefieldFocusReports(for: .rome, limit: 5)
    let report = reports.first { $0.kind == .defense && $0.targetUnitID == "rome-target" }

    #expect(report?.severity == .critical)
    #expect(report?.position == Position(x: 3, y: 3))
    #expect(report?.unitID == "rome-target")
    #expect(Set(report?.relatedUnitIDs ?? []) == Set(["carthage-east", "carthage-north"]))
    #expect(report?.recommendedOrder == .defensive)
    #expect((report?.score ?? 0) > 0)
    #expect(report?.title.contains("危急") == true)
    #expect(report?.detail.contains("预计伤害") == true)
    #expect(state == before)
}

@Test func battlefieldFocusSurfacesReadyGeneralSkillWithoutMutation() {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-commander", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), experience: 4, generalName: "凯撒", generalTrait: .eagleStandard),
        ArmyUnit(id: "rome-wounded", kind: .archer, faction: .rome, position: Position(x: 4, y: 3), health: 30),
        ArmyUnit(id: "carthage-near", kind: .cavalry, faction: .carthage, position: Position(x: 3, y: 2))
    ]
    state.activeFaction = .rome
    let before = state

    let reports = state.battlefieldFocusReports(for: .rome, limit: 5)
    let report = reports.first { $0.kind == .generalOpportunity && $0.unitID == "rome-commander" }

    #expect(report?.severity == .urgent)
    #expect(report?.position == Position(x: 3, y: 3))
    #expect(report?.relatedUnitIDs == ["rome-commander"])
    #expect(report?.recommendedOrder == .balanced)
    #expect(report?.title.contains("凯撒") == true)
    #expect(report?.summary.contains("将领") == true)
    #expect(report?.detail.isEmpty == false)
    #expect(state == before)
}

@Test func mapControlReportsAggregateFriendlyUnitsAndCitiesWithoutMutation() {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-line", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "rome-support", kind: .archer, faction: .rome, position: Position(x: 4, y: 3)),
        ArmyUnit(id: "carthage-far", kind: .legion, faction: .carthage, position: Position(x: 9, y: 6))
    ]
    state.activeFaction = .rome
    let before = state

    let reports = state.mapControlReports(for: .rome)
    let report = reports.first { $0.position == Position(x: 3, y: 3) }

    #expect(reports.count == state.tiles.count)
    #expect(reports.first?.position == Position(x: 0, y: 0))
    #expect(report?.cityID == "rome")
    #expect(report?.occupantUnitID == "rome-line")
    #expect((report?.friendlyInfluence ?? 0) > (report?.enemyInfluence ?? 0))
    #expect(report?.controlState == .friendlyControlled)
    #expect(report?.friendlyUnitIDs.contains("rome-line") == true)
    #expect(report?.summary.isEmpty == false)
    #expect(report?.detail.isEmpty == false)
    #expect(state == before)
}

@Test func mapControlReportsCoverControlStatesAndNonCriticalHeatWithoutMutation() {
    func makeState(
        cities: [City] = [],
        units: [ArmyUnit] = [],
        waterPositions: Set<Position> = []
    ) -> GameState {
        let width = 5
        let height = 5
        let tiles = (0..<height).flatMap { y in
            (0..<width).map { x in
                let position = Position(x: x, y: y)
                return Tile(position: position, terrain: waterPositions.contains(position) ? .water : .plains)
            }
        }

        return GameState(
            mode: .campaign,
            turn: 1,
            activeFaction: .rome,
            width: width,
            height: height,
            tiles: tiles,
            cities: cities,
            units: units,
            resources: [:],
            researchedTechnologies: [:],
            diplomaticRelations: [],
            missions: []
        )
    }

    let target = Position(x: 2, y: 2)
    let production = EmpireResources.zero
    let neutralState = makeState()
    let friendlyState = makeState(cities: [
        City(id: "friendly", name: "据点", position: target, owner: .rome, production: production, fortification: 0)
    ])
    let enemyState = makeState(cities: [
        City(id: "enemy", name: "敌垒", position: target, owner: .carthage, production: production, fortification: 0)
    ])
    let contestedState = makeState(
        units: [
            ArmyUnit(id: "rome-pressure", kind: .legion, faction: .rome, position: Position(x: 0, y: 2)),
            ArmyUnit(id: "carthage-pressure", kind: .legion, faction: .carthage, position: Position(x: 4, y: 2))
        ]
    )
    let watchedState = makeState(
        units: [
            ArmyUnit(id: "carthage-watch", kind: .navy, faction: .carthage, position: Position(x: 4, y: 2))
        ],
        waterPositions: [Position(x: 4, y: 2)]
    )
    let before = [
        neutralState,
        friendlyState,
        enemyState,
        contestedState,
        watchedState
    ]

    let neutral = neutralState.mapControlReport(at: target, for: .rome)
    let friendly = friendlyState.mapControlReport(at: target, for: .rome)
    let enemy = enemyState.mapControlReport(at: target, for: .rome)
    let contested = contestedState.mapControlReport(at: target, for: .rome)
    let watched = watchedState.mapControlReport(at: Position(x: 1, y: 2), for: .rome)

    #expect(neutral?.controlState == .neutral)
    #expect(neutral?.threatLevel == .quiet)
    #expect(friendly?.controlState == .friendlyControlled)
    #expect(friendly?.threatLevel == .quiet)
    #expect(enemy?.controlState == .enemyControlled)
    #expect(enemy?.threatLevel == .danger)
    #expect(contested?.controlState == .contested)
    #expect(contested?.threatLevel == .contested)
    #expect(watched?.controlState == .enemyControlled)
    #expect(watched?.threatLevel == .watched)
    #expect(before == [neutralState, friendlyState, enemyState, contestedState, watchedState])
}

@Test func threatHeatReportsSurfaceDirectAndAdvanceAttackThreatsWithoutMutation() {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-target", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "carthage-east", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3)),
        ArmyUnit(id: "carthage-hunter", kind: .cavalry, faction: .carthage, position: Position(x: 7, y: 2))
    ]
    state.activeFaction = .rome
    let before = state

    let intents = state.aiIntents(for: .carthage, limit: 4)
    let expectedDamage = intents
        .filter { $0.targetUnitID == "rome-target" }
        .reduce(0) { partial, intent in partial + (intent.projectedDamage ?? 0) }
    let reports = state.threatHeatZoneReports(for: .rome, limit: 5)
    let report = reports.first { $0.center == Position(x: 3, y: 3) }

    #expect(report?.threatLevel == .critical)
    #expect(report?.sourceUnitIDs.contains("carthage-east") == true)
    #expect(report?.sourceUnitIDs.contains("carthage-hunter") == true)
    #expect((report?.attackIntentCount ?? 0) >= 2)
    #expect(report?.projectedDamageTotal == expectedDamage)
    #expect(report?.positions.contains(Position(x: 3, y: 3)) == true)
    #expect(report?.title.isEmpty == false)
    #expect(report?.detail.isEmpty == false)
    #expect(state == before)
}

@Test func threatHeatReportsIncludeCityCaptureHotspot() {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "carthage-capturer", kind: .cavalry, faction: .carthage, position: Position(x: 6, y: 2))
    ]
    for index in state.cities.indices where state.cities[index].id != "massilia" {
        state.cities[index].owner = .carthage
    }
    if let massiliaIndex = state.cities.firstIndex(where: { $0.id == "massilia" }) {
        state.cities[massiliaIndex].owner = .rome
    }
    let before = state

    let reports = state.threatHeatZoneReports(for: .rome, limit: 5)
    let report = reports.first { $0.center == Position(x: 5, y: 2) }

    #expect(report?.threatLevel == .critical)
    #expect(report?.cityIDs.contains("massilia") == true)
    #expect(report?.sourceUnitIDs == ["carthage-capturer"])
    #expect(report?.captureIntentCount == 1)
    #expect(report?.title.contains("马赛") == true)
    #expect(state == before)
}

@Test func mapControlAndThreatHeatIgnoreTreatyProtectedFactions() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-target", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "carthage-hunter", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3))
    ]
    for index in state.cities.indices {
        state.cities[index].owner = state.cities[index].id == "rome" ? .rome : .neutral
    }
    _ = try state.sendEnvoy(to: .carthage)
    let before = state

    let mapReport = state.mapControlReport(at: Position(x: 3, y: 3), for: .rome)
    let heatReports = state.threatHeatZoneReports(for: .rome, limit: 5)

    #expect(mapReport?.enemyInfluence == 0)
    #expect(mapReport?.enemyUnitIDs.isEmpty == true)
    #expect(!heatReports.contains { $0.sourceUnitIDs.contains("carthage-hunter") })
    #expect(state == before)
}

@Test func aiOperationalPlanAggregatesFocusedAttackWithoutMutation() {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-target", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "carthage-east", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3)),
        ArmyUnit(id: "carthage-north", kind: .legion, faction: .carthage, position: Position(x: 3, y: 2))
    ]
    state.activeFaction = .rome
    let before = state

    let reports = state.aiOperationalPlanReports(against: .rome, perFactionLimit: 4, limit: 5)
    let report = reports.first { $0.kind == .focusedAttack && $0.targetUnitID == "rome-target" }

    #expect(Set(report?.sourceUnitIDs ?? []) == Set(["carthage-east", "carthage-north"]))
    #expect(report?.steps.contains { $0.coordinationRole == .mainEffort } == true)
    #expect(report?.steps.contains { $0.coordinationRole == .support } == true)
    #expect((report?.projectedDamageTotal ?? 0) > 0)
    #expect(report?.pressureLevel == .critical)
    #expect(report?.threatHeatLevel == .critical)
    #expect(report?.title.contains("集火") == true)
    #expect(report?.summary.isEmpty == false)
    #expect(report?.detail.isEmpty == false)
    #expect(state == before)
}

@Test func aiOperationalPlanReportsCityCapturePlanWithoutMutation() {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "carthage-capturer", kind: .cavalry, faction: .carthage, position: Position(x: 6, y: 2))
    ]
    for index in state.cities.indices where state.cities[index].id != "massilia" {
        state.cities[index].owner = .carthage
    }
    if let massiliaIndex = state.cities.firstIndex(where: { $0.id == "massilia" }) {
        state.cities[massiliaIndex].owner = .rome
    }
    let before = state

    let reports = state.aiOperationalPlanReports(against: .rome, perFactionLimit: 4, limit: 5)
    let report = reports.first { $0.kind == .cityCapture && $0.targetCityID == "massilia" }

    #expect(report?.targetPosition == Position(x: 5, y: 2))
    #expect(report?.sourceUnitIDs == ["carthage-capturer"])
    #expect(report?.steps.first?.coordinationRole == .mainEffort)
    #expect(report?.title.contains("马赛") == true)
    #expect(report?.pressureLevel == .critical)
    #expect(state == before)
}

@Test func aiOperationalPlanUsesEnemyForecastForCommanderSkillWithoutMutation() {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-line", kind: .legion, faction: .rome, position: Position(x: 1, y: 1)),
        ArmyUnit(id: "carthage-quartermaster", kind: .legion, faction: .carthage, position: Position(x: 5, y: 3), generalName: "阿格里帕", generalTrait: .quartermaster),
        ArmyUnit(id: "carthage-wounded", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3), health: 40)
    ]
    state.activeFaction = .rome
    let before = state

    let reports = state.aiOperationalPlanReports(against: .rome, perFactionLimit: 4, limit: 5)
    let report = reports.first { $0.kind == .commanderSkill && $0.sourceUnitIDs.contains("carthage-quartermaster") }

    #expect(report?.commanderUnitIDs == ["carthage-quartermaster"])
    #expect(report?.targetUnitID == "carthage-wounded")
    #expect(report?.steps.first?.coordinationRole == .commander)
    #expect(report?.steps.first?.skillSummary?.contains("恢复") == true)
    #expect(report?.detail.contains("阿格里帕") == true)
    #expect(state == before)
}

@Test func aiOperationalPlanKeepsRegroupFallbackWithoutPressureTarget() {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-line", kind: .legion, faction: .rome, position: Position(x: 1, y: 1)),
        ArmyUnit(id: "carthage-battered", kind: .legion, faction: .carthage, position: Position(x: 8, y: 2), health: 18)
    ]
    if let alesiaIndex = state.cities.firstIndex(where: { $0.id == "alesia" }) {
        state.cities[alesiaIndex].owner = .carthage
    }
    let before = state

    let reports = state.aiOperationalPlanReports(against: .rome, perFactionLimit: 4, limit: 5)
    let report = reports.first { $0.kind == .regroup && $0.sourceUnitIDs.contains("carthage-battered") }

    #expect(report?.targetPosition == Position(x: 8, y: 2))
    #expect(report?.steps.first?.coordinationRole == .reserve)
    #expect(report?.projectedDamageTotal == 0)
    #expect(report?.summary.isEmpty == false)
    #expect(state == before)
}

@Test func aiOperationalPlanIgnoresTreatyProtectedFactions() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-target", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "carthage-hunter", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3))
    ]
    _ = try state.sendEnvoy(to: .carthage)
    let before = state

    let reports = state.aiOperationalPlanReports(against: .rome, perFactionLimit: 4, limit: 5)

    #expect(!reports.contains { $0.sourceUnitIDs.contains("carthage-hunter") })
    #expect(state == before)
}

@Test func enemyCommanderThreatUsesEnemyForecastForSkillWithoutMutation() {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-line", kind: .legion, faction: .rome, position: Position(x: 1, y: 1)),
        ArmyUnit(id: "carthage-quartermaster", kind: .legion, faction: .carthage, position: Position(x: 5, y: 3), generalName: "阿格里帕", generalTrait: .quartermaster),
        ArmyUnit(id: "carthage-wounded", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3), health: 40)
    ]
    state.activeFaction = .rome
    let before = state

    let reports = state.enemyCommanderThreatReports(against: .rome, limit: 5)
    let report = reports.first { $0.unitID == "carthage-quartermaster" }

    #expect(report?.intentKind == .useSkill)
    #expect((report?.projectedRecovery ?? 0) > 0)
    #expect(report?.affectedUnitIDs.contains("carthage-wounded") == true)
    #expect(report?.skillReady == true)
    #expect(report?.skillBlockedReason == nil)
    #expect(report?.skillSummary.contains("恢复") == true)
    #expect(report?.detail.isEmpty == false)
    #expect(state == before)
}

@Test func enemyCommanderThreatRanksReadySkillAboveCooldownCommander() {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-line", kind: .legion, faction: .rome, position: Position(x: 1, y: 1)),
        ArmyUnit(id: "carthage-ready", kind: .legion, faction: .carthage, position: Position(x: 5, y: 3), generalName: "阿格里帕", generalTrait: .quartermaster),
        ArmyUnit(id: "carthage-cooling", kind: .legion, faction: .carthage, position: Position(x: 6, y: 3), generalName: "汉诺", generalTrait: .quartermaster, generalSkillCooldownRemaining: 2),
        ArmyUnit(id: "carthage-wounded", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3), health: 40)
    ]
    state.activeFaction = .rome
    let before = state

    let reports = state.enemyCommanderThreatReports(against: .rome, limit: 5)
    let ready = reports.first { $0.unitID == "carthage-ready" }
    let cooling = reports.first { $0.unitID == "carthage-cooling" }

    #expect(ready?.skillReady == true)
    #expect(ready?.intentKind == .useSkill)
    #expect(cooling?.skillReady == false)
    #expect(cooling?.skillBlockedReason?.contains("冷却") == true)
    #expect((ready?.score ?? 0) > (cooling?.score ?? 0))
    #expect(reports.first?.unitID == "carthage-ready")
    #expect(state == before)
}

@Test func enemyCommanderThreatAttackDamageMatchesAIIntentForecast() {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-target", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "carthage-commander", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3), generalName: "汉尼拔", generalTrait: .eagleStandard)
    ]
    state.activeFaction = .rome
    let before = state

    let intent = state.aiIntents(for: .carthage, limit: 4).first { $0.unitID == "carthage-commander" }
    let report = state.enemyCommanderThreatReports(against: .rome, limit: 5).first { $0.unitID == "carthage-commander" }

    #expect(report?.intentKind == intent?.kind)
    #expect(report?.targetUnitID == intent?.targetUnitID)
    #expect((report?.projectedDamage ?? 0) > 0)
    #expect(report?.projectedDamage == intent?.projectedDamage)
    #expect(state == before)
}

@Test func enemyCommanderThreatSiegeImpactComesFromGeneralSkillPreview() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-garrison", kind: .legion, faction: .rome, position: Position(x: 3, y: 4)),
        ArmyUnit(id: "carthage-siege", kind: .legion, faction: .carthage, position: Position(x: 2, y: 3), generalName: "汉尼拔", generalTrait: .siegeEngineer)
    ]
    state.activeFaction = .rome
    let before = state

    var previewState = state
    previewState.activeFaction = .carthage
    let preview = try previewState.generalSkillPreview(unitID: "carthage-siege")
    let report = state.enemyCommanderThreatReports(against: .rome, limit: 5).first { $0.unitID == "carthage-siege" }

    #expect(preview.affectedCityIDs.contains("rome"))
    #expect(report?.intentKind == .useSkill)
    #expect(report?.targetCityID == "rome")
    #expect(report?.affectedCityIDs == preview.affectedCityIDs)
    #expect(report?.projectedFortificationReduction == preview.projectedFortificationReduction)
    #expect(report?.skillSummary == preview.summary)
    #expect(report?.impact.contains("城防") == true)
    #expect(state == before)
}

@Test func enemyCommanderThreatIgnoresTreatyProtectedFactions() throws {
    var state = GameState.newCampaign()
    state.units = [
        ArmyUnit(id: "rome-line", kind: .legion, faction: .rome, position: Position(x: 1, y: 1)),
        ArmyUnit(id: "carthage-quartermaster", kind: .legion, faction: .carthage, position: Position(x: 5, y: 3), generalName: "阿格里帕", generalTrait: .quartermaster),
        ArmyUnit(id: "carthage-wounded", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3), health: 40)
    ]
    _ = try state.sendEnvoy(to: .carthage)
    let before = state

    let reports = state.enemyCommanderThreatReports(against: .rome, limit: 5)

    #expect(!reports.contains { $0.unitID == "carthage-quartermaster" })
    #expect(state == before)
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

@Test func legacyArmyUnitJSONDefaultsMissingSkillCooldownToZero() throws {
    let legacyUnitJSON = """
    {
      "id": "legacy-legion",
      "kind": "legion",
      "faction": "rome",
      "position": {
        "x": 1,
        "y": 2
      },
      "health": 100,
      "experience": 4,
      "generalName": "凯撒",
      "generalTrait": "eagleStandard",
      "tacticalOrder": "defensive",
      "hasMoved": false,
      "hasActed": false
    }
    """

    let unit = try JSONDecoder().decode(ArmyUnit.self, from: Data(legacyUnitJSON.utf8))

    #expect(unit.generalSkillCooldownRemaining == 0)
    #expect(unit.resolvedGeneralTrait == .eagleStandard)
    #expect(unit.resolvedTacticalOrder == .defensive)
}
