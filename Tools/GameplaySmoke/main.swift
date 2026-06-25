func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        print("FAIL: \(message)")
        fatalError(message)
    }
}

do {
    var movementState = GameState.newCampaign()
    let moveMessages = try movementState.moveUnit(id: "rome-legion-1", to: Position(x: 5, y: 2))
    expect(movementState.city(withID: "massilia")?.owner == .rome, "Rome should capture Massilia")
    expect(moveMessages.contains { $0.contains("占领马赛") }, "Capture message should be emitted")

    var recruitmentState = GameState.newCampaign()
    recruitmentState.units.removeAll { $0.position == Position(x: 3, y: 3) }
    let beforeRecruitment = recruitmentState.units.count
    _ = try recruitmentState.recruit(.legion, at: "rome")
    expect(recruitmentState.units.count == beforeRecruitment + 1, "Recruitment should add a unit")

    var technologyState = GameState.newCampaign()
    _ = try technologyState.research(.marchingDrill)
    expect(technologyState.researchedTechnologies[.rome]?.contains(.marchingDrill) == true, "Technology should be researched")

    var trainingState = GameState.newCampaign()
    _ = try trainingState.trainUnit(id: "rome-archer-1")
    expect((trainingState.unit(withID: "rome-archer-1")?.experience ?? 0) > 0, "Training should add experience")

    var generalState = GameState.newCampaign()
    _ = try generalState.appointGeneral(unitID: "rome-archer-1")
    expect(generalState.unit(withID: "rome-archer-1")?.generalName != nil, "General should be appointed")
    expect(generalState.unit(withID: "rome-archer-1")?.resolvedGeneralTrait != nil, "General should receive a trait")

    var orderState = GameState.newCampaign()
    orderState.units.append(ArmyUnit(id: "near-carthage", kind: .archer, faction: .carthage, position: Position(x: 4, y: 3), health: 60))
    let balancedPreview = try orderState.attackPreview(attackerID: "rome-legion-1", defenderID: "near-carthage")
    _ = try orderState.setTacticalOrder(unitID: "rome-legion-1", order: .assault)
    let assaultPreview = try orderState.attackPreview(attackerID: "rome-legion-1", defenderID: "near-carthage")
    expect(assaultPreview.damage > balancedPreview.damage, "Assault order should increase damage preview")
    _ = try orderState.setTacticalOrder(unitID: "rome-legion-1", order: .forcedMarch)
    expect(orderState.unit(withID: "rome-legion-1")?.resolvedTacticalOrder == .forcedMarch, "Forced march order should be stored")

    var supportState = GameState.newCampaign()
    supportState.units = [
        ArmyUnit(id: "rome-attacker", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), experience: 1, generalName: "凯撒", generalTrait: .eagleStandard),
        ArmyUnit(id: "rome-support", kind: .legion, faction: .rome, position: Position(x: 2, y: 3)),
        ArmyUnit(id: "rome-flanker", kind: .cavalry, faction: .rome, position: Position(x: 4, y: 3)),
        ArmyUnit(id: "rome-second-flanker", kind: .archer, faction: .rome, position: Position(x: 3, y: 4)),
        ArmyUnit(id: "carthage-defender", kind: .archer, faction: .carthage, position: Position(x: 4, y: 4), health: 60),
        ArmyUnit(id: "carthage-support", kind: .legion, faction: .carthage, position: Position(x: 5, y: 4))
    ]
    let supportPreview = try supportState.attackPreview(attackerID: "rome-attacker", defenderID: "carthage-defender")
    expect(supportPreview.supportBonus > 0, "Friendly support should affect combat preview")
    expect(supportPreview.flankingBonus > 0, "Flanking should affect combat preview")
    expect(supportPreview.commandBonus > 0, "Command should affect combat preview")
    expect(supportPreview.defenderSupportBonus > 0, "Defender support should affect combat preview")

    var intentState = GameState.newCampaign()
    intentState.units = [
        ArmyUnit(id: "rome-target", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "carthage-hunter", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3), hasMoved: true, hasActed: true)
    ]
    let enemyIntent = intentState.aiIntents(for: .carthage, limit: 1).first
    expect(enemyIntent?.kind == .attack, "Enemy intent should predict a direct attack")
    expect(enemyIntent?.targetUnitID == "rome-target", "Enemy intent should identify the Roman target")
    expect(intentState.unit(withID: "carthage-hunter")?.hasActed == true, "Intent forecast should not mutate unit action state")

    var skillState = GameState.newCampaign()
    let damagedArcherIndex = skillState.units.firstIndex { $0.id == "rome-archer-1" }
    expect(damagedArcherIndex != nil, "Damaged ally should exist")
    skillState.units[damagedArcherIndex!].position = Position(x: 4, y: 3)
    skillState.units[damagedArcherIndex!].health = 30
    _ = try skillState.useGeneralSkill(unitID: "rome-legion-1")
    expect(skillState.unit(withID: "rome-archer-1")?.health == 42, "Eagle standard should restore nearby ally")
    expect(skillState.unit(withID: "rome-legion-1")?.hasActed == true, "General skill should consume action")

    var siegeSkillState = GameState.newCampaign()
    siegeSkillState.units = [
        ArmyUnit(id: "test-siege", kind: .legion, faction: .rome, position: Position(x: 7, y: 2), generalName: "苏拉", generalTrait: .siegeEngineer)
    ]
    let beforeFortification = siegeSkillState.city(withID: "alesia")?.fortification ?? 0
    _ = try siegeSkillState.useGeneralSkill(unitID: "test-siege")
    expect(siegeSkillState.city(withID: "alesia")?.fortification == beforeFortification - 4, "Siege skill should reduce enemy fortification")

    var diplomacyState = GameState.newCampaign()
    _ = try diplomacyState.sendEnvoy(to: .carthage)
    expect(diplomacyState.diplomaticStatus(between: .rome, and: .carthage) == .truce, "Envoy should create a truce")

    var turnState = GameState.newCampaign()
    let beforeTurn = turnState.turn
    _ = turnState.endTurn()
    expect(turnState.activeFaction == .carthage, "End turn should advance faction")
    expect(turnState.turn == beforeTurn, "Round should not increment until Rome acts again")

    print("Gameplay smoke test passed.")
} catch {
    print("FAIL: \(error)")
    fatalError("Gameplay smoke test threw \(error)")
}
