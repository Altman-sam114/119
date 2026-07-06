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
        guard let operationalPlan = viewModel.primaryAIOperationalPlanSummary,
              !viewModel.aiOperationalPlanSummaries.isEmpty,
              viewModel.aiOperationalPlanSummaries.contains(where: { $0.report.sourceUnitIDs.contains("carthage-hunter") }),
              !operationalPlan.title.isEmpty,
              !operationalPlan.kindLabel.isEmpty,
              !operationalPlan.sourceLabel.isEmpty,
              !operationalPlan.impactLabel.isEmpty,
              !operationalPlan.detail.isEmpty,
              !operationalPlan.accessibilityLabel.isEmpty else {
            throw PreviewRenderError.missingAIOperationalPlanSummary
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
    case missingBattlefieldFocus
    case missingBattleObjectiveChainSummary
    case missingBattleObjectiveMapOverlay
    case missingBattleObjectiveStageFocus
    case missingBattleObjectiveStageCommandPreview
    case missingBattleObjectiveStageLinkedHighlight
    case missingCommanderActionGuidance
    case missingThreatHeatSummary
    case missingAIOperationalPlanSummary
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
    case missingTacticalRecommendationSummary
    case missingManeuverOptionSummary
    case missingMapOverlayLegend
    case missingTacticalOrderPreview
    case missingCityReadout
    case missingCompactCommandRender
}
