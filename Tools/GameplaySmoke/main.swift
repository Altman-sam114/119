func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        print("FAIL: \(message)")
        fatalError(message)
    }
}

// Isolated v0.70 fixtures: one acting enemy, no recruitment/rest budget,
// no ready skill, no city combat modifiers, and no other enemy first strike.
func aiTacticalActionSmokeFixture(order: TacticalOrder) -> GameState {
    var state = GameState.newCampaign()
    state.tiles = state.tiles.map { Tile(position: $0.position, terrain: .plains) }
    state.cities = [
        City(id: "rome", name: "罗马", position: Position(x: 11, y: 7),
             owner: .rome, production: .zero, fortification: 0)
    ]
    state.resources[.carthage] = .zero
    state.researchedTechnologies[.carthage] = []
    state.researchedTechnologies[.rome] = []
    state.activeFaction = .rome
    let origin = order == .forcedMarch ? Position(x: 1, y: 1) : Position(x: 3, y: 3)
    state.units = [
        ArmyUnit(id: "tactical-commander", kind: .legion, faction: .carthage,
                 position: origin, health: order == .defensive ? 10 : 100,
                 generalName: "战术夹具将领", generalTrait: .siegeEngineer,
                 generalSkillCooldownRemaining: 3),
        ArmyUnit(id: "tactical-target", kind: order == .defensive ? .cavalry : .legion,
                 faction: .rome,
                 position: order == .forcedMarch ? Position(x: 7, y: 1) : Position(x: 4, y: 3),
                 health: order == .assault ? 25 : (order == .defensive ? 88 : 12))
    ]
    if order == .assault {
        state.units.append(ArmyUnit(id: "tactical-decoy", kind: .archer, faction: .rome,
                                   position: Position(x: 2, y: 3), health: 72, experience: 10,
                                   generalName: "高价值非致死目标", generalTrait: .siegeEngineer))
    }
    if order == .forcedMarch {
        state.tiles = state.tiles.map { tile in
            let isCorridor = tile.position.y == 1 && (1...7).contains(tile.position.x)
            let isRomanCity = tile.position == Position(x: 11, y: 7)
            return Tile(position: tile.position, terrain: isCorridor || isRomanCity ? .plains : .water)
        }
    }
    return state
}

func verifyAITacticalActionSmoke(order: TacticalOrder) throws {
    let state = aiTacticalActionSmokeFixture(order: order)
    let before = state
    let commanderID = "tactical-commander"
    let targetID = "tactical-target"
    let intents = state.aiIntents(for: .carthage, limit: 4)
    guard let intent = intents.first(where: { $0.unitID == commanderID }),
          let origin = state.unit(withID: commanderID)?.position,
          let destination = intent.destination else {
        expect(false, "AI tactical action smoke requires a selected intent and landing")
        return
    }
    expect(intents.count == 1, "Tactical fixture should isolate a single acting enemy")
    expect(intent.tacticalOrder == order, "AI tactical candidate should select the proven posture")
    expect(intent.targetUnitID == targetID, "AI tactical candidate should select the proven target")
    expect(intent.kind == (order == .forcedMarch ? .advanceAttack : .attack), "Tactical fixture should preserve attack tier")

    var projection = state
    projection.activeFaction = .carthage
    let blockedSkillPreview = try projection.generalSkillPreview(unitID: commanderID)
    expect(!blockedSkillPreview.isExecutable, "Tactical fixture must exclude skills")
    if order == .forcedMarch {
        expect(projection.attackTargets(for: commanderID).isEmpty, "March fixture must exclude direct attacks")
        expect(destination == Position(x: 6, y: 1), "March should select the corridor's only attack landing")
        for alternative in [TacticalOrder.balanced, .assault, .defensive] {
            var alternativeState = projection
            _ = try alternativeState.setTacticalOrder(unitID: commanderID, order: alternative)
            expect(!alternativeState.reachablePositions(for: commanderID).contains(destination), "Only march budget should reach the attack landing")
        }
    } else {
        expect(destination == origin, "Direct tactical attack must not move before attacking")
        var previews: [TacticalOrder: CombatPreview] = [:]
        for alternative in TacticalOrder.allCases {
            var alternativeState = projection
            _ = try alternativeState.setTacticalOrder(unitID: commanderID, order: alternative)
            previews[alternative] = try alternativeState.attackPreview(attackerID: commanderID, defenderID: targetID)
            if order == .assault {
                let decoyPreview = try alternativeState.attackPreview(attackerID: commanderID, defenderID: "tactical-decoy")
                expect(!decoyPreview.defeatsDefender, "High-value competing target must remain nonlethal in every posture")
            }
        }
        if order == .assault {
            expect(previews[.assault]?.defeatsDefender == true, "Assault fixture must prove a kill")
            expect([TacticalOrder.balanced, .defensive, .forcedMarch].allSatisfy { previews[$0]?.defeatsDefender == false }, "Only assault may kill the chosen target")
        } else {
            expect(previews.values.allSatisfy { !$0.defeatsDefender }, "Survival fixture must exclude every kill candidate")
            expect(previews[.assault]?.attackerFalls == true, "Assault counterattack must kill the survival fixture attacker")
            expect(previews[.defensive]?.attackerFalls == false, "Defensive counterattack must preserve the attacker")
            expect((previews[.defensive]?.retaliation ?? 0) < (previews[.assault]?.retaliation ?? 0), "Defensive survival must come from reduced previewed retaliation")
        }
    }
    _ = try projection.setTacticalOrder(unitID: commanderID, order: intent.tacticalOrder)
    if destination != origin {
        expect(projection.reachablePositions(for: commanderID).contains(destination), "Chosen march landing must be truly reachable")
        expect(projection.reachablePositions(for: commanderID).allSatisfy { projection.tile(at: $0)?.terrain == .plains && projection.unit(at: $0) == nil }, "March must not cross water or enter occupied tiles")
        _ = try projection.moveUnit(id: commanderID, to: destination)
    }
    let preview = try projection.attackPreview(attackerID: commanderID, defenderID: targetID)
    expect(intent.projectedDamage == preview.damage, "Tactical intent damage must reuse the chosen combat preview")
    let plans = state.aiOperationalPlanReports(against: .rome, perFactionLimit: 4, limit: 5)
    let step = plans.flatMap { $0.steps }.first { $0.unitID == commanderID }
    let threats = state.enemyCommanderThreatReports(against: .rome, limit: 5)
    let threat = threats.first { $0.unitID == commanderID }
    expect(step?.intentKind == intent.kind && step?.tacticalOrder == intent.tacticalOrder, "Plan must reuse tactical kind and posture")
    expect(step?.origin == origin && step?.destination == destination && step?.targetUnitID == targetID, "Plan must reuse tactical origin, landing and target")
    expect(step?.projectedDamage == preview.damage && threat?.projectedDamage == preview.damage, "Plan and threat damage must equal the unique preview")
    expect(threat?.intentKind == intent.kind && threat?.position == origin && threat?.destination == destination && threat?.targetUnitID == targetID, "Enemy commander threat must reuse the tactical action")
    expect(step?.targetPosition == state.unit(withID: targetID)?.position && threat?.targetPosition == step?.targetPosition, "Plan and threat must point to the actual target tile")
    expect(state.aiIntents(for: .carthage, limit: 4) == intents, "Tactical intent reads must be deterministic")
    expect(state.aiOperationalPlanReports(against: .rome, perFactionLimit: 4, limit: 5) == plans, "Tactical plan reads must be deterministic")
    expect(state.enemyCommanderThreatReports(against: .rome, limit: 5) == threats && state == before, "Tactical threat reads must be deterministic and pure")

    var resolution = state
    resolution.activeFaction = .carthage
    _ = resolution.performSimpleAI(for: .carthage)
    expect(resolution.unit(withID: commanderID)?.resolvedTacticalOrder == intent.tacticalOrder, "Real AI must execute the previewed posture")
    expect(resolution.unit(withID: commanderID)?.position == destination, "Real AI must execute the previewed landing")
    expect(resolution.unit(withID: commanderID)?.health == preview.attackerRemainingHealth, "Real AI retaliation must equal the chosen preview")
    expect(resolution.unit(withID: commanderID)?.hasActed == true && resolution.unit(withID: commanderID)?.hasMoved == true, "Real AI attack must consume both action flags")
    expect(resolution.unit(withID: commanderID)?.generalSkillCooldownRemaining == 3, "Real tactical attack must not refresh or consume skill cooldown")
    if preview.defeatsDefender {
        expect(resolution.unit(withID: targetID) == nil && preview.retaliation == 0, "Previewed kill must remove only the target without retaliation")
    } else {
        expect(resolution.unit(withID: targetID)?.health == preview.defenderRemainingHealth, "Real AI target health must equal previewed damage")
    }
    expect(resolution.unit(withID: "tactical-decoy") == state.unit(withID: "tactical-decoy"), "AI must leave the competing nonlethal target untouched")
}

do {
    try verifyAITacticalActionSmoke(order: .assault)
    try verifyAITacticalActionSmoke(order: .defensive)
    try verifyAITacticalActionSmoke(order: .forcedMarch)

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
    let trainingIndex = trainingState.units.firstIndex { $0.id == "rome-archer-1" }
    expect(trainingIndex != nil, "Training target should exist")
    trainingState.units[trainingIndex!].health = 52
    let trainingBeforePreview = trainingState
    let trainingPreview = try trainingState.trainingPreview(unitID: "rome-archer-1")
    expect(trainingState == trainingBeforePreview, "Training preview should not mutate state")
    expect(trainingPreview.canTrain, "Training preview should be executable")
    expect(trainingPreview.projectedExperience == 1, "Training preview should project experience")
    expect(trainingPreview.projectedRecoveredHealth == 18, "Training preview should project recovery")
    _ = try trainingState.trainUnit(id: "rome-archer-1")
    expect(trainingState.unit(withID: "rome-archer-1")?.experience == trainingPreview.projectedExperience, "Training should add previewed experience")
    expect(trainingState.unit(withID: "rome-archer-1")?.health == trainingPreview.projectedHealth, "Training should apply previewed recovery")

    var generalState = GameState.newCampaign()
    let appointmentBeforePreview = generalState
    let appointmentPreview = try generalState.generalAppointmentPreview(unitID: "rome-archer-1")
    expect(generalState == appointmentBeforePreview, "Appointment preview should not mutate state")
    expect(appointmentPreview.canAppoint, "Appointment preview should be executable")
    expect(appointmentPreview.candidateName == "庞培", "Appointment preview should expose candidate")
    expect(appointmentPreview.candidateTrait == .eagleStandard, "Appointment preview should expose candidate trait")
    _ = try generalState.appointGeneral(unitID: "rome-archer-1")
    expect(generalState.unit(withID: "rome-archer-1")?.generalName == appointmentPreview.candidateName, "General should match appointment preview")
    expect(generalState.unit(withID: "rome-archer-1")?.resolvedGeneralTrait == appointmentPreview.candidateTrait, "General trait should match appointment preview")

    var developmentState = GameState.newCampaign()
    let developmentBeforeReports = developmentState
    let developmentReports = developmentState.unitDevelopmentRecommendationReports(for: .rome, limit: 10)
    expect(developmentState == developmentBeforeReports, "Development recommendations should not mutate state")
    expect(developmentReports.contains { $0.kind == .training }, "Development recommendations should include training")
    expect(developmentReports.contains { $0.kind == .appointment }, "Development recommendations should include appointment")
    let developmentTrainingPreview = try developmentState.trainingPreview(unitID: "rome-archer-1")
    let developmentAppointmentPreview = try developmentState.generalAppointmentPreview(unitID: "rome-archer-1")
    let archerTrainingReport = developmentReports.first { $0.unitID == "rome-archer-1" && $0.kind == .training }
    expect(archerTrainingReport?.cost == developmentTrainingPreview.cost, "Training recommendation should reuse training preview cost")
    let archerAppointmentReport = developmentReports.first { $0.unitID == "rome-archer-1" && $0.kind == .appointment }
    expect(archerAppointmentReport?.candidateName == developmentAppointmentPreview.candidateName, "Appointment recommendation should reuse appointment preview candidate")
    let selectedDevelopmentReport = try developmentState.unitDevelopmentRecommendationReport(unitID: "rome-archer-1")
    expect(selectedDevelopmentReport.unitID == "rome-archer-1", "Selected development recommendation should target requested unit")

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
        ArmyUnit(id: "carthage-low", kind: .archer, faction: .carthage, position: Position(x: 11, y: 0)),
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
        let aiMessages = aiResolutionState.performSimpleAI(for: .carthage)
        expect(aiMessages.first?.contains("骑兵") == true, "AI should execute the highest-threat cavalry before lower-threat units")
        expect(aiResolutionState.unit(withID: "rome-target")?.health == beforeHealth - advancePreview.damage, "AI resolution damage should match advance attack intent")
    }
    expect(advanceIntentState.unit(withID: "carthage-hunter")?.position == Position(x: 7, y: 2), "Advance intent forecast should not move the source unit")

    var moveSkillState = GameState.newCampaign()
    moveSkillState.tiles = moveSkillState.tiles.map { Tile(position: $0.position, terrain: .plains) }
    moveSkillState.cities = [
        City(
            id: "rome",
            name: "罗马",
            position: Position(x: 11, y: 7),
            owner: .rome,
            production: EmpireResources(gold: 40, grain: 30, iron: 20, science: 10, prestige: 2),
            fortification: 12
        )
    ]
    moveSkillState.units = [
        ArmyUnit(id: "rome-observer", kind: .legion, faction: .rome, position: Position(x: 11, y: 6)),
        ArmyUnit(
            id: "carthage-quartermaster",
            kind: .legion,
            faction: .carthage,
            position: Position(x: 1, y: 1),
            generalName: "阿格里帕",
            generalTrait: .quartermaster
        ),
        ArmyUnit(
            id: "carthage-wounded",
            kind: .cavalry,
            faction: .carthage,
            position: Position(x: 8, y: 2),
            health: 30,
            hasMoved: true,
            hasActed: true
        )
    ]
    moveSkillState.resources[.carthage] = .zero
    moveSkillState.activeFaction = .rome
    let moveSkillBefore = moveSkillState
    let moveSkillIntent = moveSkillState.aiIntents(for: .carthage, limit: 4)
        .first { $0.unitID == "carthage-quartermaster" }
    expect(moveSkillIntent?.kind == .useSkill, "AI intent should predict move-then-general-skill")
    expect(moveSkillIntent?.tacticalOrder == .forcedMarch, "Move-skill fixture should require the intent tactical order")
    expect(moveSkillIntent?.destination != Position(x: 1, y: 1), "Move-skill intent should expose a landing position")
    expect(moveSkillIntent?.targetUnitID == "carthage-wounded", "Move-skill intent should expose the post-move beneficiary")
    if let moveSkillIntent, let destination = moveSkillIntent.destination {
        var moveSkillReachabilityState = moveSkillState
        moveSkillReachabilityState.activeFaction = .carthage
        expect(
            !moveSkillReachabilityState.reachablePositions(for: moveSkillIntent.unitID).contains(destination),
            "Move-skill landing should require the forecast tactical order"
        )
        let reachabilityCommanderIndex = moveSkillReachabilityState.units.firstIndex { $0.id == moveSkillIntent.unitID }
        expect(reachabilityCommanderIndex != nil, "Move-skill reachability commander should exist")
        moveSkillReachabilityState.units[reachabilityCommanderIndex!].tacticalOrder = moveSkillIntent.tacticalOrder
        expect(
            moveSkillReachabilityState.reachablePositions(for: moveSkillIntent.unitID).contains(destination),
            "Move-skill landing should be reachable with the forecast tactical order"
        )

        var moveSkillPreviewState = moveSkillState
        moveSkillPreviewState.activeFaction = .carthage
        let commanderIndex = moveSkillPreviewState.units.firstIndex { $0.id == "carthage-quartermaster" }
        expect(commanderIndex != nil, "Move-skill commander should exist")
        moveSkillPreviewState.units[commanderIndex!].position = destination
        moveSkillPreviewState.units[commanderIndex!].hasMoved = true
        moveSkillPreviewState.units[commanderIndex!].hasActed = false
        moveSkillPreviewState.units[commanderIndex!].tacticalOrder = moveSkillIntent.tacticalOrder == .balanced ? nil : moveSkillIntent.tacticalOrder
        let moveSkillPreview = try moveSkillPreviewState.generalSkillPreview(unitID: "carthage-quartermaster")
        expect(moveSkillPreview.origin == destination, "Move-skill preview should originate at the landing position")
        expect(moveSkillPreview.projectedRecoveredHealth == 22, "Move-skill preview should expose landing recovery")
        expect(moveSkillPreview.affectedUnitIDs == ["carthage-wounded"], "Move-skill preview should expose landing beneficiaries")

        let moveSkillPlan = moveSkillState.aiOperationalPlanReports(against: .rome, perFactionLimit: 4, limit: 5)
            .first { $0.kind == .commanderSkill && $0.sourceUnitIDs.contains("carthage-quartermaster") }
        let moveSkillStep = moveSkillPlan?.steps.first { $0.unitID == "carthage-quartermaster" }
        let moveSkillThreat = moveSkillState.enemyCommanderThreatReports(against: .rome, limit: 5)
            .first { $0.unitID == "carthage-quartermaster" }
        expect(moveSkillStep?.destination == destination, "AI plan should reuse the move-skill landing position")
        expect(moveSkillStep?.targetUnitID == "carthage-wounded", "AI plan should reuse the move-skill target")
        expect(moveSkillStep?.skillSummary == moveSkillPreview.summary, "AI plan should reuse the post-move skill summary")
        expect(moveSkillThreat?.destination == destination, "Enemy commander threat should reuse the move-skill landing position")
        expect(moveSkillThreat?.projectedRecovery == moveSkillPreview.projectedRecoveredHealth, "Enemy commander threat should reuse landing recovery")
        expect(moveSkillThreat?.affectedUnitIDs == moveSkillPreview.affectedUnitIDs, "Enemy commander threat should reuse landing beneficiaries")
        expect(moveSkillThreat?.rangePositions == moveSkillPreview.rangePositions, "Enemy commander threat should reuse landing range")
        expect(moveSkillThreat?.affectedPositions == moveSkillPreview.affectedPositions, "Enemy commander threat should reuse landing impact positions")
        expect(moveSkillState == moveSkillBefore, "Move-skill intent, plan, and threat reads should not mutate state")

        var moveSkillResolution = moveSkillState
        moveSkillResolution.activeFaction = .carthage
        let moveSkillMessages = moveSkillResolution.performSimpleAI(for: .carthage)
        expect(moveSkillResolution.unit(withID: "carthage-quartermaster")?.position == destination, "AI should move to the previewed skill landing position")
        expect(moveSkillResolution.unit(withID: "carthage-quartermaster")?.generalSkillCooldownRemaining == 2, "Move-skill resolution should start cooldown")
        expect(moveSkillResolution.unit(withID: "carthage-wounded")?.health == 30 + moveSkillPreview.projectedRecoveredHealth, "Move-skill resolution should match previewed recovery")
        expect(moveSkillMessages.contains { $0.contains("战地补给") }, "Move-skill resolution should emit the general skill message")
    }

    var moveSkillKillState = moveSkillState
    moveSkillKillState.units = [
        ArmyUnit(id: "rome-kill", kind: .archer, faction: .rome, position: Position(x: 3, y: 3), health: 1),
        ArmyUnit(
            id: "carthage-quartermaster",
            kind: .legion,
            faction: .carthage,
            position: Position(x: 4, y: 3),
            generalName: "阿格里帕",
            generalTrait: .quartermaster
        ),
        ArmyUnit(id: "carthage-wounded", kind: .cavalry, faction: .carthage, position: Position(x: 8, y: 3), health: 30, hasMoved: true, hasActed: true)
    ]
    var profitableMoveSkillState = moveSkillKillState
    profitableMoveSkillState.activeFaction = .carthage
    let profitableCommanderIndex = profitableMoveSkillState.units.firstIndex { $0.id == "carthage-quartermaster" }
    expect(profitableCommanderIndex != nil, "Kill-priority commander should exist")
    expect(
        profitableMoveSkillState.reachablePositions(for: "carthage-quartermaster")
            .contains(Position(x: 6, y: 3)),
        "Kill-priority move-skill landing should be legally reachable"
    )
    profitableMoveSkillState.units[profitableCommanderIndex!].position = Position(x: 6, y: 3)
    profitableMoveSkillState.units[profitableCommanderIndex!].hasMoved = true
    let profitableMoveSkillPreview = try profitableMoveSkillState.generalSkillPreview(unitID: "carthage-quartermaster")
    expect(profitableMoveSkillPreview.projectedRecoveredHealth == 22, "Kill-priority fixture should prove a profitable move-skill exists")
    let killPriorityIntent = moveSkillKillState.aiIntents(for: .carthage, limit: 4)
        .first { $0.unitID == "carthage-quartermaster" }
    expect(killPriorityIntent?.kind == .attack, "Immediate kill should outrank profitable move-skill")
    expect(killPriorityIntent?.targetUnitID == "rome-kill", "Immediate kill should preserve the lethal target")
    moveSkillKillState.activeFaction = .carthage
    _ = moveSkillKillState.performSimpleAI(for: .carthage)
    expect(moveSkillKillState.unit(withID: "rome-kill") == nil, "AI should execute the immediate kill")
    expect(moveSkillKillState.unit(withID: "carthage-wounded")?.health == 30, "Immediate kill should not execute the move-skill")

    var campaignEndMoveSkillState = GameState.newCampaign()
    let campaignEndLand: Set<Position> = [
        Position(x: 1, y: 1), Position(x: 2, y: 1), Position(x: 3, y: 1),
        Position(x: 5, y: 1), Position(x: 7, y: 7)
    ]
    campaignEndMoveSkillState.tiles = campaignEndMoveSkillState.tiles.map { tile in
        Tile(position: tile.position, terrain: campaignEndLand.contains(tile.position) ? .plains : .water)
    }
    campaignEndMoveSkillState.cities = [
        City(
            id: "rome",
            name: "罗马",
            position: Position(x: 3, y: 1),
            owner: .rome,
            production: EmpireResources(gold: 40, grain: 30, iron: 20, science: 10, prestige: 2),
            fortification: 12
        )
    ]
    campaignEndMoveSkillState.units = [
        ArmyUnit(id: "rome-observer", kind: .legion, faction: .rome, position: Position(x: 7, y: 7)),
        ArmyUnit(id: "carthage-quartermaster", kind: .legion, faction: .carthage, position: Position(x: 1, y: 1), generalName: "阿格里帕", generalTrait: .quartermaster),
        ArmyUnit(id: "carthage-wounded", kind: .cavalry, faction: .carthage, position: Position(x: 5, y: 1), health: 30, hasMoved: true, hasActed: true)
    ]
    campaignEndMoveSkillState.resources[.carthage] = .zero
    campaignEndMoveSkillState.activeFaction = .rome
    let campaignEndBefore = campaignEndMoveSkillState
    let campaignEndIntent = campaignEndMoveSkillState.aiIntents(for: .carthage, limit: 4)
        .first { $0.unitID == "carthage-quartermaster" }
    let campaignEndPlan = campaignEndMoveSkillState.aiOperationalPlanReports(against: .rome, perFactionLimit: 4, limit: 5)
        .first { $0.sourceUnitIDs.contains("carthage-quartermaster") }
    let campaignEndStep = campaignEndPlan?.steps.first { $0.unitID == "carthage-quartermaster" }
    let campaignEndThreat = campaignEndMoveSkillState.enemyCommanderThreatReports(against: .rome, limit: 5)
        .first { $0.unitID == "carthage-quartermaster" }
    expect(campaignEndIntent?.kind == .captureCity, "Campaign-ending capture should suppress move-skill intent")
    expect(campaignEndIntent?.destination == Position(x: 3, y: 1), "Campaign-ending capture should preserve the city landing")
    expect(campaignEndPlan?.kind == .cityCapture, "Campaign-ending plan should remain a city capture")
    expect(campaignEndStep?.intentKind == .captureCity, "Campaign-ending plan step should not predict a trailing skill")
    expect(campaignEndStep?.destination == Position(x: 3, y: 1), "Campaign-ending plan should reuse the capture landing")
    expect(campaignEndThreat?.intentKind == .captureCity, "Campaign-ending threat should not predict a trailing skill")
    expect(campaignEndThreat?.destination == Position(x: 3, y: 1), "Campaign-ending threat should reuse the capture landing")
    expect(campaignEndThreat?.targetCityID == "rome", "Campaign-ending threat should preserve the captured city target")
    expect(campaignEndMoveSkillState == campaignEndBefore, "Campaign-ending intent, plan, and threat reads should remain pure")

    if let campaignEndIntent, let campaignEndDestination = campaignEndIntent.destination {
        var campaignEndProjection = campaignEndMoveSkillState
        campaignEndProjection.activeFaction = .carthage
        _ = try campaignEndProjection.setTacticalOrder(
            unitID: campaignEndIntent.unitID,
            order: campaignEndIntent.tacticalOrder
        )
        _ = try campaignEndProjection.moveUnit(id: campaignEndIntent.unitID, to: campaignEndDestination)
        expect(campaignEndProjection.city(withID: "rome")?.owner == .carthage, "Campaign projection should capture the final city")
        expect(campaignEndProjection.campaignStatus.kind == .romanDefeat, "Campaign projection should evaluate defeat at the landing")
        expect(campaignEndProjection.unit(withID: "carthage-quartermaster")?.generalSkillCooldownRemaining == 0, "Campaign projection should not start skill cooldown")
        expect(campaignEndProjection.unit(withID: "carthage-wounded")?.health == 30, "Campaign projection should not heal after victory")
    }

    var campaignEndResolution = campaignEndMoveSkillState
    campaignEndResolution.activeFaction = .carthage
    _ = campaignEndResolution.performSimpleAI(for: .carthage)
    expect(campaignEndResolution.campaignStatus.kind == .romanDefeat, "Campaign-ending capture should end the campaign")
    expect(campaignEndResolution.unit(withID: "carthage-quartermaster")?.generalSkillCooldownRemaining == 0, "Campaign-ending capture should not execute a trailing skill")
    expect(campaignEndResolution.unit(withID: "carthage-wounded")?.health == 30, "Campaign-ending capture should not heal after victory")

    var captureIntentState = GameState.newCampaign()
    captureIntentState.units = [
        ArmyUnit(id: "carthage-capturer", kind: .cavalry, faction: .carthage, position: Position(x: 6, y: 2))
    ]
    for index in captureIntentState.cities.indices where captureIntentState.cities[index].id != "massilia" {
        captureIntentState.cities[index].owner = .carthage
    }
    // Keep the neutral-city forecast in a live campaign, matching Swift Testing.
    if let romeIndex = captureIntentState.cities.firstIndex(where: { $0.id == "rome" }) {
        captureIntentState.cities[romeIndex].owner = .rome
        captureIntentState.cities[romeIndex].position = Position(x: 11, y: 7)
    }
    expect(!captureIntentState.campaignStatus.isGameOver, "City capture fixture must start in an ongoing campaign")
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

    var synergySkillState = GameState.newCampaign()
    synergySkillState.units = [
        ArmyUnit(id: "rome-commander", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), generalName: "凯撒", generalTrait: .eagleStandard),
        ArmyUnit(id: "rome-wounded", kind: .archer, faction: .rome, position: Position(x: 4, y: 3), health: 30)
    ]
    synergySkillState.activeFaction = .rome
    let synergySkillBefore = synergySkillState
    let skillSynergy = try synergySkillState.commanderSynergyReport(unitID: "rome-commander")
    expect(skillSynergy.kind == .commanderSkill, "Commander synergy should surface ready general skill")
    expect(skillSynergy.beneficiaryUnitIDs == ["rome-wounded"], "Commander synergy should expose skill beneficiaries")
    expect(skillSynergy.projectedRecoveredHealth > 0, "Commander synergy should expose projected recovery")
    expect(skillSynergy.isExecutable, "Ready commander synergy should be executable")
    expect(skillSynergy.steps.contains { $0.role == .commander }, "Commander synergy should include commander step")
    expect(synergySkillState == synergySkillBefore, "Commander synergy skill report should not mutate state")

    var synergyAttackState = GameState.newCampaign()
    synergyAttackState.units = [
        ArmyUnit(id: "rome-attacker", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), generalName: "凯撒", generalTrait: .eagleStandard),
        ArmyUnit(id: "rome-support", kind: .legion, faction: .rome, position: Position(x: 2, y: 3)),
        ArmyUnit(id: "rome-flanker", kind: .archer, faction: .rome, position: Position(x: 4, y: 2)),
        ArmyUnit(id: "carthage-target", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3), health: 70)
    ]
    synergyAttackState.activeFaction = .rome
    let synergyAttackBefore = synergyAttackState
    let attackSynergy = try synergyAttackState.commanderSynergyReport(unitID: "rome-attacker")
    let attackSynergyPreview = try synergyAttackState.attackPreview(attackerID: "rome-attacker", defenderID: "carthage-target")
    expect(attackSynergy.kind == .coordinatedAttack, "Commander synergy should surface coordinated attacks")
    expect(attackSynergy.projectedDamage == attackSynergyPreview.damage, "Coordinated attack synergy should reuse attack preview damage")
    expect(attackSynergy.supportBonus == attackSynergyPreview.supportBonus, "Coordinated attack synergy should expose support bonus")
    expect(attackSynergy.flankingBonus == attackSynergyPreview.flankingBonus, "Coordinated attack synergy should expose flanking bonus")
    expect(attackSynergy.commandBonus == attackSynergyPreview.commandBonus, "Coordinated attack synergy should expose command bonus")
    expect(attackSynergy.supportBonus > 0 && attackSynergy.flankingBonus > 0 && attackSynergy.commandBonus > 0, "Coordinated attack synergy should explain visible modifiers")
    expect(synergyAttackState == synergyAttackBefore, "Commander synergy attack report should not mutate state")

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

    var maneuverState = GameState.newCampaign()
    maneuverState.units = [
        ArmyUnit(id: "rome-striker", kind: .legion, faction: .rome, position: Position(x: 3, y: 3)),
        ArmyUnit(id: "rome-support", kind: .legion, faction: .rome, position: Position(x: 3, y: 2)),
        ArmyUnit(id: "carthage-target", kind: .archer, faction: .carthage, position: Position(x: 5, y: 3), health: 45)
    ]
    maneuverState.activeFaction = .rome
    let maneuverBefore = maneuverState
    let maneuverReports = try maneuverState.maneuverOptionReports(unitID: "rome-striker", limit: 8)
    guard let strikeManeuver = maneuverReports.first(where: { $0.kind == .strike && $0.targetUnitID == "carthage-target" }) else {
        expect(false, "Maneuver options should expose a strike landing")
        fatalError("unreachable")
    }
    var projectedManeuverState = maneuverState
    if let strikerIndex = projectedManeuverState.units.firstIndex(where: { $0.id == "rome-striker" }) {
        projectedManeuverState.units[strikerIndex].position = strikeManeuver.destination
    }
    let maneuverPreview = try projectedManeuverState.attackPreview(attackerID: "rome-striker", defenderID: "carthage-target")
    expect(strikeManeuver.path.first == Position(x: 3, y: 3), "Maneuver option should expose path origin")
    expect(strikeManeuver.path.last == strikeManeuver.destination, "Maneuver option should expose destination path")
    expect(strikeManeuver.projectedDamage == maneuverPreview.damage, "Maneuver strike should reuse projected attack preview damage")
    expect(strikeManeuver.retaliation == maneuverPreview.retaliation, "Maneuver strike should expose projected retaliation")
    expect(strikeManeuver.supportBonus == maneuverPreview.supportBonus, "Maneuver strike should expose projected support")
    expect(strikeManeuver.isExecutable, "Maneuver strike should be executable")
    expect(!strikeManeuver.detail.isEmpty, "Maneuver option should expose readable detail")
    expect(maneuverState == maneuverBefore, "Maneuver option reports should not mutate state")

    let focusBefore = recommendationState
    let focusReports = recommendationState.battlefieldFocusReports(for: .rome, limit: 5)
    let pressureFocus = focusReports.first { $0.kind == .defense && $0.targetUnitID == "rome-line" }
    expect(pressureFocus?.severity == .critical, "Battlefield focus should surface critical defensive pressure")
    expect(pressureFocus?.position == Position(x: 3, y: 3), "Battlefield focus should expose a map position")
    expect(pressureFocus?.recommendedOrder == .defensive, "Battlefield focus should expose a recommended posture")
    expect((pressureFocus?.score ?? 0) > 0, "Battlefield focus should expose a positive score")
    expect(!(pressureFocus?.title ?? "").isEmpty, "Battlefield focus should expose a readable title")
    expect(!(pressureFocus?.detail ?? "").isEmpty, "Battlefield focus should expose a readable detail")
    expect(recommendationState == focusBefore, "Battlefield focus reports should not mutate state")

    let generalFocus = formationState.battlefieldFocusReports(for: .rome, limit: 5).first { $0.kind == .generalOpportunity && $0.unitID == "rome-commander" }
    expect(generalFocus?.severity == .urgent, "Battlefield focus should surface ready general skill opportunities")
    expect(generalFocus?.summary.contains("将领") == true, "General focus should expose a commander summary")

    let mapControlBefore = recommendationState
    let mapControlReports = recommendationState.mapControlReports(for: .rome)
    let lineControl = mapControlReports.first { $0.position == Position(x: 3, y: 3) }
    let heatReport = recommendationState.threatHeatZoneReports(for: .rome, limit: 5).first
    expect(mapControlReports.count == recommendationState.tiles.count, "Map control should expose one report per tile")
    expect((lineControl?.enemyInfluence ?? 0) > 0, "Map control should include enemy influence near the line")
    expect(!(lineControl?.summary ?? "").isEmpty, "Map control should expose a readable summary")
    expect(heatReport?.center == Position(x: 3, y: 3), "Threat heat should focus the pressured Roman line")
    expect(Set(heatReport?.sourceUnitIDs ?? []) == Set(["carthage-east", "carthage-north"]), "Threat heat should expose hostile sources")
    expect((heatReport?.projectedDamageTotal ?? 0) > 0, "Threat heat should expose projected damage")
    expect(heatReport?.threatLevel == .critical, "Threat heat should flag critical pressure")
    expect(recommendationState == mapControlBefore, "Map control and threat heat reports should not mutate state")

    let operationalPlanBefore = recommendationState
    let operationalPlan = recommendationState.aiOperationalPlanReports(against: .rome, perFactionLimit: 4, limit: 5).first
    expect(operationalPlan?.kind == .focusedAttack, "AI operational plan should surface the enemy focused attack")
    expect(operationalPlan?.targetUnitID == "rome-line", "AI operational plan should identify the pressured Roman line")
    expect(Set(operationalPlan?.sourceUnitIDs ?? []) == Set(["carthage-east", "carthage-north"]), "AI operational plan should expose coordinated hostile sources")
    expect(operationalPlan?.steps.contains { $0.coordinationRole == .mainEffort } == true, "AI operational plan should mark a main effort")
    expect((operationalPlan?.projectedDamageTotal ?? 0) > 0, "AI operational plan should expose projected damage")
    expect(!(operationalPlan?.title ?? "").isEmpty, "AI operational plan should expose a readable title")
    expect(!(operationalPlan?.detail ?? "").isEmpty, "AI operational plan should expose readable detail")
    expect(recommendationState == operationalPlanBefore, "AI operational plan reports should not mutate state")

    var enemyCommanderPlanState = GameState.newCampaign()
    enemyCommanderPlanState.units = [
        ArmyUnit(id: "rome-line", kind: .legion, faction: .rome, position: Position(x: 1, y: 1)),
        ArmyUnit(id: "carthage-quartermaster", kind: .legion, faction: .carthage, position: Position(x: 5, y: 3), generalName: "阿格里帕", generalTrait: .quartermaster),
        ArmyUnit(id: "carthage-wounded", kind: .cavalry, faction: .carthage, position: Position(x: 4, y: 3), health: 40)
    ]
    let enemyCommanderPlanBefore = enemyCommanderPlanState
    let commanderPlan = enemyCommanderPlanState.aiOperationalPlanReports(against: .rome, perFactionLimit: 4, limit: 5).first { $0.kind == .commanderSkill }
    expect(commanderPlan?.commanderUnitIDs == ["carthage-quartermaster"], "AI operational plan should expose enemy commander skill coordination")
    expect(commanderPlan?.targetUnitID == "carthage-wounded", "AI operational plan should expose the enemy skill target")
    expect(commanderPlan?.steps.first?.skillSummary?.contains("恢复") == true, "AI operational plan should expose skill effect text")
    expect(enemyCommanderPlanState == enemyCommanderPlanBefore, "Enemy commander operational plan should not mutate state")

    let enemyCommanderThreat = enemyCommanderPlanState.enemyCommanderThreatReports(against: .rome, limit: 5).first { $0.unitID == "carthage-quartermaster" }
    expect(enemyCommanderThreat?.intentKind == .useSkill, "Enemy commander threat should reuse enemy forecast skill intent")
    expect((enemyCommanderThreat?.projectedRecovery ?? 0) > 0, "Enemy commander threat should expose projected recovery")
    expect(enemyCommanderThreat?.affectedUnitIDs.contains("carthage-wounded") == true, "Enemy commander threat should expose affected ally")
    expect(enemyCommanderThreat?.skillReady == true, "Enemy commander threat should evaluate skill readiness from enemy forecast")
    expect(!(enemyCommanderThreat?.detail ?? "").isEmpty, "Enemy commander threat should expose readable detail")
    expect(enemyCommanderPlanState == enemyCommanderPlanBefore, "Enemy commander threat reports should not mutate state")

    let enemyCountermeasureReports = enemyCommanderPlanState.countermeasureReports(for: .rome, limit: 5)
    let enemyCountermeasure = enemyCountermeasureReports.first { $0.linkedEnemyCommanderThreatID == "carthage-quartermaster" }
    expect(enemyCountermeasure?.linkedAIOperationalPlanID != nil, "Countermeasure should link the enemy commander plan")
    expect(enemyCountermeasure?.responseUnitID == "rome-line", "Countermeasure should assign the Roman response unit")
    expect(enemyCountermeasure?.faction == .rome, "Countermeasure should belong to Rome")
    expect(!(enemyCountermeasure?.command ?? "").isEmpty, "Countermeasure should expose a command")
    expect(enemyCommanderPlanState == enemyCommanderPlanBefore, "Countermeasure reports should not mutate state")

    var enemySiegeThreatState = GameState.newCampaign()
    enemySiegeThreatState.units = [
        ArmyUnit(id: "rome-garrison", kind: .legion, faction: .rome, position: Position(x: 3, y: 4)),
        ArmyUnit(id: "carthage-siege", kind: .legion, faction: .carthage, position: Position(x: 2, y: 3), generalName: "汉尼拔", generalTrait: .siegeEngineer)
    ]
    var enemySiegePreviewState = enemySiegeThreatState
    enemySiegePreviewState.activeFaction = .carthage
    let enemySiegePreview = try enemySiegePreviewState.generalSkillPreview(unitID: "carthage-siege")
    let enemySiegeThreat = enemySiegeThreatState.enemyCommanderThreatReports(against: .rome, limit: 5).first { $0.unitID == "carthage-siege" }
    expect(enemySiegeThreat?.targetCityID == "rome", "Enemy siege threat should expose the threatened Roman city")
    expect(enemySiegeThreat?.affectedCityIDs == enemySiegePreview.affectedCityIDs, "Enemy siege threat should reuse siege preview targets")
    expect(enemySiegeThreat?.projectedFortificationReduction == enemySiegePreview.projectedFortificationReduction, "Enemy siege threat should reuse projected fortification reduction")
    expect(enemySiegeThreat?.skillSummary == enemySiegePreview.summary, "Enemy siege threat should reuse siege skill summary")
    let siegeCountermeasure = enemySiegeThreatState.countermeasureReports(for: .rome, limit: 5).first { $0.linkedEnemyCommanderThreatID == "carthage-siege" }
    expect(siegeCountermeasure?.kind == .interruptCommander || siegeCountermeasure?.kind == .reinforceCity, "Siege countermeasure should interrupt the commander or reinforce the city")
    expect(siegeCountermeasure?.targetCityID == "rome", "Siege countermeasure should preserve threatened city")

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
