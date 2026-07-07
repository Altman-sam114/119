import AppKit
import SwiftUI

@MainActor
@main
struct RenderBattlePreview {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let outputPath = arguments.first ?? "DerivedData/battle-landscape-preview.png"
        let width = arguments.dropFirst().first.flatMap(Double.init) ?? 932
        let height = arguments.dropFirst(2).first.flatMap(Double.init) ?? 430
        let viewModel = GameViewModel()
        viewModel.isShowingMenu = false
        viewModel.state.units = [
            ArmyUnit(id: "rome-legion-1", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), health: 88, experience: 2, generalName: "凯撒", generalTrait: .eagleStandard),
            ArmyUnit(id: "carthage-hunter", kind: .cavalry, faction: .carthage, position: Position(x: 7, y: 2)),
            ArmyUnit(id: "carthage-commander", kind: .legion, faction: .carthage, position: Position(x: 9, y: 6), generalName: "汉尼拔", generalTrait: .siegeEngineer)
        ]
        for index in viewModel.state.cities.indices where viewModel.state.cities[index].owner != .rome {
            viewModel.state.cities[index].owner = .carthage
        }
        if let romeIndex = viewModel.state.cities.firstIndex(where: { $0.id == "rome" }) {
            viewModel.state.cities[romeIndex].position = Position(x: 0, y: 0)
        }
        viewModel.state.resources[.carthage] = .zero
        viewModel.state.activeFaction = .rome
        viewModel.selectedUnitID = "rome-legion-1"
        viewModel.selectedPosition = Position(x: 3, y: 3)
        viewModel.bannerMessage = "预览战斗：将领详情、姿态预览和敌军路线已显示。"

        let overlays = viewModel.enemyIntentMapOverlays
        guard let advanceOverlay = overlays.first(where: { $0.kind == .advanceAttack && $0.unitID == "carthage-hunter" }),
              advanceOverlay.destinationPosition != advanceOverlay.originPosition,
              advanceOverlay.targetPosition == Position(x: 3, y: 3),
              !advanceOverlay.routeSegments.isEmpty,
              advanceOverlay.impactLabel.contains("预计伤害") else {
            throw PreviewRenderError.missingIntentOverlay
        }
        guard let frontlinePressure = viewModel.primaryFrontlinePressureSummary,
              frontlinePressure.report.targetID == "rome-legion-1",
              frontlinePressure.targetPosition == Position(x: 3, y: 3),
              frontlinePressure.report.attackIntentCount > 0,
              frontlinePressure.report.projectedDamageTotal > 0,
              !frontlinePressure.detail.isEmpty,
              !frontlinePressure.impactLabel.isEmpty else {
            throw PreviewRenderError.missingFrontlinePressure
        }
        guard let battlefieldFocus = viewModel.primaryBattlefieldFocusSummary,
              battlefieldFocus.report.targetUnitID == "rome-legion-1",
              battlefieldFocus.targetPosition == Position(x: 3, y: 3),
              !battlefieldFocus.kindLabel.isEmpty,
              !battlefieldFocus.severityLabel.isEmpty,
              !battlefieldFocus.targetLabel.isEmpty,
              !battlefieldFocus.detail.isEmpty,
              !battlefieldFocus.accessibilityLabel.isEmpty else {
            throw PreviewRenderError.missingBattlefieldFocus
        }
        guard viewModel.primaryThreatHeatZoneSummary != nil,
              let threatHeat = viewModel.threatHeatZoneSummaries.first(where: { summary in
                  summary.targetPosition == Position(x: 3, y: 3) &&
                      summary.report.projectedDamageTotal > 0 &&
                      summary.report.sourceUnitIDs.contains("carthage-hunter")
              }),
              threatHeat.report.projectedDamageTotal > 0,
              threatHeat.report.sourceUnitIDs.contains("carthage-hunter"),
              !viewModel.threatHeatZoneSummaries.isEmpty,
              !viewModel.threatHeatOverlayPositions.isEmpty,
              viewModel.threatHeatOverlayPositions.contains(Position(x: 3, y: 3)),
              !threatHeat.levelLabel.isEmpty,
              !threatHeat.sourceLabel.isEmpty,
              !threatHeat.impactLabel.isEmpty,
              !threatHeat.detail.isEmpty,
              !threatHeat.accessibilityLabel.isEmpty else {
            throw PreviewRenderError.missingThreatHeatSummary
        }
        let unitStateBeforeSituationRead = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateBeforeSituationRead = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesBeforeSituationRead = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        let turnBeforeSituationRead = viewModel.state.turn
        let activeFactionBeforeSituationRead = viewModel.state.activeFaction
        let mapControlForSituation = viewModel.selectedMapControlSummary
        let formationForSituation = viewModel.selectedLegionFormationSummary
        let recommendationForSituation = viewModel.selectedTacticalRecommendationSummary
        let maneuverForSituation = viewModel.primaryManeuverOptionSummary
        let synergyForSituation = viewModel.selectedCommanderSynergySummary
        let countermeasurePreviewForSituation = viewModel.selectedCountermeasureCommandPreview
        let stagePreviewForSituation = viewModel.selectedBattleObjectiveStageCommandPreview
        let commanderGuidanceForSituation = viewModel.selectedCommanderActionGuidance
        guard let selectedSituation = viewModel.selectedUnitSituationReadout,
              selectedSituation.unitID == "rome-legion-1",
              selectedSituation.position == Position(x: 3, y: 3),
              selectedSituation.references(pressure: frontlinePressure),
              selectedSituation.references(threatHeat: threatHeat),
              !selectedSituation.title.isEmpty,
              !selectedSituation.statusLabel.isEmpty,
              !selectedSituation.pressureLabel.isEmpty,
              !selectedSituation.spaceLabel.isEmpty,
              !selectedSituation.opportunityLabel.isEmpty,
              !selectedSituation.nextStepLabel.isEmpty,
              !selectedSituation.riskLabel.isEmpty,
              !selectedSituation.accessibilityLabel.isEmpty,
              selectedSituation.accessibilityLabel.contains("入口"),
              !selectedSituation.signals.isEmpty,
              !selectedSituation.commandEntries.isEmpty,
              selectedSituation.primaryCommandEntry != nil,
              !selectedSituation.primaryCommandEntryLabel.isEmpty,
              !selectedSituation.commandEntrySummaryLabel.isEmpty,
              selectedSituation.signals.allSatisfy({ signal in
                  !signal.title.isEmpty &&
                      !signal.detail.isEmpty &&
                      !signal.accessibilityLabel.isEmpty &&
                      (signal.position != nil || signal.sourceID != nil)
              }),
              selectedSituation.commandEntries.allSatisfy({ entry in
                  !entry.title.isEmpty &&
                      !entry.detail.isEmpty &&
                      !entry.cueLabel.isEmpty &&
                      !entry.accessibilityLabel.isEmpty &&
                      (entry.position != nil || entry.sourceID != nil)
              }),
              selectedSituation.signals.contains(where: { $0.kind == .pressure && $0.sourceID == frontlinePressure.id }),
              selectedSituation.signals.contains(where: { $0.kind == .threatHeat && $0.sourceID == threatHeat.id }) else {
            throw PreviewRenderError.missingSelectedUnitSituationReadout
        }
        if let mapControlForSituation {
            guard selectedSituation.references(mapControl: mapControlForSituation),
                  selectedSituation.signals.contains(where: { $0.kind == .mapControl && $0.sourceID == mapControlForSituation.id }) else {
                throw PreviewRenderError.missingSelectedUnitSituationReadout
            }
        }
        if let formationForSituation {
            guard selectedSituation.references(formation: formationForSituation),
                  selectedSituation.signals.contains(where: { $0.kind == .formation && $0.sourceID == formationForSituation.id }) else {
                throw PreviewRenderError.missingSelectedUnitSituationReadout
            }
        }
        if let recommendationForSituation {
            guard selectedSituation.references(recommendation: recommendationForSituation),
                  selectedSituation.signals.contains(where: { $0.kind == .recommendation && $0.sourceID == recommendationForSituation.id }) else {
                throw PreviewRenderError.missingSelectedUnitSituationReadout
            }
        }
        if let maneuverForSituation {
            guard selectedSituation.references(maneuver: maneuverForSituation),
                  selectedSituation.signals.contains(where: { $0.kind == .maneuver && $0.sourceID == maneuverForSituation.id }) else {
                throw PreviewRenderError.missingSelectedUnitSituationReadout
            }
        }
        if let synergyForSituation {
            guard selectedSituation.references(synergy: synergyForSituation),
                  selectedSituation.signals.contains(where: { $0.kind == .synergy && $0.sourceID == synergyForSituation.id }) else {
                throw PreviewRenderError.missingSelectedUnitSituationReadout
            }
        }
        if let countermeasurePreviewForSituation,
           countermeasurePreviewForSituation.summary.report.responseUnitID == selectedSituation.unitID {
            guard selectedSituation.references(countermeasurePreview: countermeasurePreviewForSituation),
                  selectedSituation.commandEntries.contains(where: {
                      $0.kind == .countermeasure &&
                          $0.sourceID == countermeasurePreviewForSituation.id
                  }) else {
                throw PreviewRenderError.missingSelectedUnitSituationReadout
            }
        }
        if let stagePreviewForSituation,
           stagePreviewForSituation.commandUnit?.id == selectedSituation.unitID {
            guard selectedSituation.references(stagePreview: stagePreviewForSituation),
                  selectedSituation.commandEntries.contains(where: {
                      $0.kind == .objectiveStage &&
                          $0.sourceID == stagePreviewForSituation.id
                  }) else {
                throw PreviewRenderError.missingSelectedUnitSituationReadout
            }
        }
        if commanderGuidanceForSituation != nil {
            guard let commanderActionID = selectedSituation.commanderActionID,
                  selectedSituation.references(commandEntryKind: .commanderAction, sourceID: commanderActionID) else {
                throw PreviewRenderError.missingSelectedUnitSituationReadout
            }
        }
        guard selectedSituation.commandEntries.contains(where: { $0.kind == .tacticalOrder }),
              selectedSituation.tacticalOrderID != nil else {
            throw PreviewRenderError.missingSelectedUnitSituationReadout
        }
        let unitStateAfterSituationRead = viewModel.state.units
            .sorted(by: { $0.id < $1.id })
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateAfterSituationRead = viewModel.state.cities
            .sorted(by: { $0.id < $1.id })
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesAfterSituationRead = viewModel.state.resources
            .sorted(by: { $0.key.rawValue < $1.key.rawValue })
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        guard unitStateBeforeSituationRead == unitStateAfterSituationRead,
              cityStateBeforeSituationRead == cityStateAfterSituationRead,
              resourcesBeforeSituationRead == resourcesAfterSituationRead,
              turnBeforeSituationRead == viewModel.state.turn,
              activeFactionBeforeSituationRead == viewModel.state.activeFaction else {
            throw PreviewRenderError.missingSelectedUnitSituationReadout
        }
        guard let primaryOperationalPlan = viewModel.primaryAIOperationalPlanSummary,
              !viewModel.aiOperationalPlanSummaries.isEmpty,
              viewModel.aiOperationalPlanSummaries.contains(where: { $0.report.sourceUnitIDs.contains("carthage-hunter") }),
              !primaryOperationalPlan.title.isEmpty,
              !primaryOperationalPlan.kindLabel.isEmpty,
              !primaryOperationalPlan.sourceLabel.isEmpty,
              !primaryOperationalPlan.impactLabel.isEmpty,
              !primaryOperationalPlan.detail.isEmpty,
              !primaryOperationalPlan.accessibilityLabel.isEmpty else {
            throw PreviewRenderError.missingAIOperationalPlanSummary
        }
        let operationalPlan = viewModel.aiOperationalPlanSummaries.first { $0.report.sourceUnitIDs.contains("carthage-hunter") } ?? primaryOperationalPlan
        guard !operationalPlan.title.isEmpty,
              !operationalPlan.kindLabel.isEmpty,
              !operationalPlan.sourceLabel.isEmpty,
              !operationalPlan.impactLabel.isEmpty,
              !operationalPlan.detail.isEmpty,
              !operationalPlan.accessibilityLabel.isEmpty else {
            throw PreviewRenderError.missingAIOperationalPlanSummary
        }
        let unitStateBeforePlanTimelineRead = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateBeforePlanTimelineRead = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesBeforePlanTimelineRead = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        let turnBeforePlanTimelineRead = viewModel.state.turn
        let activeFactionBeforePlanTimelineRead = viewModel.state.activeFaction
        let planTimelineSteps = operationalPlan.timelineSteps
        guard !planTimelineSteps.isEmpty,
              planTimelineSteps.count == operationalPlan.report.steps.count,
              !operationalPlan.timelineLabel.isEmpty,
              !operationalPlan.timelineAccessibilityLabel.isEmpty,
              operationalPlan.timelineAccessibilityLabel.contains("时间线") ||
                  operationalPlan.timelineAccessibilityLabel.contains("队列"),
              operationalPlan.timelineAccessibilityLabel.contains("角色"),
              operationalPlan.timelineAccessibilityLabel.contains("意图"),
              operationalPlan.timelineAccessibilityLabel.contains("目标"),
              operationalPlan.timelineAccessibilityLabel.contains("预计"),
              planTimelineSteps.contains(where: { $0.step.unitID == "carthage-hunter" }),
              planTimelineSteps.contains(where: { $0.role == .mainEffort }),
              planTimelineSteps.contains(where: { $0.step.intentKind == .advanceAttack }),
              planTimelineSteps.allSatisfy({ step in
                  !step.roleLabel.isEmpty &&
                      !step.unitLabel.isEmpty &&
                      !step.intentLabel.isEmpty &&
                      !step.originLabel.isEmpty &&
                      !step.destinationLabel.isEmpty &&
                      !step.targetLabel.isEmpty &&
                      !step.orderLabel.isEmpty &&
                      !step.impactLabel.isEmpty &&
                      !step.routeLabel.isEmpty &&
                      !step.detailLabel.isEmpty &&
                      !step.compactLabel.isEmpty &&
                      !step.accessibilityLabel.isEmpty
              }),
              viewModel.state.units
                  .sorted(by: { $0.id < $1.id })
                  .map({ unit in
                      "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
                  }) == unitStateBeforePlanTimelineRead,
              viewModel.state.cities
                  .sorted(by: { $0.id < $1.id })
                  .map({ city in
                      "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
                  }) == cityStateBeforePlanTimelineRead,
              viewModel.state.resources
                  .sorted(by: { $0.key.rawValue < $1.key.rawValue })
                  .map({ entry in
                      let resources = entry.value
                      return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
                  }) == resourcesBeforePlanTimelineRead,
              viewModel.state.turn == turnBeforePlanTimelineRead,
              viewModel.state.activeFaction == activeFactionBeforePlanTimelineRead else {
            throw PreviewRenderError.missingAIOperationalPlanTimelineReadout
        }
        guard let enemyCommanderThreat = viewModel.primaryEnemyCommanderThreatSummary,
              !viewModel.enemyCommanderThreatSummaries.isEmpty,
              viewModel.enemyCommanderThreatSummaries.contains(where: { $0.report.unitID == "carthage-commander" }),
              viewModel.enemyCommanderThreatSummaries.contains(where: { $0.report.intentKind == .useSkill || !$0.report.skillSummary.isEmpty }),
              !enemyCommanderThreat.title.isEmpty,
              !enemyCommanderThreat.compactTitle.isEmpty,
              !enemyCommanderThreat.commanderLabel.isEmpty,
              !enemyCommanderThreat.traitLabel.isEmpty,
              !enemyCommanderThreat.levelLabel.isEmpty,
              !enemyCommanderThreat.intentLabel.isEmpty,
              !enemyCommanderThreat.impactLabel.isEmpty,
              !enemyCommanderThreat.statusLabel.isEmpty,
              !enemyCommanderThreat.accessibilityLabel.isEmpty else {
            throw PreviewRenderError.missingEnemyCommanderThreatSummary
        }
        guard let countermeasure = viewModel.primaryCountermeasureSummary,
              !viewModel.countermeasureSummaries.isEmpty,
              viewModel.countermeasureSummaries.contains(where: { summary in
                  summary.report.linkedEnemyCommanderThreatID != nil ||
                      summary.report.linkedAIOperationalPlanID != nil
              }),
              !countermeasure.title.isEmpty,
              !countermeasure.kindLabel.isEmpty,
              !countermeasure.priorityLabel.isEmpty,
              !countermeasure.threatLabel.isEmpty,
              !countermeasure.responseLabel.isEmpty,
              !countermeasure.unitLabel.isEmpty,
              !countermeasure.impactLabel.isEmpty,
              !countermeasure.riskLabel.isEmpty,
              !countermeasure.commandLabel.isEmpty,
              !countermeasure.accessibilityLabel.isEmpty else {
            throw PreviewRenderError.missingCountermeasureSummary
        }
        guard let countermeasureOverlay = viewModel.primaryCountermeasureMapOverlay,
              !countermeasureOverlay.routeSegments.isEmpty,
              !countermeasureOverlay.chainLabel.isEmpty,
              !countermeasureOverlay.accessibilityLabel.isEmpty,
              !viewModel.countermeasureRouteSegments.isEmpty,
              !viewModel.countermeasureOverlaysByPosition.isEmpty,
              !viewModel.countermeasureOverlayPositions.isEmpty,
              countermeasureOverlay.id == countermeasure.id,
              countermeasureOverlay.destination == countermeasure.destination,
              countermeasureOverlay.targetPosition == countermeasure.targetPosition,
              viewModel.countermeasureOverlayPositions.contains(countermeasure.responsePosition),
              viewModel.countermeasureOverlayPositions.contains(countermeasure.destination),
              viewModel.countermeasureOverlayPositions.contains(countermeasure.targetPosition),
              viewModel.countermeasureOverlaysByPosition[countermeasure.responsePosition] != nil,
              viewModel.countermeasureOverlaysByPosition[countermeasure.destination] != nil,
              viewModel.countermeasureOverlaysByPosition[countermeasure.targetPosition] != nil,
              countermeasureOverlay.positionOverlays.contains(where: { overlay in
                  overlay.role == .response &&
                      overlay.position == countermeasure.responsePosition &&
                      !overlay.stageLabel.isEmpty &&
                      !overlay.focusLabel.isEmpty &&
                      !overlay.chainLabel.isEmpty &&
                      !overlay.accessibilityLabel.isEmpty
              }),
              countermeasureOverlay.positionOverlays.contains(where: { overlay in
                  overlay.role == .destination &&
                      overlay.position == countermeasure.destination &&
                      !overlay.stageLabel.isEmpty &&
                      !overlay.focusLabel.isEmpty &&
                      !overlay.chainLabel.isEmpty &&
                      !overlay.accessibilityLabel.isEmpty
              }),
              countermeasureOverlay.positionOverlays.contains(where: { overlay in
                  overlay.role == .target &&
                      overlay.position == countermeasure.targetPosition &&
                      !overlay.stageLabel.isEmpty &&
                      !overlay.focusLabel.isEmpty &&
                      !overlay.chainLabel.isEmpty &&
                      !overlay.accessibilityLabel.isEmpty
              }),
              countermeasureOverlay.routeSegments.contains(where: { segment in
                  segment.from == countermeasure.responsePosition ||
                      segment.to == countermeasure.destination ||
                      segment.to == countermeasure.targetPosition
              }) else {
            throw PreviewRenderError.missingCountermeasureOverlay
        }
        guard let countermeasureCommandPreview = viewModel.primaryCountermeasureCommandPreview,
              countermeasureCommandPreview.id == countermeasure.id,
              countermeasureCommandPreview.summary.id == countermeasure.id,
              countermeasureCommandPreview.responseUnit?.id == countermeasure.report.responseUnitID,
              !countermeasureCommandPreview.title.isEmpty,
              !countermeasureCommandPreview.statusLabel.isEmpty,
              !countermeasureCommandPreview.orderLabel.isEmpty,
              !countermeasureCommandPreview.destinationLabel.isEmpty,
              !countermeasureCommandPreview.targetLabel.isEmpty,
              !countermeasureCommandPreview.nextStepLabel.isEmpty,
              !countermeasureCommandPreview.commandChainLabel.isEmpty,
              !countermeasureCommandPreview.chainSummaryLabel.isEmpty,
              !countermeasureCommandPreview.recommendedOrderCueLabel.isEmpty,
              !countermeasureCommandPreview.movementCueLabel.isEmpty,
              !countermeasureCommandPreview.attackCueLabel.isEmpty,
              !countermeasureCommandPreview.targetStageCueLabel.isEmpty,
              !countermeasureCommandPreview.buttonTitle.isEmpty,
              !countermeasureCommandPreview.buttonDetail.isEmpty,
              !countermeasureCommandPreview.accessibilityLabel.isEmpty,
              countermeasureCommandPreview.isRecommendedOrder(countermeasure.report.recommendedOrder),
              !countermeasureCommandPreview.steps.isEmpty,
              countermeasureCommandPreview.steps.allSatisfy({ step in
                  !step.id.isEmpty &&
                      !step.symbol.isEmpty &&
                      !step.title.isEmpty &&
                      !step.detail.isEmpty
              }) else {
            throw PreviewRenderError.missingCountermeasureCommandPreview
        }
        viewModel.focusCountermeasure(countermeasure.id)
        guard viewModel.selectedUnitID == countermeasure.report.responseUnitID,
              viewModel.focusedPosition == countermeasureCommandPreview.responseUnit?.position,
              viewModel.focusedCountermeasureID == countermeasure.id,
              viewModel.selectedCountermeasureCommandPreview?.id == countermeasure.id,
              viewModel.selectedTacticalOrderPreviews.contains(where: { preview in
                  preview.order == countermeasure.report.recommendedOrder
              }),
              viewModel.bannerMessage.contains("反制") else {
            throw PreviewRenderError.missingCountermeasureCommandPreview
        }
        if countermeasureCommandPreview.canAttackCurrentTarget {
            guard let targetUnit = countermeasureCommandPreview.targetUnit,
                  let targetOverlay = viewModel.countermeasureOverlaysByPosition[countermeasureCommandPreview.targetPosition],
                  countermeasureCommandPreview.isMapOverlayTarget(targetOverlay),
                  viewModel.attackTargets.contains(where: { countermeasureCommandPreview.isAttackTarget($0) && $0.id == targetUnit.id }) else {
                throw PreviewRenderError.missingCountermeasureCommandPreview
            }
        }
        guard let mapControl = viewModel.primaryMapControlSummary,
              !viewModel.mapControlSummaries.isEmpty,
              !viewModel.mapControlOverlayPositions.isEmpty,
              !mapControl.controlLabel.isEmpty,
              !mapControl.levelLabel.isEmpty,
              !mapControl.sourceLabel.isEmpty,
              !mapControl.detail.isEmpty,
              !mapControl.accessibilityLabel.isEmpty else {
            throw PreviewRenderError.missingMapControlSummary
        }
        let movementSegments = advanceOverlay.routeSegments.filter { !$0.isTargetLeg }
        guard movementSegments.count > 1,
              movementSegments.allSatisfy({ segment in
                  segment.from.neighbors(width: viewModel.state.width, height: viewModel.state.height).contains(segment.to)
              }),
              movementSegments.first?.from == advanceOverlay.originPosition,
              movementSegments.last?.to == advanceOverlay.destinationPosition,
              advanceOverlay.routeSegments.contains(where: { segment in
                  segment.isTargetLeg &&
                      segment.from == advanceOverlay.destinationPosition &&
                      segment.to == Position(x: 3, y: 3)
              }) else {
            throw PreviewRenderError.missingHexIntentRoute
        }
        guard let commanderBrief = viewModel.selectedCommanderBrief,
              commanderBrief.traitName == GeneralTrait.eagleStandard.displayName,
              commanderBrief.passiveContributions.contains(where: { $0.id == "attack" && $0.value == "+5" }),
              commanderBrief.skillName == GeneralTrait.eagleStandard.skillName,
              !commanderBrief.skillStatusLabel.isEmpty,
              commanderBrief.warMeritSummary != nil else {
            throw PreviewRenderError.missingCommanderBrief
        }
        guard let selectedSkillPreview = viewModel.selectedGeneralSkillPreview,
              let commanderGuidance = viewModel.selectedCommanderActionGuidance,
              let skillTargetReadout = viewModel.selectedGeneralSkillTargetReadout,
              let skillButtonDetail = viewModel.selectedGeneralSkillCommandButtonDetail,
              !commanderGuidance.title.isEmpty,
              !commanderGuidance.skillCueLabel.isEmpty,
              !commanderGuidance.statusLabel.isEmpty,
              !commanderGuidance.accessibilityLabel.isEmpty,
              selectedSkillPreview.trait == .eagleStandard,
              viewModel.canUseSelectedGeneralSkill == selectedSkillPreview.isExecutable,
              viewModel.selectedGeneralSkillCooldownDetail == selectedSkillPreview.cooldownText,
              skillButtonDetail.contains(viewModel.selectedGeneralSkillButtonDetail ?? selectedSkillPreview.cooldownText) else {
            throw PreviewRenderError.missingCommanderActionGuidance
        }
        if let prefix = commanderGuidance.buttonDetailPrefix {
            guard skillButtonDetail.contains(prefix) else {
                throw PreviewRenderError.missingCommanderActionGuidance
            }
        }
        let expectedSkillTargetCount = selectedSkillPreview.affectedUnitIDs.count + selectedSkillPreview.affectedCityIDs.count
        let readoutTargetPositions = Set(skillTargetReadout.targets.map(\.position))
        let previewTargetPositions = Set(selectedSkillPreview.affectedPositions)
        guard skillTargetReadout.targets.count == expectedSkillTargetCount,
              !skillTargetReadout.title.isEmpty,
              !skillTargetReadout.targetCountLabel.isEmpty,
              !skillTargetReadout.effectLabel.isEmpty,
              !skillTargetReadout.mapCueLabel.isEmpty,
              !skillTargetReadout.statusLabel.isEmpty,
              !skillTargetReadout.accessibilityLabel.isEmpty,
              skillTargetReadout.targetCountLabel.contains("\(expectedSkillTargetCount)"),
              readoutTargetPositions == previewTargetPositions else {
            throw PreviewRenderError.missingGeneralSkillTargetReadout
        }
        if selectedSkillPreview.affectedPositions.isEmpty {
            guard skillTargetReadout.mapCueLabel.contains("暂无") else {
                throw PreviewRenderError.missingGeneralSkillTargetReadout
            }
        } else {
            guard skillTargetReadout.mapCueLabel.contains("\(selectedSkillPreview.affectedPositions.count)") else {
                throw PreviewRenderError.missingGeneralSkillTargetReadout
            }
        }
        if selectedSkillPreview.projectedRecoveredHealth > 0 {
            guard skillTargetReadout.effectLabel.contains("\(selectedSkillPreview.projectedRecoveredHealth)") else {
                throw PreviewRenderError.missingGeneralSkillTargetReadout
            }
        }
        if selectedSkillPreview.projectedFortificationReduction > 0 {
            guard skillTargetReadout.effectLabel.contains("\(selectedSkillPreview.projectedFortificationReduction)") else {
                throw PreviewRenderError.missingGeneralSkillTargetReadout
            }
        }
        let unitStateBeforeCommanderChainRead = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateBeforeCommanderChainRead = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesBeforeCommanderChainRead = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        let turnBeforeCommanderChainRead = viewModel.state.turn
        let activeFactionBeforeCommanderChainRead = viewModel.state.activeFaction
        let commanderChainWarMerit = viewModel.selectedWarMeritStatus
        let commanderChainSynergy = viewModel.selectedCommanderSynergySummary
        let commanderChainStagePreview = viewModel.selectedBattleObjectiveStageCommandPreview
        let commanderChainSituation = viewModel.selectedUnitSituationReadout
        guard let commanderChainReadout = viewModel.selectedCommanderChainReadout,
              commanderChainReadout.unitID == "rome-legion-1",
              commanderChainReadout.references(brief: commanderBrief),
              commanderChainReadout.references(skillTargetReadout: skillTargetReadout),
              commanderChainReadout.references(guidance: commanderGuidance, unitID: "rome-legion-1"),
              !commanderChainReadout.title.isEmpty,
              !commanderChainReadout.statusLabel.isEmpty,
              !commanderChainReadout.passiveLabel.isEmpty,
              !commanderChainReadout.skillTargetLabel.isEmpty,
              !commanderChainReadout.warMeritLabel.isEmpty,
              !commanderChainReadout.entryLabel.isEmpty,
              !commanderChainReadout.summaryLabel.isEmpty,
              !commanderChainReadout.accessibilityLabel.isEmpty,
              commanderChainReadout.accessibilityLabel.contains("被动"),
              commanderChainReadout.accessibilityLabel.contains("目标"),
              commanderChainReadout.accessibilityLabel.contains("战功"),
              commanderChainReadout.accessibilityLabel.contains("将令"),
              commanderChainReadout.accessibilityLabel.contains("入口"),
              !commanderChainReadout.signals.isEmpty,
              commanderChainReadout.signals.allSatisfy({ signal in
                  !signal.title.isEmpty &&
                      !signal.detail.isEmpty &&
                      !signal.accessibilityLabel.isEmpty &&
                      signal.sourceID != nil
              }),
              commanderChainReadout.signals.contains(where: { $0.kind == .passive && $0.sourceID == commanderBrief.unitID }),
              commanderChainReadout.signals.contains(where: { $0.kind == .skillTarget && $0.sourceID == skillTargetReadout.title }),
              commanderChainReadout.signals.contains(where: { $0.kind == .guidance }) else {
            throw PreviewRenderError.missingCommanderChainReadout
        }
        if let commanderChainWarMerit {
            guard commanderChainReadout.references(warMerit: commanderChainWarMerit),
                  commanderChainReadout.signals.contains(where: { $0.kind == .warMerit }) else {
                throw PreviewRenderError.missingCommanderChainReadout
            }
        }
        if let commanderChainSynergy {
            guard commanderChainReadout.references(synergy: commanderChainSynergy),
                  commanderChainReadout.signals.contains(where: { $0.kind == .synergy && $0.sourceID == commanderChainSynergy.id }) else {
                throw PreviewRenderError.missingCommanderChainReadout
            }
        }
        if let commanderChainStagePreview {
            guard commanderChainReadout.references(stagePreview: commanderChainStagePreview),
                  commanderChainReadout.signals.contains(where: { $0.kind == .objectiveStage && $0.sourceID == commanderChainStagePreview.id }) else {
                throw PreviewRenderError.missingCommanderChainReadout
            }
        }
        if let commanderChainSituation {
            guard commanderChainReadout.references(situation: commanderChainSituation),
                  commanderChainReadout.signals.contains(where: { $0.kind == .situationEntry }) else {
                throw PreviewRenderError.missingCommanderChainReadout
            }
        }
        let unitStateAfterCommanderChainRead = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateAfterCommanderChainRead = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesAfterCommanderChainRead = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        guard unitStateBeforeCommanderChainRead == unitStateAfterCommanderChainRead,
              cityStateBeforeCommanderChainRead == cityStateAfterCommanderChainRead,
              resourcesBeforeCommanderChainRead == resourcesAfterCommanderChainRead,
              turnBeforeCommanderChainRead == viewModel.state.turn,
              activeFactionBeforeCommanderChainRead == viewModel.state.activeFaction else {
            throw PreviewRenderError.missingCommanderChainReadout
        }
        guard let formationSummary = viewModel.selectedLegionFormationSummary,
              let primaryFormationSummary = viewModel.primaryLegionFormationSummary,
              formationSummary.report.unitID == "rome-legion-1",
              primaryFormationSummary.report.unitID == "rome-legion-1",
              !formationSummary.roleLabel.isEmpty,
              !formationSummary.readinessLabel.isEmpty,
              !formationSummary.recommendationLabel.isEmpty,
              !formationSummary.accessibilityLabel.isEmpty else {
            throw PreviewRenderError.missingLegionFormationSummary
        }
        guard let developmentSummary = viewModel.selectedUnitDevelopmentDecisionSummary,
              developmentSummary.unitID == "rome-legion-1",
              let trainingPreview = developmentSummary.trainingPreview,
              let appointmentPreview = developmentSummary.appointmentPreview,
              let trainingOption = developmentSummary.trainingOption,
              let appointmentOption = developmentSummary.appointmentOption,
              !developmentSummary.title.isEmpty,
              !developmentSummary.accessibilityLabel.isEmpty,
              trainingPreview.projectedExperience > trainingPreview.currentExperience,
              !trainingPreview.summary.isEmpty,
              !trainingPreview.detail.isEmpty,
              !trainingOption.costLabel.isEmpty,
              !trainingOption.impactLabel.isEmpty,
              !trainingOption.statusLabel.isEmpty,
              !trainingOption.accessibilityLabel.isEmpty,
              appointmentPreview.candidateName != nil,
              appointmentPreview.candidateTrait != nil,
              !appointmentPreview.summary.isEmpty,
              !appointmentPreview.detail.isEmpty,
              !appointmentOption.costLabel.isEmpty,
              !appointmentOption.impactLabel.isEmpty,
              !appointmentOption.statusLabel.isEmpty,
              !appointmentOption.accessibilityLabel.isEmpty else {
            throw PreviewRenderError.missingUnitDevelopmentDecisionSummary
        }
        let developmentRecommendations = viewModel.unitDevelopmentRecommendationSummaries
        guard let primaryDevelopmentRecommendation = viewModel.primaryUnitDevelopmentRecommendationSummary,
              !developmentRecommendations.isEmpty,
              developmentRecommendations.contains(where: { $0.kind == .training }),
              developmentRecommendations.contains(where: { $0.kind == .appointment }),
              !primaryDevelopmentRecommendation.title.isEmpty,
              !primaryDevelopmentRecommendation.compactTitle.isEmpty,
              !primaryDevelopmentRecommendation.priorityLabel.isEmpty,
              !primaryDevelopmentRecommendation.reasonLabel.isEmpty,
              !primaryDevelopmentRecommendation.impactLabel.isEmpty,
              !primaryDevelopmentRecommendation.statusLabel.isEmpty,
              !primaryDevelopmentRecommendation.accessibilityLabel.isEmpty else {
            throw PreviewRenderError.missingUnitDevelopmentRecommendationSummary
        }
        guard let selectedSynergySummary = viewModel.selectedCommanderSynergySummary,
              let primarySynergySummary = viewModel.primaryCommanderSynergySummary,
              !viewModel.commanderSynergySummaries.isEmpty,
              selectedSynergySummary.report.unitID == "rome-legion-1",
              primarySynergySummary.report.unitID == "rome-legion-1",
              !selectedSynergySummary.kindLabel.isEmpty,
              !selectedSynergySummary.targetLabel.isEmpty,
              !selectedSynergySummary.impactLabel.isEmpty,
              !selectedSynergySummary.detail.isEmpty,
              !selectedSynergySummary.accessibilityLabel.isEmpty else {
            throw PreviewRenderError.missingCommanderSynergySummary
        }
        let unitStateBeforeSynergyStepRead = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateBeforeSynergyStepRead = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesBeforeSynergyStepRead = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        let turnBeforeSynergyStepRead = viewModel.state.turn
        let activeFactionBeforeSynergyStepRead = viewModel.state.activeFaction
        let synergyStepReadouts = selectedSynergySummary.stepReadouts
        guard !synergyStepReadouts.isEmpty,
              synergyStepReadouts.count == selectedSynergySummary.report.steps.count,
              !selectedSynergySummary.stepSequenceLabel.isEmpty,
              !selectedSynergySummary.stepAccessibilityLabel.isEmpty,
              selectedSynergySummary.stepAccessibilityLabel.contains("姿态"),
              selectedSynergySummary.stepAccessibilityLabel.contains("目标"),
              synergyStepReadouts.allSatisfy({ step in
                  !step.roleLabel.isEmpty &&
                      !step.unitLabel.isEmpty &&
                      !step.positionLabel.isEmpty &&
                      !step.targetLabel.isEmpty &&
                      !step.orderLabel.isEmpty &&
                      !step.compactLabel.isEmpty &&
                      !step.routeLabel.isEmpty &&
                      !step.detailLabel.isEmpty &&
                      !step.accessibilityLabel.isEmpty
              }),
              synergyStepReadouts.contains(where: { $0.role == .commander || $0.role == .mainEffort }),
              synergyStepReadouts.contains(where: { $0.step.unitID == selectedSynergySummary.report.unitID }),
              synergyStepReadouts.contains(where: { $0.positionLabel == Position(x: 3, y: 3).description }),
              viewModel.state.units
                  .sorted(by: { $0.id < $1.id })
                  .map({ unit in
                      "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
                  }) == unitStateBeforeSynergyStepRead,
              viewModel.state.cities
                  .sorted(by: { $0.id < $1.id })
                  .map({ city in
                      "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
                  }) == cityStateBeforeSynergyStepRead,
              viewModel.state.resources
                  .sorted(by: { $0.key.rawValue < $1.key.rawValue })
                  .map({ entry in
                      let resources = entry.value
                      return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
                  }) == resourcesBeforeSynergyStepRead,
              viewModel.state.turn == turnBeforeSynergyStepRead,
              viewModel.state.activeFaction == activeFactionBeforeSynergyStepRead else {
            throw PreviewRenderError.missingCommanderSynergyStepReadout
        }
        guard let recommendationSummary = viewModel.selectedTacticalRecommendationSummary,
              recommendationSummary.report.unitID == "rome-legion-1",
              !recommendationSummary.kindLabel.isEmpty,
              !recommendationSummary.targetLabel.isEmpty,
              !recommendationSummary.pathLabel.isEmpty,
              !recommendationSummary.report.command.isEmpty,
              !recommendationSummary.routeSegments.isEmpty,
              !viewModel.selectedTacticalRecommendationPathPositions.isEmpty,
              viewModel.selectedTacticalRecommendationTargetPosition != nil else {
            throw PreviewRenderError.missingTacticalRecommendationSummary
        }
        guard let primaryManeuverSummary = viewModel.primaryManeuverOptionSummary,
              !viewModel.selectedManeuverOptionSummaries.isEmpty,
              !viewModel.maneuverOptionOverlaysByPosition.isEmpty,
              !viewModel.maneuverOptionOverlayPositions.isEmpty,
              viewModel.maneuverOptionOverlayPositions.contains(primaryManeuverSummary.destination),
              primaryManeuverSummary.report.unitID == "rome-legion-1",
              !primaryManeuverSummary.kindLabel.isEmpty,
              !primaryManeuverSummary.destinationLabel.isEmpty,
              !primaryManeuverSummary.targetLabel.isEmpty,
              !primaryManeuverSummary.impactLabel.isEmpty,
              !primaryManeuverSummary.riskLabel.isEmpty,
              !primaryManeuverSummary.detail.isEmpty,
              !primaryManeuverSummary.accessibilityLabel.isEmpty else {
            throw PreviewRenderError.missingManeuverOptionSummary
        }
        guard let objectiveChain = viewModel.primaryBattleObjectiveChainSummary,
              objectiveChain.references(focus: battlefieldFocus),
              objectiveChain.references(synergy: selectedSynergySummary),
              objectiveChain.references(maneuver: primaryManeuverSummary),
              objectiveChain.references(recommendation: recommendationSummary),
              !objectiveChain.title.isEmpty,
              !objectiveChain.focusStageLabel.isEmpty,
              !objectiveChain.synergyStageLabel.isEmpty,
              !objectiveChain.maneuverStageLabel.isEmpty,
              !objectiveChain.recommendationStageLabel.isEmpty,
              !objectiveChain.chainLabel.isEmpty,
              !objectiveChain.compactLabel.isEmpty,
              !objectiveChain.priorityLabel.isEmpty,
              !objectiveChain.accessibilityLabel.isEmpty,
              !battlefieldFocus.objectiveCueLabel.isEmpty,
              !selectedSynergySummary.objectiveCueLabel.isEmpty,
              !primaryManeuverSummary.objectiveCueLabel.isEmpty,
              !recommendationSummary.objectiveCueLabel.isEmpty else {
            throw PreviewRenderError.missingBattleObjectiveChainSummary
        }
        let unitStateBeforeConvergenceRead = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateBeforeConvergenceRead = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesBeforeConvergenceRead = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        let turnBeforeConvergenceRead = viewModel.state.turn
        let activeFactionBeforeConvergenceRead = viewModel.state.activeFaction
        let activeStagePreviewForConvergence = viewModel.activeBattleObjectiveStageCommandPreview
        let primaryThreatHeatForConvergence = viewModel.primaryThreatHeatZoneSummary
        let activeMapControlForConvergence = viewModel.selectedMapControlSummary ?? viewModel.primaryMapControlSummary
        guard let battlefieldConvergence = viewModel.primaryBattlefieldConvergenceSummary,
              battlefieldConvergence.references(objectiveChain: objectiveChain),
              battlefieldConvergence.references(countermeasure: countermeasure),
              battlefieldConvergence.references(countermeasurePreview: countermeasureCommandPreview),
              activeStagePreviewForConvergence.map({ battlefieldConvergence.references(stagePreview: $0) }) ?? true,
              battlefieldConvergence.references(synergy: selectedSynergySummary),
              battlefieldConvergence.references(maneuver: primaryManeuverSummary),
              primaryThreatHeatForConvergence.map({ battlefieldConvergence.references(threatHeat: $0) }) ?? true,
              activeMapControlForConvergence.map({ battlefieldConvergence.references(mapControl: $0) }) ?? true,
              !battlefieldConvergence.title.isEmpty,
              !battlefieldConvergence.compactLabel.isEmpty,
              !battlefieldConvergence.priorityLabel.isEmpty,
              !battlefieldConvergence.objectiveLabel.isEmpty,
              !battlefieldConvergence.responseLabel.isEmpty,
              !battlefieldConvergence.spaceLabel.isEmpty,
              !battlefieldConvergence.nextStepLabel.isEmpty,
              !battlefieldConvergence.riskLabel.isEmpty,
              !battlefieldConvergence.accessibilityLabel.isEmpty,
              battlefieldConvergence.hasSignals,
              battlefieldConvergence.signals.contains(where: { $0.role == .objective && $0.sourceID == objectiveChain.id && $0.position == battlefieldFocus.targetPosition }),
              battlefieldConvergence.signals.contains(where: { $0.role == .countermeasure && $0.sourceID == countermeasure.id && $0.position == countermeasure.targetPosition }),
              battlefieldConvergence.signals.contains(where: { $0.role == .synergy && $0.sourceID == selectedSynergySummary.id && $0.position == selectedSynergySummary.targetPosition }),
              battlefieldConvergence.signals.contains(where: { $0.role == .maneuver && $0.sourceID == primaryManeuverSummary.id && $0.position == primaryManeuverSummary.destination }),
              primaryThreatHeatForConvergence.map({ heat in
                  battlefieldConvergence.signals.contains(where: { $0.role == .threatHeat && $0.sourceID == heat.id && $0.position == heat.targetPosition })
              }) ?? true,
              battlefieldConvergence.signals.allSatisfy({ signal in
                  !signal.id.isEmpty &&
                      !signal.title.isEmpty &&
                      !signal.detail.isEmpty &&
                      signal.sourceID?.isEmpty == false &&
                      signal.position != nil &&
                      !signal.accessibilityLabel.isEmpty
              }) else {
            throw PreviewRenderError.missingBattlefieldConvergenceSummary
        }
        let unitStateAfterConvergenceRead = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateAfterConvergenceRead = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesAfterConvergenceRead = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        guard unitStateAfterConvergenceRead == unitStateBeforeConvergenceRead,
              cityStateAfterConvergenceRead == cityStateBeforeConvergenceRead,
              resourcesAfterConvergenceRead == resourcesBeforeConvergenceRead,
              viewModel.state.turn == turnBeforeConvergenceRead,
              viewModel.state.activeFaction == activeFactionBeforeConvergenceRead else {
            throw PreviewRenderError.missingBattlefieldConvergenceSummary
        }
        let unitStateBeforeEngagementLoopRead = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateBeforeEngagementLoopRead = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesBeforeEngagementLoopRead = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        let turnBeforeEngagementLoopRead = viewModel.state.turn
        let activeFactionBeforeEngagementLoopRead = viewModel.state.activeFaction
        guard let engagementLoop = viewModel.primaryEnemyEngagementLoopReadout,
              engagementLoop.references(intent: advanceOverlay),
              engagementLoop.references(pressure: frontlinePressure),
              engagementLoop.references(enemyCommanderThreat: enemyCommanderThreat),
              engagementLoop.references(countermeasure: countermeasure),
              engagementLoop.references(countermeasurePreview: countermeasureCommandPreview),
              engagementLoop.references(responseCommanderChain: commanderChainReadout),
              engagementLoop.references(convergence: battlefieldConvergence),
              !engagementLoop.title.isEmpty,
              !engagementLoop.statusLabel.isEmpty,
              !engagementLoop.intentLabel.isEmpty,
              !engagementLoop.pressureLabel.isEmpty,
              !engagementLoop.enemyCommanderLabel.isEmpty,
              !engagementLoop.countermeasureLabel.isEmpty,
              !engagementLoop.responseLabel.isEmpty,
              !engagementLoop.nextStepLabel.isEmpty,
              !engagementLoop.riskLabel.isEmpty,
              !engagementLoop.compactLabel.isEmpty,
              !engagementLoop.accessibilityLabel.isEmpty,
              engagementLoop.accessibilityLabel.contains("敌路"),
              engagementLoop.accessibilityLabel.contains("压力"),
              engagementLoop.accessibilityLabel.contains("敌将"),
              engagementLoop.accessibilityLabel.contains("反制"),
              engagementLoop.accessibilityLabel.contains("回应"),
              engagementLoop.accessibilityLabel.contains("下一步"),
              engagementLoop.hasSignals,
              engagementLoop.signals.contains(where: { $0.kind == .intentRoute && $0.sourceID == advanceOverlay.id }),
              engagementLoop.signals.contains(where: { $0.kind == .frontline && $0.sourceID == frontlinePressure.id }),
              engagementLoop.signals.contains(where: { $0.kind == .enemyCommander && $0.sourceID == enemyCommanderThreat.id }),
              engagementLoop.signals.contains(where: { $0.kind == .countermeasure && $0.sourceID == countermeasure.id }),
              engagementLoop.signals.contains(where: { $0.kind == .counterCommand && $0.sourceID == countermeasureCommandPreview.id }),
              engagementLoop.signals.contains(where: { $0.kind == .responseCommander && $0.sourceID == commanderChainReadout.unitID }),
              engagementLoop.signals.contains(where: { $0.kind == .convergence && $0.sourceID == battlefieldConvergence.id }),
              engagementLoop.signals.allSatisfy({ signal in
                  !signal.id.isEmpty &&
                      !signal.title.isEmpty &&
                      !signal.detail.isEmpty &&
                      !signal.sourceID.isEmpty &&
                      !signal.accessibilityLabel.isEmpty
              }) else {
            throw PreviewRenderError.missingEnemyEngagementLoopReadout
        }
        let unitStateAfterEngagementLoopRead = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateAfterEngagementLoopRead = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesAfterEngagementLoopRead = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        guard unitStateBeforeEngagementLoopRead == unitStateAfterEngagementLoopRead,
              cityStateBeforeEngagementLoopRead == cityStateAfterEngagementLoopRead,
              resourcesBeforeEngagementLoopRead == resourcesAfterEngagementLoopRead,
              turnBeforeEngagementLoopRead == viewModel.state.turn,
              activeFactionBeforeEngagementLoopRead == viewModel.state.activeFaction else {
            throw PreviewRenderError.missingEnemyEngagementLoopReadout
        }
        let unitStateBeforeCommanderBridgeRead = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateBeforeCommanderBridgeRead = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesBeforeCommanderBridgeRead = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        let turnBeforeCommanderBridgeRead = viewModel.state.turn
        let activeFactionBeforeCommanderBridgeRead = viewModel.state.activeFaction
        let bridgeCountermeasurePreview = viewModel.selectedCountermeasureCommandPreview ?? countermeasureCommandPreview
        let bridgeStagePreview = viewModel.selectedBattleObjectiveStageCommandPreview ?? viewModel.primaryBattleObjectiveStageCommandPreview
        guard let commanderBridgeReadout = viewModel.selectedCommanderOpportunityBridgeReadout,
              commanderBridgeReadout.unitID == "rome-legion-1",
              commanderBridgeReadout.references(brief: commanderBrief),
              commanderBridgeReadout.references(chain: commanderChainReadout),
              commanderBridgeReadout.references(skillTargetReadout: skillTargetReadout),
              commanderBridgeReadout.references(guidance: commanderGuidance, unitID: "rome-legion-1"),
              commanderBridgeReadout.references(synergy: selectedSynergySummary),
              commanderBridgeReadout.references(enemyCommanderThreat: enemyCommanderThreat),
              commanderBridgeReadout.references(countermeasure: countermeasure),
              commanderBridgeReadout.references(countermeasurePreview: bridgeCountermeasurePreview),
              bridgeStagePreview.map({ commanderBridgeReadout.references(stagePreview: $0) }) ?? false,
              commanderBridgeReadout.references(engagementLoop: engagementLoop),
              !commanderBridgeReadout.title.isEmpty,
              !commanderBridgeReadout.statusLabel.isEmpty,
              !commanderBridgeReadout.opportunityLabel.isEmpty,
              !commanderBridgeReadout.skillWindowLabel.isEmpty,
              !commanderBridgeReadout.enemyThreatLabel.isEmpty,
              !commanderBridgeReadout.counterLabel.isEmpty,
              !commanderBridgeReadout.entryLabel.isEmpty,
              !commanderBridgeReadout.nextStepLabel.isEmpty,
              !commanderBridgeReadout.riskLabel.isEmpty,
              !commanderBridgeReadout.compactLabel.isEmpty,
              !commanderBridgeReadout.accessibilityLabel.isEmpty,
              commanderBridgeReadout.accessibilityLabel.contains("战机"),
              commanderBridgeReadout.accessibilityLabel.contains("敌将"),
              commanderBridgeReadout.accessibilityLabel.contains("反制"),
              commanderBridgeReadout.accessibilityLabel.contains("入口"),
              commanderBridgeReadout.accessibilityLabel.contains("下一步"),
              commanderBridgeReadout.hasSignals,
              commanderBridgeReadout.signals.contains(where: { $0.kind == .commanderBrief && $0.sourceID == commanderBrief.unitID }),
              commanderBridgeReadout.signals.contains(where: { $0.kind == .commanderChain && $0.sourceID == commanderChainReadout.unitID }),
              commanderBridgeReadout.signals.contains(where: { $0.kind == .skillWindow && $0.sourceID == skillTargetReadout.title }),
              commanderBridgeReadout.signals.contains(where: { $0.kind == .guidance }),
              commanderBridgeReadout.signals.contains(where: { $0.kind == .synergy && $0.sourceID == selectedSynergySummary.id }),
              commanderBridgeReadout.signals.contains(where: { $0.kind == .enemyCommander && $0.sourceID == enemyCommanderThreat.id }),
              commanderBridgeReadout.signals.contains(where: { $0.kind == .countermeasure && $0.sourceID == countermeasure.id }),
              commanderBridgeReadout.signals.contains(where: { $0.kind == .counterCommand && $0.sourceID == bridgeCountermeasurePreview.id }),
              bridgeStagePreview.map({ stagePreview in
                  commanderBridgeReadout.signals.contains(where: { $0.kind == .objectiveStage && $0.sourceID == stagePreview.id })
              }) ?? false,
              commanderBridgeReadout.signals.contains(where: { $0.kind == .engagementLoop && $0.sourceID == engagementLoop.compactLabel }),
              commanderBridgeReadout.signals.allSatisfy({ signal in
                  !signal.id.isEmpty &&
                      !signal.title.isEmpty &&
                      !signal.detail.isEmpty &&
                      !signal.sourceID.isEmpty &&
                      !signal.accessibilityLabel.isEmpty
              }) else {
            throw PreviewRenderError.missingCommanderOpportunityBridgeReadout
        }
        let unitStateAfterCommanderBridgeRead = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateAfterCommanderBridgeRead = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesAfterCommanderBridgeRead = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        guard unitStateBeforeCommanderBridgeRead == unitStateAfterCommanderBridgeRead,
              cityStateBeforeCommanderBridgeRead == cityStateAfterCommanderBridgeRead,
              resourcesBeforeCommanderBridgeRead == resourcesAfterCommanderBridgeRead,
              turnBeforeCommanderBridgeRead == viewModel.state.turn,
              activeFactionBeforeCommanderBridgeRead == viewModel.state.activeFaction else {
            throw PreviewRenderError.missingCommanderOpportunityBridgeReadout
        }
        let unitStateBeforeOrderWindowRead = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateBeforeOrderWindowRead = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesBeforeOrderWindowRead = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        let turnBeforeOrderWindowRead = viewModel.state.turn
        let activeFactionBeforeOrderWindowRead = viewModel.state.activeFaction
        let orderWindowRecommendedOrder = viewModel.selectedTacticalOrderPreviews.first { !$0.isCurrent && $0.canSwitch } ??
            viewModel.selectedTacticalOrderPreviews.first { $0.isCurrent } ??
            viewModel.selectedTacticalOrderPreviews.first
        guard let orderWindowReadout = viewModel.selectedUnitOrderWindowReadout,
              orderWindowReadout.unitID == "rome-legion-1",
              orderWindowReadout.references(situation: selectedSituation),
              orderWindowReadout.references(countermeasurePreview: bridgeCountermeasurePreview),
              bridgeStagePreview.map({ orderWindowReadout.references(stagePreview: $0) }) ?? false,
              orderWindowReadout.references(commanderBridge: commanderBridgeReadout),
              orderWindowReadout.references(commanderChain: commanderChainReadout),
              orderWindowReadout.references(recommendation: recommendationSummary),
              orderWindowReadout.references(maneuver: primaryManeuverSummary),
              orderWindowReadout.references(engagementLoop: engagementLoop),
              orderWindowReadout.references(convergence: battlefieldConvergence),
              orderWindowRecommendedOrder.map({ orderWindowReadout.references(recommendedOrder: $0) }) ?? false,
              !orderWindowReadout.title.isEmpty,
              !orderWindowReadout.statusLabel.isEmpty,
              !orderWindowReadout.openingLabel.isEmpty,
              !orderWindowReadout.postureLabel.isEmpty,
              !orderWindowReadout.movementLabel.isEmpty,
              !orderWindowReadout.strikeLabel.isEmpty,
              !orderWindowReadout.commanderLabel.isEmpty,
              !orderWindowReadout.counterLabel.isEmpty,
              !orderWindowReadout.nextStepLabel.isEmpty,
              !orderWindowReadout.riskLabel.isEmpty,
              !orderWindowReadout.compactLabel.isEmpty,
              !orderWindowReadout.accessibilityLabel.isEmpty,
              orderWindowReadout.accessibilityLabel.contains("军令"),
              orderWindowReadout.accessibilityLabel.contains("姿态"),
              orderWindowReadout.accessibilityLabel.contains("机动"),
              orderWindowReadout.accessibilityLabel.contains("反制"),
              orderWindowReadout.accessibilityLabel.contains("下一步"),
              orderWindowReadout.hasSteps,
              orderWindowReadout.steps.contains(where: { $0.kind == .countermeasure && $0.sourceID == bridgeCountermeasurePreview.id }),
              bridgeStagePreview.map({ stagePreview in
                  orderWindowReadout.steps.contains(where: { $0.kind == .objectiveStage && $0.sourceID == stagePreview.id })
              }) ?? false,
              orderWindowReadout.steps.contains(where: { $0.kind == .commander && $0.sourceID == "\(commanderBridgeReadout.unitID)-\(commanderBridgeReadout.compactLabel)" }),
              orderWindowReadout.steps.contains(where: { $0.kind == .maneuver && $0.sourceID == primaryManeuverSummary.id }),
              orderWindowReadout.steps.contains(where: { $0.kind == .recommendation && $0.sourceID == recommendationSummary.id }),
              orderWindowRecommendedOrder.map({ preview in
                  orderWindowReadout.steps.contains(where: { $0.kind == .tacticalOrder && $0.sourceID == preview.order.rawValue })
              }) ?? false,
              orderWindowReadout.steps.contains(where: { $0.kind == .engagement && $0.sourceID == engagementLoop.compactLabel }),
              orderWindowReadout.steps.contains(where: { $0.kind == .convergence && $0.sourceID == battlefieldConvergence.id }),
              orderWindowReadout.steps.allSatisfy({ step in
                  !step.id.isEmpty &&
                      !step.title.isEmpty &&
                      !step.detail.isEmpty &&
                      !step.cueLabel.isEmpty &&
                      !step.sourceID.isEmpty &&
                      !step.accessibilityLabel.isEmpty
              }) else {
            throw PreviewRenderError.missingSelectedUnitOrderWindowReadout
        }
        let unitStateAfterOrderWindowRead = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateAfterOrderWindowRead = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesAfterOrderWindowRead = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        guard unitStateBeforeOrderWindowRead == unitStateAfterOrderWindowRead,
              cityStateBeforeOrderWindowRead == cityStateAfterOrderWindowRead,
              resourcesBeforeOrderWindowRead == resourcesAfterOrderWindowRead,
              turnBeforeOrderWindowRead == viewModel.state.turn,
              activeFactionBeforeOrderWindowRead == viewModel.state.activeFaction else {
            throw PreviewRenderError.missingSelectedUnitOrderWindowReadout
        }
        guard let battleObjectiveOverlay = viewModel.primaryBattleObjectiveMapOverlay,
              battleObjectiveOverlay.references(chain: objectiveChain),
              !battleObjectiveOverlay.chainLabel.isEmpty,
              !battleObjectiveOverlay.accessibilityLabel.isEmpty,
              !battleObjectiveOverlay.positionOverlays.isEmpty,
              !battleObjectiveOverlay.routeSegments.isEmpty,
              !viewModel.battleObjectiveRouteSegments.isEmpty,
              !viewModel.battleObjectiveOverlaysByPosition.isEmpty,
              !viewModel.battleObjectiveOverlayPositions.isEmpty,
              viewModel.battleObjectiveOverlayPositions.contains(battlefieldFocus.targetPosition),
              viewModel.battleObjectiveOverlaysByPosition[battlefieldFocus.targetPosition]?.contains(where: { overlay in
                  overlay.role == .focus &&
                      overlay.position == battlefieldFocus.targetPosition &&
                      !overlay.stageLabel.isEmpty &&
                      !overlay.focusLabel.isEmpty &&
                      !overlay.chainLabel.isEmpty &&
                      !overlay.accessibilityLabel.isEmpty
              }) == true,
              viewModel.battleObjectiveOverlayPositions.contains(selectedSynergySummary.targetPosition),
              viewModel.battleObjectiveOverlaysByPosition[selectedSynergySummary.targetPosition]?.contains(where: { overlay in
                  overlay.role == .synergy &&
                      overlay.position == selectedSynergySummary.targetPosition &&
                      !overlay.stageLabel.isEmpty &&
                      !overlay.focusLabel.isEmpty &&
                      !overlay.accessibilityLabel.isEmpty
              }) == true,
              viewModel.battleObjectiveOverlayPositions.contains(primaryManeuverSummary.destination),
              viewModel.battleObjectiveOverlaysByPosition[primaryManeuverSummary.destination]?.contains(where: { overlay in
                  overlay.role == .maneuver &&
                      overlay.position == primaryManeuverSummary.destination &&
                      !overlay.stageLabel.isEmpty &&
                      !overlay.focusLabel.isEmpty &&
                      !overlay.accessibilityLabel.isEmpty
              }) == true,
              viewModel.battleObjectiveOverlayPositions.contains(recommendationSummary.targetPosition),
              viewModel.battleObjectiveOverlaysByPosition[recommendationSummary.targetPosition]?.contains(where: { overlay in
                  overlay.role == .recommendation &&
                      overlay.position == recommendationSummary.targetPosition &&
                      !overlay.stageLabel.isEmpty &&
                      !overlay.focusLabel.isEmpty &&
                      !overlay.accessibilityLabel.isEmpty
              }) == true,
              battleObjectiveOverlay.routeSegments.allSatisfy({ segment in
                  !segment.id.isEmpty &&
                      battleObjectiveOverlay.positionOverlays.contains(where: { $0.position == segment.from }) &&
                      battleObjectiveOverlay.positionOverlays.contains(where: { $0.position == segment.to })
              }) else {
            throw PreviewRenderError.missingBattleObjectiveMapOverlay
        }
        let unitStateBeforeReconRead = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateBeforeReconRead = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesBeforeReconRead = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        let turnBeforeReconRead = viewModel.state.turn
        let activeFactionBeforeReconRead = viewModel.state.activeFaction
        viewModel.selectMapReconPerspective(.enemyIntent)
        let enemyReconReadout = viewModel.mapReconPerspectiveHUDReadout
        guard viewModel.selectedMapReconPerspective == .enemyIntent,
              enemyReconReadout.selectedKind == .enemyIntent,
              enemyReconReadout.availableKinds == MapReconPerspectiveKind.allCases,
              enemyReconReadout.references(intent: advanceOverlay),
              enemyReconReadout.references(engagementLoop: engagementLoop),
              enemyReconReadout.hasSignals,
              enemyReconReadout.signals.contains(where: { $0.kind == .enemyIntent && $0.sourceID == advanceOverlay.id }),
              enemyReconReadout.signals.contains(where: { $0.kind == .engagementLoop }),
              !enemyReconReadout.title.isEmpty,
              !enemyReconReadout.statusLabel.isEmpty,
              !enemyReconReadout.compactLabel.isEmpty,
              !enemyReconReadout.detailLabel.isEmpty,
              !enemyReconReadout.nextStepLabel.isEmpty,
              !enemyReconReadout.riskLabel.isEmpty,
              !enemyReconReadout.selectorLabel.isEmpty,
              !enemyReconReadout.accessibilityLabel.isEmpty,
              enemyReconReadout.accessibilityLabel.contains("侦察"),
              viewModel.bannerMessage.contains("敌路") else {
            throw PreviewRenderError.missingMapReconnaissanceViewHUD
        }
        viewModel.selectMapReconPerspective(.countermeasure)
        let counterReconReadout = viewModel.mapReconPerspectiveHUDReadout
        guard viewModel.selectedMapReconPerspective == .countermeasure,
              counterReconReadout.selectedKind == .countermeasure,
              counterReconReadout.references(countermeasure: countermeasure),
              counterReconReadout.references(countermeasurePreview: countermeasureCommandPreview),
              counterReconReadout.hasSignals,
              counterReconReadout.signals.contains(where: { $0.kind == .countermeasure && $0.sourceID == countermeasure.id }),
              counterReconReadout.signals.contains(where: { $0.kind == .counterCommand && $0.sourceID == countermeasureCommandPreview.id }),
              !counterReconReadout.detailLabel.isEmpty,
              !counterReconReadout.nextStepLabel.isEmpty,
              viewModel.bannerMessage.contains("反制") else {
            throw PreviewRenderError.missingMapReconnaissanceViewHUD
        }
        viewModel.selectMapReconPerspective(.objective)
        let reconObjectiveStagePreview = viewModel.activeBattleObjectiveStageCommandPreview
        let objectiveReconReadout = viewModel.mapReconPerspectiveHUDReadout
        guard viewModel.selectedMapReconPerspective == .objective,
              objectiveReconReadout.selectedKind == .objective,
              objectiveReconReadout.references(objectiveChain: objectiveChain),
              reconObjectiveStagePreview.map({ objectiveReconReadout.references(stagePreview: $0) }) ?? false,
              objectiveReconReadout.hasSignals,
              objectiveReconReadout.signals.contains(where: { $0.kind == .objectiveChain && $0.sourceID == objectiveChain.id }),
              reconObjectiveStagePreview.map({ stagePreview in
                  objectiveReconReadout.signals.contains(where: { $0.kind == .objectiveStage && $0.sourceID == stagePreview.id })
              }) ?? false,
              !objectiveReconReadout.detailLabel.isEmpty,
              !objectiveReconReadout.nextStepLabel.isEmpty,
              viewModel.bannerMessage.contains("目标线") else {
            throw PreviewRenderError.missingMapReconnaissanceViewHUD
        }
        viewModel.selectMapReconPerspective(.terrainPressure)
        let terrainReconReadout = viewModel.mapReconPerspectiveHUDReadout
        guard viewModel.selectedMapReconPerspective == .terrainPressure,
              terrainReconReadout.selectedKind == .terrainPressure,
              terrainReconReadout.hasSignals,
              terrainReconReadout.references(convergence: battlefieldConvergence),
              terrainReconReadout.threatHeatID != nil || terrainReconReadout.mapControlID != nil,
              terrainReconReadout.signals.contains(where: { $0.kind == .threatHeat || $0.kind == .mapControl || $0.kind == .convergence }),
              !terrainReconReadout.detailLabel.isEmpty,
              !terrainReconReadout.nextStepLabel.isEmpty,
              viewModel.bannerMessage.contains("热区") else {
            throw PreviewRenderError.missingMapReconnaissanceViewHUD
        }
        let unitStateAfterReconRead = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateAfterReconRead = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesAfterReconRead = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        guard unitStateBeforeReconRead == unitStateAfterReconRead,
              cityStateBeforeReconRead == cityStateAfterReconRead,
              resourcesBeforeReconRead == resourcesAfterReconRead,
              turnBeforeReconRead == viewModel.state.turn,
              activeFactionBeforeReconRead == viewModel.state.activeFaction else {
            throw PreviewRenderError.missingMapReconnaissanceViewHUD
        }
        let unitStateBeforeCampaignAdvanceRead = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateBeforeCampaignAdvanceRead = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesBeforeCampaignAdvanceRead = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        let turnBeforeCampaignAdvanceRead = viewModel.state.turn
        let activeFactionBeforeCampaignAdvanceRead = viewModel.state.activeFaction
        let selectedUnitBeforeCampaignAdvanceRead = viewModel.selectedUnitID
        let selectedCityBeforeCampaignAdvanceRead = viewModel.selectedCityID
        let focusedObjectiveBeforeCampaignAdvanceRead = viewModel.focusedBattleObjectiveRole
        let reconPerspectiveBeforeCampaignAdvanceRead = viewModel.selectedMapReconPerspective
        let campaignMission = viewModel.primaryMission
        let campaignReconReadout = viewModel.mapReconPerspectiveHUDReadout
        guard let campaignAdvance = viewModel.primaryCampaignAdvanceReadout,
              campaignMission.map({ campaignAdvance.references(mission: $0) }) ?? false,
              campaignAdvance.progressLabel == (viewModel.campaignStatus.progressText ?? viewModel.campaignStatus.detail),
              campaignAdvance.references(pressure: frontlinePressure),
              campaignAdvance.references(objectiveChain: objectiveChain),
              reconObjectiveStagePreview.map({ campaignAdvance.references(stagePreview: $0) }) ?? false,
              campaignAdvance.references(recon: campaignReconReadout),
              campaignAdvance.references(convergence: battlefieldConvergence),
              !campaignAdvance.title.isEmpty,
              !campaignAdvance.statusLabel.isEmpty,
              !campaignAdvance.missionTitle.isEmpty,
              !campaignAdvance.missionObjectiveLabel.isEmpty,
              !campaignAdvance.progressLabel.isEmpty,
              !campaignAdvance.frontlineLabel.isEmpty,
              !campaignAdvance.objectiveLineLabel.isEmpty,
              !campaignAdvance.mapCueLabel.isEmpty,
              !campaignAdvance.nextStepLabel.isEmpty,
              !campaignAdvance.riskLabel.isEmpty,
              !campaignAdvance.compactLabel.isEmpty,
              !campaignAdvance.accessibilityLabel.isEmpty,
              campaignAdvance.accessibilityLabel.contains("任务"),
              campaignAdvance.accessibilityLabel.contains("进度"),
              campaignAdvance.accessibilityLabel.contains("战线"),
              campaignAdvance.accessibilityLabel.contains("目标线"),
              campaignAdvance.accessibilityLabel.contains("下一步"),
              campaignAdvance.hasSignals,
              campaignAdvance.signals.contains(where: { $0.kind == .mission && $0.sourceID == campaignMission?.id }),
              campaignAdvance.signals.contains(where: { $0.kind == .progress }),
              campaignAdvance.signals.contains(where: { $0.kind == .frontline && $0.sourceID == frontlinePressure.id }),
              campaignAdvance.signals.contains(where: { $0.kind == .objectiveChain && $0.sourceID == objectiveChain.id }),
              reconObjectiveStagePreview.map({ stagePreview in
                  campaignAdvance.signals.contains(where: { $0.kind == .objectiveStage && $0.sourceID == stagePreview.id })
              }) ?? false,
              campaignAdvance.signals.contains(where: { $0.kind == .recon && $0.sourceID == campaignReconReadout.selectedKind.rawValue }),
              campaignAdvance.signals.contains(where: { $0.kind == .convergence && $0.sourceID == battlefieldConvergence.id }),
              campaignAdvance.signals.allSatisfy({ signal in
                  !signal.id.isEmpty &&
                      !signal.title.isEmpty &&
                      !signal.detail.isEmpty &&
                      !signal.accessibilityLabel.isEmpty
              }) else {
            throw PreviewRenderError.missingCampaignAdvanceReadout
        }
        let unitStateAfterCampaignAdvanceRead = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateAfterCampaignAdvanceRead = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesAfterCampaignAdvanceRead = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        guard unitStateBeforeCampaignAdvanceRead == unitStateAfterCampaignAdvanceRead,
              cityStateBeforeCampaignAdvanceRead == cityStateAfterCampaignAdvanceRead,
              resourcesBeforeCampaignAdvanceRead == resourcesAfterCampaignAdvanceRead,
              turnBeforeCampaignAdvanceRead == viewModel.state.turn,
              activeFactionBeforeCampaignAdvanceRead == viewModel.state.activeFaction,
              selectedUnitBeforeCampaignAdvanceRead == viewModel.selectedUnitID,
              selectedCityBeforeCampaignAdvanceRead == viewModel.selectedCityID,
              focusedObjectiveBeforeCampaignAdvanceRead == viewModel.focusedBattleObjectiveRole,
              reconPerspectiveBeforeCampaignAdvanceRead == viewModel.selectedMapReconPerspective else {
            throw PreviewRenderError.missingCampaignAdvanceReadout
        }
        let unitStateBeforeBattleObjectiveFocus = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateBeforeBattleObjectiveFocus = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesBeforeBattleObjectiveFocus = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        let turnBeforeBattleObjectiveFocus = viewModel.state.turn
        let activeFactionBeforeBattleObjectiveFocus = viewModel.state.activeFaction
        let battleObjectiveStageCommandPreviews = viewModel.battleObjectiveStageCommandPreviews
        guard !battleObjectiveStageCommandPreviews.isEmpty,
              viewModel.primaryBattleObjectiveStageCommandPreview != nil else {
            throw PreviewRenderError.missingBattleObjectiveStageCommandPreview
        }
        let expectedBattleObjectiveStages: [(role: BattleObjectiveMapRole, position: Position, sourceSummaryID: String)] = [
            (.focus, battlefieldFocus.targetPosition, battlefieldFocus.id),
            (.synergy, selectedSynergySummary.targetPosition, selectedSynergySummary.id),
            (.maneuver, primaryManeuverSummary.destination, primaryManeuverSummary.id),
            (.recommendation, recommendationSummary.targetPosition, recommendationSummary.id)
        ]
        for stage in expectedBattleObjectiveStages {
            guard let overlay = battleObjectiveOverlay.positionOverlays.first(where: { $0.role == stage.role }),
                  let preview = battleObjectiveStageCommandPreviews.first(where: { $0.role == stage.role }),
                  preview.chainID == objectiveChain.id,
                  preview.role == overlay.role,
                  preview.position == overlay.position,
                  preview.position == stage.position,
                  preview.sourceSummaryID == stage.sourceSummaryID,
                  preview.stageLabel == overlay.stageLabel,
                  preview.focusLabel == overlay.focusLabel,
                  preview.chainLabel == overlay.chainLabel,
                  !preview.title.isEmpty,
                  !preview.statusLabel.isEmpty,
                  !preview.commandEntryLabel.isEmpty,
                  !preview.nextStepLabel.isEmpty,
                  !preview.buttonTitle.isEmpty,
                  !preview.buttonDetail.isEmpty,
                  !preview.accessibilityLabel.isEmpty,
                  !preview.steps.isEmpty,
                  preview.steps.allSatisfy({ step in
                      !step.id.isEmpty &&
                          !step.symbol.isEmpty &&
                          !step.title.isEmpty &&
                          !step.detail.isEmpty
                  }) else {
                throw PreviewRenderError.missingBattleObjectiveStageCommandPreview
            }
        }
        for stage in expectedBattleObjectiveStages {
            viewModel.focusPrimaryBattleObjectiveStage(stage.role)
            guard viewModel.focusedBattleObjectiveRole == stage.role,
                  viewModel.focusedBattleObjectiveOverlay?.role == stage.role,
                  viewModel.focusedBattleObjectiveOverlay?.position == stage.position,
                  let focusedPreview = viewModel.focusedBattleObjectiveStageCommandPreview,
                  focusedPreview.role == stage.role,
                  focusedPreview.position == stage.position,
                  focusedPreview.sourceSummaryID == stage.sourceSummaryID,
                  !focusedPreview.commandEntryLabel.isEmpty,
                  !focusedPreview.nextStepLabel.isEmpty,
                  !focusedPreview.buttonDetail.isEmpty,
                  viewModel.bannerMessage.contains("目标线") else {
                throw PreviewRenderError.missingBattleObjectiveStageCommandPreview
            }
            guard viewModel.activeBattleObjectiveStageRole == stage.role,
                  let activePreview = viewModel.activeBattleObjectiveStageCommandPreview,
                  activePreview.chainID == focusedPreview.chainID,
                  activePreview.role == focusedPreview.role,
                  activePreview.position == focusedPreview.position,
                  activePreview.sourceSummaryID == focusedPreview.sourceSummaryID,
                  viewModel.battleObjectiveOverlaysByPosition[stage.position]?.contains(where: { overlay in
                      overlay.role == stage.role &&
                          overlay.position == stage.position &&
                          overlay.stageLabel == focusedPreview.stageLabel
                  }) == true,
                  activePreview.commandEntryCueLabel.contains(focusedPreview.stageLabel),
                  activePreview.commandEntryCueLabel.contains(focusedPreview.commandEntryLabel),
                  activePreview.recommendedOrderStageCueLabel.contains(focusedPreview.stageLabel),
                  activePreview.recommendedOrderStageCueLabel.contains(focusedPreview.orderCueLabel),
                  activePreview.attackStageCueLabel.contains(focusedPreview.stageLabel),
                  activePreview.attackStageCueLabel.contains(focusedPreview.attackCueLabel),
                  activePreview.skillStageCueLabel.contains(focusedPreview.stageLabel),
                  activePreview.skillStageCueLabel.contains(focusedPreview.skillCueLabel) else {
                throw PreviewRenderError.missingBattleObjectiveStageLinkedHighlight
            }
            if let commandUnit = focusedPreview.commandUnit {
                guard focusedPreview.isCommandUnit(commandUnit),
                      viewModel.selectedBattleObjectiveStageCommandPreview?.role == focusedPreview.role,
                      viewModel.selectedBattleObjectiveStageCommandPreview?.position == focusedPreview.position,
                      viewModel.selectedBattleObjectiveStageCommandPreview?.sourceSummaryID == focusedPreview.sourceSummaryID else {
                    throw PreviewRenderError.missingBattleObjectiveStageLinkedHighlight
                }
            }
            if let recommendedOrder = focusedPreview.recommendedOrder,
               let commandUnit = focusedPreview.commandUnit {
                guard focusedPreview.isRecommendedOrder(recommendedOrder),
                      viewModel.selectedUnitID == commandUnit.id,
                      viewModel.selectedTacticalOrderPreview(for: recommendedOrder) != nil,
                      focusedPreview.recommendedOrderStageCueLabel.contains(recommendedOrder.displayName) else {
                    throw PreviewRenderError.missingBattleObjectiveStageLinkedHighlight
                }
            }
            if focusedPreview.canAttackCurrentTarget,
               let targetUnit = focusedPreview.targetUnit {
                guard viewModel.attackTargets.contains(where: { target in
                    target.id == targetUnit.id &&
                        focusedPreview.isAttackTarget(target) &&
                        focusedPreview.attackStageCueLabel.contains(focusedPreview.attackCueLabel)
                }) else {
                    throw PreviewRenderError.missingBattleObjectiveStageLinkedHighlight
                }
            }
            if focusedPreview.shouldHighlightSkillEntry,
               let commandUnit = focusedPreview.commandUnit {
                guard focusedPreview.isCommandUnit(commandUnit),
                      viewModel.selectedUnitID == commandUnit.id,
                      viewModel.canUseSelectedGeneralSkill,
                      focusedPreview.skillStageCueLabel.contains(focusedPreview.skillCueLabel) else {
                    throw PreviewRenderError.missingBattleObjectiveStageLinkedHighlight
                }
            }
            if focusedPreview.role == .synergy,
               let commandUnit = focusedPreview.commandUnit,
               commandUnit.resolvedGeneralTrait != nil {
                guard let guidance = viewModel.selectedCommanderActionGuidance,
                      let skillButtonDetail = viewModel.selectedGeneralSkillCommandButtonDetail,
                      guidance.isLinkedToBattleObjectiveStage,
                      guidance.stageCueLabel == focusedPreview.skillStageCueLabel,
                      guidance.skillCueLabel == focusedPreview.skillStageCueLabel,
                      skillButtonDetail.contains(focusedPreview.skillStageCueLabel),
                      viewModel.selectedCommanderSynergySummary?.id == focusedPreview.sourceSummaryID else {
                    throw PreviewRenderError.missingCommanderActionGuidance
                }
            }
        }
        viewModel.focusPrimaryBattleObjectiveStage(.maneuver)
        guard viewModel.focusedPosition == primaryManeuverSummary.destination,
              viewModel.focusedBattleObjectiveRole == .maneuver,
              viewModel.focusedBattleObjectiveOverlay?.role == .maneuver,
              viewModel.focusedBattleObjectiveOverlay?.position == primaryManeuverSummary.destination,
              viewModel.selectedUnitID == primaryManeuverSummary.unit?.id,
              viewModel.bannerMessage.contains("目标线"),
              viewModel.bannerMessage.contains("3 机动") else {
            throw PreviewRenderError.missingBattleObjectiveStageFocus
        }
        viewModel.focusPrimaryBattleObjectiveStage(.recommendation)
        guard viewModel.focusedPosition == recommendationSummary.targetPosition,
              viewModel.focusedBattleObjectiveRole == .recommendation,
              viewModel.focusedBattleObjectiveOverlay?.role == .recommendation,
              viewModel.focusedBattleObjectiveOverlay?.position == recommendationSummary.targetPosition,
              viewModel.selectedUnitID == recommendationSummary.unit?.id,
              viewModel.bannerMessage.contains("目标线"),
              viewModel.bannerMessage.contains("4 军议") else {
            throw PreviewRenderError.missingBattleObjectiveStageFocus
        }
        viewModel.focusPrimaryBattleObjectiveStage(.focus)
        guard viewModel.focusedPosition == battlefieldFocus.targetPosition,
              viewModel.focusedBattleObjectiveRole == .focus,
              viewModel.focusedBattleObjectiveOverlay?.role == .focus,
              viewModel.focusedBattleObjectiveOverlay?.position == battlefieldFocus.targetPosition,
              viewModel.bannerMessage.contains("目标线"),
              viewModel.bannerMessage.contains("1 焦点") else {
            throw PreviewRenderError.missingBattleObjectiveStageFocus
        }
        if let focusUnit = battlefieldFocus.unit,
           focusUnit.faction == .rome {
            guard viewModel.selectedUnitID == focusUnit.id else {
                throw PreviewRenderError.missingBattleObjectiveStageFocus
            }
        }
        let unitStateAfterBattleObjectiveFocus = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateAfterBattleObjectiveFocus = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesAfterBattleObjectiveFocus = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        guard unitStateAfterBattleObjectiveFocus == unitStateBeforeBattleObjectiveFocus,
              cityStateAfterBattleObjectiveFocus == cityStateBeforeBattleObjectiveFocus,
              resourcesAfterBattleObjectiveFocus == resourcesBeforeBattleObjectiveFocus,
              viewModel.state.turn == turnBeforeBattleObjectiveFocus,
              viewModel.state.activeFaction == activeFactionBeforeBattleObjectiveFocus else {
            throw PreviewRenderError.missingBattleObjectiveStageFocus
        }
        let legendItems = viewModel.activeMapOverlayLegendItems
        let legendKinds = Set(legendItems.map(\.kind))
        let requiredLegendKinds: Set<MapOverlayLegendKind> = [
            .enemyRoute,
            .enemyTarget,
            .threatHeat,
            .mapControl,
            .tacticalPath,
            .maneuverOption,
            .battleObjective,
            .countermeasure
        ]
        guard !legendItems.isEmpty,
              requiredLegendKinds.isSubset(of: legendKinds),
              legendItems.allSatisfy({ item in
                  !item.symbol.isEmpty &&
                      !item.title.isEmpty &&
                      !item.detail.isEmpty &&
                      !item.accessibilityLabel.isEmpty
              }) else {
            throw PreviewRenderError.missingMapOverlayLegend
        }
        let orderPreviews = viewModel.selectedTacticalOrderPreviews
        guard orderPreviews.count == TacticalOrder.allCases.count,
              orderPreviews.contains(where: { !$0.isCurrent && ($0.attackDelta != 0 || $0.defenseDelta != 0 || $0.movementDelta != 0) }),
              orderPreviews.contains(where: { $0.order == .assault && $0.attackDelta > 0 }),
              orderPreviews.contains(where: { $0.order == .forcedMarch && $0.movementDelta > 0 }) else {
            throw PreviewRenderError.missingTacticalOrderPreview
        }
        let unitOutputPath = outputPathWithSuffix(outputPath, suffix: "unit")
        let unitBitmap = try renderBattleView(
            viewModel: viewModel,
            outputPath: unitOutputPath,
            width: width,
            height: height
        )
        guard !isCompactViewport(width: width, height: height) ||
                hasVisibleCompactCommandContent(in: unitBitmap, logicalWidth: width, logicalHeight: height) else {
            throw PreviewRenderError.missingCompactCommandRender
        }

        guard let previewCity = viewModel.state.city(withID: "neapolis") else {
            throw PreviewRenderError.missingCityReadout
        }
        viewModel.selectedUnitID = nil
        viewModel.selectedCityID = previewCity.id
        viewModel.selectedPosition = previewCity.position
        viewModel.bannerMessage = "预览城市：城市经营、扩建收益和招募部署已显示。"

        guard viewModel.selectedUnitID == nil,
              viewModel.selectedCityID == "neapolis",
              viewModel.selectedCity?.owner == .rome,
              viewModel.selectedTile?.terrain == .city,
              viewModel.commandCity?.id == previewCity.id,
              let cityBrief = viewModel.selectedCityBrief,
              cityBrief.productionLabel.contains("金 +28"),
              cityBrief.productionLabel.contains("粮 +22"),
              cityBrief.productionLabel.contains("铁 +12"),
              cityBrief.developmentCostLabel.contains("金 70"),
              cityBrief.developmentGainLabel.contains("城防 +3"),
              cityBrief.recruitmentOptions.count == UnitKind.allCases.count,
              cityBrief.recruitmentOptions.contains(where: { $0.kind == .legion && $0.canRecruit }),
              cityBrief.recruitmentOptions.contains(where: { $0.kind == .navy && $0.canRecruit && $0.deploymentLabel.contains("(4,5)") }) else {
            throw PreviewRenderError.missingCityReadout
        }

        let cityBitmap = try renderBattleView(
            viewModel: viewModel,
            outputPath: outputPath,
            width: width,
            height: height
        )
        guard !isCompactViewport(width: width, height: height) ||
                hasVisibleCompactCommandContent(in: cityBitmap, logicalWidth: width, logicalHeight: height) else {
            throw PreviewRenderError.missingCompactCommandRender
        }
        guard hasVisibleCityReadoutContent(in: cityBitmap, logicalWidth: width, logicalHeight: height) else {
            throw PreviewRenderError.missingCityReadout
        }

        print(outputPath)
        print(unitOutputPath)
    }

    private static func renderBattleView(
        viewModel: GameViewModel,
        outputPath: String,
        width: Double,
        height: Double
    ) throws -> NSBitmapImageRep {
        let content = BattleView()
            .environmentObject(viewModel)
            .frame(width: width, height: height)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2

        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            throw PreviewRenderError.renderFailed
        }

        try png.write(to: URL(fileURLWithPath: outputPath))
        return bitmap
    }

    private static func outputPathWithSuffix(_ outputPath: String, suffix: String) -> String {
        let url = URL(fileURLWithPath: outputPath)
        let pathExtension = url.pathExtension
        let baseURL = pathExtension.isEmpty ? url : url.deletingPathExtension()
        let suffixedPath = "\(baseURL.path)-\(suffix)"
        guard !pathExtension.isEmpty else {
            return suffixedPath
        }

        return "\(suffixedPath).\(pathExtension)"
    }

    private static func isCompactViewport(width: Double, height: Double) -> Bool {
        (width < 700 && height >= width) || (width > height && height < 560)
    }

    private static func hasVisibleCompactCommandContent(
        in bitmap: NSBitmapImageRep,
        logicalWidth: Double,
        logicalHeight: Double
    ) -> Bool {
        let scaleX = Double(bitmap.pixelsWide) / logicalWidth
        let scaleY = Double(bitmap.pixelsHigh) / logicalHeight
        let region: (x: Int, y: Int, width: Int, height: Int)

        if logicalWidth > logicalHeight {
            region = (
                x: Int(logicalWidth * 0.68),
                y: Int(logicalHeight * 0.20),
                width: Int(logicalWidth * 0.30),
                height: Int(logicalHeight * 0.72)
            )
        } else {
            region = (
                x: Int(logicalWidth * 0.04),
                y: Int(logicalHeight * 0.48),
                width: Int(logicalWidth * 0.92),
                height: Int(logicalHeight * 0.46)
            )
        }

        var visiblePixelCount = 0
        for logicalY in stride(from: region.y, to: region.y + region.height, by: 4) {
            for logicalX in stride(from: region.x, to: region.x + region.width, by: 4) {
                let pixelX = min(max(Int(Double(logicalX) * scaleX), 0), bitmap.pixelsWide - 1)
                let pixelY = min(max(Int(Double(logicalY) * scaleY), 0), bitmap.pixelsHigh - 1)
                guard let color = bitmap.colorAt(x: pixelX, y: pixelY)?.usingColorSpace(.deviceRGB) else {
                    continue
                }

                let brightness = (color.redComponent + color.greenComponent + color.blueComponent) / 3
                if color.alphaComponent > 0.6 && brightness > 0.42 {
                    visiblePixelCount += 1
                }
            }
        }

        return visiblePixelCount > 80
    }

    private static func hasVisibleCityReadoutContent(
        in bitmap: NSBitmapImageRep,
        logicalWidth: Double,
        logicalHeight: Double
    ) -> Bool {
        let scaleX = Double(bitmap.pixelsWide) / logicalWidth
        let scaleY = Double(bitmap.pixelsHigh) / logicalHeight
        let region: (x: Int, y: Int, width: Int, height: Int)

        if logicalWidth < 700 && logicalHeight >= logicalWidth {
            region = (
                x: Int(logicalWidth * 0.04),
                y: Int(logicalHeight * 0.50),
                width: Int(logicalWidth * 0.92),
                height: Int(logicalHeight * 0.36)
            )
        } else {
            region = (
                x: Int(logicalWidth * 0.68),
                y: Int(logicalHeight * 0.08),
                width: Int(logicalWidth * 0.30),
                height: Int(logicalHeight * 0.70)
            )
        }

        var visiblePixelCount = 0
        for logicalY in stride(from: region.y, to: region.y + region.height, by: 4) {
            for logicalX in stride(from: region.x, to: region.x + region.width, by: 4) {
                let pixelX = min(max(Int(Double(logicalX) * scaleX), 0), bitmap.pixelsWide - 1)
                let pixelY = min(max(Int(Double(logicalY) * scaleY), 0), bitmap.pixelsHigh - 1)
                guard let color = bitmap.colorAt(x: pixelX, y: pixelY)?.usingColorSpace(.deviceRGB) else {
                    continue
                }

                let brightness = (color.redComponent + color.greenComponent + color.blueComponent) / 3
                if color.alphaComponent > 0.6 && brightness > 0.40 {
                    visiblePixelCount += 1
                }
            }
        }

        return visiblePixelCount > 70
    }
}

enum PreviewRenderError: Error {
    case renderFailed
    case missingIntentOverlay
    case missingHexIntentRoute
    case missingFrontlinePressure
    case missingSelectedUnitSituationReadout
    case missingBattlefieldFocus
    case missingEnemyEngagementLoopReadout
    case missingBattlefieldConvergenceSummary
    case missingBattleObjectiveChainSummary
    case missingBattleObjectiveMapOverlay
    case missingBattleObjectiveStageFocus
    case missingBattleObjectiveStageCommandPreview
    case missingBattleObjectiveStageLinkedHighlight
    case missingCommanderChainReadout
    case missingCommanderOpportunityBridgeReadout
    case missingSelectedUnitOrderWindowReadout
    case missingMapReconnaissanceViewHUD
    case missingCampaignAdvanceReadout
    case missingCommanderActionGuidance
    case missingGeneralSkillTargetReadout
    case missingThreatHeatSummary
    case missingAIOperationalPlanSummary
    case missingAIOperationalPlanTimelineReadout
    case missingEnemyCommanderThreatSummary
    case missingCountermeasureSummary
    case missingCountermeasureOverlay
    case missingCountermeasureCommandPreview
    case missingMapControlSummary
    case missingCommanderBrief
    case missingLegionFormationSummary
    case missingUnitDevelopmentDecisionSummary
    case missingUnitDevelopmentRecommendationSummary
    case missingCommanderSynergySummary
    case missingCommanderSynergyStepReadout
    case missingTacticalRecommendationSummary
    case missingManeuverOptionSummary
    case missingMapOverlayLegend
    case missingTacticalOrderPreview
    case missingCityReadout
    case missingCompactCommandRender
}
