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
        guard let legacyEnemyCommanderThreat = viewModel.primaryEnemyCommanderThreatSummary,
              !viewModel.enemyCommanderThreatSummaries.isEmpty,
              viewModel.enemyCommanderThreatSummaries.contains(where: { $0.report.unitID == "carthage-commander" }),
              viewModel.enemyCommanderThreatSummaries.contains(where: { $0.report.intentKind == .useSkill || !$0.report.skillSummary.isEmpty }),
              legacyEnemyCommanderThreat.id == "carthage-commander",
              !legacyEnemyCommanderThreat.title.isEmpty,
              !legacyEnemyCommanderThreat.compactTitle.isEmpty,
              !legacyEnemyCommanderThreat.commanderLabel.isEmpty,
              !legacyEnemyCommanderThreat.traitLabel.isEmpty,
              !legacyEnemyCommanderThreat.levelLabel.isEmpty,
              !legacyEnemyCommanderThreat.intentLabel.isEmpty,
              !legacyEnemyCommanderThreat.originLabel.isEmpty,
              !legacyEnemyCommanderThreat.rangeLabel.isEmpty,
              !legacyEnemyCommanderThreat.affectedPositionLabel.isEmpty,
              !legacyEnemyCommanderThreat.targetPositionLabel.isEmpty,
              !legacyEnemyCommanderThreat.destinationLabel.isEmpty,
              !legacyEnemyCommanderThreat.spaceChainLabel.isEmpty,
              !legacyEnemyCommanderThreat.impactLabel.isEmpty,
              !legacyEnemyCommanderThreat.statusLabel.isEmpty,
              !legacyEnemyCommanderThreat.accessibilityLabel.isEmpty else {
            throw PreviewRenderError.missingEnemyCommanderThreatSummary
        }
        // Keep the v0.64 three-unit fixture intact through all legacy heat and
        // read-only assertions; this second commander exists only for v0.65.
        viewModel.state.units.append(
            ArmyUnit(
                id: "carthage-commander-2",
                kind: .legion,
                faction: .carthage,
                position: Position(x: 11, y: 1),
                generalName: "马戈",
                generalTrait: .siegeEngineer,
                generalSkillCooldownRemaining: 3,
                hasActed: true
            )
        )
        guard let enemyCommanderThreat = viewModel.primaryEnemyCommanderThreatSummary else {
            throw PreviewRenderError.missingActiveEnemyCommanderThreatPrimary
        }
        guard enemyCommanderThreat.id == "carthage-commander",
              !viewModel.enemyCommanderThreatSummaries.isEmpty,
              viewModel.enemyCommanderThreatSummaries.contains(where: { $0.id == "carthage-commander" }) else {
            throw PreviewRenderError.missingActiveEnemyCommanderThreatPrimary
        }
        guard let secondaryEnemyCommanderThreat = viewModel.enemyCommanderThreatSummaries.first(where: {
            $0.id != enemyCommanderThreat.id
        }) else {
            throw PreviewRenderError.missingActiveEnemyCommanderThreatSecondary
        }
        guard let activeThreatWithoutFocus = viewModel.activeEnemyCommanderThreatSummary,
              activeThreatWithoutFocus.id == enemyCommanderThreat.id,
              viewModel.activeEnemyCommanderThreatID == enemyCommanderThreat.id else {
            throw PreviewRenderError.missingActiveEnemyCommanderThreatSummary
        }
        guard let activeOverlayWithoutFocus = viewModel.activeEnemyCommanderThreatMapOverlay else {
            throw PreviewRenderError.missingActiveEnemyCommanderThreatOverlay
        }
        guard activeOverlayWithoutFocus.id == enemyCommanderThreat.id,
              activeOverlayWithoutFocus.threatID == enemyCommanderThreat.id,
              activeOverlayWithoutFocus.references(enemyCommanderThreat) else {
            throw PreviewRenderError.missingActiveEnemyCommanderThreatSource
        }
        guard let noFocusReadout = viewModel.activeEnemyCommanderThreatFocusReadout,
              noFocusReadout.references(summary: activeThreatWithoutFocus),
              noFocusReadout.references(overlay: activeOverlayWithoutFocus),
              noFocusReadout.threatID == enemyCommanderThreat.id,
              noFocusReadout.overlayID == activeOverlayWithoutFocus.id,
              noFocusReadout.originPosition == activeThreatWithoutFocus.originPosition,
              noFocusReadout.targetPosition == activeThreatWithoutFocus.targetPosition,
              noFocusReadout.rangePositions == activeOverlayWithoutFocus.rangePositions,
              noFocusReadout.affectedPositions == activeOverlayWithoutFocus.affectedPositions,
              noFocusReadout.routeLabel == activeOverlayWithoutFocus.chainLabel,
              noFocusReadout.routeSegments.count == activeOverlayWithoutFocus.routeSegments.count,
              !noFocusReadout.compactLabel.isEmpty,
              !noFocusReadout.detailLabel.isEmpty,
              !noFocusReadout.accessibilityLabel.isEmpty,
              noFocusReadout.commandAvailabilityLabel.contains("仅侦察"),
              noFocusReadout.hasExecutableCommand == false,
              noFocusReadout.isFocused == false,
              noFocusReadout.isPrimaryFallback == false,
              noFocusReadout.focusStateLabel.contains("首要") else {
            throw PreviewRenderError.missingEnemyCommanderThreatFocusReadout
        }
        var enemyThreatExpectedPositions = Set([enemyCommanderThreat.report.position, enemyCommanderThreat.targetPosition])
        enemyThreatExpectedPositions.formUnion(enemyCommanderThreat.report.rangePositions)
        enemyThreatExpectedPositions.formUnion(enemyCommanderThreat.report.affectedPositions)
        if let destination = enemyCommanderThreat.report.destination {
            enemyThreatExpectedPositions.insert(destination)
        }
        guard let enemyCommanderThreatOverlay = viewModel.primaryEnemyCommanderThreatMapOverlay,
              enemyCommanderThreatOverlay.id == enemyCommanderThreat.id,
              enemyCommanderThreatOverlay.threatID == enemyCommanderThreat.id,
              enemyCommanderThreatOverlay.position == enemyCommanderThreat.report.position,
              enemyCommanderThreatOverlay.commanderPosition == enemyCommanderThreat.report.position,
              enemyCommanderThreatOverlay.targetPosition == enemyCommanderThreat.targetPosition,
              enemyCommanderThreatOverlay.destination == enemyCommanderThreat.report.destination,
              enemyCommanderThreatOverlay.rangePositions == enemyCommanderThreat.report.rangePositions,
              enemyCommanderThreatOverlay.affectedPositions == enemyCommanderThreat.report.affectedPositions,
              enemyCommanderThreatOverlay.commanderLabel == enemyCommanderThreat.commanderLabel,
              enemyCommanderThreatOverlay.skillName == enemyCommanderThreat.skillName,
              !enemyCommanderThreatOverlay.impactLabel.isEmpty,
              !enemyCommanderThreatOverlay.statusLabel.isEmpty,
              !enemyCommanderThreatOverlay.chainLabel.isEmpty,
              !enemyCommanderThreatOverlay.accessibilityLabel.isEmpty,
              enemyCommanderThreatOverlay.references(enemyCommanderThreat),
              enemyCommanderThreatOverlay.references(enemyCommanderThreat.report),
              !enemyCommanderThreatOverlay.rangePositions.isEmpty,
              enemyCommanderThreatOverlay.position.isInside(width: viewModel.state.width, height: viewModel.state.height),
              enemyCommanderThreatOverlay.targetPosition.isInside(width: viewModel.state.width, height: viewModel.state.height),
              enemyCommanderThreatOverlay.rangePositions.allSatisfy({ $0.isInside(width: viewModel.state.width, height: viewModel.state.height) }),
              enemyCommanderThreatOverlay.affectedPositions.allSatisfy({ $0.isInside(width: viewModel.state.width, height: viewModel.state.height) }),
              enemyCommanderThreatOverlay.destination.map({ $0.isInside(width: viewModel.state.width, height: viewModel.state.height) }) ?? true,
              !enemyCommanderThreatOverlay.positionOverlays.isEmpty,
              enemyCommanderThreatOverlay.positionOverlays.allSatisfy({ overlay in
                  overlay.threatID == enemyCommanderThreat.id &&
                      !overlay.label.isEmpty &&
                      !overlay.accessibilityLabel.isEmpty &&
                      overlay.position.isInside(width: viewModel.state.width, height: viewModel.state.height)
              }),
              Set(enemyCommanderThreatOverlay.positionOverlays.map(\.position)).isSuperset(of: enemyThreatExpectedPositions),
              Set(enemyCommanderThreatOverlay.positionOverlays.map(\.role)).contains(.origin),
              Set(enemyCommanderThreatOverlay.positionOverlays.map(\.role)).contains(.range),
              Set(enemyCommanderThreatOverlay.positionOverlays.map(\.role)).contains(.target),
              enemyCommanderThreat.report.affectedPositions.isEmpty
                  ? !enemyCommanderThreatOverlay.positionOverlays.contains(where: { $0.role == .affected })
                  : enemyCommanderThreatOverlay.positionOverlays.contains(where: { $0.role == .affected }),
              enemyCommanderThreat.report.destination.map({ destination in
                  enemyCommanderThreatOverlay.positionOverlays.contains(where: { $0.role == .destination && $0.position == destination })
              }) ?? true,
              enemyCommanderThreat.report.affectedPositions.isEmpty
                  ? enemyCommanderThreatOverlay.chainLabel.contains("无直接影响")
                  : enemyCommanderThreatOverlay.positionOverlays.contains(where: { $0.role == .affected }),
              !enemyCommanderThreatOverlay.routeSegments.isEmpty,
              enemyCommanderThreatOverlay.routeSegments.allSatisfy({ segment in
                  segment.from.isInside(width: viewModel.state.width, height: viewModel.state.height) &&
                      segment.to.isInside(width: viewModel.state.width, height: viewModel.state.height)
              }),
              enemyCommanderThreatOverlay.routeSegments.contains(where: { segment in
                  segment.isTargetLeg &&
                      segment.to == enemyCommanderThreatOverlay.targetPosition &&
                      segment.from == (enemyCommanderThreatOverlay.destination ?? enemyCommanderThreatOverlay.position)
              }),
              !viewModel.enemyCommanderThreatMapOverlays.isEmpty,
              viewModel.enemyCommanderThreatOverlayPositions.isSuperset(of: enemyThreatExpectedPositions),
              viewModel.enemyCommanderThreatOverlaysByPosition.values.flatMap({ $0 }).contains(where: { $0.threatID == enemyCommanderThreat.id }) else {
            throw PreviewRenderError.missingEnemyCommanderThreatMapOverlay
        }
        let threatLegendKinds = Set(viewModel.activeMapOverlayLegendItems.map(\.kind))
        let threatBaselineContext = BattleDisplayContextReadout(
            mode: .baselineRecon, sourceID: nil, title: "战场侦察", statusLabel: "敌路",
            primaryLegendKinds: [.enemyRoute], secondaryLegendKinds: [], commandCueLabel: "观察敌路"
        )
        let threatFocusContext = BattleDisplayContextReadout(
            mode: .enemyCommanderFocus, sourceID: enemyCommanderThreat.id, title: "敌将聚焦", statusLabel: "威胁",
            primaryLegendKinds: [.enemyCommanderThreat], secondaryLegendKinds: [.enemyRoute, .enemyTarget], commandCueLabel: "敌将 → 目标"
        )
        let enemyThreatPresentation = MapOverlayPresentation(perspective: .enemyIntent, context: threatFocusContext)
        let counterThreatPresentation = MapOverlayPresentation(perspective: .countermeasure, context: threatBaselineContext)
        let objectiveThreatPresentation = MapOverlayPresentation(perspective: .objective, context: threatBaselineContext)
        let terrainThreatPresentation = MapOverlayPresentation(perspective: .terrainPressure, context: threatBaselineContext)
        guard threatLegendKinds.contains(MapOverlayLegendKind.enemyCommanderThreat),
              enemyThreatPresentation.isFocusedLegend(.enemyCommanderThreat),
              enemyThreatPresentation.legendPriority(.enemyCommanderThreat) == 0,
              enemyThreatPresentation.enemyCommanderThreatOpacity > counterThreatPresentation.enemyCommanderThreatOpacity,
              enemyThreatPresentation.enemyCommanderThreatOpacity > objectiveThreatPresentation.enemyCommanderThreatOpacity,
              enemyThreatPresentation.enemyCommanderThreatOpacity > terrainThreatPresentation.enemyCommanderThreatOpacity,
              !counterThreatPresentation.showsEnemyCommanderThreatDetails,
              !objectiveThreatPresentation.showsEnemyCommanderThreatDetails,
              !terrainThreatPresentation.showsEnemyCommanderThreatDetails,
              counterThreatPresentation.legendPriority(.enemyCommanderThreat) <= 1,
              objectiveThreatPresentation.legendPriority(.enemyCommanderThreat) >= 1,
              terrainThreatPresentation.legendPriority(.enemyCommanderThreat) >= 1 else {
            throw PreviewRenderError.missingEnemyCommanderThreatMapOverlay
        }
        let stateBeforeEnemyCommanderThreatFocus = viewModel.state
        let threatStateEncoder = JSONEncoder()
        threatStateEncoder.outputFormatting = [.sortedKeys]
        let stateArchiveBeforeEnemyCommanderThreatFocus = try threatStateEncoder.encode(stateBeforeEnemyCommanderThreatFocus)
        let aiIntentSnapshotBeforeEnemyCommanderThreatFocus = viewModel.enemyIntentSummaries.map(\.intent)
        guard viewModel.selectedUnitID == "rome-legion-1",
              let primaryCommanderBridgeBeforeSecondaryFocus = viewModel.selectedCommanderOpportunityBridgeReadout,
              primaryCommanderBridgeBeforeSecondaryFocus.enemyCommanderThreatID == enemyCommanderThreat.id else {
            throw PreviewRenderError.missingActiveEnemyCommanderThreatReadout
        }
        viewModel.focusEnemyCommanderThreat(secondaryEnemyCommanderThreat.id)
        let stateArchiveAfterSecondaryEnemyCommanderThreatFocus = try threatStateEncoder.encode(viewModel.state)
        let aiIntentSnapshotAfterSecondaryEnemyCommanderThreatFocus = viewModel.enemyIntentSummaries.map(\.intent)
        let primaryEngagementLoopWhileSecondaryFocused = viewModel.primaryEnemyEngagementLoopReadout
        guard let secondaryFocusReadout = viewModel.activeEnemyCommanderThreatFocusReadout,
              let focusedSecondaryThreat = viewModel.focusedEnemyCommanderThreatSummary,
              let activeSecondaryThreat = viewModel.activeEnemyCommanderThreatSummary,
              let activeSecondaryOverlay = viewModel.activeEnemyCommanderThreatMapOverlay,
              secondaryFocusReadout.references(summary: activeSecondaryThreat),
              secondaryFocusReadout.references(overlay: activeSecondaryOverlay),
              secondaryFocusReadout.threatID == secondaryEnemyCommanderThreat.id,
              secondaryFocusReadout.overlayID == secondaryEnemyCommanderThreat.id,
              secondaryFocusReadout.isFocused,
              secondaryFocusReadout.isPrimaryFallback == false,
              secondaryFocusReadout.selectedPerspective == .enemyIntent,
              secondaryFocusReadout.rangePositions == activeSecondaryOverlay.rangePositions,
              secondaryFocusReadout.affectedPositions == activeSecondaryOverlay.affectedPositions,
              secondaryFocusReadout.routeLabel == activeSecondaryOverlay.chainLabel,
              !secondaryFocusReadout.compactLabel.isEmpty,
              !secondaryFocusReadout.detailLabel.isEmpty,
              !secondaryFocusReadout.accessibilityLabel.isEmpty,
              secondaryFocusReadout.accessibilityLabel.contains("威胁身份\(secondaryEnemyCommanderThreat.id)"),
              secondaryFocusReadout.commandAvailabilityLabel.contains("仅侦察"),
              secondaryFocusReadout.hasExecutableCommand == false,
              viewModel.selectedUnitID == nil,
              viewModel.selectedCityID == nil,
              focusedSecondaryThreat.id == secondaryEnemyCommanderThreat.id,
              activeSecondaryThreat.id == secondaryEnemyCommanderThreat.id,
              viewModel.activeEnemyCommanderThreatID == secondaryEnemyCommanderThreat.id,
              activeSecondaryOverlay.id == secondaryEnemyCommanderThreat.id,
              activeSecondaryOverlay.threatID == secondaryEnemyCommanderThreat.id,
              activeSecondaryOverlay.references(activeSecondaryThreat),
              viewModel.primaryEnemyCommanderThreatSummary?.id == enemyCommanderThreat.id,
              primaryEngagementLoopWhileSecondaryFocused?.enemyCommanderThreatID == enemyCommanderThreat.id,
              primaryCommanderBridgeBeforeSecondaryFocus.enemyCommanderThreatID == enemyCommanderThreat.id,
              viewModel.mapReconPerspectiveHUDReadout.enemyCommanderThreatID == secondaryEnemyCommanderThreat.id,
              viewModel.mapReconPerspectiveHUDReadout.references(threat: activeSecondaryOverlay),
              viewModel.mapReconPerspectiveHUDReadout.signals.contains(where: { signal in
                  signal.kind == .enemyCommander && signal.sourceID == secondaryEnemyCommanderThreat.id
              }),
              viewModel.state == stateBeforeEnemyCommanderThreatFocus,
              stateArchiveBeforeEnemyCommanderThreatFocus == stateArchiveAfterSecondaryEnemyCommanderThreatFocus,
              aiIntentSnapshotBeforeEnemyCommanderThreatFocus == aiIntentSnapshotAfterSecondaryEnemyCommanderThreatFocus else {
            throw PreviewRenderError.missingActiveEnemyCommanderThreatReadout
        }

        // Render focused threat-only states before the legacy unit/city images are
        // captured. These additional outputs are isolated from the default six
        // images, so the v0.64/v0.65 pixel baselines remain unchanged.
        let focusedOutputPath = outputPathWithSuffix(outputPath, suffix: "focused")
        let focusedEnemyDrawerOutputPath = outputPathWithSuffix(outputPath, suffix: "focused-enemy")
        let focusedBitmap = try renderBattleView(
            viewModel: viewModel,
            outputPath: focusedOutputPath,
            width: width,
            height: height
        )
        guard hasVisibleFocusedEnemyCommanderThreatPreview(
            in: focusedBitmap,
            logicalWidth: width,
            logicalHeight: height,
            readout: secondaryFocusReadout
        ) else {
            throw PreviewRenderError.missingFocusedEnemyCommanderThreatRender
        }
        let focusedEnemyDrawerBitmap = try renderBattleView(
            viewModel: viewModel,
            outputPath: focusedEnemyDrawerOutputPath,
            width: width,
            height: height,
            initialDrawer: .enemy,
            drawerUsesScrollView: false
        )
        guard hasVisibleFocusedEnemyCommanderThreatCard(
            in: focusedEnemyDrawerBitmap,
            logicalWidth: width,
            logicalHeight: height,
            readout: secondaryFocusReadout
        ) else {
            throw PreviewRenderError.missingFocusedEnemyCommanderThreatCardRender
        }

        // Exercise the real command path against a copy of the same deterministic
        // double-threat state. focusEnemyCommanderThreat clears normal selection,
        // so the fixture restores a legal Rome unit selection before calling the
        // public skip command; apply() must then clear the enemy focus while the
        // core state changes exactly as GameState.skipUnit predicts.
        let commandFixtureViewModel = GameViewModel()
        commandFixtureViewModel.isShowingMenu = false
        commandFixtureViewModel.state = stateBeforeEnemyCommanderThreatFocus
        commandFixtureViewModel.focusEnemyCommanderThreat(secondaryEnemyCommanderThreat.id)
        guard commandFixtureViewModel.focusedEnemyCommanderThreatID == secondaryEnemyCommanderThreat.id,
              commandFixtureViewModel.activeEnemyCommanderThreatFocusReadout?.threatID == secondaryEnemyCommanderThreat.id,
              commandFixtureViewModel.activeEnemyCommanderThreatFocusReadout?.isFocused == true else {
            throw PreviewRenderError.missingEnemyCommanderThreatCommandCleanup
        }
        commandFixtureViewModel.selectedUnitID = "rome-legion-1"
        commandFixtureViewModel.selectedCityID = nil
        commandFixtureViewModel.selectedPosition = Position(x: 3, y: 3)
        var expectedStateAfterSkip = stateBeforeEnemyCommanderThreatFocus
        guard (try? expectedStateAfterSkip.skipUnit(id: "rome-legion-1")) != nil else {
            throw PreviewRenderError.missingEnemyCommanderThreatCommandCleanup
        }
        let commandStateArchiveBefore = try threatStateEncoder.encode(commandFixtureViewModel.state)
        let commandAIIntentSnapshotBefore = commandFixtureViewModel.enemyIntentSummaries.map(\.intent)
        commandFixtureViewModel.skipSelectedUnit()
        let commandStateArchiveAfter = try threatStateEncoder.encode(commandFixtureViewModel.state)
        let commandAIIntentSnapshotAfter = commandFixtureViewModel.enemyIntentSummaries.map(\.intent)
        guard commandFixtureViewModel.state == expectedStateAfterSkip,
              commandStateArchiveBefore != commandStateArchiveAfter,
              commandAIIntentSnapshotBefore == commandAIIntentSnapshotAfter,
              commandFixtureViewModel.state.unit(withID: "rome-legion-1")?.hasActed == true,
              commandFixtureViewModel.focusedEnemyCommanderThreatID == nil,
              let postCommandSummary = commandFixtureViewModel.activeEnemyCommanderThreatSummary,
              let postCommandOverlay = commandFixtureViewModel.activeEnemyCommanderThreatMapOverlay,
              let postCommandReadout = commandFixtureViewModel.activeEnemyCommanderThreatFocusReadout,
              postCommandReadout.references(summary: postCommandSummary),
              postCommandReadout.references(overlay: postCommandOverlay),
              postCommandReadout.threatID == postCommandSummary.id,
              postCommandReadout.overlayID == postCommandOverlay.id,
              postCommandReadout.isFocused == false,
              postCommandReadout.isPrimaryFallback == false,
              postCommandReadout.hasExecutableCommand == false,
              postCommandReadout.threatID != secondaryEnemyCommanderThreat.id,
              !postCommandReadout.accessibilityLabel.contains(secondaryEnemyCommanderThreat.commanderLabel),
              commandFixtureViewModel.mapReconPerspectiveHUDReadout.enemyCommanderThreatID == postCommandOverlay.id,
              commandFixtureViewModel.mapReconPerspectiveHUDReadout.references(threat: postCommandOverlay) else {
            throw PreviewRenderError.missingEnemyCommanderThreatCommandCleanup
        }
        viewModel.focusedEnemyCommanderThreatID = "missing-enemy-commander-threat"
        guard let invalidFocusReadout = viewModel.activeEnemyCommanderThreatFocusReadout,
              invalidFocusReadout.threatID == enemyCommanderThreat.id,
              invalidFocusReadout.overlayID == enemyCommanderThreat.id,
              invalidFocusReadout.isFocused == false,
              invalidFocusReadout.isPrimaryFallback,
              invalidFocusReadout.focusStateLabel.contains("焦点失效"),
              invalidFocusReadout.commandAvailabilityLabel.contains("仅侦察"),
              invalidFocusReadout.hasExecutableCommand == false,
              !invalidFocusReadout.accessibilityLabel.contains(secondaryEnemyCommanderThreat.commanderLabel),
              viewModel.activeEnemyCommanderThreatSummary?.id == enemyCommanderThreat.id,
              viewModel.activeEnemyCommanderThreatID == enemyCommanderThreat.id,
              viewModel.activeEnemyCommanderThreatMapOverlay?.id == enemyCommanderThreat.id,
              viewModel.focusedEnemyCommanderThreatID == "missing-enemy-commander-threat" else {
            throw PreviewRenderError.missingActiveEnemyCommanderThreatReadout
        }
        viewModel.focusEnemyCommanderThreat(enemyCommanderThreat.id)
        let stateArchiveAfterEnemyCommanderThreatFocus = try threatStateEncoder.encode(viewModel.state)
        let aiIntentSnapshotAfterEnemyCommanderThreatFocus = viewModel.enemyIntentSummaries.map(\.intent)
        guard let focusedPrimaryReadout = viewModel.activeEnemyCommanderThreatFocusReadout,
              let focusedEnemyCommanderThreatOverlay = viewModel.primaryEnemyCommanderThreatMapOverlay,
              focusedPrimaryReadout.references(summary: enemyCommanderThreat),
              focusedPrimaryReadout.references(overlay: focusedEnemyCommanderThreatOverlay),
              focusedPrimaryReadout.threatID == enemyCommanderThreat.id,
              focusedPrimaryReadout.overlayID == enemyCommanderThreat.id,
              focusedPrimaryReadout.isFocused,
              focusedPrimaryReadout.isPrimaryFallback == false,
              focusedPrimaryReadout.selectedPerspective == .enemyIntent,
              focusedPrimaryReadout.commandAvailabilityLabel.contains("仅侦察"),
              focusedPrimaryReadout.hasExecutableCommand == false,
              !focusedPrimaryReadout.compactLabel.isEmpty,
              !focusedPrimaryReadout.detailLabel.isEmpty,
              !focusedPrimaryReadout.accessibilityLabel.isEmpty,
              focusedEnemyCommanderThreatOverlay.id == enemyCommanderThreat.id,
              focusedEnemyCommanderThreatOverlay.isFocused,
              viewModel.focusedEnemyCommanderThreatID == enemyCommanderThreat.id,
              viewModel.selectedUnitID == nil,
              viewModel.selectedCityID == nil,
              viewModel.selectedPosition == enemyCommanderThreatOverlay.position,
              viewModel.selectedMapReconPerspective == .enemyIntent,
              viewModel.mapReconPerspectiveHUDReadout.references(threat: focusedEnemyCommanderThreatOverlay),
              viewModel.mapReconPerspectiveHUDReadout.enemyCommanderThreatID == enemyCommanderThreat.id,
              viewModel.mapReconPerspectiveHUDReadout.signals.contains(where: { signal in
                  signal.kind == .enemyCommander &&
                      signal.sourceID == enemyCommanderThreat.id &&
                      signal.position == enemyCommanderThreatOverlay.position &&
                      !signal.accessibilityLabel.isEmpty
              }),
              viewModel.bannerMessage.contains("仅供侦察"),
              viewModel.state == stateBeforeEnemyCommanderThreatFocus,
              stateArchiveBeforeEnemyCommanderThreatFocus == stateArchiveAfterEnemyCommanderThreatFocus,
              aiIntentSnapshotBeforeEnemyCommanderThreatFocus == aiIntentSnapshotAfterEnemyCommanderThreatFocus,
              viewModel.selectedGeneralSkillPreview == nil,
              viewModel.attackTargets.isEmpty else {
            throw PreviewRenderError.missingEnemyCommanderThreatMapOverlay
        }
        let focusedBanner = viewModel.bannerMessage
        let focusedPosition = viewModel.selectedPosition
        guard let focusedReadoutBeforeRepeat = viewModel.activeEnemyCommanderThreatFocusReadout else {
            throw PreviewRenderError.missingEnemyCommanderThreatFocusReadout
        }
        viewModel.focusEnemyCommanderThreat(enemyCommanderThreat.id)
        let stateArchiveAfterRepeatedEnemyCommanderThreatFocus = try threatStateEncoder.encode(viewModel.state)
        guard let repeatedFocusReadout = viewModel.activeEnemyCommanderThreatFocusReadout,
              repeatedFocusReadout.threatID == focusedReadoutBeforeRepeat.threatID,
              repeatedFocusReadout.overlayID == focusedReadoutBeforeRepeat.overlayID,
              repeatedFocusReadout.focusStateLabel == focusedReadoutBeforeRepeat.focusStateLabel,
              repeatedFocusReadout.detailLabel == focusedReadoutBeforeRepeat.detailLabel,
              repeatedFocusReadout.hasExecutableCommand == false,
              viewModel.focusedEnemyCommanderThreatID == enemyCommanderThreat.id,
              viewModel.selectedPosition == focusedPosition,
              viewModel.bannerMessage == focusedBanner,
              viewModel.state == stateBeforeEnemyCommanderThreatFocus,
              stateArchiveBeforeEnemyCommanderThreatFocus == stateArchiveAfterRepeatedEnemyCommanderThreatFocus,
              aiIntentSnapshotBeforeEnemyCommanderThreatFocus == viewModel.enemyIntentSummaries.map(\.intent) else {
            throw PreviewRenderError.missingEnemyCommanderThreatMapOverlay
        }
        viewModel.focusEnemyCommanderThreat("missing-enemy-commander-threat")
        let stateArchiveAfterInvalidEnemyCommanderThreatFocus = try threatStateEncoder.encode(viewModel.state)
        guard viewModel.focusedEnemyCommanderThreatID == enemyCommanderThreat.id,
              viewModel.selectedPosition == focusedPosition,
              viewModel.state == stateBeforeEnemyCommanderThreatFocus,
              stateArchiveBeforeEnemyCommanderThreatFocus == stateArchiveAfterInvalidEnemyCommanderThreatFocus,
              aiIntentSnapshotBeforeEnemyCommanderThreatFocus == viewModel.enemyIntentSummaries.map(\.intent),
              viewModel.bannerMessage.contains("无法定位") else {
            throw PreviewRenderError.missingEnemyCommanderThreatMapOverlay
        }
        viewModel.selectTile(Position(x: 1, y: 1))
        guard viewModel.focusedEnemyCommanderThreatID == nil,
              let postSelectionReadout = viewModel.activeEnemyCommanderThreatFocusReadout,
              postSelectionReadout.threatID == enemyCommanderThreat.id,
              postSelectionReadout.isFocused == false,
              postSelectionReadout.isPrimaryFallback == false,
              !postSelectionReadout.accessibilityLabel.contains(secondaryEnemyCommanderThreat.commanderLabel) else {
            throw PreviewRenderError.missingEnemyCommanderThreatFocusReadout
        }
        viewModel.focusEnemyCommanderThreat(enemyCommanderThreat.id)
        viewModel.state.units.removeAll { $0.id == "carthage-commander-2" }
        guard viewModel.state.units.count == 3,
              !viewModel.state.units.contains(where: { $0.id == "carthage-commander-2" }),
              viewModel.focusedEnemyCommanderThreatID == enemyCommanderThreat.id,
              viewModel.primaryEnemyCommanderThreatSummary?.id == "carthage-commander",
              viewModel.activeEnemyCommanderThreatSummary?.id == "carthage-commander" else {
            throw PreviewRenderError.missingActiveEnemyCommanderThreatReadout
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
        guard let postCountermeasureFocusReadout = viewModel.activeEnemyCommanderThreatFocusReadout,
              let countermeasureContext = viewModel.activeCountermeasureCommandContextReadout,
              let activeCountermeasureOverlay = viewModel.activeCountermeasureMapOverlay,
              viewModel.selectedUnitID == countermeasure.report.responseUnitID,
              viewModel.focusedPosition == countermeasureCommandPreview.responseUnit?.position,
              viewModel.focusedCountermeasureID == countermeasure.id,
              viewModel.selectedMapReconPerspective == .countermeasure,
              viewModel.focusedEnemyCommanderThreatID == nil,
              postCountermeasureFocusReadout.isFocused == false,
              postCountermeasureFocusReadout.isPrimaryFallback == false,
              postCountermeasureFocusReadout.threatID == enemyCommanderThreat.id,
              viewModel.selectedCountermeasureCommandPreview?.id == countermeasure.id,
              countermeasureContext.sourceID == countermeasure.id,
              countermeasureContext.reportID == countermeasure.report.id,
              countermeasureContext.previewID == countermeasureCommandPreview.id,
              countermeasureContext.overlayID == activeCountermeasureOverlay.id,
              countermeasureContext.references(preview: countermeasureCommandPreview),
              countermeasureContext.references(overlay: activeCountermeasureOverlay),
              countermeasureContext.isFocused,
              countermeasureContext.isPrimaryFallback == false,
              countermeasureContext.responseUnitID == countermeasure.report.responseUnitID,
              countermeasureContext.destination == countermeasure.destination,
              countermeasureContext.targetPosition == countermeasure.targetPosition,
              countermeasureContext.recommendedOrder == countermeasure.report.recommendedOrder,
              !countermeasureContext.impactLabel.isEmpty,
              !countermeasureContext.riskLabel.isEmpty,
              !countermeasureContext.steps.isEmpty,
              !countermeasureContext.commandAvailabilityLabel.isEmpty,
              countermeasureContext.isReadOnlyPreview,
              countermeasureContext.isSingleStepConfirmation,
              countermeasureContext.accessibilityLabel.contains("确认姿态、前往落点、锁定目标"),
              viewModel.selectedTacticalOrderPreviews.contains(where: { preview in
                  preview.order == countermeasure.report.recommendedOrder
              }),
              viewModel.bannerMessage.contains("反制") else {
            throw PreviewRenderError.missingCountermeasureCommandPreview
        }
        if countermeasureCommandPreview.canAttackCurrentTarget {
            guard let targetUnit = countermeasureCommandPreview.targetUnit,
                  let targetOverlay = viewModel.activeCountermeasureOverlaysByPosition[countermeasureCommandPreview.targetPosition],
                  countermeasureCommandPreview.isMapOverlayTarget(targetOverlay),
                  viewModel.attackTargets.contains(where: { countermeasureCommandPreview.isAttackTarget($0) && $0.id == targetUnit.id }) else {
                throw PreviewRenderError.missingCountermeasureCommandPreview
            }
        }
        let focusedCountermeasureOutputPath = outputPathWithSuffix(outputPath, suffix: "focused-countermeasure")
        let focusedCountermeasureBitmap = try renderBattleView(
            viewModel: viewModel,
            outputPath: focusedCountermeasureOutputPath,
            width: width,
            height: height
        )
        guard hasVisibleFocusedCountermeasurePreview(
            in: focusedCountermeasureBitmap,
            logicalWidth: width,
            logicalHeight: height,
            context: countermeasureContext
        ) else {
            throw PreviewRenderError.missingCountermeasureCommandRender
        }

        let invalidCountermeasureFocusID = "v0.67-missing-countermeasure"
        viewModel.focusCountermeasure(invalidCountermeasureFocusID)
        guard let fallbackCountermeasureContext = viewModel.activeCountermeasureCommandContextReadout,
              fallbackCountermeasureContext.sourceID == countermeasure.id,
              fallbackCountermeasureContext.focusedCountermeasureID == invalidCountermeasureFocusID,
              fallbackCountermeasureContext.isFocused == false,
              fallbackCountermeasureContext.isPrimaryFallback,
              !fallbackCountermeasureContext.accessibilityLabel.contains(invalidCountermeasureFocusID) else {
            throw PreviewRenderError.missingCountermeasureCommandSource
        }
        viewModel.focusCountermeasure(countermeasure.id)
        guard viewModel.activeCountermeasureCommandContextReadout?.sourceID == countermeasure.id else {
            throw PreviewRenderError.missingCountermeasureCommandCleanup
        }
        let countermeasureCommandFixtureState = viewModel.state
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
        let commandDockTarget = ArmyUnit(
            id: "carthage-command-dock-target",
            kind: .legion,
            faction: .carthage,
            position: Position(x: 4, y: 3),
            health: 64,
            generalName: "哈斯德鲁巴",
            generalTrait: .quartermaster
        )
        let commandDockSecondaryTarget = ArmyUnit(
            id: "carthage-command-dock-secondary-target",
            kind: .archer,
            faction: .carthage,
            position: Position(x: 3, y: 4),
            health: 72
        )
        guard viewModel.state.unit(at: commandDockTarget.position) == nil,
              viewModel.state.unit(at: commandDockSecondaryTarget.position) == nil else {
            throw PreviewRenderError.missingCommandDockAttackFixture
        }
        let enemyBaselineContext = BattleDisplayContextReadout(
            mode: .baselineRecon, sourceID: nil, title: "战场侦察", statusLabel: "监视",
            primaryLegendKinds: [.enemyRoute], secondaryLegendKinds: [], commandCueLabel: "观察战场"
        )
        let counterBaselineContext = BattleDisplayContextReadout(
            mode: .baselineRecon, sourceID: nil, title: "战场侦察", statusLabel: "反制",
            primaryLegendKinds: [.countermeasure], secondaryLegendKinds: [], commandCueLabel: "观察反制"
        )
        let objectiveBaselineContext = BattleDisplayContextReadout(
            mode: .baselineRecon, sourceID: nil, title: "战场侦察", statusLabel: "目标线",
            primaryLegendKinds: [.battleObjective], secondaryLegendKinds: [], commandCueLabel: "观察目标线"
        )
        let terrainBaselineContext = BattleDisplayContextReadout(
            mode: .baselineRecon, sourceID: nil, title: "战场侦察", statusLabel: "热区",
            primaryLegendKinds: [.threatHeat], secondaryLegendKinds: [.mapControl], commandCueLabel: "观察空间压力"
        )
        let unitContext = BattleDisplayContextReadout(
            mode: .unitExecution, sourceID: "unit", title: "军团执行", statusLabel: "平衡",
            primaryLegendKinds: [.reachable, .attackTarget, .skillRange], secondaryLegendKinds: [.tacticalPath], commandCueLabel: "选择行动"
        )
        let attackContext = BattleDisplayContextReadout(
            mode: .attackLock, sourceID: "attack", title: "攻击锁定", statusLabel: "预演",
            primaryLegendKinds: [.attackTarget], secondaryLegendKinds: [], commandCueLabel: "攻击者 → 目标"
        )
        let enemyFocusContext = BattleDisplayContextReadout(
            mode: .enemyCommanderFocus, sourceID: "enemy", title: "敌将聚焦", statusLabel: "威胁",
            primaryLegendKinds: [.enemyCommanderThreat], secondaryLegendKinds: [.enemyRoute, .enemyTarget], commandCueLabel: "敌将 → 目标"
        )
        let counterFocusContext = BattleDisplayContextReadout(
            mode: .countermeasureFocus, sourceID: "counter", title: "反制聚焦", statusLabel: "定位",
            primaryLegendKinds: [.countermeasure], secondaryLegendKinds: [.enemyCommanderThreat], commandCueLabel: "回应 → 落点 → 目标"
        )
        let enemyPresentation = MapOverlayPresentation(perspective: .enemyIntent, context: enemyBaselineContext)
        let counterPresentation = MapOverlayPresentation(perspective: .countermeasure, context: counterBaselineContext)
        let objectivePresentation = MapOverlayPresentation(perspective: .objective, context: objectiveBaselineContext)
        let terrainPresentation = MapOverlayPresentation(perspective: .terrainPressure, context: terrainBaselineContext)
        let unitPresentation = MapOverlayPresentation(perspective: .enemyIntent, context: unitContext)
        let attackPresentation = MapOverlayPresentation(perspective: .enemyIntent, context: attackContext)
        let enemyFocusPresentation = MapOverlayPresentation(perspective: .enemyIntent, context: enemyFocusContext)
        let counterFocusPresentation = MapOverlayPresentation(perspective: .countermeasure, context: counterFocusContext)
        let terrainProfiles = TerrainType.allCases.map(\.materialProfile)
        let shortLandscapeMetrics = HexMetrics(
            mapWidth: viewModel.state.width,
            mapHeight: viewModel.state.height,
            container: CGSize(width: 916, height: 278)
        )
        let portraitMetrics = HexMetrics(
            mapWidth: viewModel.state.width,
            mapHeight: viewModel.state.height,
            container: CGSize(width: 374, height: 670)
        )
        let wideMetrics = HexMetrics(
            mapWidth: viewModel.state.width,
            mapHeight: viewModel.state.height,
            container: CGSize(width: 1008, height: 606)
        )
        let shortInterfaceMetrics = BattleInterfaceMetrics(container: CGSize(width: 932, height: 430))
        let portraitInterfaceMetrics = BattleInterfaceMetrics(container: CGSize(width: 390, height: 844))
        let wideInterfaceMetrics = BattleInterfaceMetrics(container: CGSize(width: 1024, height: 768))
        let cameraContainer = CGSize(width: 390, height: 670)
        let cameraCenter = CGPoint(x: cameraContainer.width / 2, y: cameraContainer.height / 2)
        var minimumCamera = MapViewportState()
        minimumCamera.setScale(0.2, in: cameraContainer)
        minimumCamera.pan(by: CGSize(width: 120, height: -90), in: cameraContainer)
        var maximumCamera = MapViewportState()
        maximumCamera.setScale(9, in: cameraContainer)
        maximumCamera.pan(by: CGSize(width: 10_000, height: -10_000), in: cameraContainer)
        let maximumCameraOffset = maximumCamera.maximumOffset(in: cameraContainer)
        var centeredCamera = MapViewportState()
        centeredCamera.focus(on: cameraCenter, in: cameraContainer)
        var edgeCamera = MapViewportState()
        edgeCamera.focus(on: .zero, in: cameraContainer)
        let edgeCameraLimit = edgeCamera.maximumOffset(in: cameraContainer)
        let interactiveCamera = MapViewportState().applying(
            magnification: 1.5,
            translation: CGSize(width: 10_000, height: 10_000),
            in: cameraContainer
        )
        var resetCamera = edgeCamera
        resetCamera.reset()
        guard enemyPresentation.showsEnemyIntentDetails,
              enemyPresentation.enemyRouteOpacity == 1,
              !enemyPresentation.showsBattleObjective,
              counterPresentation.showsCountermeasure,
              !counterPresentation.showsEnemyIntentDetails,
              counterPresentation.enemyRouteOpacity <= 0.24,
              objectivePresentation.showsBattleObjective,
              objectivePresentation.tacticalRouteOpacity > enemyPresentation.tacticalRouteOpacity,
              objectivePresentation.enemyRouteOpacity <= 0.08,
              terrainPresentation.showsTerrainPressure,
              terrainPresentation.enemyRouteOpacity <= 0.10,
              terrainPresentation.tacticalRouteOpacity <= 0.14,
              terrainPresentation.isFocusedLegend(.threatHeat),
              !terrainPresentation.isFocusedLegend(.enemyRoute) else {
            throw PreviewRenderError.missingMapOverlayFocusStrategy
        }
        guard unitContext.primaryLegendKinds == [.reachable, .attackTarget, .skillRange],
              attackPresentation.enemyRouteOpacity < 0.1,
              attackPresentation.enemyCommanderThreatOpacity < 0.1,
              enemyFocusPresentation.enemyCommanderThreatOpacity > enemyFocusPresentation.enemyRouteOpacity,
              counterFocusPresentation.isFocusedLegend(.countermeasure),
              counterFocusPresentation.legendPriority(.enemyCommanderThreat) == 1,
              counterFocusPresentation.enemyCommanderThreatOpacity < counterFocusPresentation.enemyRouteOpacity + 0.2 else {
            throw PreviewRenderError.missingBattleDisplayContext
        }
        guard shortInterfaceMetrics.isShortLandscape,
              shortInterfaceMetrics.topBarHeight <= 42,
              shortInterfaceMetrics.commandDockHeight <= 80,
              shortInterfaceMetrics.fixedChromeHeight / 430 < 0.29,
              portraitInterfaceMetrics.isPortrait,
              portraitInterfaceMetrics.commandDockHeight <= 102,
              portraitInterfaceMetrics.fixedChromeHeight / 844 < 0.18,
              !wideInterfaceMetrics.isShortLandscape,
              wideInterfaceMetrics.commandDockHeight <= 88,
              wideInterfaceMetrics.fixedChromeHeight / 768 < 0.18,
              shortInterfaceMetrics.edgeToolVisualSize < 44,
              wideInterfaceMetrics.edgeToolSpacing <= 2 else {
            throw PreviewRenderError.missingBattleCommandHierarchy
        }
        guard minimumCamera.isDefault,
              minimumCamera.scale == MapViewportState.minimumScale,
              minimumCamera.offset == .zero,
              maximumCamera.scale == MapViewportState.maximumScale,
              abs(maximumCamera.offset.width - maximumCameraOffset.width) < 0.001,
              abs(maximumCamera.offset.height + maximumCameraOffset.height) < 0.001,
              centeredCamera.scale == MapViewportState.focusScale,
              centeredCamera.offset == .zero,
              edgeCamera.scale == MapViewportState.focusScale,
              abs(edgeCamera.offset.width - edgeCameraLimit.width) < 0.001,
              abs(edgeCamera.offset.height - edgeCameraLimit.height) < 0.001,
              interactiveCamera.scale == 1.5,
              abs(interactiveCamera.offset.width - interactiveCamera.maximumOffset(in: cameraContainer).width) < 0.001,
              abs(interactiveCamera.offset.height - interactiveCamera.maximumOffset(in: cameraContainer).height) < 0.001,
              resetCamera.isDefault else {
            throw PreviewRenderError.missingMapViewportStrategy
        }
        guard Set(terrainProfiles.map(\.signature)).count == TerrainType.allCases.count,
              terrainProfiles.allSatisfy({ $0.layerCount >= 3 && $0.landmarkOpacity <= 0.18 }),
              shortLandscapeMetrics.tileAspect < 0.72,
              shortLandscapeMetrics.mapSize.width > 300,
              portraitMetrics.mapSize.width > 330,
              wideMetrics.mapSize.width > 700 else {
            throw PreviewRenderError.missingTerrainMaterialStrategy
        }
        let coastlineSegments = CoastlineBuilder.segments(
            tiles: viewModel.state.tiles,
            metrics: wideMetrics
        )
        let terrainByPosition = Dictionary(
            uniqueKeysWithValues: viewModel.state.tiles.map { ($0.position, $0.terrain) }
        )
        let coastlineThreshold = wideMetrics.tileWidth * 0.95
        let deepSeaPosition = Position(x: 1, y: 7)
        let deepSeaIsSurroundedByWater = terrainByPosition[deepSeaPosition] == .water &&
            viewModel.state.tiles.allSatisfy { tile in
                let deepSeaCenter = wideMetrics.center(for: deepSeaPosition)
                let center = wideMetrics.center(for: tile.position)
                let dx = center.x - deepSeaCenter.x
                let dy = center.y - deepSeaCenter.y
                let isVisualNeighbor = tile.position != deepSeaPosition &&
                    (dx * dx + dy * dy).squareRoot() <= coastlineThreshold
                return !isVisualNeighbor || tile.terrain == .water
            }
        guard coastlineSegments.count > 10,
              coastlineSegments.allSatisfy({ segment in
                  let waterCenter = wideMetrics.center(for: segment.waterPosition)
                  let landCenter = wideMetrics.center(for: segment.landPosition)
                  let dx = landCenter.x - waterCenter.x
                  let dy = landCenter.y - waterCenter.y
                  return terrainByPosition[segment.waterPosition] == .water &&
                      terrainByPosition[segment.landPosition] != .water &&
                      (dx * dx + dy * dy).squareRoot() <= coastlineThreshold
              }),
              deepSeaIsSurroundedByWater,
              !coastlineSegments.contains(where: { $0.waterPosition == deepSeaPosition }) else {
            throw PreviewRenderError.missingCoastlineStrategy
        }
        viewModel.state.units.append(commandDockTarget)
        viewModel.state.units.append(commandDockSecondaryTarget)
        guard viewModel.attackTargets.contains(where: { $0.id == commandDockTarget.id }),
              viewModel.attackTargets.contains(where: { $0.id == commandDockSecondaryTarget.id }),
              Set(viewModel.attackTargets.map(\.id)) == Set([commandDockTarget.id, commandDockSecondaryTarget.id]),
              let commandSituation = viewModel.selectedUnitSituationReadout,
              !commandSituation.primaryCommandEntryLabel.isEmpty else {
            throw PreviewRenderError.missingCommandDockAttackFixture
        }
        try assertCountermeasureSingleStepCommands(
            in: countermeasureCommandFixtureState,
            targetPreparedState: viewModel.state
        )
        viewModel.focusEnemyCommanderThreat(enemyCommanderThreat.id)
        viewModel.selectedUnitID = "rome-legion-1"
        viewModel.selectedCityID = nil
        viewModel.selectedPosition = Position(x: 3, y: 3)
        let stateBeforeAttackForecast = viewModel.state
        let stateEncoder = JSONEncoder()
        stateEncoder.outputFormatting = [.sortedKeys]
        let stateArchiveBeforeAttackForecast = try stateEncoder.encode(stateBeforeAttackForecast)
        let aiIntentSnapshotBeforeAttackForecast = viewModel.enemyIntentSummaries.map(\.intent)
        let selectedCityBeforeAttackForecast = viewModel.selectedCityID
        let unitStateBeforeAttackForecast = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateBeforeAttackForecast = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesBeforeAttackForecast = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        let turnBeforeAttackForecast = viewModel.state.turn
        let activeFactionBeforeAttackForecast = viewModel.state.activeFaction
        viewModel.focusAttackTarget(commandDockTarget.id)
        guard let attackFocusReadout = viewModel.activeEnemyCommanderThreatFocusReadout,
              viewModel.selectedAttackTargetID == commandDockTarget.id,
              viewModel.focusedEnemyCommanderThreatID == nil,
              attackFocusReadout.isFocused == false,
              attackFocusReadout.isPrimaryFallback == false,
              viewModel.selectedPosition == commandDockTarget.position,
              let selectedCombatForecast = viewModel.selectedCombatForecast,
              selectedCombatForecast.attacker.id == "rome-legion-1",
              selectedCombatForecast.defender.id == commandDockTarget.id,
              selectedCombatForecast.attackerIdentityLabel.contains("罗马军团"),
              selectedCombatForecast.defenderIdentityLabel.contains("迦太基"),
              selectedCombatForecast.attackerGeneralLabel == "凯撒",
              selectedCombatForecast.attackerPositionLabel.contains("(3,3)"),
              selectedCombatForecast.defenderPositionLabel.contains(commandDockTarget.position.description),
              selectedCombatForecast.identityChainLabel.contains(selectedCombatForecast.attackerIdentityLabel),
              selectedCombatForecast.identityChainLabel.contains(selectedCombatForecast.defenderIdentityLabel),
              let canonicalCombatPreview = try? viewModel.state.attackPreview(
                  attackerID: "rome-legion-1",
                  defenderID: commandDockTarget.id
              ),
              selectedCombatForecast.preview == canonicalCombatPreview,
              selectedCombatForecast.compactLabel.contains(selectedCombatForecast.identityChainLabel),
              selectedCombatForecast.detailLabel.contains(selectedCombatForecast.identityChainLabel),
              !selectedCombatForecast.compactLabel.isEmpty,
              !selectedCombatForecast.detailLabel.isEmpty,
              !selectedCombatForecast.accessibilityLabel.isEmpty else {
            throw PreviewRenderError.missingAttackForecast
        }
        let unitStateAfterAttackForecast = viewModel.state.units
            .sorted { $0.id < $1.id }
            .map { unit in
                "\(unit.id)|\(unit.position.description)|\(unit.health)|\(unit.hasMoved)|\(unit.hasActed)|\(unit.generalSkillCooldownRemaining)|\(unit.tacticalOrder?.rawValue ?? "balanced")"
            }
        let cityStateAfterAttackForecast = viewModel.state.cities
            .sorted { $0.id < $1.id }
            .map { city in
                "\(city.id)|\(city.owner.rawValue)|\(city.fortification)|\(city.position.description)"
            }
        let resourcesAfterAttackForecast = viewModel.state.resources
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { entry in
                let resources = entry.value
                return "\(entry.key.rawValue)|\(resources.gold)|\(resources.grain)|\(resources.iron)|\(resources.science)|\(resources.prestige)"
            }
        let stateArchiveAfterAttackForecast = try stateEncoder.encode(viewModel.state)
        let aiIntentSnapshotAfterAttackForecast = viewModel.enemyIntentSummaries.map(\.intent)
        guard unitStateBeforeAttackForecast == unitStateAfterAttackForecast,
              cityStateBeforeAttackForecast == cityStateAfterAttackForecast,
              resourcesBeforeAttackForecast == resourcesAfterAttackForecast,
              stateBeforeAttackForecast == viewModel.state,
              stateArchiveBeforeAttackForecast == stateArchiveAfterAttackForecast,
              aiIntentSnapshotBeforeAttackForecast == aiIntentSnapshotAfterAttackForecast,
              turnBeforeAttackForecast == viewModel.state.turn,
              activeFactionBeforeAttackForecast == viewModel.state.activeFaction else {
            throw PreviewRenderError.missingAttackForecast
        }
        let unitOutputPath = outputPathWithSuffix(outputPath, suffix: "unit")
        let unitBitmap = try renderBattleView(
            viewModel: viewModel,
            outputPath: unitOutputPath,
            width: width,
            height: height
        )
        guard hasMapDominantBattleShell(in: unitBitmap, logicalWidth: width, logicalHeight: height) else {
            throw PreviewRenderError.missingMapDominantBattleShell
        }
        guard hasVisibleMapIntelligenceDock(in: unitBitmap, logicalWidth: width, logicalHeight: height) else {
            throw PreviewRenderError.missingMapIntelligenceDock
        }
        guard hasStrategicMapMaterialCoverage(in: unitBitmap, logicalWidth: width, logicalHeight: height) else {
            throw PreviewRenderError.missingStrategicMapMaterialCoverage
        }
        guard hasVisibleUnitCommandDockContent(in: unitBitmap, logicalWidth: width, logicalHeight: height) else {
            throw PreviewRenderError.missingCompactCommandRender
        }

        viewModel.cancelSelectedAttackTarget()
        let stateArchiveAfterCancel = try stateEncoder.encode(viewModel.state)
        let aiIntentSnapshotAfterCancel = viewModel.enemyIntentSummaries.map(\.intent)
        guard let cancelFocusReadout = viewModel.activeEnemyCommanderThreatFocusReadout,
              viewModel.selectedAttackTargetID == nil,
              viewModel.selectedCombatForecast == nil,
              viewModel.selectedUnitID == "rome-legion-1",
              viewModel.selectedCityID == selectedCityBeforeAttackForecast,
              viewModel.selectedPosition == Position(x: 3, y: 3),
              viewModel.focusedEnemyCommanderThreatID == nil,
              cancelFocusReadout.isFocused == false,
              cancelFocusReadout.isPrimaryFallback == false,
              viewModel.focusedCountermeasureID == nil,
              viewModel.focusedBattleObjectiveRole == nil,
              viewModel.state == stateBeforeAttackForecast,
              stateArchiveBeforeAttackForecast == stateArchiveAfterCancel,
              aiIntentSnapshotBeforeAttackForecast == aiIntentSnapshotAfterCancel else {
            throw PreviewRenderError.missingAttackForecast
        }
        viewModel.cancelSelectedAttackTarget()
        let stateArchiveAfterRepeatedCancel = try stateEncoder.encode(viewModel.state)
        guard viewModel.selectedAttackTargetID == nil,
              viewModel.selectedUnitID == "rome-legion-1",
              viewModel.selectedCityID == selectedCityBeforeAttackForecast,
              viewModel.selectedPosition == Position(x: 3, y: 3),
              viewModel.state == stateBeforeAttackForecast,
              stateArchiveBeforeAttackForecast == stateArchiveAfterRepeatedCancel else {
            throw PreviewRenderError.missingAttackForecast
        }

        guard let previewCity = viewModel.state.city(withID: "neapolis") else {
            throw PreviewRenderError.missingCityReadout
        }
        viewModel.selectedUnitID = nil
        viewModel.selectedCityID = previewCity.id
        viewModel.selectedPosition = previewCity.position
        viewModel.cancelSelectedAttackTarget()
        viewModel.bannerMessage = "预览城市：城市经营、扩建收益和招募部署已显示。"

        guard viewModel.selectedUnitID == nil,
              viewModel.selectedCityID == "neapolis",
              viewModel.selectedAttackTargetID == nil,
              viewModel.selectedCombatForecast == nil,
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
        guard hasMapDominantBattleShell(in: cityBitmap, logicalWidth: width, logicalHeight: height) else {
            throw PreviewRenderError.missingMapDominantBattleShell
        }
        guard hasVisibleMapIntelligenceDock(in: cityBitmap, logicalWidth: width, logicalHeight: height) else {
            throw PreviewRenderError.missingMapIntelligenceDock
        }
        guard hasStrategicMapMaterialCoverage(in: cityBitmap, logicalWidth: width, logicalHeight: height) else {
            throw PreviewRenderError.missingStrategicMapMaterialCoverage
        }
        guard hasVisibleCityReadoutContent(in: cityBitmap, logicalWidth: width, logicalHeight: height) else {
            throw PreviewRenderError.missingCompactCommandRender
        }
        guard commandDockSignaturesDiffer(
            unitBitmap: unitBitmap,
            cityBitmap: cityBitmap,
            logicalWidth: width,
            logicalHeight: height
        ) else {
            throw PreviewRenderError.missingDistinctCommandDockRender
        }

        let endTurnLifecycleViewModel = GameViewModel()
        endTurnLifecycleViewModel.focusedEnemyCommanderThreatID = "v0.66-secondary-threat"
        endTurnLifecycleViewModel.endTurn()
        guard endTurnLifecycleViewModel.focusedEnemyCommanderThreatID == nil else {
            throw PreviewRenderError.missingEnemyCommanderThreatFocusReadout
        }
        if let endTurnReadout = endTurnLifecycleViewModel.activeEnemyCommanderThreatFocusReadout {
            guard endTurnReadout.isFocused == false,
                  endTurnReadout.isPrimaryFallback == false,
                  !endTurnReadout.accessibilityLabel.contains("v0.66-secondary-threat") else {
                throw PreviewRenderError.missingEnemyCommanderThreatFocusReadout
            }
        }

        let startLifecycleViewModel = GameViewModel()
        startLifecycleViewModel.focusedEnemyCommanderThreatID = "v0.66-secondary-threat"
        startLifecycleViewModel.start(mode: startLifecycleViewModel.selectedMode)
        guard startLifecycleViewModel.focusedEnemyCommanderThreatID == nil else {
            throw PreviewRenderError.missingEnemyCommanderThreatFocusReadout
        }
        if let startReadout = startLifecycleViewModel.activeEnemyCommanderThreatFocusReadout {
            guard startReadout.isFocused == false,
                  startReadout.isPrimaryFallback == false,
                  !startReadout.accessibilityLabel.contains("v0.66-secondary-threat") else {
                throw PreviewRenderError.missingEnemyCommanderThreatFocusReadout
            }
        }

        print(outputPath)
        print(unitOutputPath)
        print(focusedOutputPath)
        print(focusedEnemyDrawerOutputPath)
        print(focusedCountermeasureOutputPath)
    }

    private static func assertCountermeasureSingleStepCommands(
        in fixtureState: GameState,
        targetPreparedState: GameState
    ) throws {
        guard let orderFixture = focusedCountermeasureFixture(
            state: fixtureState,
            matching: { preview in
                preview.canSetOrder &&
                    preview.responseUnit?.resolvedTacticalOrder != preview.recommendedOrder
            }
        ) else {
            throw PreviewRenderError.missingCountermeasureOrderRuntimeConfirmation
        }
        let orderViewModel = orderFixture.viewModel
        let orderContext = orderFixture.context
        guard orderContext.canConfirmOrder,
              let orderUnitBefore = orderViewModel.state.unit(withID: orderContext.responseUnitID),
              orderUnitBefore.resolvedTacticalOrder != orderContext.recommendedOrder else {
            throw PreviewRenderError.missingCountermeasureOrderRuntimeConfirmation
        }
        let orderBefore = try countermeasureRuntimeSnapshot(of: orderViewModel)
        var expectedOrderState = orderBefore.state
        guard (try? expectedOrderState.setTacticalOrder(
            unitID: orderContext.responseUnitID,
            order: orderContext.recommendedOrder
        )) != nil else {
            throw PreviewRenderError.missingCountermeasureOrderRuntimeConfirmation
        }
        orderViewModel.confirmCountermeasureOrder()
        let orderAfter = try countermeasureRuntimeSnapshot(of: orderViewModel)
        let expectedOrderArchive = try encodedState(expectedOrderState)
        guard let orderUnitAfter = orderViewModel.state.unit(withID: orderContext.responseUnitID),
              orderAfter.state == expectedOrderState,
              orderAfter.archive == expectedOrderArchive,
              orderBefore.archive != orderAfter.archive,
              orderBefore.resources == orderAfter.resources,
              orderBefore.cities == orderAfter.cities,
              orderBefore.turn == orderAfter.turn,
              orderBefore.activeFaction == orderAfter.activeFaction,
              orderBefore.campaignStatus == orderAfter.campaignStatus,
              orderAfter.aiIntents == countermeasureAIIntentSnapshot(in: expectedOrderState),
              orderUnitAfter.resolvedTacticalOrder == orderContext.recommendedOrder,
              orderUnitAfter.position == orderUnitBefore.position,
              orderUnitAfter.health == orderUnitBefore.health,
              orderUnitAfter.experience == orderUnitBefore.experience,
              orderUnitAfter.generalSkillCooldownRemaining == orderUnitBefore.generalSkillCooldownRemaining,
              orderUnitAfter.hasMoved == orderUnitBefore.hasMoved,
              orderUnitAfter.hasActed == orderUnitBefore.hasActed,
              orderViewModel.selectedUnitID == orderContext.responseUnitID,
              orderViewModel.selectedAttackTargetID == nil,
              orderViewModel.selectedCombatForecast == nil,
              orderViewModel.focusedCountermeasureID == nil,
              countermeasureContextIsFresh(
                  orderViewModel.activeCountermeasureCommandContextReadout,
                  after: orderUnitAfter,
                  previousSourceID: orderContext.sourceID
              ) else {
            throw PreviewRenderError.missingCountermeasureOrderRuntimeConfirmation
        }

        guard let movementFixture = focusedCountermeasureFixture(
            state: fixtureState,
            matching: { preview in
                guard let responseUnit = preview.responseUnit else { return false }
                let destinationOwner = fixtureState.city(at: preview.destination)?.owner
                return preview.canMoveToDestination &&
                    responseUnit.position != preview.destination &&
                    (destinationOwner == nil || destinationOwner == responseUnit.faction)
            }
        ) else {
            throw PreviewRenderError.missingCountermeasureMovementRuntimeConfirmation
        }
        let movementViewModel = movementFixture.viewModel
        let movementContext = movementFixture.context
        guard movementContext.canConfirmMovement,
              let movementUnitBefore = movementViewModel.state.unit(withID: movementContext.responseUnitID),
              movementUnitBefore.position == movementContext.responsePosition,
              movementUnitBefore.position != movementContext.destination,
              movementViewModel.reachablePositions.contains(movementContext.destination) else {
            throw PreviewRenderError.missingCountermeasureMovementRuntimeConfirmation
        }
        let movementBefore = try countermeasureRuntimeSnapshot(of: movementViewModel)
        var expectedMovementState = movementBefore.state
        guard (try? expectedMovementState.moveUnit(
            id: movementContext.responseUnitID,
            to: movementContext.destination
        )) != nil else {
            throw PreviewRenderError.missingCountermeasureMovementRuntimeConfirmation
        }
        movementViewModel.confirmCountermeasureMovement()
        let movementAfter = try countermeasureRuntimeSnapshot(of: movementViewModel)
        let expectedMovementArchive = try encodedState(expectedMovementState)
        let unchangedMovementUnitsBefore = movementBefore.units.filter { $0.id != movementContext.responseUnitID }
        let unchangedMovementUnitsAfter = movementAfter.units.filter { $0.id != movementContext.responseUnitID }
        let responsePreviewsAfterMovement = movementViewModel.countermeasureCommandPreviews.filter {
            $0.summary.report.responseUnitID == movementContext.responseUnitID
        }
        guard let movementUnitAfter = movementViewModel.state.unit(withID: movementContext.responseUnitID),
              movementAfter.state == expectedMovementState,
              movementAfter.archive == expectedMovementArchive,
              movementBefore.archive != movementAfter.archive,
              movementBefore.resources == movementAfter.resources,
              movementBefore.cities == movementAfter.cities,
              movementBefore.turn == movementAfter.turn,
              movementBefore.activeFaction == movementAfter.activeFaction,
              movementBefore.campaignStatus == movementAfter.campaignStatus,
              movementAfter.aiIntents == countermeasureAIIntentSnapshot(in: expectedMovementState),
              unchangedMovementUnitsBefore == unchangedMovementUnitsAfter,
              movementUnitAfter.position == movementContext.destination,
              movementUnitAfter.position != movementContext.responsePosition,
              movementUnitAfter.health == movementUnitBefore.health,
              movementUnitAfter.experience == movementUnitBefore.experience,
              movementUnitAfter.generalSkillCooldownRemaining == movementUnitBefore.generalSkillCooldownRemaining,
              movementUnitAfter.resolvedTacticalOrder == movementUnitBefore.resolvedTacticalOrder,
              movementUnitAfter.hasMoved,
              movementUnitAfter.hasActed == movementUnitBefore.hasActed,
              movementViewModel.selectedUnitID == movementContext.responseUnitID,
              movementViewModel.selectedPosition == movementContext.destination,
              movementViewModel.selectedAttackTargetID == nil,
              movementViewModel.selectedCombatForecast == nil,
              movementViewModel.focusedCountermeasureID == nil,
              responsePreviewsAfterMovement.allSatisfy({ preview in
                  preview.responseUnit?.position == movementContext.destination &&
                      preview.summary.responsePosition == movementContext.destination
              }),
              countermeasureContextIsFresh(
                  movementViewModel.activeCountermeasureCommandContextReadout,
                  after: movementUnitAfter,
                  previousSourceID: movementContext.sourceID
              ) else {
            throw PreviewRenderError.missingCountermeasureMovementRuntimeConfirmation
        }

        guard let targetFixture = attackableCountermeasureFixture(
            state: fixtureState,
            movementPreparedState: movementAfter.state,
            targetPreparedState: targetPreparedState
        ) else {
            throw PreviewRenderError.missingCountermeasureTargetRuntimeConfirmation
        }
        let targetViewModel = targetFixture.viewModel
        let targetContext = targetFixture.context
        guard targetFixture.preview.summary.report.targetUnitID == targetContext.targetUnitID,
              targetContext.references(preview: targetFixture.preview),
              targetContext.sourceID == targetFixture.preview.id,
              targetContext.canLockTarget,
              let targetUnitID = targetContext.targetUnitID,
              let targetUnitBefore = targetViewModel.state.unit(withID: targetUnitID),
              let responseUnitBeforeTargetLock = targetViewModel.state.unit(withID: targetContext.responseUnitID),
              targetViewModel.attackTargets.contains(where: { $0.id == targetUnitID }) else {
            throw PreviewRenderError.missingCountermeasureTargetRuntimeConfirmation
        }
        let targetBefore = try countermeasureRuntimeSnapshot(of: targetViewModel)
        targetViewModel.lockCountermeasureTarget()
        let targetAfter = try countermeasureRuntimeSnapshot(of: targetViewModel)
        guard let selectedForecast = targetViewModel.selectedCombatForecast,
              let canonicalPreview = try? targetViewModel.state.attackPreview(
                  attackerID: targetContext.responseUnitID,
                  defenderID: targetUnitID
              ),
              targetAfter.state == targetBefore.state,
              targetAfter.archive == targetBefore.archive,
              targetAfter.units == targetBefore.units,
              targetAfter.cities == targetBefore.cities,
              targetAfter.resources == targetBefore.resources,
              targetAfter.turn == targetBefore.turn,
              targetAfter.activeFaction == targetBefore.activeFaction,
              targetAfter.campaignStatus == targetBefore.campaignStatus,
              targetAfter.aiIntents == targetBefore.aiIntents,
              targetViewModel.selectedUnitID == targetContext.responseUnitID,
              targetViewModel.selectedAttackTargetID == targetUnitID,
              targetViewModel.selectedPosition == targetUnitBefore.position,
              selectedForecast.attacker.id == responseUnitBeforeTargetLock.id,
              selectedForecast.defender.id == targetUnitBefore.id,
              selectedForecast.preview == canonicalPreview,
              selectedForecast.identityChainLabel.contains(selectedForecast.attackerIdentityLabel),
              selectedForecast.identityChainLabel.contains(selectedForecast.defenderIdentityLabel),
              selectedForecast.positionChainLabel.contains(selectedForecast.attackerPositionLabel),
              selectedForecast.positionChainLabel.contains(selectedForecast.defenderPositionLabel),
              selectedForecast.confirmationAccessibilityLabel.contains(selectedForecast.identityChainLabel),
              selectedForecast.cancelAccessibilityLabel.contains(selectedForecast.identityChainLabel),
              !selectedForecast.confirmationTitle.isEmpty,
              !selectedForecast.outcomeLabel.isEmpty,
              !selectedForecast.compactLabel.isEmpty,
              !selectedForecast.detailLabel.isEmpty,
              !selectedForecast.accessibilityLabel.isEmpty,
              targetViewModel.attackTargetAccessibilityLabel(for: targetUnitBefore).contains("已锁定"),
              targetViewModel.focusedCountermeasureID == nil,
              targetViewModel.activeCountermeasureCommandContextReadout?.isFocused != true,
              targetViewModel.bannerMessage.contains("已锁定") else {
            throw PreviewRenderError.missingCountermeasureTargetRuntimeConfirmation
        }
    }

    private static func focusedCountermeasureFixture(
        state: GameState,
        matching predicate: (CountermeasureCommandPreview) -> Bool
    ) -> (
        viewModel: GameViewModel,
        preview: CountermeasureCommandPreview,
        context: CountermeasureCommandContextReadout
    )? {
        let viewModel = GameViewModel()
        viewModel.isShowingMenu = false
        viewModel.state = state
        guard let preview = viewModel.countermeasureCommandPreviews.first(where: predicate) else {
            return nil
        }
        viewModel.focusCountermeasure(preview.id)
        guard let context = viewModel.activeCountermeasureCommandContextReadout,
              context.sourceID == preview.id,
              context.responseUnitID == preview.summary.report.responseUnitID,
              context.isFocused,
              context.isPrimaryFallback == false,
              viewModel.selectedUnitID == context.responseUnitID else {
            return nil
        }
        return (viewModel, preview, context)
    }

    private static func attackableCountermeasureFixture(
        state: GameState,
        movementPreparedState: GameState,
        targetPreparedState: GameState
    ) -> (
        viewModel: GameViewModel,
        preview: CountermeasureCommandPreview,
        context: CountermeasureCommandContextReadout
    )? {
        if let directFixture = focusedCountermeasureFixture(
            state: state,
            matching: { $0.canAttackCurrentTarget && $0.targetUnit != nil }
        ) {
            return directFixture
        }
        if let preparedFixture = focusedCountermeasureFixture(
            state: movementPreparedState,
            matching: { $0.canAttackCurrentTarget && $0.targetUnit != nil }
        ) {
            return preparedFixture
        }
        if let injectedFixture = focusedCountermeasureFixture(
            state: targetPreparedState,
            matching: { preview in
                preview.targetUnit?.id == "carthage-command-dock-target" &&
                    preview.canAttackCurrentTarget
            }
        ) {
            return injectedFixture
        }

        let sourceViewModel = GameViewModel()
        sourceViewModel.isShowingMenu = false
        sourceViewModel.state = state
        let movementSources = sourceViewModel.countermeasureCommandPreviews.filter { preview in
            preview.responseUnit?.position != preview.destination &&
                preview.canMoveToDestination
        }
        for source in movementSources {
            guard let preparation = focusedCountermeasureFixture(
                state: state,
                matching: { $0.id == source.id }
            ),
            preparation.context.canConfirmMovement else {
                continue
            }
            let responseUnitID = preparation.context.responseUnitID
            let targetUnitID = preparation.context.targetUnitID
            preparation.viewModel.confirmCountermeasureMovement()
            guard preparation.viewModel.state.unit(withID: responseUnitID)?.position == preparation.context.destination,
                  preparation.viewModel.focusedCountermeasureID == nil,
                  let attackFixture = focusedCountermeasureFixture(
                      state: preparation.viewModel.state,
                      matching: { preview in
                          preview.summary.report.responseUnitID == responseUnitID &&
                              preview.targetUnit?.id == targetUnitID &&
                              preview.canAttackCurrentTarget
                      }
                  ) else {
                continue
            }
            return attackFixture
        }
        return nil
    }

    private static func countermeasureRuntimeSnapshot(
        of viewModel: GameViewModel
    ) throws -> CountermeasureCommandRuntimeSnapshot {
        CountermeasureCommandRuntimeSnapshot(
            state: viewModel.state,
            archive: try encodedState(viewModel.state),
            units: viewModel.state.units,
            cities: viewModel.state.cities,
            resources: viewModel.state.resources,
            turn: viewModel.state.turn,
            activeFaction: viewModel.state.activeFaction,
            campaignStatus: viewModel.state.campaignStatus,
            aiIntents: viewModel.enemyIntentSummaries.map(\.intent)
        )
    }

    private static func encodedState(_ state: GameState) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(state)
    }

    private static func countermeasureAIIntentSnapshot(in state: GameState) -> [AIIntent] {
        Faction.turnOrder
            .filter { faction in
                faction != .rome &&
                    state.diplomaticStatus(between: .rome, and: faction) == .war
            }
            .flatMap { state.aiIntents(for: $0, limit: 2) }
    }

    private static func countermeasureContextIsFresh(
        _ context: CountermeasureCommandContextReadout?,
        after responseUnit: ArmyUnit,
        previousSourceID: String
    ) -> Bool {
        guard let context,
              context.sourceID == previousSourceID else {
            return true
        }
        return context.focusedCountermeasureID == nil &&
            context.isFocused == false &&
            context.responseUnitID == responseUnit.id &&
            context.responsePosition == responseUnit.position &&
            context.responseIdentityLabel.contains(responseUnit.position.description)
    }

    private static func renderBattleView(
        viewModel: GameViewModel,
        outputPath: String,
        width: Double,
        height: Double,
        initialDrawer: BattleDrawerCategory? = nil,
        drawerUsesScrollView: Bool = true
    ) throws -> NSBitmapImageRep {
        let content = BattleView(
            initialDrawer: initialDrawer,
            drawerUsesScrollView: drawerUsesScrollView
        )
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

    private static func hasVisibleUnitCommandDockContent(
        in bitmap: NSBitmapImageRep,
        logicalWidth: Double,
        logicalHeight: Double
    ) -> Bool {
        let signature = commandDockSignature(in: bitmap, logicalWidth: logicalWidth, logicalHeight: logicalHeight)
        emitPreviewDiagnostic("Unit dock pixels: \(signature)")
        return signature.bright > 60 && signature.red > 20 && signature.cyan > 20
    }

    private static func hasVisibleCityReadoutContent(
        in bitmap: NSBitmapImageRep,
        logicalWidth: Double,
        logicalHeight: Double
    ) -> Bool {
        let signature = commandDockSignature(in: bitmap, logicalWidth: logicalWidth, logicalHeight: logicalHeight)
        emitPreviewDiagnostic("City dock pixels: \(signature)")
        return signature.bright > 60 && signature.orange > 30
    }

    private static func commandDockSampleRegion(
        logicalWidth: Double,
        logicalHeight: Double
    ) -> (x: Int, y: Int, width: Int, height: Int) {
        let interfaceMetrics = BattleInterfaceMetrics(
            container: CGSize(width: logicalWidth, height: logicalHeight)
        )
        let heightRatio = logicalHeight >= logicalWidth ? 0.15 : (logicalHeight < 560 ? 0.23 : 0.15)
        let commandContentStart = Int(interfaceMetrics.commandIdentityWidth + 25)
        let regionHeight = Int(logicalHeight * heightRatio)
        return (
            x: commandContentStart,
            y: max(0, Int(logicalHeight) - regionHeight - 2),
            width: max(1, Int(logicalWidth) - commandContentStart - 54),
            height: regionHeight
        )
    }

    private static func commandDockSignature(
        in bitmap: NSBitmapImageRep,
        logicalWidth: Double,
        logicalHeight: Double
    ) -> (bright: Int, red: Int, cyan: Int, orange: Int) {
        let scaleX = Double(bitmap.pixelsWide) / logicalWidth
        let scaleY = Double(bitmap.pixelsHigh) / logicalHeight
        let region = commandDockSampleRegion(logicalWidth: logicalWidth, logicalHeight: logicalHeight)
        var signature = (bright: 0, red: 0, cyan: 0, orange: 0)

        for logicalY in stride(from: region.y, to: region.y + region.height, by: 3) {
            for logicalX in stride(from: region.x, to: region.x + region.width, by: 3) {
                let pixelX = min(max(Int(Double(logicalX) * scaleX), 0), bitmap.pixelsWide - 1)
                let pixelY = min(max(Int(Double(logicalY) * scaleY), 0), bitmap.pixelsHigh - 1)
                guard let color = bitmap.colorAt(x: pixelX, y: pixelY)?.usingColorSpace(.deviceRGB),
                      color.alphaComponent > 0.6 else {
                    continue
                }
                let red = color.redComponent
                let green = color.greenComponent
                let blue = color.blueComponent
                let brightness = (red + green + blue) / 3
                if brightness > 0.38 { signature.bright += 1 }
                if red > 0.18 && red > green + 0.18 && red > blue + 0.12 { signature.red += 1 }
                if green > 0.18 && blue > 0.20 && green > red + 0.05 && blue > red + 0.07 { signature.cyan += 1 }
                if red > 0.22 && green > 0.12 && red > green + 0.06 && green > blue + 0.05 { signature.orange += 1 }
            }
        }
        return signature
    }

    private static func hasVisibleFocusedEnemyCommanderThreatPreview(
        in bitmap: NSBitmapImageRep,
        logicalWidth: Double,
        logicalHeight: Double,
        readout: EnemyCommanderThreatFocusReadout
    ) -> Bool {
        let metrics = BattleInterfaceMetrics(
            container: CGSize(width: logicalWidth, height: logicalHeight)
        )
        let scaleX = Double(bitmap.pixelsWide) / logicalWidth
        let scaleY = Double(bitmap.pixelsHigh) / logicalHeight

        func signature(in region: (x: Int, y: Int, width: Int, height: Int)) -> (bright: Int, warm: Int, contrast: Int) {
            var result = (bright: 0, warm: 0, contrast: 0)
            for logicalY in stride(from: max(0, region.y), to: min(Int(logicalHeight), region.y + region.height), by: 3) {
                for logicalX in stride(from: max(0, region.x), to: min(Int(logicalWidth), region.x + region.width), by: 3) {
                    let pixelX = min(max(Int(Double(logicalX) * scaleX), 0), bitmap.pixelsWide - 1)
                    let pixelY = min(max(Int(Double(logicalY) * scaleY), 0), bitmap.pixelsHigh - 1)
                    guard let color = bitmap.colorAt(x: pixelX, y: pixelY)?.usingColorSpace(.deviceRGB),
                          color.alphaComponent > 0.6 else {
                        continue
                    }
                    let red = color.redComponent
                    let green = color.greenComponent
                    let blue = color.blueComponent
                    let brightness = (red + green + blue) / 3
                    let spread = max(max(red, green), blue) - min(min(red, green), blue)
                    if brightness > 0.34 { result.bright += 1 }
                    if red > 0.18 && green > 0.12 && red > blue + 0.05 && green > blue + 0.03 {
                        result.warm += 1
                    }
                    if spread > 0.12 { result.contrast += 1 }
                }
            }
            return result
        }

        let mapReadoutRegion = (
            x: 8,
            y: Int(metrics.topBarHeight + metrics.mapInset + 48),
            width: max(1, min(Int(logicalWidth) - 16, logicalWidth < 620 ? Int(logicalWidth) - 20 : 620)),
            height: logicalWidth < 620 ? 88 : 72
        )
        let commandRegion = (
            x: 4,
            y: max(0, Int(logicalHeight - metrics.commandDockHeight) + 2),
            width: max(1, Int(logicalWidth) - 8),
            height: max(1, Int(metrics.commandDockHeight) - 4)
        )
        let mapSignature = signature(in: mapReadoutRegion)
        let commandSignature = signature(in: commandRegion)
        let minimumCommandHeight: CGFloat = metrics.isPortrait ? 102 : (metrics.isShortLandscape ? 80 : 88)
        let minimumIdentityWidth: CGFloat = logicalWidth < 700 ? 128 : 220
        let layoutBudgetIsSafe = metrics.commandDockHeight >= minimumCommandHeight &&
            metrics.commandIdentityWidth >= minimumIdentityWidth &&
            44 >= 44
        emitPreviewDiagnostic("Focused threat preview pixels: map=\(mapSignature), command=\(commandSignature), layoutBudget=\(layoutBudgetIsSafe)")
        return readout.isFocused &&
            readout.hasExecutableCommand == false &&
            readout.commandAvailabilityLabel.contains("仅侦察") &&
            !readout.commanderLabel.isEmpty &&
            !readout.skillName.isEmpty &&
            !readout.targetLabel.isEmpty &&
            !readout.routeLabel.isEmpty &&
            readout.accessibilityLabel.contains("威胁身份\(readout.threatID)") &&
            layoutBudgetIsSafe &&
            mapSignature.bright > 18 &&
            mapSignature.warm > 2 &&
            mapSignature.contrast > 10 &&
            commandSignature.bright > 20 &&
            commandSignature.warm > 2 &&
            commandSignature.contrast > 10
    }

    private static func hasVisibleFocusedCountermeasurePreview(
        in bitmap: NSBitmapImageRep,
        logicalWidth: Double,
        logicalHeight: Double,
        context: CountermeasureCommandContextReadout
    ) -> Bool {
        let dock = commandDockSignature(in: bitmap, logicalWidth: logicalWidth, logicalHeight: logicalHeight)
        emitPreviewDiagnostic("Focused countermeasure pixels: dock=\(dock), source=\(context.sourceID)")
        return context.isFocused &&
            context.selectedPerspective == .countermeasure &&
            !context.responseUnitLabel.isEmpty &&
            !context.destinationLabel.isEmpty &&
            !context.targetLabel.isEmpty &&
            !context.nextStepLabel.isEmpty &&
            context.accessibilityLabel.contains("不会自动执行后续步骤") &&
            !context.userFacingAccessibilityLabel.contains(context.sourceID) &&
            !context.mapFocusLabel.contains(context.sourceID) &&
            context.automationIdentifier.contains(context.sourceID) &&
            dock.bright > 20 &&
            (dock.red > 2 || dock.cyan > 2 || dock.orange > 2)
    }

    private static func hasVisibleFocusedEnemyCommanderThreatCard(
        in bitmap: NSBitmapImageRep,
        logicalWidth: Double,
        logicalHeight: Double,
        readout: EnemyCommanderThreatFocusReadout
    ) -> Bool {
        let metrics = BattleInterfaceMetrics(
            container: CGSize(width: logicalWidth, height: logicalHeight)
        )
        let scaleX = Double(bitmap.pixelsWide) / logicalWidth
        let scaleY = Double(bitmap.pixelsHigh) / logicalHeight
        let drawerWidth = logicalHeight >= logicalWidth
            ? max(280, logicalWidth - 20)
            : min(380, logicalWidth * 0.42)
        let drawerHeight = logicalHeight >= logicalWidth
            ? min(520, logicalHeight * 0.56)
            : max(180, min(620, logicalHeight - Double(metrics.fixedChromeHeight) - 58))
        let drawerX = logicalWidth - drawerWidth - (logicalHeight >= logicalWidth ? 10 : 8)
        let drawerY = Double(metrics.topBarHeight) + 52
        // The focused EnemyIntentPanelView promotes the same-source threat card
        // above the plan card. Mirror the existing drawer header, scroll padding,
        // panel padding, title row and spacing so this samples the actual card
        // body rather than an arbitrary drawer/background region.
        let drawerHeaderHeight = 48.0
        let drawerScrollPadding = 10.0
        let panelPadding = 12.0
        let panelTitleHeight = 20.0
        let panelTitleSpacing = 10.0
        let focusedCardTop = drawerY + drawerHeaderHeight + drawerScrollPadding +
            panelPadding + panelTitleHeight + panelTitleSpacing
        let cardRegion = (
            x: max(0, Int(drawerX + drawerScrollPadding + 8)),
            y: max(0, Int(focusedCardTop)),
            width: max(1, Int(drawerWidth - 16)),
            height: max(1, Int(drawerHeight - (focusedCardTop - drawerY) - drawerScrollPadding))
        )

        var signature = (bright: 0, warm: 0, contrast: 0)
        for logicalY in stride(from: cardRegion.y, to: min(Int(logicalHeight), cardRegion.y + cardRegion.height), by: 3) {
            for logicalX in stride(from: cardRegion.x, to: min(Int(logicalWidth), cardRegion.x + cardRegion.width), by: 3) {
                let pixelX = min(max(Int(Double(logicalX) * scaleX), 0), bitmap.pixelsWide - 1)
                let pixelY = min(max(Int(Double(logicalY) * scaleY), 0), bitmap.pixelsHigh - 1)
                guard let color = bitmap.colorAt(x: pixelX, y: pixelY)?.usingColorSpace(.deviceRGB),
                      color.alphaComponent > 0.6 else {
                    continue
                }
                let red = color.redComponent
                let green = color.greenComponent
                let blue = color.blueComponent
                let brightness = (red + green + blue) / 3
                let spread = max(max(red, green), blue) - min(min(red, green), blue)
                if brightness > 0.34 { signature.bright += 1 }
                if red > 0.20 && green > 0.12 && red > blue + 0.06 && green > blue + 0.04 {
                    signature.warm += 1
                }
                if spread > 0.12 { signature.contrast += 1 }
            }
        }
        let hitAreaBudgetIsSafe = drawerWidth >= 280 &&
            drawerHeight >= 180 &&
            cardRegion.width >= 44 &&
            cardRegion.height >= 44 &&
            drawerX >= 0 &&
            drawerY >= Double(metrics.topBarHeight) &&
            44 >= 44
        emitPreviewDiagnostic("Focused threat card pixels: \(signature), region=\(cardRegion), hitAreaBudget=\(hitAreaBudgetIsSafe)")
        return readout.isFocused &&
            readout.isPrimaryFallback == false &&
            readout.selectedPerspective == .enemyIntent &&
            readout.threatID == readout.overlayID &&
            !readout.commanderLabel.isEmpty &&
            !readout.traitLabel.isEmpty &&
            !readout.skillName.isEmpty &&
            !readout.skillSymbol.isEmpty &&
            !readout.title.isEmpty &&
            readout.focusStateLabel == "已定位" &&
            readout.commandAvailabilityLabel.contains("仅侦察") &&
            !readout.targetLabel.isEmpty &&
            !readout.routeLabel.isEmpty &&
            !readout.spaceChainLabel.isEmpty &&
            !readout.detailLabel.isEmpty &&
            readout.accessibilityLabel.contains("威胁身份\(readout.threatID)") &&
            hitAreaBudgetIsSafe &&
            signature.bright > 18 &&
            signature.warm > 2 &&
            signature.contrast > 8
    }

    private static func commandDockSignaturesDiffer(
        unitBitmap: NSBitmapImageRep,
        cityBitmap: NSBitmapImageRep,
        logicalWidth: Double,
        logicalHeight: Double
    ) -> Bool {
        let unit = commandDockSignature(in: unitBitmap, logicalWidth: logicalWidth, logicalHeight: logicalHeight)
        let city = commandDockSignature(in: cityBitmap, logicalWidth: logicalWidth, logicalHeight: logicalHeight)
        emitPreviewDiagnostic("Command dock delta: unit=\(unit), city=\(city)")
        return unit.red > city.red + 10 && city.orange > unit.orange + 10
    }

    private static func hasVisibleMapIntelligenceDock(
        in bitmap: NSBitmapImageRep,
        logicalWidth: Double,
        logicalHeight: Double
    ) -> Bool {
        let scaleX = Double(bitmap.pixelsWide) / logicalWidth
        let scaleY = Double(bitmap.pixelsHigh) / logicalHeight
        let interfaceMetrics = BattleInterfaceMetrics(
            container: CGSize(width: logicalWidth, height: logicalHeight)
        )
        let commandDockHeight = Double(interfaceMetrics.commandDockHeight)
        let intelligenceHeight: Int = logicalWidth < 620 ? 96 : 58
        let region = (
            x: 10,
            y: max(0, Int(logicalHeight - commandDockHeight) - intelligenceHeight - 4),
            width: min(230, max(1, Int(logicalWidth) - 20)),
            height: intelligenceHeight
        )
        let legendRegionX = logicalWidth < 620 ? 140 : 300
        let legendRegionY = logicalWidth < 620
            ? region.y + intelligenceHeight / 2
            : region.y
        let legendRegion = (
            x: legendRegionX,
            y: legendRegionY,
            width: max(1, Int(logicalWidth) - legendRegionX - 20),
            height: logicalWidth < 620 ? intelligenceHeight / 2 : intelligenceHeight
        )
        var signature = (bright: 0, red: 0, cyan: 0, gold: 0)
        var legendSignature = (bright: 0, tinted: 0)

        for logicalY in stride(from: region.y, to: region.y + region.height, by: 2) {
            for logicalX in stride(from: region.x, to: region.x + region.width, by: 2) {
                let pixelX = min(max(Int(Double(logicalX) * scaleX), 0), bitmap.pixelsWide - 1)
                let pixelY = min(max(Int(Double(logicalY) * scaleY), 0), bitmap.pixelsHigh - 1)
                guard let color = bitmap.colorAt(x: pixelX, y: pixelY)?.usingColorSpace(.deviceRGB),
                      color.alphaComponent > 0.6 else {
                    continue
                }
                let red = color.redComponent
                let green = color.greenComponent
                let blue = color.blueComponent
                let brightness = (red + green + blue) / 3
                if brightness > 0.34 { signature.bright += 1 }
                if red > 0.16 && red > green + 0.07 && red > blue + 0.05 { signature.red += 1 }
                if green > 0.09 && blue > 0.10 && green > red + 0.02 && blue > red + 0.03 { signature.cyan += 1 }
                if red > 0.14 && green > 0.10 && red > blue + 0.06 && green > blue + 0.03 { signature.gold += 1 }
            }
        }

        for logicalY in stride(from: legendRegion.y, to: legendRegion.y + legendRegion.height, by: 2) {
            for logicalX in stride(from: legendRegion.x, to: legendRegion.x + legendRegion.width, by: 2) {
                let pixelX = min(max(Int(Double(logicalX) * scaleX), 0), bitmap.pixelsWide - 1)
                let pixelY = min(max(Int(Double(logicalY) * scaleY), 0), bitmap.pixelsHigh - 1)
                guard let color = bitmap.colorAt(x: pixelX, y: pixelY)?.usingColorSpace(.deviceRGB),
                      color.alphaComponent > 0.6 else {
                    continue
                }
                let components = [color.redComponent, color.greenComponent, color.blueComponent]
                let brightness = components.reduce(0, +) / 3
                if brightness > 0.42 { legendSignature.bright += 1 }
                if brightness > 0.16,
                   (components.max() ?? 0) - (components.min() ?? 0) > 0.10 {
                    legendSignature.tinted += 1
                }
            }
        }

        emitPreviewDiagnostic("Map intelligence dock pixels: buttons=\(signature), legend=\(legendSignature)")
        return signature.bright > 25 &&
            signature.red > 8 &&
            signature.cyan > 8 &&
            signature.gold > 8 &&
            legendSignature.bright > 8 &&
            legendSignature.tinted > 12
    }

    private static func hasMapDominantBattleShell(
        in bitmap: NSBitmapImageRep,
        logicalWidth: Double,
        logicalHeight: Double
    ) -> Bool {
        let scaleX = Double(bitmap.pixelsWide) / logicalWidth
        let scaleY = Double(bitmap.pixelsHigh) / logicalHeight
        let mapRegion = (
            x: Int(logicalWidth * 0.08),
            y: Int(logicalHeight * 0.22),
            width: Int(logicalWidth * 0.72),
            height: Int(logicalHeight * 0.42)
        )

        func counts(in regions: [(x: Int, y: Int, width: Int, height: Int)]) -> (map: Int, bright: Int) {
            var mapPixels = 0
            var brightPixels = 0
            for region in regions {
                for logicalY in stride(from: region.y, to: region.y + region.height, by: 5) {
                    for logicalX in stride(from: region.x, to: region.x + region.width, by: 5) {
                        let pixelX = min(max(Int(Double(logicalX) * scaleX), 0), bitmap.pixelsWide - 1)
                        let pixelY = min(max(Int(Double(logicalY) * scaleY), 0), bitmap.pixelsHigh - 1)
                        guard let color = bitmap.colorAt(x: pixelX, y: pixelY)?.usingColorSpace(.deviceRGB) else {
                            continue
                        }
                        let brightness = (color.redComponent + color.greenComponent + color.blueComponent) / 3
                        let maximumChannel = max(max(color.redComponent, color.greenComponent), color.blueComponent)
                        let minimumChannel = min(min(color.redComponent, color.greenComponent), color.blueComponent)
                        let spread = maximumChannel - minimumChannel
                        if color.alphaComponent > 0.6 && brightness > 0.16 && spread > 0.035 {
                            mapPixels += 1
                        }
                        if color.alphaComponent > 0.6 && brightness > 0.38 {
                            brightPixels += 1
                        }
                    }
                }
            }
            return (mapPixels, brightPixels)
        }

        func toolIconPixels(in region: (x: Int, y: Int, width: Int, height: Int)) -> Int {
            var brightPixels = 0
            for logicalY in stride(from: region.y, to: region.y + region.height, by: 2) {
                for logicalX in stride(from: region.x, to: region.x + region.width, by: 2) {
                    let pixelX = min(max(Int(Double(logicalX) * scaleX), 0), bitmap.pixelsWide - 1)
                    let pixelY = min(max(Int(Double(logicalY) * scaleY), 0), bitmap.pixelsHigh - 1)
                    guard let color = bitmap.colorAt(x: pixelX, y: pixelY)?.usingColorSpace(.deviceRGB) else {
                        continue
                    }
                    let brightness = (color.redComponent + color.greenComponent + color.blueComponent) / 3
                    if color.alphaComponent > 0.6 && brightness > 0.30 {
                        brightPixels += 1
                    }
                }
            }
            return brightPixels
        }

        let mapCounts = counts(in: [mapRegion])
        let interfaceMetrics = BattleInterfaceMetrics(
            container: CGSize(width: logicalWidth, height: logicalHeight)
        )
        let toolTop = Int(interfaceMetrics.topBarHeight + interfaceMetrics.mapInset + 4)
        let toolStripWidth = 5 * 44 + 4 * Int(interfaceMetrics.edgeToolSpacing) + 4
        let toolStartX = max(0, Int(logicalWidth) - toolStripWidth - Int(interfaceMetrics.mapInset + 4))
        let toolBins = (0..<5).map { index in
            return (
                x: toolStartX + 2 + index * (44 + Int(interfaceMetrics.edgeToolSpacing)),
                y: toolTop + 2,
                width: 44,
                height: 44
            )
        }
        let toolCounts = toolBins.map { toolIconPixels(in: $0) }
        emitPreviewDiagnostic("Battle shell pixels: map=\(mapCounts.map), tools=\(toolCounts)")
        return mapCounts.map > 240 && toolCounts.allSatisfy { $0 > 10 }
    }

    private static func hasStrategicMapMaterialCoverage(
        in bitmap: NSBitmapImageRep,
        logicalWidth: Double,
        logicalHeight: Double
    ) -> Bool {
        let scaleX = Double(bitmap.pixelsWide) / logicalWidth
        let scaleY = Double(bitmap.pixelsHigh) / logicalHeight
        let interfaceMetrics = BattleInterfaceMetrics(
            container: CGSize(width: logicalWidth, height: logicalHeight)
        )
        let mapTop = Int(interfaceMetrics.topBarHeight + interfaceMetrics.mapInset)
        let mapBottom = max(mapTop + 1, Int(logicalHeight - interfaceMetrics.commandDockHeight - interfaceMetrics.mapInset))
        let bandWidth = max(1, Int(logicalWidth / 3))
        var bandMaterial = [0, 0, 0]
        var palette = (green: 0, blue: 0, earth: 0, contrast: 0)

        for logicalY in stride(from: mapTop, to: mapBottom, by: 5) {
            for logicalX in stride(from: 6, to: max(7, Int(logicalWidth) - 6), by: 5) {
                let pixelX = min(max(Int(Double(logicalX) * scaleX), 0), bitmap.pixelsWide - 1)
                let pixelY = min(max(Int(Double(logicalY) * scaleY), 0), bitmap.pixelsHigh - 1)
                guard let color = bitmap.colorAt(x: pixelX, y: pixelY)?.usingColorSpace(.deviceRGB),
                      color.alphaComponent > 0.6 else {
                    continue
                }
                let red = color.redComponent
                let green = color.greenComponent
                let blue = color.blueComponent
                let brightness = (red + green + blue) / 3
                let spread = max(max(red, green), blue) - min(min(red, green), blue)
                guard brightness > 0.13 && spread > 0.025 else { continue }

                bandMaterial[min(2, logicalX / bandWidth)] += 1
                if green > red + 0.025 && green > blue - 0.025 { palette.green += 1 }
                if blue > red + 0.045 { palette.blue += 1 }
                if red > blue + 0.035 && green > blue + 0.015 { palette.earth += 1 }
                if spread > 0.10 { palette.contrast += 1 }
            }
        }

        emitPreviewDiagnostic("Strategic map material pixels: bands=\(bandMaterial), palette=\(palette)")
        return bandMaterial.allSatisfy { $0 > 55 } &&
            palette.green > 45 &&
            palette.blue > 45 &&
            palette.earth > 35 &&
            palette.contrast > 90
    }

    private static func emitPreviewDiagnostic(_ message: String) {
        FileHandle.standardError.write(Data("\(message)\n".utf8))
    }
}

private struct CountermeasureCommandRuntimeSnapshot {
    var state: GameState
    var archive: Data
    var units: [ArmyUnit]
    var cities: [City]
    var resources: [Faction: EmpireResources]
    var turn: Int
    var activeFaction: Faction
    var campaignStatus: CampaignStatus
    var aiIntents: [AIIntent]
}

enum PreviewRenderError: Error {
    case renderFailed
    case missingMapDominantBattleShell
    case missingMapIntelligenceDock
    case missingMapOverlayFocusStrategy
    case missingBattleDisplayContext
    case missingMapOverlayHierarchy
    case visibleRawSourceIdentifier
    case missingContextualCommandDock
    case missingMapVisualPriority
    case missingBattleCommandHierarchy
    case missingMapViewportStrategy
    case missingTerrainMaterialStrategy
    case missingCoastlineStrategy
    case missingStrategicMapMaterialCoverage
    case missingCommandDockAttackFixture
    case missingAttackForecast
    case missingDistinctCommandDockRender
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
    case missingEnemyCommanderThreatMapOverlay
    case missingActiveEnemyCommanderThreatPrimary
    case missingActiveEnemyCommanderThreatSecondary
    case missingActiveEnemyCommanderThreatSummary
    case missingActiveEnemyCommanderThreatOverlay
    case missingActiveEnemyCommanderThreatSource
    case missingActiveEnemyCommanderThreatReadout
    case missingEnemyCommanderThreatFocusReadout
    case missingEnemyCommanderThreatCommandCleanup
    case missingFocusedEnemyCommanderThreatRender
    case missingFocusedEnemyCommanderThreatCardRender
    case missingCountermeasureSummary
    case missingCountermeasureOverlay
    case missingCountermeasureCommandPreview
    case missingCountermeasureCommandContext
    case missingCountermeasureCommandSource
    case missingCountermeasureCommandConfirmation
    case missingCountermeasureOrderRuntimeConfirmation
    case missingCountermeasureMovementRuntimeConfirmation
    case missingCountermeasureTargetRuntimeConfirmation
    case missingCountermeasureCommandCleanup
    case missingCountermeasureCommandRender
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
