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
    let recruitmentPreview = try recruitmentState.recruitmentPreview(.legion, at: "rome")
    expect(recruitmentPreview.canRecruit, "Recruitment preview should allow legion in empty Rome")
    expect(recruitmentPreview.deploymentPosition == Position(x: 3, y: 3), "Recruitment preview should expose spawn position")
    _ = try recruitmentState.recruit(.legion, at: "rome")
    expect(recruitmentState.units.count == beforeRecruitment + 1, "Recruitment should add a unit")
    if let deploymentPosition = recruitmentPreview.deploymentPosition {
        expect(recruitmentState.unit(at: deploymentPosition)?.kind == .legion, "Recruitment should use previewed spawn position")
    } else {
        expect(false, "Recruitment preview should include a deployment position")
    }

    var cityPreviewState = GameState.newCampaign()
    let developmentPreview = try cityPreviewState.cityDevelopmentPreview(id: "rome")
    let beforeDevelopmentFortification = cityPreviewState.city(withID: "rome")?.fortification ?? 0
    expect(developmentPreview.canDevelop, "City development preview should be executable")
    expect(developmentPreview.productionIncrease.gold == 10, "City development preview should expose gold increase")
    _ = try cityPreviewState.developCity(id: "rome")
    expect(cityPreviewState.city(withID: "rome")?.fortification == beforeDevelopmentFortification + developmentPreview.fortificationIncrease, "City development should match preview")

    let harborPreviewState = GameState.newCampaign()
    let navyPreview = try harborPreviewState.recruitmentPreview(.navy, at: "neapolis")
    expect(navyPreview.canRecruit, "Navy preview should find Neapolis harbor")
    expect(navyPreview.deploymentPosition == Position(x: 4, y: 5), "Navy preview should expose adjacent harbor")

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
    expect(enemyIntent?.destination == Position(x: 4, y: 3), "Direct intent should expose the attacker origin as destination for UI overlays")
    expect((enemyIntent?.projectedDamage ?? 0) > 0, "Direct intent should expose projected damage")
    if let enemyIntent {
        var directIntentPreviewState = intentState
        directIntentPreviewState.activeFaction = .carthage
        let hunterIndex = directIntentPreviewState.units.firstIndex { $0.id == "carthage-hunter" }
        expect(hunterIndex != nil, "Direct intent attacker should exist")
        directIntentPreviewState.units[hunterIndex!].hasMoved = false
        directIntentPreviewState.units[hunterIndex!].hasActed = false
        directIntentPreviewState.units[hunterIndex!].tacticalOrder = enemyIntent.tacticalOrder == .balanced ? nil : enemyIntent.tacticalOrder
        let directIntentPreview = try directIntentPreviewState.attackPreview(attackerID: "carthage-hunter", defenderID: "rome-target")
        expect(enemyIntent.projectedDamage == directIntentPreview.damage, "Direct intent damage should match combat preview")
    }
    expect(intentState.unit(withID: "carthage-hunter")?.hasActed == true, "Intent forecast should not mutate unit action state")

    var advanceIntentState = GameState.newCampaign()
    advanceIntentState.units = [
        ArmyUnit(id: "rome-target", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "carthage-hunter", kind: .cavalry, faction: .carthage, position: Position(x: 7, y: 2)),
        ArmyUnit(id: "carthage-support-north", kind: .legion, faction: .carthage, position: Position(x: 3, y: 1), hasMoved: true, hasActed: true),
        ArmyUnit(id: "carthage-support-east", kind: .legion, faction: .carthage, position: Position(x: 5, y: 4), hasMoved: true, hasActed: true),
        ArmyUnit(id: "carthage-support-south", kind: .legion, faction: .carthage, position: Position(x: 2, y: 4), hasMoved: true, hasActed: true)
    ]
    for index in advanceIntentState.cities.indices where advanceIntentState.cities[index].owner != .rome {
        advanceIntentState.cities[index].owner = .carthage
    }
    if let romeIndex = advanceIntentState.cities.firstIndex(where: { $0.id == "rome" }) {
        advanceIntentState.cities[romeIndex].position = Position(x: 0, y: 0)
    }
    advanceIntentState.resources[.carthage] = .zero
    let advanceIntent = advanceIntentState.aiIntents(for: .carthage, limit: 4).first { $0.unitID == "carthage-hunter" }
    expect(advanceIntent?.kind == .advanceAttack, "Enemy intent should predict a move-then-attack")
    expect(advanceIntent?.targetUnitID == "rome-target", "Advance attack intent should identify the Roman target")
    expect(advanceIntent?.destination != nil, "Advance attack intent should expose a destination for UI route overlays")
    expect((advanceIntent?.projectedDamage ?? 0) > 0, "Advance attack intent should expose projected damage")
    if let advanceIntent, let destination = advanceIntent.destination {
        var advancePreviewState = advanceIntentState
        advancePreviewState.activeFaction = .carthage
        let hunterIndex = advancePreviewState.units.firstIndex { $0.id == "carthage-hunter" }
        expect(hunterIndex != nil, "Advance intent attacker should exist")
        advancePreviewState.units[hunterIndex!].position = destination
        advancePreviewState.units[hunterIndex!].hasMoved = true
        advancePreviewState.units[hunterIndex!].hasActed = false
        advancePreviewState.units[hunterIndex!].tacticalOrder = advanceIntent.tacticalOrder == .balanced ? nil : advanceIntent.tacticalOrder
        let advancePreview = try advancePreviewState.attackPreview(attackerID: "carthage-hunter", defenderID: "rome-target")
        expect(advancePreview.supportBonus > 0, "Advance preview should include moved-position support")
        expect(advanceIntent.projectedDamage == advancePreview.damage, "Advance attack intent damage should match combat preview")

        var aiResolutionState = advanceIntentState
        aiResolutionState.activeFaction = .carthage
        let beforeHealth = aiResolutionState.unit(withID: "rome-target")?.health ?? 0
        _ = aiResolutionState.performSimpleAI(for: .carthage)
        expect(aiResolutionState.unit(withID: "rome-target")?.health == beforeHealth - advancePreview.damage, "AI resolution damage should match advance attack intent")
    }
    expect(advanceIntentState.unit(withID: "carthage-hunter")?.position == Position(x: 7, y: 2), "Advance intent forecast should not move the source unit")

    var captureIntentState = GameState.newCampaign()
    captureIntentState.units = [
        ArmyUnit(id: "carthage-capturer", kind: .cavalry, faction: .carthage, position: Position(x: 6, y: 2))
    ]
    for index in captureIntentState.cities.indices where captureIntentState.cities[index].id != "massilia" {
        captureIntentState.cities[index].owner = .carthage
    }
    let captureBefore = captureIntentState
    let captureIntent = captureIntentState.aiIntents(for: .carthage, limit: 1).first
    expect(captureIntent?.kind == .captureCity, "Enemy intent should predict city capture")
    expect(captureIntent?.targetCityID == "massilia", "Capture intent should identify target city")
    expect(captureIntent?.destination == Position(x: 5, y: 2), "Capture intent should expose destination for UI route overlays")
    expect(captureIntentState == captureBefore, "Capture intent forecast should not mutate state")

    var pressureState = GameState.newCampaign()
    pressureState.units = [
        ArmyUnit(id: "rome-target", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "carthage-east", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3)),
        ArmyUnit(id: "carthage-north", kind: .legion, faction: .carthage, position: Position(x: 3, y: 2))
    ]
    let pressureBefore = pressureState
    let pressureIntents = pressureState.aiIntents(for: .carthage, limit: 4)
    let pressureExpectedDamage = pressureIntents
        .filter { $0.targetUnitID == "rome-target" }
        .reduce(0) { partial, intent in partial + (intent.projectedDamage ?? 0) }
    let pressureReport = pressureState.frontlinePressureReports(against: .rome, perFactionLimit: 4, limit: 2).first
    expect(pressureReport?.targetID == "rome-target", "Frontline pressure should identify the focused Roman target")
    expect(Set(pressureReport?.sourceUnitIDs ?? []) == Set(["carthage-east", "carthage-north"]), "Frontline pressure should aggregate multiple source units")
    expect(pressureReport?.attackIntentCount == 2, "Frontline pressure should count incoming attack intents")
    expect(pressureReport?.projectedDamageTotal == pressureExpectedDamage, "Frontline pressure damage should sum AI intent damage")
    expect(pressureReport?.level == .critical, "Multiple incoming attacks should mark critical pressure")
    expect(pressureState == pressureBefore, "Frontline pressure forecast should not mutate state")

    var skillState = GameState.newCampaign()
    let damagedArcherIndex = skillState.units.firstIndex { $0.id == "rome-archer-1" }
    expect(damagedArcherIndex != nil, "Damaged ally should exist")
    skillState.units[damagedArcherIndex!].position = Position(x: 4, y: 3)
    skillState.units[damagedArcherIndex!].health = 30
    let skillPreviewState = skillState
    let skillPreview = try skillState.generalSkillPreview(unitID: "rome-legion-1")
    expect(skillState == skillPreviewState, "General skill preview should not mutate state")
    expect(skillPreview.affectedUnitIDs == ["rome-archer-1"], "General skill preview should identify affected ally")
    expect(skillPreview.projectedRecoveredHealth == 12, "General skill preview should project recovery")
    _ = try skillState.useGeneralSkill(unitID: "rome-legion-1")
    expect(skillState.unit(withID: "rome-archer-1")?.health == 30 + skillPreview.projectedRecoveredHealth, "Eagle standard should match recovery preview")
    expect(skillState.unit(withID: "rome-legion-1")?.hasActed == true, "General skill should consume action")
    expect(skillState.unit(withID: "rome-legion-1")?.generalSkillCooldownRemaining == 2, "General skill should start cooldown")
    let commanderIndex = skillState.units.firstIndex { $0.id == "rome-legion-1" }
    expect(commanderIndex != nil, "Commander should exist after skill")
    skillState.units[commanderIndex!].hasActed = false
    let cooldownPreview = try skillState.generalSkillPreview(unitID: "rome-legion-1")
    expect(!cooldownPreview.isExecutable, "Cooldown preview should block skill reuse")
    expect(cooldownPreview.cooldownRemaining == 2, "Cooldown preview should report remaining turns")
    _ = skillState.endTurn()
    expect(skillState.unit(withID: "rome-legion-1")?.generalSkillCooldownRemaining == 2, "Enemy turn start should not tick Roman cooldown")
    _ = skillState.endTurn()
    _ = skillState.endTurn()
    _ = skillState.endTurn()
    expect(skillState.activeFaction == .rome, "Cooldown smoke should return to Rome")
    expect(skillState.unit(withID: "rome-legion-1")?.generalSkillCooldownRemaining == 1, "Roman turn start should tick Roman cooldown once")
    let warMerit = skillState.warMeritStatus(for: skillState.unit(withID: "rome-legion-1")!)
    expect(warMerit.damageBonus == warMerit.experience * 3, "War merit damage bonus should match experience formula")
    expect(!warMerit.rankName.isEmpty, "War merit should expose a readable rank")

    var formationState = GameState.newCampaign()
    formationState.units = [
        ArmyUnit(id: "rome-commander", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), experience: 4, generalName: "凯撒", generalTrait: .eagleStandard),
        ArmyUnit(id: "rome-support", kind: .archer, faction: .rome, position: Position(x: 4, y: 3), health: 50),
        ArmyUnit(id: "carthage-near", kind: .cavalry, faction: .carthage, position: Position(x: 3, y: 2))
    ]
    let formationBefore = formationState
    let formationReport = try formationState.legionFormationReport(unitID: "rome-commander")
    expect(formationReport.role == .command, "Formation report should identify commander role")
    expect(formationReport.readiness == .engaged, "Formation report should expose readiness")
    expect(formationReport.rankName == "百夫长", "Formation report should expose war merit rank")
    expect(formationReport.adjacentAllyCount == 1, "Formation report should count adjacent allies")
    expect(formationReport.nearbyEnemyCount == 1, "Formation report should count nearby enemies")
    expect(formationReport.skillReady, "Formation report should detect useful ready skill")
    expect(!formationReport.commandSuggestion.isEmpty, "Formation report should expose a command suggestion")
    expect(formationState == formationBefore, "Formation report should not mutate state")

    var recommendationState = GameState.newCampaign()
    recommendationState.units = [
        ArmyUnit(id: "rome-line", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "rome-reserve", kind: .legion, faction: .rome, position: Position(x: 1, y: 3)),
        ArmyUnit(id: "carthage-east", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3)),
        ArmyUnit(id: "carthage-north", kind: .legion, faction: .carthage, position: Position(x: 3, y: 2))
    ]
    recommendationState.activeFaction = .rome
    let recommendationBefore = recommendationState
    let recommendation = try recommendationState.tacticalRecommendation(unitID: "rome-reserve")
    expect(recommendation.kind == .reinforce, "Tactical recommendation should identify reinforcement opportunities")
    expect(recommendation.targetUnitID == "rome-line", "Tactical recommendation should point to the pressured Roman line")
    expect(recommendation.destination.hexDistance(to: recommendation.targetPosition) < Position(x: 1, y: 3).hexDistance(to: recommendation.targetPosition), "Tactical recommendation should move closer to the pressured target")
    expect(!recommendation.path.isEmpty, "Tactical recommendation should expose a map path")
    expect(!recommendation.command.isEmpty, "Tactical recommendation should expose a command sentence")
    expect(recommendationState == recommendationBefore, "Tactical recommendation should not mutate state")

    var siegeSkillState = GameState.newCampaign()
    siegeSkillState.units = [
        ArmyUnit(id: "test-siege", kind: .legion, faction: .rome, position: Position(x: 7, y: 2), generalName: "苏拉", generalTrait: .siegeEngineer)
    ]
    let beforeFortification = siegeSkillState.city(withID: "alesia")?.fortification ?? 0
    let siegePreview = try siegeSkillState.generalSkillPreview(unitID: "test-siege")
    expect(siegePreview.affectedCityIDs == ["alesia"], "Siege preview should identify affected city")
    expect(siegePreview.projectedFortificationReduction == 4, "Siege preview should project fortification reduction")
    _ = try siegeSkillState.useGeneralSkill(unitID: "test-siege")
    expect(siegeSkillState.city(withID: "alesia")?.fortification == beforeFortification - siegePreview.projectedFortificationReduction, "Siege skill should match fortification preview")

    var diplomacyState = GameState.newCampaign()
    _ = try diplomacyState.sendEnvoy(to: .carthage)
    expect(diplomacyState.diplomaticStatus(between: .rome, and: .carthage) == .truce, "Envoy should create a truce")

    var turnState = GameState.newCampaign()
    let beforeTurn = turnState.turn
    _ = turnState.endTurn()
    expect(turnState.activeFaction == .carthage, "End turn should advance faction")
    expect(turnState.turn == beforeTurn, "Round should not increment until Rome acts again")

    var victoryState = GameState.newCampaign()
    for index in victoryState.cities.indices where ["syracuse", "carthage"].contains(victoryState.cities[index].id) {
        victoryState.cities[index].owner = .rome
    }
    victoryState.units.append(ArmyUnit(id: "rome-smoke-extra", kind: .legion, faction: .rome, position: Position(x: 1, y: 1)))
    let victoryMessages = try victoryState.recruit(.archer, at: "rome")
    expect(victoryState.campaignStatus.kind == .romanVictory, "Completed objectives should create Roman victory")
    expect(victoryMessages.contains { $0.contains("战役胜利") }, "Victory message should be emitted")
    expect(victoryState.endTurn() == [GameRuleError.campaignAlreadyEnded.displayMessage], "Ended campaign should block turn advance")

    var defeatState = GameState.newCampaign()
    for index in defeatState.cities.indices where defeatState.cities[index].owner == .rome {
        defeatState.cities[index].owner = .carthage
    }
    expect(defeatState.campaignStatus.kind == .romanDefeat, "Losing all Roman cities should create defeat")

    print("Gameplay smoke test passed.")
} catch {
    print("FAIL: \(error)")
    fatalError("Gameplay smoke test threw \(error)")
}
