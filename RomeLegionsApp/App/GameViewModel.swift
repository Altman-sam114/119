import Foundation
import SwiftUI

@MainActor
final class GameViewModel: ObservableObject {
    @Published var state = GameState.newCampaign()
    @Published var selectedMode: GameMode = .campaign
    @Published var selectedUnitID: String?
    @Published var selectedCityID: String?
    @Published var selectedPosition: Position?
    @Published var selectedAttackTargetID: String?
    @Published var selectedTechnology: Technology?
    @Published var focusedCountermeasureID: String?
    @Published var focusedBattleObjectiveRole: BattleObjectiveMapRole?
    @Published var focusedEnemyCommanderThreatID: String?
    @Published var selectedMapReconPerspective: MapReconPerspectiveKind = .enemyIntent
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

    var selectedCityBrief: SelectedCityBrief? {
        guard let selectedCity else { return nil }
        return cityBrief(for: selectedCity)
    }

    var commandCityBrief: SelectedCityBrief? {
        guard let commandCity else { return nil }
        return cityBrief(for: commandCity)
    }

    var commandCityRecruitmentOptions: [CityRecruitmentOptionPreview] {
        commandCityBrief?.recruitmentOptions ?? []
    }

    var focusedPosition: Position? {
        selectedPosition ?? selectedUnit?.position ?? selectedCity?.position
    }

    var selectedTile: Tile? {
        guard let position = focusedPosition else { return nil }
        return state.tile(at: position)
    }

    var campaignStatus: CampaignStatus {
        state.campaignStatus
    }

    var isCampaignOver: Bool {
        campaignStatus.isGameOver
    }

    var campaignStatusTitle: String {
        campaignStatus.title
    }

    var campaignStatusDetail: String {
        campaignStatus.detail
    }

    var primaryMission: Mission? {
        if let primaryMissionID = campaignStatus.primaryMissionID,
           let mission = state.missions.first(where: { $0.id == primaryMissionID }) {
            return mission
        }

        return state.missions.first { !$0.isCompleted } ?? state.missions.first
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

    var aiOperationalPlanSummaries: [AIOperationalPlanSummary] {
        state.aiOperationalPlanReports(against: .rome, perFactionLimit: 4, limit: 5)
            .map(aiOperationalPlanSummary(for:))
    }

    var primaryAIOperationalPlanSummary: AIOperationalPlanSummary? {
        aiOperationalPlanSummaries.first
    }

    var enemyCommanderThreatSummaries: [EnemyCommanderThreatSummary] {
        state.enemyCommanderThreatReports(against: .rome, limit: 5)
            .map(enemyCommanderThreatSummary(for:))
    }

    var primaryEnemyCommanderThreatSummary: EnemyCommanderThreatSummary? {
        enemyCommanderThreatSummaries.first
    }

    var focusedEnemyCommanderThreatSummary: EnemyCommanderThreatSummary? {
        guard let focusedEnemyCommanderThreatID else { return nil }
        return enemyCommanderThreatSummaries.first { $0.id == focusedEnemyCommanderThreatID }
    }

    /// 当前地图与敌情读板使用的威胁来源：有效焦点优先，否则回到全局首要威胁。
    /// 这是纯 ViewModel 派生值；失效焦点不会写回选择态、GameState 或存档。
    var activeEnemyCommanderThreatSummary: EnemyCommanderThreatSummary? {
        focusedEnemyCommanderThreatSummary ?? primaryEnemyCommanderThreatSummary
    }

    var activeEnemyCommanderThreatID: String? {
        activeEnemyCommanderThreatSummary?.id
    }

    var enemyCommanderThreatMapOverlays: [EnemyCommanderThreatMapOverlay] {
        let focusedID = focusedEnemyCommanderThreatID
        return enemyCommanderThreatSummaries.map { summary in
            EnemyCommanderThreatMapOverlay(
                summary: summary,
                isFocused: summary.id == focusedID
            )
        }
    }

    var activeEnemyCommanderThreatMapOverlay: EnemyCommanderThreatMapOverlay? {
        guard let summary = activeEnemyCommanderThreatSummary else {
            return nil
        }

        return EnemyCommanderThreatMapOverlay(
            summary: summary,
            isFocused: summary.id == focusedEnemyCommanderThreatID
        )
    }

    /// v0.64 兼容 API；其历史“primary”名称保留，但展示语义已是 active（focused ?? primary）。
    var primaryEnemyCommanderThreatMapOverlay: EnemyCommanderThreatMapOverlay? {
        activeEnemyCommanderThreatMapOverlay
    }

    var enemyCommanderThreatMapOverlaysByPosition: [Position: [EnemyCommanderThreatPositionOverlay]] {
        enemyCommanderThreatMapOverlays.reduce(into: [Position: [EnemyCommanderThreatPositionOverlay]]()) { result, overlay in
            for positionOverlay in overlay.positionOverlays {
                result[positionOverlay.position, default: []].append(positionOverlay)
            }
        }
    }

    var enemyCommanderThreatOverlaysByPosition: [Position: [EnemyCommanderThreatPositionOverlay]] {
        enemyCommanderThreatMapOverlaysByPosition
    }

    var enemyCommanderThreatOverlayPositions: Set<Position> {
        Set(enemyCommanderThreatOverlaysByPosition.keys)
    }

    var countermeasureSummaries: [CountermeasureSummary] {
        state.countermeasureReports(for: .rome, limit: 5)
            .map(countermeasureSummary(for:))
    }

    var primaryCountermeasureSummary: CountermeasureSummary? {
        countermeasureSummaries.first
    }

    var countermeasureCommandPreviews: [CountermeasureCommandPreview] {
        countermeasureSummaries.map(countermeasureCommandPreview(for:))
    }

    var primaryCountermeasureCommandPreview: CountermeasureCommandPreview? {
        primaryCountermeasureSummary.map(countermeasureCommandPreview(for:))
    }

    var selectedCountermeasureCommandPreview: CountermeasureCommandPreview? {
        guard let selectedUnitID else { return nil }
        let previews = countermeasureCommandPreviews
        if let focusedCountermeasureID,
           let focusedPreview = previews.first(where: {
               $0.id == focusedCountermeasureID &&
                   $0.summary.report.responseUnitID == selectedUnitID
           }) {
            return focusedPreview
        }

        return previews.first { $0.summary.report.responseUnitID == selectedUnitID }
    }

    var primaryCountermeasureMapOverlay: CountermeasureMapOverlay? {
        primaryCountermeasureSummary.map { CountermeasureMapOverlay(summary: $0) }
    }

    var countermeasureRouteSegments: [CountermeasureRouteSegment] {
        primaryCountermeasureMapOverlay?.routeSegments ?? []
    }

    var countermeasureOverlaysByPosition: [Position: CountermeasurePositionOverlay] {
        guard let overlay = primaryCountermeasureMapOverlay else { return [:] }

        return overlay.positionOverlays.reduce(into: [Position: CountermeasurePositionOverlay]()) { result, positionOverlay in
            result[positionOverlay.position] = positionOverlay
        }
    }

    var countermeasureOverlayPositions: Set<Position> {
        Set(countermeasureOverlaysByPosition.keys)
    }

    var mapControlSummaries: [MapControlSummary] {
        state.mapControlReports(for: .rome)
            .map(mapControlSummary(for:))
    }

    var primaryMapControlSummary: MapControlSummary? {
        mapControlSummaries.first { $0.threatLevel != .quiet && $0.report.enemyInfluence > 0 } ??
            selectedMapControlSummary ??
            mapControlSummaries.first
    }

    var selectedMapControlSummary: MapControlSummary? {
        guard let position = focusedPosition,
              let report = state.mapControlReport(at: position, for: .rome) else {
            return nil
        }

        return mapControlSummary(for: report)
    }

    var threatHeatZoneSummaries: [ThreatHeatZoneSummary] {
        state.threatHeatZoneReports(for: .rome, limit: 5)
            .map(threatHeatZoneSummary(for:))
    }

    var primaryThreatHeatZoneSummary: ThreatHeatZoneSummary? {
        threatHeatZoneSummaries.first
    }

    var threatHeatZoneOverlaysByPosition: [Position: ThreatHeatZoneSummary] {
        var values: [Position: ThreatHeatZoneSummary] = [:]
        for summary in threatHeatZoneSummaries {
            for position in summary.report.positions {
                let current = values[position]
                if current == nil || summary.report.score > (current?.report.score ?? 0) {
                    values[position] = summary
                }
            }
        }
        return values
    }

    var threatHeatOverlayPositions: Set<Position> {
        Set(threatHeatZoneOverlaysByPosition.keys)
    }

    var mapControlOverlayPositions: Set<Position> {
        Set(mapControlSummaries.filter { $0.controlState == .contested || $0.threatLevel != .quiet }.map(\.position))
    }

    var battlefieldFocusSummaries: [BattlefieldFocusSummary] {
        state.battlefieldFocusReports(for: .rome, limit: 5)
            .map(battlefieldFocusSummary(for:))
    }

    var primaryBattlefieldFocusSummary: BattlefieldFocusSummary? {
        battlefieldFocusSummaries.first
    }

    var commanderSynergySummaries: [CommanderSynergySummary] {
        state.commanderSynergyReports(for: .rome, limit: 5)
            .map(commanderSynergySummary(for:))
    }

    var primaryCommanderSynergySummary: CommanderSynergySummary? {
        commanderSynergySummaries.first
    }

    var primaryBattleObjectiveChainSummary: BattleObjectiveChainSummary? {
        guard let focus = primaryBattlefieldFocusSummary else {
            return nil
        }

        return BattleObjectiveChainSummary(
            focus: focus,
            synergy: selectedCommanderSynergySummary ?? primaryCommanderSynergySummary,
            maneuver: primaryManeuverOptionSummary,
            recommendation: selectedTacticalRecommendationSummary
        )
    }

    var primaryBattleObjectiveMapOverlay: BattleObjectiveMapOverlay? {
        primaryBattleObjectiveChainSummary.map { BattleObjectiveMapOverlay(chain: $0) }
    }

    var battleObjectiveRouteSegments: [BattleObjectiveRouteSegment] {
        primaryBattleObjectiveMapOverlay?.routeSegments ?? []
    }

    var battleObjectiveOverlaysByPosition: [Position: [BattleObjectivePositionOverlay]] {
        guard let overlay = primaryBattleObjectiveMapOverlay else { return [:] }

        return overlay.positionOverlays.reduce(into: [Position: [BattleObjectivePositionOverlay]]()) { result, positionOverlay in
            result[positionOverlay.position, default: []].append(positionOverlay)
        }
    }

    var battleObjectiveOverlayPositions: Set<Position> {
        Set(battleObjectiveOverlaysByPosition.keys)
    }

    var focusedBattleObjectiveOverlay: BattleObjectivePositionOverlay? {
        guard let focusedBattleObjectiveRole else { return nil }

        return primaryBattleObjectiveMapOverlay?.positionOverlays.first { overlay in
            overlay.role == focusedBattleObjectiveRole
        }
    }

    var battleObjectiveStageCommandPreviews: [BattleObjectiveStageCommandPreview] {
        guard let overlay = primaryBattleObjectiveMapOverlay else { return [] }

        return overlay.positionOverlays.compactMap { positionOverlay in
            battleObjectiveStageCommandPreview(for: positionOverlay)
        }
    }

    var focusedBattleObjectiveStageCommandPreview: BattleObjectiveStageCommandPreview? {
        guard let focusedBattleObjectiveRole else { return nil }

        return battleObjectiveStageCommandPreviews.first { preview in
            preview.role == focusedBattleObjectiveRole
        }
    }

    var selectedBattleObjectiveStageCommandPreview: BattleObjectiveStageCommandPreview? {
        guard let selectedUnitID else { return nil }

        let previews = battleObjectiveStageCommandPreviews
        if let focusedBattleObjectiveRole,
           let focusedPreview = previews.first(where: {
               $0.role == focusedBattleObjectiveRole &&
                   $0.commandUnit?.id == selectedUnitID
           }) {
            return focusedPreview
        }

        return previews.first { preview in
            preview.commandUnit?.id == selectedUnitID
        }
    }

    var primaryBattleObjectiveStageCommandPreview: BattleObjectiveStageCommandPreview? {
        focusedBattleObjectiveStageCommandPreview ?? battleObjectiveStageCommandPreviews.first
    }

    var activeBattleObjectiveStageCommandPreview: BattleObjectiveStageCommandPreview? {
        focusedBattleObjectiveStageCommandPreview ??
            selectedBattleObjectiveStageCommandPreview ??
            primaryBattleObjectiveStageCommandPreview
    }

    var activeBattleObjectiveStageRole: BattleObjectiveMapRole? {
        activeBattleObjectiveStageCommandPreview?.role
    }

    var primaryBattlefieldConvergenceSummary: BattlefieldConvergenceSummary? {
        let summary = BattlefieldConvergenceSummary(
            objectiveChain: primaryBattleObjectiveChainSummary,
            countermeasure: primaryCountermeasureSummary,
            countermeasurePreview: primaryCountermeasureCommandPreview,
            stagePreview: activeBattleObjectiveStageCommandPreview,
            synergy: selectedCommanderSynergySummary ?? primaryCommanderSynergySummary,
            maneuver: primaryManeuverOptionSummary,
            threatHeat: primaryThreatHeatZoneSummary,
            mapControl: selectedMapControlSummary ?? primaryMapControlSummary
        )

        return summary.hasSignals ? summary : nil
    }

    var primaryCampaignAdvanceReadout: CampaignAdvanceReadout? {
        let mission = primaryMission
        let progress = campaignStatus.progressText ?? campaignStatus.detail
        let pressure = primaryFrontlinePressureSummary
        let objectiveChain = primaryBattleObjectiveChainSummary
        let objectiveStage = activeBattleObjectiveStageCommandPreview
        let recon = mapReconPerspectiveHUDReadout
        let convergence = primaryBattlefieldConvergenceSummary

        guard mission != nil || objectiveChain != nil || pressure != nil || convergence != nil else {
            return nil
        }

        var signals: [CampaignAdvanceSignal] = []

        if let mission {
            signals.append(
                CampaignAdvanceSignal(
                    kind: .mission,
                    title: mission.title,
                    detail: mission.objective,
                    position: nil,
                    sourceID: mission.id
                )
            )
        }

        if !progress.isEmpty {
            signals.append(
                CampaignAdvanceSignal(
                    kind: .progress,
                    title: campaignStatusTitle,
                    detail: progress,
                    position: nil,
                    sourceID: campaignStatus.primaryMissionID
                )
            )
        }

        if let pressure {
            signals.append(
                CampaignAdvanceSignal(
                    kind: .frontline,
                    title: pressure.pressureLabel,
                    detail: pressure.detail,
                    position: pressure.targetPosition,
                    sourceID: pressure.id
                )
            )
        }

        if let objectiveChain {
            signals.append(
                CampaignAdvanceSignal(
                    kind: .objectiveChain,
                    title: objectiveChain.priorityLabel,
                    detail: objectiveChain.chainLabel,
                    position: objectiveChain.focus.targetPosition,
                    sourceID: objectiveChain.id
                )
            )
        }

        if let objectiveStage {
            signals.append(
                CampaignAdvanceSignal(
                    kind: .objectiveStage,
                    title: objectiveStage.stageLabel,
                    detail: objectiveStage.commandEntryCueLabel,
                    position: objectiveStage.position,
                    sourceID: objectiveStage.id
                )
            )
        }

        if recon.hasSignals {
            signals.append(
                CampaignAdvanceSignal(
                    kind: .recon,
                    title: recon.selectedKind.displayName,
                    detail: recon.compactLabel,
                    position: recon.signals.first?.position,
                    sourceID: recon.selectedKind.rawValue
                )
            )
        }

        if let convergence {
            signals.append(
                CampaignAdvanceSignal(
                    kind: .convergence,
                    title: convergence.priorityLabel,
                    detail: convergence.compactLabel,
                    position: convergence.signals.first?.position,
                    sourceID: convergence.id
                )
            )
        }

        let missionTitle = mission?.title ?? campaignStatusTitle
        let missionObjectiveLabel = mission?.objective ?? campaignStatusDetail
        let frontlineLabel = pressure?.compactTitle ?? pressure?.pressureLabel ?? "战线待确认"
        let objectiveLineLabel = objectiveStage?.focusLabel ?? objectiveChain?.compactLabel ?? "目标线待确认"
        let mapCueLabel = recon.compactLabel
        let nextStepLabel = objectiveStage?.nextStepLabel ??
            convergence?.nextStepLabel ??
            objectiveChain?.focusStageLabel ??
            missionObjectiveLabel
        let riskLabel = pressure?.pressureLabel ??
            convergence?.riskLabel ??
            objectiveChain?.priorityLabel ??
            "风险待确认"
        let statusLabel = campaignStatus.isGameOver ? campaignStatusTitle : "推进中"
        let compactParts = [
            missionTitle,
            progress,
            objectiveStage?.stageLabel ?? objectiveChain?.focusStageLabel,
            pressure?.pressureLabel
        ].compactMap { value -> String? in
            guard let value, !value.isEmpty else { return nil }
            return value
        }

        return CampaignAdvanceReadout(
            title: "战役推进线",
            statusLabel: statusLabel,
            missionTitle: missionTitle,
            missionObjectiveLabel: missionObjectiveLabel,
            progressLabel: progress,
            frontlineLabel: frontlineLabel,
            objectiveLineLabel: objectiveLineLabel,
            mapCueLabel: mapCueLabel,
            nextStepLabel: nextStepLabel,
            riskLabel: riskLabel,
            compactLabel: compactParts.prefix(3).joined(separator: " · "),
            signals: signals,
            missionID: mission?.id,
            progressText: campaignStatus.progressText,
            frontlineID: pressure?.id,
            objectiveChainID: objectiveChain?.id,
            objectiveStagePreviewID: objectiveStage?.id,
            reconPerspectiveID: recon.selectedKind.rawValue,
            convergenceID: convergence?.id
        )
    }

    var primaryEnemyEngagementLoopReadout: EnemyEngagementLoopReadout? {
        let pressure = primaryFrontlinePressureSummary
        let intent = primaryEnemyEngagementIntentOverlay(matching: pressure)
        let enemyCommanderThreat = primaryEnemyCommanderThreatSummary
        let countermeasure = primaryCountermeasureSummary
        let countermeasurePreview = primaryCountermeasureCommandPreview
        let responseCommanderChain = selectedCommanderChainReadoutForEngagement(countermeasure: countermeasure)
        let convergence = primaryBattlefieldConvergenceSummary
        var signals: [EnemyEngagementLoopSignal] = []

        if let intent {
            signals.append(
                EnemyEngagementLoopSignal(
                    kind: .intentRoute,
                    title: intent.summary.shortTitle,
                    detail: intent.summary.routeDetail,
                    position: intent.targetPosition ?? intent.destinationPosition,
                    sourceID: intent.id
                )
            )
        }

        if let pressure {
            signals.append(
                EnemyEngagementLoopSignal(
                    kind: .frontline,
                    title: pressure.pressureLabel,
                    detail: pressure.detail,
                    position: pressure.targetPosition,
                    sourceID: pressure.id
                )
            )
        }

        if let enemyCommanderThreat {
            signals.append(
                EnemyEngagementLoopSignal(
                    kind: .enemyCommander,
                    title: enemyCommanderThreat.commanderLabel,
                    detail: "\(enemyCommanderThreat.skillName) · \(enemyCommanderThreat.impactLabel)",
                    position: enemyCommanderThreat.targetPosition,
                    sourceID: enemyCommanderThreat.id
                )
            )
        }

        if let countermeasure {
            signals.append(
                EnemyEngagementLoopSignal(
                    kind: .countermeasure,
                    title: countermeasure.kindLabel,
                    detail: countermeasure.countermeasureChainLabel,
                    position: countermeasure.targetPosition,
                    sourceID: countermeasure.id
                )
            )
        }

        if let countermeasurePreview {
            signals.append(
                EnemyEngagementLoopSignal(
                    kind: .counterCommand,
                    title: countermeasurePreview.statusLabel,
                    detail: countermeasurePreview.commandChainLabel,
                    position: countermeasurePreview.destination,
                    sourceID: countermeasurePreview.id
                )
            )
        }

        if let responseCommanderChain {
            signals.append(
                EnemyEngagementLoopSignal(
                    kind: .responseCommander,
                    title: responseCommanderChain.title,
                    detail: responseCommanderChain.compactLabel,
                    position: countermeasurePreview?.responseUnit?.position ?? countermeasure?.responsePosition,
                    sourceID: responseCommanderChain.unitID
                )
            )
        }

        if let convergence,
           !convergence.id.isEmpty {
            signals.append(
                EnemyEngagementLoopSignal(
                    kind: .convergence,
                    title: convergence.priorityLabel,
                    detail: convergence.compactLabel,
                    position: convergence.signals.first?.position,
                    sourceID: convergence.id
                )
            )
        }

        guard !signals.isEmpty else {
            return nil
        }

        let intentLabel = intent.map { "\($0.summary.shortTitle) · \($0.summary.destinationLabel)" } ?? "敌路待确认"
        let pressureLabel = pressure?.compactTitle ?? "战线待确认"
        let enemyCommanderLabel = enemyCommanderThreat.map { "\($0.commanderLabel) · \($0.skillName)" } ?? "敌将待确认"
        let countermeasureLabel = countermeasure.map { "\($0.kindLabel) · \($0.responseLabel)" } ?? "暂无反制"
        let previewResponseUnit: ArmyUnit? = {
            guard let countermeasurePreview else { return nil }
            return countermeasurePreview.responseUnit
        }()
        let previewResponseLabel = previewResponseUnit.map { unit in
            if let generalName = unit.generalName {
                return "\(generalName)回应"
            }
            return "\(unit.faction.displayName)\(unit.kind.displayName)回应"
        }
        let responseLabel = responseCommanderChain?.compactLabel ??
            previewResponseLabel ??
            countermeasure?.responseLabel ??
            "等待回应军团"
        let nextStepLabel = countermeasurePreview?.nextStepLabel ??
            convergence?.nextStepLabel ??
            countermeasure?.commandLabel ??
            intent?.impactLabel ??
            "等待敌情"
        let riskLabel = countermeasure?.riskLabel ??
            convergence?.riskLabel ??
            pressure?.pressureLabel ??
            enemyCommanderThreat?.levelLabel ??
            "风险待确认"
        let statusLabel = countermeasure?.priorityLabel ??
            enemyCommanderThreat?.levelLabel ??
            pressure?.pressureLabel ??
            "监视"
        let compactLabel = [
            intent?.summary.shortTitle,
            pressure?.pressureLabel,
            enemyCommanderThreat?.levelLabel,
            countermeasure?.kindLabel,
            responseCommanderChain != nil ? "将领回应" : nil
        ].compactMap { $0 }.joined(separator: " · ")

        return EnemyEngagementLoopReadout(
            title: "敌情交战闭环",
            statusLabel: statusLabel,
            intentLabel: intentLabel,
            pressureLabel: pressureLabel,
            enemyCommanderLabel: enemyCommanderLabel,
            countermeasureLabel: countermeasureLabel,
            responseLabel: responseLabel,
            nextStepLabel: nextStepLabel,
            riskLabel: riskLabel,
            compactLabel: compactLabel.isEmpty ? "敌情闭环待确认" : compactLabel,
            signals: signals,
            intentID: intent?.id,
            pressureID: pressure?.id,
            enemyCommanderThreatID: enemyCommanderThreat?.id,
            countermeasureID: countermeasure?.id,
            countermeasurePreviewID: countermeasurePreview?.id,
            responseCommanderChainUnitID: responseCommanderChain?.unitID,
            convergenceID: convergence?.id
        )
    }

    var mapReconPerspectiveHUDReadout: MapReconPerspectiveHUDReadout {
        let intent = primaryEnemyEngagementIntentOverlay(matching: primaryFrontlinePressureSummary)
        let engagementLoop = primaryEnemyEngagementLoopReadout
        let countermeasure = primaryCountermeasureSummary
        let countermeasurePreview = primaryCountermeasureCommandPreview
        let objectiveChain = primaryBattleObjectiveChainSummary
        let objectiveStagePreview = activeBattleObjectiveStageCommandPreview
        let threatHeat = primaryThreatHeatZoneSummary
        let mapControl = selectedMapControlSummary ?? primaryMapControlSummary
        let convergence = primaryBattlefieldConvergenceSummary
        let enemyCommanderThreat = activeEnemyCommanderThreatSummary
        var signals: [MapReconPerspectiveSignal] = []

        func append(
            _ kind: MapReconPerspectiveSignalKind,
            title: String,
            detail: String,
            position: Position?,
            sourceID: String
        ) {
            signals.append(
                MapReconPerspectiveSignal(
                    kind: kind,
                    title: title,
                    detail: detail,
                    position: position,
                    sourceID: sourceID
                )
            )
        }

        switch selectedMapReconPerspective {
        case .enemyIntent:
            if let intent {
                append(
                    .enemyIntent,
                    title: intent.summary.shortTitle,
                    detail: intent.summary.routeDetail,
                    position: intent.targetPosition ?? intent.destinationPosition,
                    sourceID: intent.id
                )
            }
            if let engagementLoop {
                append(
                    .engagementLoop,
                    title: engagementLoop.statusLabel,
                    detail: engagementLoop.compactLabel,
                    position: intent?.targetPosition ?? intent?.destinationPosition,
                    sourceID: engagementLoop.compactLabel
                )
            }

        case .countermeasure:
            if let countermeasure {
                append(
                    .countermeasure,
                    title: countermeasure.kindLabel,
                    detail: countermeasure.countermeasureChainLabel,
                    position: countermeasure.targetPosition,
                    sourceID: countermeasure.id
                )
            }
            if let countermeasurePreview {
                append(
                    .counterCommand,
                    title: countermeasurePreview.statusLabel,
                    detail: countermeasurePreview.commandChainLabel,
                    position: countermeasurePreview.destination,
                    sourceID: countermeasurePreview.id
                )
            }

        case .objective:
            if let objectiveChain {
                append(
                    .objectiveChain,
                    title: objectiveChain.priorityLabel,
                    detail: objectiveChain.compactLabel,
                    position: objectiveChain.focus.targetPosition,
                    sourceID: objectiveChain.id
                )
            }
            if let objectiveStagePreview {
                append(
                    .objectiveStage,
                    title: objectiveStagePreview.stageLabel,
                    detail: objectiveStagePreview.commandEntryLabel,
                    position: objectiveStagePreview.position,
                    sourceID: objectiveStagePreview.id
                )
            }

        case .terrainPressure:
            if let threatHeat {
                append(
                    .threatHeat,
                    title: threatHeat.levelLabel,
                    detail: threatHeat.impactLabel,
                    position: threatHeat.targetPosition,
                    sourceID: threatHeat.id
                )
            }
            if let mapControl {
                append(
                    .mapControl,
                    title: mapControl.controlLabel,
                    detail: mapControl.impactLabel,
                    position: mapControl.position,
                    sourceID: mapControl.id
                )
            }
            if let convergence {
                append(
                    .convergence,
                    title: convergence.priorityLabel,
                    detail: convergence.spaceLabel,
                    position: convergence.signals.first?.position,
                    sourceID: convergence.id
                )
            }
        }

        if let enemyCommanderThreat {
            append(
                .enemyCommander,
                title: enemyCommanderThreat.commanderLabel,
                detail: "\(enemyCommanderThreat.skillName) · \(enemyCommanderThreat.spaceChainLabel)",
                position: enemyCommanderThreat.originPosition,
                sourceID: enemyCommanderThreat.id
            )
        }

        let title = "地图侦察"
        let statusLabel: String
        let detailLabel: String
        let nextStepLabel: String
        let riskLabel: String
        let compactLabel: String

        switch selectedMapReconPerspective {
        case .enemyIntent:
            statusLabel = engagementLoop?.statusLabel ?? intent?.summary.threatLabel ?? "监视"
            detailLabel = intent.map { "\($0.summary.shortTitle) · \($0.summary.destinationLabel)" } ??
                enemyCommanderThreat.map { "敌将\($0.commanderLabel) · \($0.rangeLabel)" } ??
                "敌路待确认"
            nextStepLabel = engagementLoop?.nextStepLabel ?? enemyCommanderThreat.map { "定位\($0.commanderLabel)技能范围" } ?? intent?.impactLabel ?? "先确认敌军目标"
            riskLabel = engagementLoop?.riskLabel ?? enemyCommanderThreat?.levelLabel ?? primaryFrontlinePressureSummary?.pressureLabel ?? "风险待确认"
            compactLabel = "敌路 · \(detailLabel)"

        case .countermeasure:
            statusLabel = countermeasurePreview?.statusLabel ?? countermeasure?.priorityLabel ?? "待响应"
            detailLabel = countermeasure?.countermeasureChainLabel ?? "暂无首要反制"
            nextStepLabel = countermeasurePreview?.nextStepLabel ?? countermeasure?.commandLabel ?? "等待反制建议"
            riskLabel = countermeasure?.riskLabel ?? engagementLoop?.riskLabel ?? "风险待确认"
            compactLabel = "反制 · \(countermeasure?.kindLabel ?? statusLabel)"

        case .objective:
            statusLabel = objectiveStagePreview?.statusLabel ?? objectiveChain?.priorityLabel ?? "待确认"
            detailLabel = objectiveStagePreview?.focusLabel ?? objectiveChain?.compactLabel ?? "目标线待确认"
            nextStepLabel = objectiveStagePreview?.nextStepLabel ?? objectiveChain?.chainLabel ?? "确认目标线阶段"
            riskLabel = objectiveChain?.priorityLabel ?? convergence?.riskLabel ?? "风险待确认"
            compactLabel = "目标线 · \(statusLabel)"

        case .terrainPressure:
            statusLabel = threatHeat?.levelLabel ?? mapControl?.levelLabel ?? convergence?.priorityLabel ?? "平静"
            detailLabel = threatHeat.map { "\($0.title) · \($0.impactLabel)" } ??
                mapControl.map { "\($0.title) · \($0.impactLabel)" } ??
                "热区和控区待确认"
            nextStepLabel = convergence?.nextStepLabel ?? mapControl?.detail ?? "继续观察空间压力"
            riskLabel = threatHeat?.impactLabel ?? mapControl?.levelLabel ?? "风险待确认"
            compactLabel = "热区 · \(statusLabel)"
        }

        return MapReconPerspectiveHUDReadout(
            selectedKind: selectedMapReconPerspective,
            availableKinds: MapReconPerspectiveKind.allCases,
            title: title,
            statusLabel: statusLabel,
            compactLabel: compactLabel,
            detailLabel: detailLabel,
            nextStepLabel: nextStepLabel,
            riskLabel: riskLabel,
            signals: signals,
            intentID: intent?.id,
            enemyCommanderThreatID: enemyCommanderThreat?.id,
            engagementLoopID: engagementLoop?.compactLabel,
            countermeasureID: countermeasure?.id,
            countermeasurePreviewID: countermeasurePreview?.id,
            objectiveChainID: objectiveChain?.id,
            objectiveStagePreviewID: objectiveStagePreview?.id,
            threatHeatID: threatHeat?.id,
            mapControlID: mapControl?.id,
            convergenceID: convergence?.id
        )
    }

    private func primaryEnemyEngagementIntentOverlay(matching pressure: FrontlinePressureSummary?) -> EnemyIntentMapOverlay? {
        let overlays = enemyIntentMapOverlays

        if let pressure {
            let matchingOverlays = overlays.filter { overlay in
                overlay.targetPosition == pressure.targetPosition ||
                    overlay.destinationPosition == pressure.targetPosition ||
                    overlay.summary.intent.targetUnitID == pressure.report.targetID ||
                    overlay.summary.intent.targetCityID == pressure.report.targetID
            }

            return matchingOverlays.first { $0.kind == .advanceAttack } ??
                matchingOverlays.first ??
                overlays.first
        }

        return overlays.first
    }

    private func selectedCommanderChainReadoutForEngagement(countermeasure: CountermeasureSummary?) -> SelectedCommanderChainReadout? {
        guard let readout = selectedCommanderChainReadout else {
            return nil
        }

        guard let countermeasure else {
            return readout
        }

        return readout.unitID == countermeasure.report.responseUnitID ? readout : nil
    }

    var frontlinePressureSummaries: [FrontlinePressureSummary] {
        state.frontlinePressureReports(against: .rome, perFactionLimit: 4, limit: 4)
            .map { report in
                let targetUnit = report.targetKind == .unit ? state.unit(withID: report.targetID) : nil
                let targetCity = report.targetKind == .city ? state.city(withID: report.targetID) : nil
                let sourceUnits = report.sourceUnitIDs.compactMap { state.unit(withID: $0) }
                return FrontlinePressureSummary(
                    report: report,
                    targetUnit: targetUnit,
                    targetCity: targetCity,
                    sourceUnits: sourceUnits
                )
            }
    }

    var primaryFrontlinePressureSummary: FrontlinePressureSummary? {
        frontlinePressureSummaries.first
    }

    private func selectedUnitSituationCommandEntries(
        for selectedUnit: ArmyUnit,
        countermeasurePreview: CountermeasureCommandPreview?,
        stagePreview: BattleObjectiveStageCommandPreview?,
        commanderGuidance: CommanderActionGuidance?,
        maneuver: ManeuverOptionSummary?,
        recommendation: TacticalRecommendationSummary?,
        tacticalOrderPreviews: [SelectedTacticalOrderPreview]
    ) -> [SelectedUnitSituationCommandEntry] {
        var entries: [SelectedUnitSituationCommandEntry] = []

        func append(
            kind: SelectedUnitSituationCommandEntryKind,
            title: String,
            detail: String,
            cueLabel: String,
            position: Position?,
            sourceID: String?
        ) {
            entries.append(
                SelectedUnitSituationCommandEntry(
                    kind: kind,
                    title: title,
                    detail: detail,
                    cueLabel: cueLabel,
                    position: position,
                    sourceID: sourceID,
                    isPrimary: entries.isEmpty
                )
            )
        }

        if let countermeasurePreview {
            append(
                kind: .countermeasure,
                title: countermeasurePreview.title,
                detail: "\(countermeasurePreview.statusLabel) · \(countermeasurePreview.nextStepLabel)",
                cueLabel: "\(countermeasurePreview.summary.kindLabel) · \(countermeasurePreview.nextStepLabel)",
                position: countermeasurePreview.destination,
                sourceID: countermeasurePreview.id
            )
        }

        if let stagePreview {
            append(
                kind: .objectiveStage,
                title: stagePreview.title,
                detail: "\(stagePreview.statusLabel) · \(stagePreview.nextStepLabel)",
                cueLabel: stagePreview.commandEntryCueLabel,
                position: stagePreview.position,
                sourceID: stagePreview.id
            )
        }

        if let commanderGuidance {
            append(
                kind: .commanderAction,
                title: commanderGuidance.title,
                detail: "\(commanderGuidance.statusLabel) · \(commanderGuidance.skillCueLabel)",
                cueLabel: commanderGuidance.stageCueLabel ?? commanderGuidance.skillCueLabel,
                position: stagePreview?.position ?? selectedUnit.position,
                sourceID: "\(selectedUnit.id)-commander-action"
            )
        }

        if let maneuver {
            append(
                kind: .maneuver,
                title: "机动入口",
                detail: "\(maneuver.destinationLabel) · \(maneuver.impactLabel)",
                cueLabel: "\(maneuver.kindLabel) · \(maneuver.destinationLabel)",
                position: maneuver.destination,
                sourceID: maneuver.id
            )
        }

        if let recommendation {
            append(
                kind: .recommendation,
                title: "军议入口",
                detail: "\(recommendation.kindLabel) · \(recommendation.riskLabel)",
                cueLabel: recommendation.report.command,
                position: recommendation.destination,
                sourceID: recommendation.id
            )
        }

        if let orderPreview = tacticalOrderPreviews.first(where: { !$0.isCurrent && $0.canSwitch }) ??
            tacticalOrderPreviews.first(where: { $0.isCurrent }) {
            let statusLabel = orderPreview.isCurrent ? "当前姿态" : (orderPreview.blockedReason ?? "可切换")
            append(
                kind: .tacticalOrder,
                title: "姿态入口",
                detail: "\(orderPreview.order.displayName) · \(statusLabel)",
                cueLabel: orderPreview.isCurrent ? "保持\(orderPreview.order.displayName)" : "切换\(orderPreview.order.displayName)",
                position: selectedUnit.position,
                sourceID: orderPreview.order.rawValue
            )
        }

        if entries.isEmpty {
            append(
                kind: .tacticalOrder,
                title: "姿态入口",
                detail: "保持\(selectedUnit.resolvedTacticalOrder.displayName)",
                cueLabel: "保持\(selectedUnit.resolvedTacticalOrder.displayName)",
                position: selectedUnit.position,
                sourceID: selectedUnit.resolvedTacticalOrder.rawValue
            )
        }

        return entries
    }

    var selectedUnitSituationReadout: SelectedUnitSituationReadout? {
        guard let selectedUnit else { return nil }

        let pressure = frontlinePressureSummaries.first { summary in
            summary.report.targetKind == .unit &&
                summary.report.targetID == selectedUnit.id
        }
        let threatHeat = threatHeatZoneOverlaysByPosition[selectedUnit.position] ??
            threatHeatZoneSummaries.first { summary in
                summary.report.positions.contains(selectedUnit.position)
            }
        let mapControl = state.mapControlReport(at: selectedUnit.position, for: .rome)
            .map { mapControlSummary(for: $0) }
        let formation = selectedLegionFormationSummary
        let recommendation = selectedTacticalRecommendationSummary
        let maneuver = primaryManeuverOptionSummary
        let synergy = selectedCommanderSynergySummary
        let countermeasurePreview = selectedCountermeasureCommandPreview
        let stagePreview = selectedBattleObjectiveStageCommandPreview
        let commanderGuidance = selectedCommanderActionGuidance
        let commandEntries = selectedUnitSituationCommandEntries(
            for: selectedUnit,
            countermeasurePreview: countermeasurePreview,
            stagePreview: stagePreview,
            commanderGuidance: commanderGuidance,
            maneuver: maneuver,
            recommendation: recommendation,
            tacticalOrderPreviews: selectedTacticalOrderPreviews
        )
        var signals: [SelectedUnitSituationSignal] = []

        if let pressure {
            signals.append(
                SelectedUnitSituationSignal(
                    kind: .pressure,
                    title: pressure.pressureLabel,
                    detail: "\(pressure.sourceLabel) · \(pressure.impactLabel)",
                    position: pressure.targetPosition,
                    sourceID: pressure.id
                )
            )
        }

        if let threatHeat {
            signals.append(
                SelectedUnitSituationSignal(
                    kind: .threatHeat,
                    title: threatHeat.levelLabel,
                    detail: "\(threatHeat.sourceLabel) · \(threatHeat.impactLabel)",
                    position: selectedUnit.position,
                    sourceID: threatHeat.id
                )
            )
        }

        if let mapControl {
            signals.append(
                SelectedUnitSituationSignal(
                    kind: .mapControl,
                    title: mapControl.compactTitle,
                    detail: mapControl.detail,
                    position: mapControl.position,
                    sourceID: mapControl.id
                )
            )
        }

        if let formation {
            signals.append(
                SelectedUnitSituationSignal(
                    kind: .formation,
                    title: formation.readinessLabel,
                    detail: formation.recommendationLabel,
                    position: selectedUnit.position,
                    sourceID: formation.id
                )
            )
        }

        if let recommendation {
            signals.append(
                SelectedUnitSituationSignal(
                    kind: .recommendation,
                    title: recommendation.kindLabel,
                    detail: recommendation.report.command,
                    position: recommendation.destination,
                    sourceID: recommendation.id
                )
            )
        }

        if let maneuver {
            signals.append(
                SelectedUnitSituationSignal(
                    kind: .maneuver,
                    title: maneuver.kindLabel,
                    detail: "\(maneuver.destinationLabel) · \(maneuver.impactLabel)",
                    position: maneuver.destination,
                    sourceID: maneuver.id
                )
            )
        }

        if let synergy {
            signals.append(
                SelectedUnitSituationSignal(
                    kind: .synergy,
                    title: synergy.kindLabel,
                    detail: "\(synergy.impactLabel) · \(synergy.statusLabel)",
                    position: synergy.targetPosition,
                    sourceID: synergy.id
                )
            )
        }

        if signals.isEmpty {
            signals.append(
                SelectedUnitSituationSignal(
                    kind: .formation,
                    title: "待命",
                    detail: "暂无本方处境信号",
                    position: selectedUnit.position,
                    sourceID: selectedUnit.id
                )
            )
        }

        let pressureLabel: String
        if let pressure {
            pressureLabel = "\(pressure.pressureLabel) · \(pressure.impactLabel)"
        } else if let threatHeat {
            pressureLabel = "\(threatHeat.levelLabel) · \(threatHeat.impactLabel)"
        } else {
            pressureLabel = formation?.supportLabel ?? "暂无直接压力"
        }

        let spaceLabel: String
        if let mapControl {
            spaceLabel = "\(mapControl.controlLabel) · \(mapControl.levelLabel) · \(mapControl.sourceLabel)"
        } else if let threatHeat {
            spaceLabel = "\(threatHeat.controlLabel) · \(threatHeat.sourceLabel)"
        } else {
            spaceLabel = "空间待确认"
        }

        let opportunityLabel = synergy?.impactLabel ??
            maneuver?.impactLabel ??
            recommendation?.kindLabel ??
            formation?.roleLabel ??
            "维持阵线"
        let nextStepLabel = recommendation?.report.command ??
            maneuver.map { "\($0.destinationLabel) · \($0.report.recommendedOrder.displayName)" } ??
            formation?.recommendationLabel ??
            "保持\(selectedUnit.resolvedTacticalOrder.displayName)"
        let riskLabel = recommendation?.riskLabel ??
            maneuver?.riskLabel ??
            synergy?.riskLabel ??
            pressure?.pressureLabel ??
            threatHeat?.levelLabel ??
            "低"
        let statusLabel = pressure?.pressureLabel ??
            threatHeat?.levelLabel ??
            mapControl?.levelLabel ??
            formation?.readinessLabel ??
            "待命"

        return SelectedUnitSituationReadout(
            unitID: selectedUnit.id,
            position: selectedUnit.position,
            title: "\(selectedUnit.kind.displayName)处境",
            statusLabel: statusLabel,
            pressureLabel: pressureLabel,
            spaceLabel: spaceLabel,
            opportunityLabel: opportunityLabel,
            nextStepLabel: nextStepLabel,
            riskLabel: riskLabel,
            signals: signals,
            commandEntries: commandEntries,
            pressureID: pressure?.id,
            threatHeatID: threatHeat?.id,
            mapControlID: mapControl?.id,
            formationID: formation?.id,
            recommendationID: recommendation?.id,
            maneuverID: maneuver?.id,
            synergyID: synergy?.id,
            countermeasurePreviewID: countermeasurePreview?.id,
            battleObjectiveStagePreviewID: stagePreview?.id,
            commanderActionID: commanderGuidance.map { _ in "\(selectedUnit.id)-commander-action" },
            tacticalOrderID: commandEntries.first { $0.kind == .tacticalOrder }?.sourceID
        )
    }

    var legionFormationSummaries: [LegionFormationSummary] {
        state.legionFormationReports(for: .rome, limit: 5)
            .map(legionFormationSummary(for:))
    }

    var primaryLegionFormationSummary: LegionFormationSummary? {
        legionFormationSummaries.first
    }

    var selectedLegionFormationSummary: LegionFormationSummary? {
        guard let selectedUnitID,
              let report = try? state.legionFormationReport(unitID: selectedUnitID) else {
            return nil
        }

        return legionFormationSummary(for: report)
    }

    var selectedUnitDevelopmentDecisionSummary: UnitDevelopmentDecisionSummary? {
        guard let selectedUnit else { return nil }
        return unitDevelopmentDecisionSummary(for: selectedUnit)
    }

    var unitDevelopmentRecommendationSummaries: [UnitDevelopmentRecommendationSummary] {
        state.unitDevelopmentRecommendationReports(for: .rome, limit: 6)
            .map(unitDevelopmentRecommendationSummary(for:))
    }

    var primaryUnitDevelopmentRecommendationSummary: UnitDevelopmentRecommendationSummary? {
        unitDevelopmentRecommendationSummaries.first
    }

    var selectedCommanderSynergySummary: CommanderSynergySummary? {
        guard let selectedUnitID,
              let report = try? state.commanderSynergyReport(unitID: selectedUnitID) else {
            return nil
        }

        return commanderSynergySummary(for: report)
    }

    var selectedManeuverOptionSummaries: [ManeuverOptionSummary] {
        guard let selectedUnitID,
              let reports = try? state.maneuverOptionReports(unitID: selectedUnitID, limit: 5) else {
            return []
        }

        return reports.map(maneuverOptionSummary(for:))
    }

    var primaryManeuverOptionSummary: ManeuverOptionSummary? {
        selectedManeuverOptionSummaries.first
    }

    var maneuverOptionOverlaysByPosition: [Position: ManeuverOptionSummary] {
        var values: [Position: ManeuverOptionSummary] = [:]
        for summary in selectedManeuverOptionSummaries {
            let current = values[summary.destination]
            if current == nil || summary.report.score > (current?.report.score ?? 0) {
                values[summary.destination] = summary
            }
        }
        return values
    }

    var maneuverOptionOverlayPositions: Set<Position> {
        Set(maneuverOptionOverlaysByPosition.keys)
    }

    var activeMapOverlayLegendItems: [MapOverlayLegendItem] {
        var items: [MapOverlayLegendItem] = []
        var insertedKinds = Set<MapOverlayLegendKind>()

        func append(
            _ kind: MapOverlayLegendKind,
            symbol: String,
            title: String,
            detail: String
        ) {
            guard insertedKinds.insert(kind).inserted else { return }
            items.append(
                MapOverlayLegendItem(
                    kind: kind,
                    symbol: symbol,
                    title: title,
                    detail: detail,
                    accessibilityLabel: "\(title)，\(detail)"
                )
            )
        }

        let intentOverlays = enemyIntentMapOverlays
        if intentOverlays.contains(where: { !$0.routeSegments.isEmpty }) {
            append(.enemyRoute, symbol: "arrow.right", title: "敌路", detail: "红线为敌军计划路线")
        }

        if !enemyIntentDestinationOverlays(for: intentOverlays).isEmpty ||
            !enemyIntentTargetOverlays(for: intentOverlays).isEmpty {
            append(.enemyTarget, symbol: "scope", title: "敌标", detail: "准星标出敌军目标")
        }

        if !enemyCommanderThreatOverlayPositions.isEmpty {
            append(
                MapOverlayLegendKind.enemyCommanderThreat,
                symbol: "crown.fill",
                title: "敌将威胁",
                detail: "徽标、范围和影响区来自敌将技能预演"
            )
        }

        if !threatHeatOverlayPositions.isEmpty {
            append(.threatHeat, symbol: "flame.fill", title: "热区", detail: "火焰提示高危威胁")
        }

        if !mapControlOverlayPositions.isEmpty {
            append(.mapControl, symbol: "shield.fill", title: "控区", detail: "底色显示争夺与控制")
        }

        if !selectedTacticalRecommendationPathPositions.isEmpty ||
            selectedTacticalRecommendationTargetPosition != nil {
            append(.tacticalPath, symbol: "arrow.turn.up.right", title: "军议", detail: "蓝线为本方建议路径")
        }

        if !maneuverOptionOverlayPositions.isEmpty {
            append(.maneuverOption, symbol: "figure.run", title: "机动", detail: "虚线点提示推荐落点")
        }

        if primaryBattleObjectiveMapOverlay != nil,
           !battleObjectiveOverlayPositions.isEmpty {
            append(.battleObjective, symbol: "point.topleft.down.curvedto.point.bottomright.up.fill", title: "目标线", detail: "金线串联焦点将令机动军议")
        }

        if primaryCountermeasureMapOverlay != nil,
           !countermeasureOverlayPositions.isEmpty {
            append(.countermeasure, symbol: "shield.lefthalf.filled", title: "反制", detail: "青线连接回应落点与目标")
        }

        if !reachablePositions.isEmpty {
            append(.reachable, symbol: "arrow.up.right.circle", title: "可达", detail: "黄圈为本回合可移动")
        }

        if !attackTargets.isEmpty {
            append(.attackTarget, symbol: "bolt.fill", title: "攻击", detail: "红环为可攻击目标")
        }

        if !selectedGeneralSkillRangePositions.isEmpty ||
            !selectedGeneralSkillTargetPositions.isEmpty ||
            !selectedGeneralSkillTargetUnitIDs.isEmpty ||
            !selectedGeneralSkillTargetCityIDs.isEmpty {
            append(.skillRange, symbol: "sparkles", title: "技能", detail: "紫光为将领技能范围")
        }

        return items
    }

    var selectedTacticalRecommendationSummary: TacticalRecommendationSummary? {
        guard let selectedUnitID,
              let report = try? state.tacticalRecommendation(unitID: selectedUnitID) else {
            return nil
        }

        return TacticalRecommendationSummary(
            report: report,
            unit: state.unit(withID: report.unitID),
            targetUnit: report.targetUnitID.flatMap { state.unit(withID: $0) },
            targetCity: report.targetCityID.flatMap { state.city(withID: $0) }
        )
    }

    var selectedTacticalRecommendationPathPositions: Set<Position> {
        guard let summary = selectedTacticalRecommendationSummary else { return [] }
        return Set(summary.report.path)
    }

    var selectedTacticalRecommendationTargetPosition: Position? {
        selectedTacticalRecommendationSummary?.targetPosition
    }

    private func legionFormationSummary(for report: LegionFormationReport) -> LegionFormationSummary {
        LegionFormationSummary(
            report: report,
            unit: state.unit(withID: report.unitID)
        )
    }

    private func unitDevelopmentDecisionSummary(for unit: ArmyUnit) -> UnitDevelopmentDecisionSummary {
        let trainingPreview = try? state.trainingPreview(unitID: unit.id)
        let appointmentPreview = try? state.generalAppointmentPreview(unitID: unit.id)
        let unitTitle = "\(unit.faction.displayName)\(unit.kind.displayName)"

        return UnitDevelopmentDecisionSummary(
            unitID: unit.id,
            unitTitle: unitTitle,
            trainingPreview: trainingPreview,
            appointmentPreview: appointmentPreview,
            trainingOption: trainingPreview.map(trainingDecisionOption(for:)),
            appointmentOption: appointmentPreview.map(appointmentDecisionOption(for:))
        )
    }

    private func unitDevelopmentRecommendationSummary(
        for report: UnitDevelopmentRecommendationReport
    ) -> UnitDevelopmentRecommendationSummary {
        let statusLabel: String
        if report.canExecute {
            statusLabel = "可执行"
        } else if report.blockedReason == GameRuleError.insufficientResources.displayMessage,
                  let shortageLabel = resourceShortageLabel(for: report.cost) {
            statusLabel = shortageLabel
        } else {
            statusLabel = report.blockedReason ?? "暂不可用"
        }

        return UnitDevelopmentRecommendationSummary(
            report: report,
            unit: state.unit(withID: report.unitID),
            statusLabel: statusLabel
        )
    }

    private func trainingDecisionOption(for preview: TrainingPreview) -> UnitDevelopmentDecisionOption {
        let costLabel = resourceLabel(preview.cost, signed: false, includeZero: false)
        let shortCostLabel = shortResourceLabel(preview.cost)
        let blockedReason = decisionBlockedReason(error: preview.blockingError, fallback: preview.blockedReason, cost: preview.cost)
        let statusLabel = preview.canTrain ? "可训练" : (blockedReason ?? "不可训练")
        let impactLabel = "\(preview.summary) · \(preview.detail)"
        let buttonDetail = preview.canTrain ? "\(preview.summary) · \(shortCostLabel)" : statusLabel
        let accessibilityParts = [
            "训练",
            "成本\(costLabel)",
            preview.summary,
            preview.detail,
            statusLabel
        ]

        return UnitDevelopmentDecisionOption(
            kind: .training,
            title: "训练",
            symbol: "figure.walk",
            costLabel: costLabel,
            shortCostLabel: shortCostLabel,
            impactLabel: impactLabel,
            statusLabel: statusLabel,
            buttonDetail: buttonDetail,
            canExecute: preview.canTrain,
            accessibilityLabel: accessibilityParts.joined(separator: "，")
        )
    }

    private func appointmentDecisionOption(for preview: GeneralAppointmentPreview) -> UnitDevelopmentDecisionOption {
        let costLabel = resourceLabel(preview.cost, signed: false, includeZero: false)
        let shortCostLabel = shortResourceLabel(preview.cost)
        let blockedReason = decisionBlockedReason(error: preview.blockingError, fallback: preview.blockedReason, cost: preview.cost)
        let statusLabel = preview.canAppoint ? "可任命" : (blockedReason ?? "不可任命")
        let candidateLabel: String
        if let candidateName = preview.candidateName,
           let trait = preview.candidateTrait {
            candidateLabel = "\(candidateName) · \(trait.displayName)"
        } else {
            candidateLabel = "暂无候选"
        }
        let impactLabel = "\(candidateLabel) · \(preview.detail)"
        let buttonDetail = preview.canAppoint ? "\(candidateLabel) · \(shortCostLabel)" : statusLabel
        let accessibilityParts = [
            "任命",
            "成本\(costLabel)",
            candidateLabel,
            preview.detail,
            statusLabel
        ]

        return UnitDevelopmentDecisionOption(
            kind: .appointment,
            title: "任命",
            symbol: "person.crop.circle.badge.plus",
            costLabel: costLabel,
            shortCostLabel: shortCostLabel,
            impactLabel: impactLabel,
            statusLabel: statusLabel,
            buttonDetail: buttonDetail,
            canExecute: preview.canAppoint,
            accessibilityLabel: accessibilityParts.joined(separator: "，")
        )
    }

    private func decisionBlockedReason(
        error: GameRuleError?,
        fallback: String?,
        cost: EmpireResources
    ) -> String? {
        if error == .insufficientResources,
           let shortageLabel = resourceShortageLabel(for: cost) {
            return shortageLabel
        }

        return fallback
    }

    private func battlefieldFocusSummary(for report: BattlefieldFocusReport) -> BattlefieldFocusSummary {
        BattlefieldFocusSummary(
            report: report,
            unit: report.unitID.flatMap { state.unit(withID: $0) },
            targetUnit: report.targetUnitID.flatMap { state.unit(withID: $0) },
            targetCity: report.targetCityID.flatMap { state.city(withID: $0) },
            relatedUnits: report.relatedUnitIDs.compactMap { state.unit(withID: $0) }
        )
    }

    private func commanderSynergySummary(for report: CommanderSynergyReport) -> CommanderSynergySummary {
        CommanderSynergySummary(
            report: report,
            unit: state.unit(withID: report.unitID),
            commanderUnit: report.commanderUnitID.flatMap { state.unit(withID: $0) },
            targetUnit: report.targetUnitID.flatMap { state.unit(withID: $0) },
            targetCity: report.targetCityID.flatMap { state.city(withID: $0) },
            supportingUnits: report.supportingUnitIDs.compactMap { state.unit(withID: $0) },
            beneficiaryUnits: report.beneficiaryUnitIDs.compactMap { state.unit(withID: $0) }
        )
    }

    private func maneuverOptionSummary(for report: ManeuverOptionReport) -> ManeuverOptionSummary {
        ManeuverOptionSummary(
            report: report,
            unit: state.unit(withID: report.unitID),
            targetUnit: report.targetUnitID.flatMap { state.unit(withID: $0) },
            targetCity: report.targetCityID.flatMap { state.city(withID: $0) }
        )
    }

    private func mapControlSummary(for report: MapControlReport) -> MapControlSummary {
        MapControlSummary(
            report: report,
            city: report.cityID.flatMap { state.city(withID: $0) },
            occupant: report.occupantUnitID.flatMap { state.unit(withID: $0) },
            friendlyUnits: report.friendlyUnitIDs.compactMap { state.unit(withID: $0) },
            enemyUnits: report.enemyUnitIDs.compactMap { state.unit(withID: $0) }
        )
    }

    private func threatHeatZoneSummary(for report: ThreatHeatZoneReport) -> ThreatHeatZoneSummary {
        ThreatHeatZoneSummary(
            report: report,
            sourceUnits: report.sourceUnitIDs.compactMap { state.unit(withID: $0) },
            cities: report.cityIDs.compactMap { state.city(withID: $0) }
        )
    }

    private func aiOperationalPlanSummary(for report: AIOperationalPlanReport) -> AIOperationalPlanSummary {
        let targetUnit = report.targetUnitID.flatMap { state.unit(withID: $0) }
        let targetCity = report.targetCityID.flatMap { state.city(withID: $0) }
        let sourceUnits = report.sourceUnitIDs.compactMap { state.unit(withID: $0) }
        let commanderUnits = report.commanderUnitIDs.compactMap { state.unit(withID: $0) }
        let timelineSteps = aiOperationalPlanTimelineSteps(
            for: report,
            targetUnit: targetUnit,
            targetCity: targetCity,
            sourceUnits: sourceUnits,
            commanderUnits: commanderUnits
        )

        return AIOperationalPlanSummary(
            report: report,
            targetUnit: targetUnit,
            targetCity: targetCity,
            sourceUnits: sourceUnits,
            commanderUnits: commanderUnits,
            timelineSteps: timelineSteps
        )
    }

    private func aiOperationalPlanTimelineSteps(
        for report: AIOperationalPlanReport,
        targetUnit: ArmyUnit?,
        targetCity: City?,
        sourceUnits: [ArmyUnit],
        commanderUnits: [ArmyUnit]
    ) -> [AIOperationalPlanTimelineStepReadout] {
        let lookupUnits = sourceUnits + commanderUnits + [targetUnit].compactMap { $0 }

        return report.steps.enumerated().map { index, step in
            let targetStepUnit: ArmyUnit?
            if let targetUnitID = step.targetUnitID {
                if let matchingUnit = lookupUnits.first(where: { $0.id == targetUnitID }) {
                    targetStepUnit = matchingUnit
                } else if let targetUnit, targetUnit.id == targetUnitID {
                    targetStepUnit = targetUnit
                } else {
                    targetStepUnit = nil
                }
            } else {
                targetStepUnit = nil
            }

            let targetStepCity: City?
            if let targetCityID = step.targetCityID,
               let targetCity,
               targetCity.id == targetCityID {
                targetStepCity = targetCity
            } else {
                targetStepCity = nil
            }

            return AIOperationalPlanTimelineStepReadout(
                sequence: index + 1,
                step: step,
                unit: lookupUnits.first { $0.id == step.unitID },
                targetUnit: targetStepUnit,
                targetCity: targetStepCity
            )
        }
    }

    private func enemyCommanderThreatSummary(for report: EnemyCommanderThreatReport) -> EnemyCommanderThreatSummary {
        EnemyCommanderThreatSummary(
            report: report,
            commanderUnit: state.unit(withID: report.unitID),
            targetUnit: report.targetUnitID.flatMap { state.unit(withID: $0) },
            targetCity: report.targetCityID.flatMap { state.city(withID: $0) },
            affectedUnits: report.affectedUnitIDs.compactMap { state.unit(withID: $0) },
            affectedCities: report.affectedCityIDs.compactMap { state.city(withID: $0) }
        )
    }

    private func countermeasureSummary(for report: CountermeasureReport) -> CountermeasureSummary {
        CountermeasureSummary(
            report: report,
            responseUnit: state.unit(withID: report.responseUnitID),
            targetUnit: report.targetUnitID.flatMap { state.unit(withID: $0) },
            targetCity: report.targetCityID.flatMap { state.city(withID: $0) }
        )
    }

    func countermeasureCommandPreview(for summary: CountermeasureSummary) -> CountermeasureCommandPreview {
        let responseUnit = state.unit(withID: summary.report.responseUnitID)
        let targetUnit = summary.report.targetUnitID.flatMap { state.unit(withID: $0) }
        let targetCity = summary.report.targetCityID.flatMap { state.city(withID: $0) }
        let recommendedOrder = summary.report.recommendedOrder
        let destination = summary.destination
        let targetPosition = summary.targetPosition
        var blockingReasons: [String] = []
        var steps: [CountermeasureCommandStep] = []

        guard let responseUnit else {
            return CountermeasureCommandPreview(
                summary: summary,
                responseUnit: nil,
                targetUnit: targetUnit,
                targetCity: targetCity,
                recommendedOrder: recommendedOrder,
                destination: destination,
                targetPosition: targetPosition,
                canFocus: false,
                canSetOrder: false,
                canMoveToDestination: false,
                canAttackCurrentTarget: false,
                isExecutableNow: false,
                blockingReasons: ["回应单位不存在"],
                steps: [
                    CountermeasureCommandStep(
                        id: "\(summary.id)-missing-unit",
                        symbol: "questionmark.circle.fill",
                        title: "回应",
                        detail: "回应单位不存在",
                        isReady: false
                    )
                ]
            )
        }

        if isCampaignOver {
            blockingReasons.append("战役已结束")
        }

        if responseUnit.faction != .rome {
            blockingReasons.append("回应单位不属罗马")
        }

        if responseUnit.faction != state.activeFaction {
            blockingReasons.append("非当前阵营")
        }

        let orderBlockedReason = tacticalOrderBlockedReason(recommendedOrder, for: responseUnit)
        let orderReady = orderBlockedReason == nil || orderBlockedReason == "当前姿态"
        let canSetOrder = orderBlockedReason == nil && responseUnit.resolvedTacticalOrder != recommendedOrder
        if let orderBlockedReason,
           orderBlockedReason != "当前姿态" {
            blockingReasons.append(orderBlockedReason)
        }
        steps.append(
            CountermeasureCommandStep(
                id: "\(summary.id)-order",
                symbol: tacticalOrderCommandSymbol(recommendedOrder),
                title: "姿态",
                detail: orderBlockedReason == "当前姿态" ? "已是\(recommendedOrder.displayName)" : "建议\(recommendedOrder.displayName)",
                isReady: orderReady
            )
        )

        let reachable = state.reachablePositions(for: responseUnit.id)
        let isAtDestination = responseUnit.position == destination
        let canMoveToDestination = isAtDestination || reachable.contains(destination)
        if !canMoveToDestination {
            blockingReasons.append(responseUnit.hasMoved ? "已移动，无法抵达落点" : "落点暂不可达")
        }
        steps.append(
            CountermeasureCommandStep(
                id: "\(summary.id)-destination",
                symbol: isAtDestination ? "location.fill" : "arrow.up.right.circle.fill",
                title: "落点",
                detail: isAtDestination ? "已在 \(destination.description)" : (canMoveToDestination ? "可达 \(destination.description)" : "不可达 \(destination.description)"),
                isReady: canMoveToDestination
            )
        )

        let attackableTargets = state.attackTargets(for: responseUnit.id)
        let canAttackCurrentTarget = targetUnit.map { target in
            attackableTargets.contains { $0.id == target.id }
        } ?? false
        let targetDetail: String
        if let targetUnit {
            targetDetail = canAttackCurrentTarget ? "可直接攻击 \(targetUnit.kind.displayName)" : "距目标 \(responseUnit.position.hexDistance(to: targetUnit.position))"
        } else if let targetCity {
            targetDetail = "目标 \(targetCity.name)"
        } else {
            targetDetail = "目标 \(targetPosition.description)"
        }
        steps.append(
            CountermeasureCommandStep(
                id: "\(summary.id)-target",
                symbol: canAttackCurrentTarget ? "bolt.fill" : "scope",
                title: "目标",
                detail: targetDetail,
                isReady: canAttackCurrentTarget || targetUnit == nil
            )
        )

        let canFocus = responseUnit.faction == .rome
        let canAdvanceNow = canSetOrder || (!isAtDestination && canMoveToDestination) || canAttackCurrentTarget
        let isExecutableNow = canFocus &&
            blockingReasons.isEmpty &&
            canAdvanceNow

        return CountermeasureCommandPreview(
            summary: summary,
            responseUnit: responseUnit,
            targetUnit: targetUnit,
            targetCity: targetCity,
            recommendedOrder: recommendedOrder,
            destination: destination,
            targetPosition: targetPosition,
            canFocus: canFocus,
            canSetOrder: canSetOrder,
            canMoveToDestination: canMoveToDestination,
            canAttackCurrentTarget: canAttackCurrentTarget,
            isExecutableNow: isExecutableNow,
            blockingReasons: blockingReasons,
            steps: steps
        )
    }

    private func battleObjectiveStageCommandPreview(for overlay: BattleObjectivePositionOverlay) -> BattleObjectiveStageCommandPreview? {
        let chain = overlay.chain
        let commandUnit = battleObjectiveFocusUnit(for: overlay)
        let sourceSummaryID: String
        let targetUnit: ArmyUnit?
        let targetCity: City?
        let recommendedOrder: TacticalOrder?
        let destination: Position?
        let targetPosition: Position
        let commandEntryLabel: String
        let sourceStatusLabel: String

        switch overlay.role {
        case .focus:
            sourceSummaryID = chain.focus.id
            targetUnit = chain.focus.targetUnit
            targetCity = chain.focus.targetCity
            recommendedOrder = chain.focus.report.recommendedOrder
            destination = chain.focus.targetPosition
            targetPosition = chain.focus.targetPosition
            commandEntryLabel = "定位焦点"
            sourceStatusLabel = "\(chain.focus.kindLabel) · \(chain.focus.severityLabel)"
        case .synergy:
            guard let synergy = chain.synergy else { return nil }
            sourceSummaryID = synergy.id
            targetUnit = synergy.targetUnit
            targetCity = synergy.targetCity
            recommendedOrder = synergy.report.recommendedOrder
            destination = commandUnit?.position
            targetPosition = synergy.targetPosition
            commandEntryLabel = synergy.kind == .commanderSkill ? "将领技能" : "将令协同"
            sourceStatusLabel = synergy.statusLabel
        case .maneuver:
            guard let maneuver = chain.maneuver else { return nil }
            sourceSummaryID = maneuver.id
            targetUnit = maneuver.targetUnit
            targetCity = maneuver.targetCity
            recommendedOrder = maneuver.report.recommendedOrder
            destination = maneuver.destination
            targetPosition = maneuver.targetPosition
            commandEntryLabel = "移动落点"
            sourceStatusLabel = maneuver.report.isExecutable ? "可机动" : (maneuver.report.blockedReason ?? maneuver.riskLabel)
        case .recommendation:
            guard let recommendation = chain.recommendation else { return nil }
            sourceSummaryID = recommendation.id
            targetUnit = recommendation.targetUnit
            targetCity = recommendation.targetCity
            recommendedOrder = recommendation.report.recommendedOrder
            destination = recommendation.destination
            targetPosition = recommendation.targetPosition
            commandEntryLabel = "军令执行"
            sourceStatusLabel = recommendation.riskLabel
        }

        var blockingReasons: [String] = []
        var steps: [BattleObjectiveStageCommandStep] = []

        if isCampaignOver {
            blockingReasons.append("战役已结束")
        }

        guard let commandUnit else {
            return BattleObjectiveStageCommandPreview(
                chain: chain,
                role: overlay.role,
                position: overlay.position,
                sourceSummaryID: sourceSummaryID,
                commandUnit: nil,
                targetUnit: targetUnit,
                targetCity: targetCity,
                recommendedOrder: recommendedOrder,
                destination: destination,
                targetPosition: targetPosition,
                commandEntryLabel: commandEntryLabel,
                canFocus: false,
                canSetOrder: false,
                canMoveToDestination: false,
                canAttackCurrentTarget: false,
                canUseGeneralSkill: false,
                isExecutableNow: false,
                blockingReasons: ["无罗马执行单位"],
                steps: [
                    BattleObjectiveStageCommandStep(
                        id: "\(chain.id)-\(overlay.role.rawValue)-missing-unit",
                        symbol: "questionmark.circle.fill",
                        title: overlay.role.displayName,
                        detail: "阶段仅可定位观察",
                        isReady: false
                    )
                ]
            )
        }

        if commandUnit.faction != .rome {
            blockingReasons.append("执行单位不属罗马")
        }

        if commandUnit.faction != state.activeFaction {
            blockingReasons.append("非当前阵营")
        }

        steps.append(
            BattleObjectiveStageCommandStep(
                id: "\(chain.id)-\(overlay.role.rawValue)-entry",
                symbol: "target",
                title: "入口",
                detail: "\(commandEntryLabel) · \(sourceStatusLabel)",
                isReady: commandUnit.faction == .rome
            )
        )

        let canSetOrder: Bool
        if let recommendedOrder {
            let orderBlockedReason = tacticalOrderBlockedReason(recommendedOrder, for: commandUnit)
            let orderReady = orderBlockedReason == nil || orderBlockedReason == "当前姿态"
            canSetOrder = orderBlockedReason == nil && commandUnit.resolvedTacticalOrder != recommendedOrder
            if let orderBlockedReason,
               orderBlockedReason != "当前姿态" {
                blockingReasons.append(orderBlockedReason)
            }
            steps.append(
                BattleObjectiveStageCommandStep(
                    id: "\(chain.id)-\(overlay.role.rawValue)-order",
                    symbol: tacticalOrderCommandSymbol(recommendedOrder),
                    title: "姿态",
                    detail: orderBlockedReason == "当前姿态" ? "已是\(recommendedOrder.displayName)" : "建议\(recommendedOrder.displayName)",
                    isReady: orderReady
                )
            )
        } else {
            canSetOrder = false
        }

        let canMoveToDestination: Bool
        if let destination {
            let isAtDestination = commandUnit.position == destination
            let reachable = state.reachablePositions(for: commandUnit.id)
            canMoveToDestination = isAtDestination || reachable.contains(destination)
            if !canMoveToDestination,
               overlay.role == .maneuver || overlay.role == .recommendation {
                blockingReasons.append(commandUnit.hasMoved ? "已移动，无法抵达落点" : "落点暂不可达")
            }
            steps.append(
                BattleObjectiveStageCommandStep(
                    id: "\(chain.id)-\(overlay.role.rawValue)-destination",
                    symbol: isAtDestination ? "location.fill" : "arrow.up.right.circle.fill",
                    title: "落点",
                    detail: isAtDestination ? "已在\(destination.description)" : (canMoveToDestination ? "可达\(destination.description)" : "不可达\(destination.description)"),
                    isReady: canMoveToDestination
                )
            )
        } else {
            canMoveToDestination = false
        }

        let attackableTargets = state.attackTargets(for: commandUnit.id)
        let canAttackCurrentTarget = targetUnit.map { target in
            attackableTargets.contains { $0.id == target.id }
        } ?? false
        let targetDetail: String
        if let targetUnit {
            targetDetail = canAttackCurrentTarget ? "可攻击\(targetUnit.kind.displayName)" : "距目标\(commandUnit.position.hexDistance(to: targetUnit.position))"
        } else if let targetCity {
            targetDetail = "目标\(targetCity.name)"
        } else {
            targetDetail = "目标\(targetPosition.description)"
        }
        steps.append(
            BattleObjectiveStageCommandStep(
                id: "\(chain.id)-\(overlay.role.rawValue)-target",
                symbol: canAttackCurrentTarget ? "bolt.fill" : "scope",
                title: "目标",
                detail: targetDetail,
                isReady: canAttackCurrentTarget || targetUnit == nil
            )
        )

        let skillPreview = try? state.generalSkillPreview(unitID: commandUnit.id)
        let canUseGeneralSkill = overlay.role == .synergy && (skillPreview?.isExecutable ?? false)
        if overlay.role == .synergy {
            steps.append(
                BattleObjectiveStageCommandStep(
                    id: "\(chain.id)-\(overlay.role.rawValue)-skill",
                    symbol: canUseGeneralSkill ? "sparkles" : "hourglass",
                    title: "技能",
                    detail: skillPreview.map { preview in
                        preview.isExecutable ? "\(preview.trait.skillName)可用" : (preview.blockedReason ?? preview.cooldownText)
                    } ?? "无主动技能",
                    isReady: canUseGeneralSkill
                )
            )
        }

        let canFocus = commandUnit.faction == .rome
        let shouldMove = destination.map { $0 != commandUnit.position } ?? false
        let canAdvanceNow = canSetOrder ||
            (shouldMove && canMoveToDestination) ||
            canAttackCurrentTarget ||
            canUseGeneralSkill
        let isExecutableNow = canFocus &&
            blockingReasons.isEmpty &&
            canAdvanceNow

        return BattleObjectiveStageCommandPreview(
            chain: chain,
            role: overlay.role,
            position: overlay.position,
            sourceSummaryID: sourceSummaryID,
            commandUnit: commandUnit,
            targetUnit: targetUnit,
            targetCity: targetCity,
            recommendedOrder: recommendedOrder,
            destination: destination,
            targetPosition: targetPosition,
            commandEntryLabel: commandEntryLabel,
            canFocus: canFocus,
            canSetOrder: canSetOrder,
            canMoveToDestination: canMoveToDestination,
            canAttackCurrentTarget: canAttackCurrentTarget,
            canUseGeneralSkill: canUseGeneralSkill,
            isExecutableNow: isExecutableNow,
            blockingReasons: blockingReasons,
            steps: steps
        )
    }

    func enemyIntentSummary(for unitID: String) -> EnemyIntentSummary? {
        enemyIntentSummaries.first { $0.unit.id == unitID }
    }

    var enemyIntentMapOverlays: [EnemyIntentMapOverlay] {
        enemyIntentMapOverlays(for: enemyIntentSummaries)
    }

    func enemyIntentMapOverlays(for summaries: [EnemyIntentSummary]) -> [EnemyIntentMapOverlay] {
        summaries.prefix(4).map { summary in
            EnemyIntentMapOverlay(
                summary: summary,
                routeSegments: enemyIntentRouteSegments(for: summary)
            )
        }
    }

    private func enemyIntentRouteSegments(for summary: EnemyIntentSummary) -> [EnemyIntentRouteSegment] {
        var segments = enemyIntentMovementRouteSegments(for: summary)

        if let targetPosition = summary.targetPosition,
           targetPosition != summary.destinationPosition {
            segments.append(
                EnemyIntentRouteSegment(
                    id: "\(summary.id)-target",
                    from: summary.destinationPosition,
                    to: targetPosition,
                    kind: summary.intent.kind,
                    isTargetLeg: true,
                    isHighThreat: summary.isHighThreat
                )
            )
        }

        return segments
    }

    private func enemyIntentMovementRouteSegments(for summary: EnemyIntentSummary) -> [EnemyIntentRouteSegment] {
        let origin = summary.originPosition
        let destination = summary.destinationPosition
        guard origin != destination else { return [] }

        guard let path = enemyIntentMovementPath(for: summary),
              path.count >= 2 else {
            return [
                EnemyIntentRouteSegment(
                    id: "\(summary.id)-move",
                    from: origin,
                    to: destination,
                    kind: summary.intent.kind,
                    isTargetLeg: false,
                    isHighThreat: summary.isHighThreat
                )
            ]
        }

        return zip(path, path.dropFirst()).enumerated().map { index, pair in
            EnemyIntentRouteSegment(
                id: "\(summary.id)-route-\(index)",
                from: pair.0,
                to: pair.1,
                kind: summary.intent.kind,
                isTargetLeg: false,
                isHighThreat: summary.isHighThreat
            )
        }
    }

    private func enemyIntentMovementPath(for summary: EnemyIntentSummary) -> [Position]? {
        let origin = summary.originPosition
        let destination = summary.destinationPosition
        guard origin != destination else { return [origin] }

        var planningUnit = summary.unit
        planningUnit.tacticalOrder = summary.intent.tacticalOrder == .balanced ? nil : summary.intent.tacticalOrder

        let movementLimit = state.effectiveMovement(for: planningUnit)
        var bestCost: [Position: Int] = [origin: 0]
        var previous: [Position: Position] = [:]
        var frontier = [origin]

        while !frontier.isEmpty {
            let currentIndex = frontier.indices.min { leftIndex, rightIndex in
                let left = frontier[leftIndex]
                let right = frontier[rightIndex]
                let leftCost = bestCost[left] ?? Int.max
                let rightCost = bestCost[right] ?? Int.max
                if leftCost != rightCost { return leftCost < rightCost }

                let leftDistance = left.hexDistance(to: destination)
                let rightDistance = right.hexDistance(to: destination)
                if leftDistance != rightDistance { return leftDistance < rightDistance }

                if left.y != right.y { return left.y < right.y }
                return left.x < right.x
            } ?? frontier.startIndex
            let current = frontier.remove(at: currentIndex)
            if current == destination {
                return reconstructEnemyIntentPath(to: destination, from: previous, origin: origin)
            }

            let currentCost = bestCost[current] ?? 0
            for neighbor in current.neighbors(width: state.width, height: state.height) {
                guard let tile = state.tile(at: neighbor),
                      planningUnit.kind.canEnter(tile.terrain),
                      state.unit(at: neighbor).map({ $0.id == planningUnit.id }) ?? true else {
                    continue
                }

                let nextCost = currentCost + tile.terrain.movementCost
                guard nextCost <= movementLimit else { continue }

                if nextCost < (bestCost[neighbor] ?? Int.max) {
                    bestCost[neighbor] = nextCost
                    previous[neighbor] = current
                    if !frontier.contains(neighbor) {
                        frontier.append(neighbor)
                    }
                }
            }
        }

        return nil
    }

    private func reconstructEnemyIntentPath(
        to destination: Position,
        from previous: [Position: Position],
        origin: Position
    ) -> [Position]? {
        var path = [destination]
        var current = destination

        while current != origin {
            guard let step = previous[current] else { return nil }
            current = step
            path.append(current)
        }

        return path.reversed()
    }

    func enemyIntentDestinationOverlays(for overlays: [EnemyIntentMapOverlay]) -> [Position: EnemyIntentMapOverlay] {
        overlays.reduce(into: [Position: EnemyIntentMapOverlay]()) { result, overlay in
            guard overlay.showsDestinationMarker else { return }
            if result[overlay.destinationPosition] == nil {
                result[overlay.destinationPosition] = overlay
            }
        }
    }

    func enemyIntentTargetOverlays(for overlays: [EnemyIntentMapOverlay]) -> [Position: EnemyIntentMapOverlay] {
        overlays.reduce(into: [Position: EnemyIntentMapOverlay]()) { result, overlay in
            guard let targetPosition = overlay.targetPosition else { return }
            if result[targetPosition] == nil {
                result[targetPosition] = overlay
            }
        }
    }

    private func cityBrief(for city: City) -> SelectedCityBrief {
        let developmentPreview = try? state.cityDevelopmentPreview(id: city.id)
        let recruitmentOptions = UnitKind.allCases.map { kind in
            cityRecruitmentOptionPreview(for: kind, at: city)
        }
        let productionLabel = resourceLabel(city.production, signed: true, includeZero: true)
        let ownerIncomeLabel = "\(city.owner.displayName)收入 \(resourceLabel(state.income(for: city.owner), signed: true, includeZero: false))"
        let romanResourceLabel = "罗马库存 \(resourceLabel(romanResources, signed: false, includeZero: false))"
        let developmentCostLabel = developmentPreview.map { resourceLabel($0.cost, signed: false, includeZero: false) } ?? "无"
        let developmentGainLabel = developmentPreview.map { preview in
            "\(resourceLabel(preview.productionIncrease, signed: true, includeZero: false)) · 城防 +\(preview.fortificationIncrease)"
        } ?? "无"
        let developmentStatusLabel = developmentPreview.map { preview in
            preview.canDevelop ? "扩建后城防 \(preview.projectedFortification)" : (preview.blockedReason ?? "不可扩建")
        } ?? "不可扩建"
        let deploymentSummary = cityDeploymentSummary(for: city, recruitmentOptions: recruitmentOptions)
        let availableRecruitmentCount = recruitmentOptions.filter { $0.canRecruit }.count
        let accessibilityParts = [
            city.name,
            city.owner.displayName,
            "位置\(city.position)",
            "城防\(city.fortification)",
            "本城产出\(productionLabel)",
            ownerIncomeLabel,
            deploymentSummary,
            "可招募\(availableRecruitmentCount)项"
        ]

        return SelectedCityBrief(
            cityID: city.id,
            title: city.name,
            ownerLabel: city.owner.displayName,
            positionLabel: "坐标 \(city.position.x),\(city.position.y)",
            fortificationLabel: "城防 \(city.fortification)",
            productionLabel: productionLabel,
            ownerIncomeLabel: ownerIncomeLabel,
            romanResourceLabel: romanResourceLabel,
            deploymentSummary: deploymentSummary,
            developmentPreview: developmentPreview,
            developmentCostLabel: developmentCostLabel,
            developmentGainLabel: developmentGainLabel,
            developmentStatusLabel: developmentStatusLabel,
            canDevelop: developmentPreview?.canDevelop ?? false,
            recruitmentOptions: recruitmentOptions,
            availableRecruitmentCount: availableRecruitmentCount,
            accessibilityLabel: accessibilityParts.joined(separator: "，")
        )
    }

    private func cityRecruitmentOptionPreview(for kind: UnitKind, at city: City) -> CityRecruitmentOptionPreview {
        let corePreview = try? state.recruitmentPreview(kind, at: city.id)
        let cost = corePreview?.cost ?? kind.recruitmentCost
        let shortageLabel = resourceShortageLabel(for: cost)
        let blockedReason: String?
        if corePreview?.blockingError == .insufficientResources, let shortageLabel {
            blockedReason = shortageLabel
        } else {
            blockedReason = corePreview?.blockedReason
        }
        let deploymentLabel = corePreview?.deploymentPosition.map { "部署 \($0)" } ?? (blockedReason ?? "不可部署")
        let shortStatusLabel = corePreview?.canRecruit == true ? "可征召" : (blockedReason ?? "受阻")
        let statsLabel = "攻 \(kind.attack) · 防 \(kind.defense) · 移 \(kind.movement) · 射 \(kind.range) · 兵 \(kind.maxHealth)"
        let costLabel = resourceLabel(cost, signed: false, includeZero: false)
        let accessibilityParts = [
            kind.displayName,
            statsLabel,
            "成本\(costLabel)",
            deploymentLabel,
            shortStatusLabel
        ]

        return CityRecruitmentOptionPreview(
            kind: kind,
            statsLabel: statsLabel,
            costLabel: costLabel,
            shortCostLabel: shortResourceLabel(cost),
            deploymentLabel: deploymentLabel,
            shortStatusLabel: shortStatusLabel,
            canRecruit: corePreview?.canRecruit ?? false,
            blockedReason: blockedReason,
            accessibilityLabel: accessibilityParts.joined(separator: "，")
        )
    }

    private func cityDeploymentSummary(
        for city: City,
        recruitmentOptions: [CityRecruitmentOptionPreview]
    ) -> String {
        let cityOccupant = state.unit(at: city.position).map { "\($0.faction.displayName)\($0.kind.displayName)" } ?? "空闲"
        let neighbors = city.position.neighbors(width: state.width, height: state.height)
        let openLandNeighbors = neighbors.filter { position in
            guard let tile = state.tile(at: position) else { return false }
            return tile.terrain != .water && state.unit(at: position) == nil
        }.count
        let openHarbors = neighbors.filter { position in
            state.tile(at: position)?.terrain == .water && state.unit(at: position) == nil
        }.count
        let canRecruitCount = recruitmentOptions.filter { $0.canRecruit }.count

        return "城内\(cityOccupant) · 陆军邻格 \(openLandNeighbors) · 港口 \(openHarbors) · 可招募 \(canRecruitCount)"
    }

    private func resourceLabel(
        _ resources: EmpireResources,
        signed: Bool,
        includeZero: Bool
    ) -> String {
        let values = resourcePairs(resources)
            .filter { includeZero || $0.value != 0 }
            .map { pair in
                let value = signed ? signedValue(pair.value) : "\(pair.value)"
                return "\(pair.label) \(value)"
            }

        return values.isEmpty ? "0" : values.joined(separator: " · ")
    }

    private func shortResourceLabel(_ resources: EmpireResources) -> String {
        let values = resourcePairs(resources)
            .filter { $0.value != 0 }
            .prefix(2)
            .map { "\($0.label)\($0.value)" }

        return values.isEmpty ? "0" : values.joined(separator: " ")
    }

    private func resourceShortageLabel(for cost: EmpireResources) -> String? {
        let pool = state.resources[state.activeFaction] ?? .zero
        let shortages = [
            ("金", max(0, cost.gold - pool.gold)),
            ("粮", max(0, cost.grain - pool.grain)),
            ("铁", max(0, cost.iron - pool.iron)),
            ("科", max(0, cost.science - pool.science)),
            ("威", max(0, cost.prestige - pool.prestige))
        ]
        .filter { $0.1 > 0 }
        .map { "缺\($0.0) \($0.1)" }

        return shortages.isEmpty ? nil : shortages.joined(separator: " · ")
    }

    private func resourcePairs(_ resources: EmpireResources) -> [(label: String, value: Int)] {
        [
            ("金", resources.gold),
            ("粮", resources.grain),
            ("铁", resources.iron),
            ("科", resources.science),
            ("威", resources.prestige)
        ]
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
        guard !isCampaignOver else { return [] }
        guard let selectedUnitID = selectedUnitID else { return [] }
        return state.reachablePositions(for: selectedUnitID)
    }

    var attackTargets: [ArmyUnit] {
        guard !isCampaignOver else { return [] }
        guard let selectedUnitID = selectedUnitID else { return [] }
        return state.attackTargets(for: selectedUnitID)
    }

    var selectedCombatForecast: SelectedCombatForecast? {
        guard let selectedUnit,
              selectedUnit.faction == state.activeFaction,
              let selectedAttackTargetID,
              let defender = attackTargets.first(where: { $0.id == selectedAttackTargetID }),
              let preview = attackPreview(for: defender.id) else {
            return nil
        }

        return SelectedCombatForecast(
            attacker: selectedUnit,
            defender: defender,
            preview: preview
        )
    }

    func isSelectedAttackTarget(_ defenderID: String) -> Bool {
        selectedCombatForecast?.defender.id == defenderID
    }

    func attackTargetAccessibilityLabel(for target: ArmyUnit) -> String {
        let targetLabel = SelectedCombatForecast.identityLabel(for: target)
        let locationLabel = "位置\(target.position.description)，生命\(target.health)/\(target.kind.maxHealth)"
        let lockLabel = isSelectedAttackTarget(target.id) ? "已锁定" : "锁定"
        if let forecast = selectedCombatForecast,
           forecast.defender.id == target.id {
            return "已锁定，\(forecast.accessibilityLabel)，再次点击可取消锁定"
        }
        guard let preview = attackPreview(for: target.id) else {
            let attackerLabel = selectedUnit.map { SelectedCombatForecast.identityLabel(for: $0) } ?? "当前军团"
            return "\(lockLabel)\(targetLabel)，攻击者\(attackerLabel)，\(locationLabel)"
        }

        let result = preview.defeatsDefender ? "可歼灭" : (preview.attackerFalls ? "高风险" : "可攻击")
        let attackerLabel = selectedUnit.map { SelectedCombatForecast.identityLabel(for: $0) } ?? "当前军团"
        return "\(lockLabel)攻击者\(attackerLabel)对防守者\(targetLabel)，\(locationLabel)，伤害 \(preview.damage)，反击 \(preview.retaliation)，\(result)"
    }

    func attackPreview(for defenderID: String) -> CombatPreview? {
        guard let selectedUnitID = selectedUnitID else { return nil }
        return try? state.attackPreview(attackerID: selectedUnitID, defenderID: defenderID)
    }

    var selectedGeneralSkillPreview: GeneralSkillPreview? {
        guard let selectedUnitID = selectedUnitID else { return nil }
        return try? state.generalSkillPreview(unitID: selectedUnitID)
    }

    var selectedWarMeritStatus: WarMeritStatus? {
        guard let selectedUnit else { return nil }
        return state.warMeritStatus(for: selectedUnit)
    }

    var selectedGeneralSkillRangePositions: Set<Position> {
        Set(selectedGeneralSkillPreview?.rangePositions ?? [])
    }

    var selectedGeneralSkillTargetPositions: Set<Position> {
        Set(selectedGeneralSkillPreview?.affectedPositions ?? [])
    }

    var selectedGeneralSkillTargetUnitIDs: Set<String> {
        Set(selectedGeneralSkillPreview?.affectedUnitIDs ?? [])
    }

    var selectedGeneralSkillTargetCityIDs: Set<String> {
        Set(selectedGeneralSkillPreview?.affectedCityIDs ?? [])
    }

    var selectedGeneralSkillTargetReadout: SelectedGeneralSkillTargetReadout? {
        guard let preview = selectedGeneralSkillPreview else { return nil }

        let unitTargets = preview.affectedUnitIDs.compactMap { unitID -> GeneralSkillTargetReadoutTarget? in
            guard let unit = state.unit(withID: unitID) else { return nil }
            let effect = preview.projectedRecoveredHealth > 0 ? "恢复 \(preview.trait.recoveryAmount)" : preview.summary
            let title = "\(unit.faction.displayName)\(unit.kind.displayName)"
            let subtitle = "\(unit.position.description) · 生命 \(unit.health)/\(unit.kind.maxHealth)"
            return GeneralSkillTargetReadoutTarget(
                id: "unit-\(unit.id)",
                title: title,
                subtitle: subtitle,
                position: unit.position,
                effectLabel: effect,
                accessibilityLabel: "\(title)，\(subtitle)，\(effect)"
            )
        }
        let cityTargets = preview.affectedCityIDs.compactMap { cityID -> GeneralSkillTargetReadoutTarget? in
            guard let city = state.city(withID: cityID) else { return nil }
            let effect = preview.projectedFortificationReduction > 0 ? "城防 -\(preview.trait.fortificationReductionAmount)" : preview.summary
            let title = city.name
            let subtitle = "\(city.position.description) · \(city.owner.displayName)"
            return GeneralSkillTargetReadoutTarget(
                id: "city-\(city.id)",
                title: title,
                subtitle: subtitle,
                position: city.position,
                effectLabel: effect,
                accessibilityLabel: "\(title)，\(subtitle)，\(effect)"
            )
        }
        let targets = unitTargets + cityTargets
        let totalTargetCount = preview.affectedUnitIDs.count + preview.affectedCityIDs.count
        let targetKindLabel = preview.trait == .siegeEngineer ? "敌城" : "友军"
        let targetCountLabel = totalTargetCount > 0 ? "目标 \(totalTargetCount) \(targetKindLabel)" : "暂无目标 · 0"
        let effectLabel: String
        if preview.projectedFortificationReduction > 0 {
            effectLabel = "削城防 \(preview.projectedFortificationReduction)"
        } else if preview.projectedRecoveredHealth > 0 {
            effectLabel = "恢复 \(preview.projectedRecoveredHealth)"
        } else {
            effectLabel = preview.summary
        }
        let visibleTargetLabels = targets.prefix(3).map(\.title)
        let hiddenCount = max(0, totalTargetCount - visibleTargetLabels.count)
        let targetLabels = hiddenCount > 0 ? visibleTargetLabels + ["等 \(hiddenCount) 个"] : visibleTargetLabels
        let mapCueLabel = preview.affectedPositions.isEmpty ? "地图暂无目标标记" : "地图紫标 \(preview.affectedPositions.count) 处"
        let statusLabel = preview.blockedReason ?? (preview.isExecutable ? "可发动" : preview.summary)
        let accessibilityLabel = [
            preview.trait.skillName,
            targetCountLabel,
            effectLabel,
            mapCueLabel,
            statusLabel,
            selectedCommanderActionGuidance?.stageCueLabel,
            targets.map(\.accessibilityLabel).joined(separator: "，")
        ].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "，")

        return SelectedGeneralSkillTargetReadout(
            title: "\(preview.trait.skillName)目标",
            effectLabel: effectLabel,
            targetCountLabel: targetCountLabel,
            targetLabels: targetLabels,
            mapCueLabel: mapCueLabel,
            statusLabel: statusLabel,
            targets: targets,
            accessibilityLabel: accessibilityLabel
        )
    }

    var selectedGeneralSkillButtonDetail: String? {
        guard let preview = selectedGeneralSkillPreview else { return nil }
        if preview.cooldownRemaining > 0 {
            return preview.cooldownText
        }

        return preview.blockedReason ?? "\(preview.summary) · \(preview.cooldownText)"
    }

    var selectedGeneralSkillCommandButtonDetail: String? {
        let detail = [
            selectedCommanderActionGuidance?.buttonDetailPrefix,
            selectedGeneralSkillButtonDetail
        ].compactMap { $0 }.joined(separator: " · ")
        return detail.isEmpty ? nil : detail
    }

    var selectedGeneralSkillCooldownDetail: String? {
        selectedGeneralSkillPreview?.cooldownText
    }

    var selectedCommanderActionGuidance: CommanderActionGuidance? {
        guard let selectedUnit,
              selectedUnit.resolvedGeneralTrait != nil,
              let brief = selectedCommanderBrief,
              let skillPreview = selectedGeneralSkillPreview else {
            return nil
        }

        let synergySummary = selectedCommanderSynergySummary
        let stagePreview = selectedBattleObjectiveStageCommandPreview
        let isLinkedStage = stagePreview?.role == .synergy &&
            stagePreview?.isCommandUnit(selectedUnit) == true
        let stageCueLabel = isLinkedStage ? stagePreview?.skillStageCueLabel : nil
        let skillCueLabel = stageCueLabel ??
            (synergySummary?.kind == .commanderSkill ? "将令 · \(synergySummary?.statusLabel ?? brief.skillStatusLabel)" : brief.skillStatusLabel)
        let buttonDetailPrefix = stageCueLabel ??
            (synergySummary?.kind == .commanderSkill ? "将令 · \(brief.skillStatusLabel)" : nil)
        let statusLabel = skillPreview.isExecutable ? "技能入口就绪" : (skillPreview.blockedReason ?? brief.skillStatusLabel)
        let title = synergySummary.map { "将令行动 · \($0.targetLabel)" } ?? "将领行动"
        let accessibilityLabel = [
            title,
            stageCueLabel,
            "技能\(brief.skillName ?? "无主动技能")",
            skillCueLabel,
            "状态\(statusLabel)",
            synergySummary.map { "目标\($0.targetLabel)" }
        ].compactMap { $0 }.joined(separator: "，")

        return CommanderActionGuidance(
            title: title,
            stageCueLabel: stageCueLabel,
            skillCueLabel: skillCueLabel,
            buttonDetailPrefix: buttonDetailPrefix,
            statusLabel: statusLabel,
            isLinkedToBattleObjectiveStage: isLinkedStage,
            accessibilityLabel: accessibilityLabel
        )
    }

    var selectedCommanderChainReadout: SelectedCommanderChainReadout? {
        guard let selectedUnit,
              selectedUnit.resolvedGeneralTrait != nil,
              let brief = selectedCommanderBrief else {
            return nil
        }

        let skillTargetReadout = selectedGeneralSkillTargetReadout
        let warMerit = selectedWarMeritStatus
        let guidance = selectedCommanderActionGuidance
        let synergy = selectedCommanderSynergySummary
        let stagePreview = selectedBattleObjectiveStageCommandPreview
        let situation = selectedUnitSituationReadout
        let passiveLabel = brief.passiveContributions.isEmpty ?
            "无被动" :
            brief.passiveContributions
                .prefix(2)
                .map { "\($0.label)\($0.value)" }
                .joined(separator: " · ")
        let skillTargetLabel = skillTargetReadout?.targetCountLabel ?? brief.skillStatusLabel
        let warMeritLabel = warMerit?.summary ?? "战功待积累"
        let entryLabel = guidance?.stageCueLabel ??
            guidance?.skillCueLabel ??
            stagePreview?.skillStageCueLabel ??
            situation?.commandEntrySummaryLabel ??
            brief.skillStatusLabel
        let summaryLabel = [
            passiveLabel,
            skillTargetLabel,
            warMerit.map { "\($0.rankName) +\($0.damageBonus)" },
            entryLabel
        ].compactMap { $0 }.joined(separator: " · ")
        var signals: [SelectedCommanderChainSignal] = []

        signals.append(
            SelectedCommanderChainSignal(
                kind: .passive,
                title: passiveLabel,
                detail: brief.passiveContributions.isEmpty ?
                    passiveLabel :
                    brief.passiveContributions.map { "\($0.label)\($0.value) \($0.detail)" }.joined(separator: " · "),
                sourceID: brief.unitID
            )
        )

        if let skillTargetReadout {
            signals.append(
                SelectedCommanderChainSignal(
                    kind: .skillTarget,
                    title: skillTargetReadout.targetCountLabel,
                    detail: "\(skillTargetReadout.effectLabel) · \(skillTargetReadout.mapCueLabel)",
                    sourceID: skillTargetReadout.title
                )
            )
        }

        if let warMerit {
            signals.append(
                SelectedCommanderChainSignal(
                    kind: .warMerit,
                    title: warMerit.rankName,
                    detail: warMerit.summary,
                    sourceID: "\(warMerit.experience)-\(warMerit.rankName)"
                )
            )
        }

        if let guidance {
            signals.append(
                SelectedCommanderChainSignal(
                    kind: .guidance,
                    title: guidance.title,
                    detail: guidance.skillCueLabel,
                    sourceID: "\(selectedUnit.id)-commander-action"
                )
            )
        }

        if let synergy {
            signals.append(
                SelectedCommanderChainSignal(
                    kind: .synergy,
                    title: synergy.kindLabel,
                    detail: "\(synergy.impactLabel) · \(synergy.statusLabel)",
                    sourceID: synergy.id
                )
            )
        }

        if let stagePreview {
            signals.append(
                SelectedCommanderChainSignal(
                    kind: .objectiveStage,
                    title: stagePreview.stageLabel,
                    detail: stagePreview.commandEntryCueLabel,
                    sourceID: stagePreview.id
                )
            )
        }

        if let situationEntry = situation?.primaryCommandEntry {
            signals.append(
                SelectedCommanderChainSignal(
                    kind: .situationEntry,
                    title: situationEntry.kind.displayName,
                    detail: situationEntry.cueLabel,
                    sourceID: situationEntry.id
                )
            )
        }

        return SelectedCommanderChainReadout(
            unitID: selectedUnit.id,
            title: "\(brief.generalName ?? selectedUnit.kind.displayName)指挥链",
            statusLabel: guidance?.statusLabel ?? brief.skillStatusLabel,
            passiveLabel: passiveLabel,
            skillTargetLabel: skillTargetLabel,
            warMeritLabel: warMeritLabel,
            entryLabel: entryLabel,
            summaryLabel: summaryLabel,
            signals: signals,
            commanderBriefID: brief.unitID,
            skillTargetReadoutID: skillTargetReadout?.title,
            warMeritID: warMerit.map { "\($0.experience)-\($0.rankName)" },
            guidanceID: guidance.map { _ in "\(selectedUnit.id)-commander-action" },
            synergyID: synergy?.id,
            stagePreviewID: stagePreview?.id,
            situationEntryID: situation?.primaryCommandEntry?.id
        )
    }

    var selectedCommanderOpportunityBridgeReadout: SelectedCommanderOpportunityBridgeReadout? {
        guard let selectedUnit,
              selectedUnit.resolvedGeneralTrait != nil,
              let brief = selectedCommanderBrief,
              let commanderChain = selectedCommanderChainReadout else {
            return nil
        }

        let skillTargetReadout = selectedGeneralSkillTargetReadout
        let guidance = selectedCommanderActionGuidance
        let synergy = selectedCommanderSynergySummary
        // This bridge explains the global primary countermeasure opportunity;
        // it is intentionally not the currently focused map reconnaissance threat.
        let enemyCommanderThreat = primaryEnemyCommanderThreatSummary
        let countermeasure = primaryCountermeasureSummary
        let countermeasurePreview = selectedCountermeasureCommandPreview ?? primaryCountermeasureCommandPreview
        let stagePreview = selectedBattleObjectiveStageCommandPreview ?? primaryBattleObjectiveStageCommandPreview
        let engagementLoop = primaryEnemyEngagementLoopReadout
        let commanderName = brief.generalName ?? selectedUnit.kind.displayName
        let opportunityLabel = synergy.map { "\($0.kindLabel) · \($0.impactLabel)" } ??
            skillTargetReadout.map { "\($0.targetCountLabel) · \($0.effectLabel)" } ??
            commanderChain.entryLabel
        let skillWindowLabel = skillTargetReadout.map { "\($0.statusLabel) · \($0.mapCueLabel)" } ??
            guidance?.skillCueLabel ??
            brief.skillStatusLabel
        let enemyThreatLabel = enemyCommanderThreat.map { "\($0.commanderLabel) · \($0.impactLabel)" } ??
            engagementLoop?.enemyCommanderLabel ??
            "敌将待确认"
        let counterLabel = countermeasurePreview.map { "\($0.summary.kindLabel) · \($0.nextStepLabel)" } ??
            countermeasure.map { "\($0.kindLabel) · \($0.responseLabel)" } ??
            "反制待确认"
        let entryLabel = guidance?.stageCueLabel ??
            guidance?.skillCueLabel ??
            stagePreview?.commandEntryCueLabel ??
            countermeasurePreview?.commandChainLabel ??
            "入口待确认"
        let nextStepLabel = countermeasurePreview?.nextStepLabel ??
            stagePreview?.nextStepLabel ??
            guidance?.statusLabel ??
            engagementLoop?.nextStepLabel ??
            "等待将领战机"
        let riskLabel = countermeasure?.riskLabel ??
            engagementLoop?.riskLabel ??
            enemyCommanderThreat?.levelLabel ??
            synergy?.riskLabel ??
            "风险待确认"
        let statusLabel = guidance?.statusLabel ??
            skillTargetReadout?.statusLabel ??
            brief.skillStatusLabel
        let compactLabelParts = [
            synergy?.kindLabel ?? "战机",
            enemyCommanderThreat?.levelLabel ?? "敌将",
            countermeasurePreview != nil || countermeasure != nil ? "反制入口" : stagePreview?.stageLabel
        ].compactMap { $0 }
        var signals: [CommanderOpportunityBridgeSignal] = []

        signals.append(
            CommanderOpportunityBridgeSignal(
                kind: .commanderBrief,
                title: commanderName,
                detail: brief.skillStatusLabel,
                position: selectedUnit.position,
                sourceID: brief.unitID
            )
        )

        signals.append(
            CommanderOpportunityBridgeSignal(
                kind: .commanderChain,
                title: commanderChain.title,
                detail: commanderChain.compactLabel,
                position: selectedUnit.position,
                sourceID: commanderChain.unitID
            )
        )

        if let skillTargetReadout {
            signals.append(
                CommanderOpportunityBridgeSignal(
                    kind: .skillWindow,
                    title: skillTargetReadout.targetCountLabel,
                    detail: "\(skillTargetReadout.effectLabel) · \(skillTargetReadout.mapCueLabel)",
                    position: skillTargetReadout.targets.first?.position ?? selectedUnit.position,
                    sourceID: skillTargetReadout.title
                )
            )
        }

        if let guidance {
            signals.append(
                CommanderOpportunityBridgeSignal(
                    kind: .guidance,
                    title: guidance.title,
                    detail: guidance.skillCueLabel,
                    position: selectedUnit.position,
                    sourceID: "\(selectedUnit.id)-commander-action"
                )
            )
        }

        if let synergy {
            signals.append(
                CommanderOpportunityBridgeSignal(
                    kind: .synergy,
                    title: synergy.kindLabel,
                    detail: "\(synergy.impactLabel) · \(synergy.statusLabel)",
                    position: synergy.targetPosition,
                    sourceID: synergy.id
                )
            )
        }

        if let enemyCommanderThreat {
            signals.append(
                CommanderOpportunityBridgeSignal(
                    kind: .enemyCommander,
                    title: enemyCommanderThreat.commanderLabel,
                    detail: "\(enemyCommanderThreat.skillName) · \(enemyCommanderThreat.impactLabel)",
                    position: enemyCommanderThreat.targetPosition,
                    sourceID: enemyCommanderThreat.id
                )
            )
        }

        if let countermeasure {
            signals.append(
                CommanderOpportunityBridgeSignal(
                    kind: .countermeasure,
                    title: countermeasure.kindLabel,
                    detail: countermeasure.countermeasureChainLabel,
                    position: countermeasure.targetPosition,
                    sourceID: countermeasure.id
                )
            )
        }

        if let countermeasurePreview {
            signals.append(
                CommanderOpportunityBridgeSignal(
                    kind: .counterCommand,
                    title: countermeasurePreview.statusLabel,
                    detail: countermeasurePreview.commandChainLabel,
                    position: countermeasurePreview.destination,
                    sourceID: countermeasurePreview.id
                )
            )
        }

        if let stagePreview {
            signals.append(
                CommanderOpportunityBridgeSignal(
                    kind: .objectiveStage,
                    title: stagePreview.stageLabel,
                    detail: stagePreview.commandEntryCueLabel,
                    position: stagePreview.position,
                    sourceID: stagePreview.id
                )
            )
        }

        if let engagementLoop {
            signals.append(
                CommanderOpportunityBridgeSignal(
                    kind: .engagementLoop,
                    title: engagementLoop.statusLabel,
                    detail: engagementLoop.compactLabel,
                    position: stagePreview?.position ?? countermeasurePreview?.targetPosition ?? selectedUnit.position,
                    sourceID: engagementLoop.compactLabel
                )
            )
        }

        return SelectedCommanderOpportunityBridgeReadout(
            unitID: selectedUnit.id,
            title: "\(commanderName)战机桥接",
            statusLabel: statusLabel,
            opportunityLabel: opportunityLabel,
            skillWindowLabel: skillWindowLabel,
            enemyThreatLabel: enemyThreatLabel,
            counterLabel: counterLabel,
            entryLabel: entryLabel,
            nextStepLabel: nextStepLabel,
            riskLabel: riskLabel,
            compactLabel: compactLabelParts.joined(separator: " · "),
            signals: signals,
            commanderBriefID: brief.unitID,
            commanderChainUnitID: commanderChain.unitID,
            skillTargetReadoutID: skillTargetReadout?.title,
            guidanceID: guidance.map { _ in "\(selectedUnit.id)-commander-action" },
            synergyID: synergy?.id,
            enemyCommanderThreatID: enemyCommanderThreat?.id,
            countermeasureID: countermeasure?.id,
            countermeasurePreviewID: countermeasurePreview?.id,
            stagePreviewID: stagePreview?.id,
            engagementLoopID: engagementLoop?.compactLabel
        )
    }

    var selectedUnitOrderWindowReadout: SelectedUnitOrderWindowReadout? {
        guard let selectedUnit,
              let situation = selectedUnitSituationReadout else {
            return nil
        }

        let countermeasurePreview = selectedCountermeasureCommandPreview ?? primaryCountermeasureCommandPreview
        let stagePreview = selectedBattleObjectiveStageCommandPreview ?? primaryBattleObjectiveStageCommandPreview
        let commanderBridge = selectedCommanderOpportunityBridgeReadout
        let commanderChain = selectedCommanderChainReadout
        let commanderGuidance = selectedCommanderActionGuidance
        let recommendation = selectedTacticalRecommendationSummary
        let maneuver = primaryManeuverOptionSummary
        // The order window inherits the global engagement loop, not active map focus.
        let engagementLoop = primaryEnemyEngagementLoopReadout
        let convergence = primaryBattlefieldConvergenceSummary
        let recommendedOrder = selectedTacticalOrderPreviews.first { !$0.isCurrent && $0.canSwitch } ??
            selectedTacticalOrderPreviews.first { $0.isCurrent } ??
            selectedTacticalOrderPreviews.first
        var steps: [SelectedUnitOrderWindowStep] = []

        func appendStep(
            kind: SelectedUnitOrderWindowStepKind,
            title: String,
            detail: String,
            cueLabel: String,
            position: Position?,
            sourceID: String
        ) {
            steps.append(
                SelectedUnitOrderWindowStep(
                    kind: kind,
                    title: title,
                    detail: detail,
                    cueLabel: cueLabel,
                    position: position,
                    sourceID: sourceID,
                    isPrimary: steps.isEmpty
                )
            )
        }

        if let countermeasurePreview {
            appendStep(
                kind: .countermeasure,
                title: countermeasurePreview.title,
                detail: "\(countermeasurePreview.statusLabel) · \(countermeasurePreview.commandChainLabel)",
                cueLabel: countermeasurePreview.nextStepLabel,
                position: countermeasurePreview.destination,
                sourceID: countermeasurePreview.id
            )
        }

        if let stagePreview {
            appendStep(
                kind: .objectiveStage,
                title: stagePreview.title,
                detail: "\(stagePreview.stageLabel) · \(stagePreview.statusLabel)",
                cueLabel: stagePreview.commandEntryCueLabel,
                position: stagePreview.position,
                sourceID: stagePreview.id
            )
        }

        if let commanderBridge {
            appendStep(
                kind: .commander,
                title: commanderBridge.title,
                detail: "\(commanderBridge.opportunityLabel) · \(commanderBridge.enemyThreatLabel)",
                cueLabel: commanderBridge.entryLabel,
                position: selectedUnit.position,
                sourceID: "\(commanderBridge.unitID)-\(commanderBridge.compactLabel)"
            )
        } else if let commanderGuidance {
            appendStep(
                kind: .commander,
                title: commanderGuidance.title,
                detail: "\(commanderGuidance.statusLabel) · \(commanderGuidance.skillCueLabel)",
                cueLabel: commanderGuidance.stageCueLabel ?? commanderGuidance.skillCueLabel,
                position: selectedUnit.position,
                sourceID: "\(selectedUnit.id)-commander-action"
            )
        }

        if let maneuver {
            appendStep(
                kind: .maneuver,
                title: maneuver.title,
                detail: "\(maneuver.destinationLabel) · \(maneuver.impactLabel)",
                cueLabel: maneuver.objectiveCueLabel,
                position: maneuver.destination,
                sourceID: maneuver.id
            )
        }

        if let recommendation {
            appendStep(
                kind: .recommendation,
                title: recommendation.title,
                detail: "\(recommendation.kindLabel) · \(recommendation.riskLabel)",
                cueLabel: recommendation.report.command,
                position: recommendation.destination,
                sourceID: recommendation.id
            )
        }

        if let recommendedOrder {
            let cue = recommendedOrder.isCurrent ? "保持\(recommendedOrder.order.displayName)" : "切换\(recommendedOrder.order.displayName)"
            appendStep(
                kind: .tacticalOrder,
                title: "姿态窗口",
                detail: recommendedOrder.detail,
                cueLabel: cue,
                position: selectedUnit.position,
                sourceID: recommendedOrder.order.rawValue
            )
        }

        if let engagementLoop {
            appendStep(
                kind: .engagement,
                title: engagementLoop.title,
                detail: "\(engagementLoop.intentLabel) · \(engagementLoop.enemyCommanderLabel)",
                cueLabel: engagementLoop.nextStepLabel,
                position: engagementLoop.signals.first?.position ?? selectedUnit.position,
                sourceID: engagementLoop.compactLabel
            )
        }

        if let convergence {
            appendStep(
                kind: .convergence,
                title: convergence.title,
                detail: "\(convergence.objectiveLabel) · \(convergence.responseLabel)",
                cueLabel: convergence.nextStepLabel,
                position: convergence.signals.first?.position ?? selectedUnit.position,
                sourceID: convergence.id
            )
        }

        guard !steps.isEmpty else {
            return nil
        }

        let openingLabel = steps.first?.cueLabel ?? situation.primaryCommandEntryLabel
        let postureLabel = recommendedOrder.map { preview in
            if preview.isCurrent {
                return "保持\(preview.order.displayName)"
            }
            return preview.canSwitch ? "切换\(preview.order.displayName)" : "\(preview.order.displayName)受阻"
        } ?? "姿态待确认"
        let movementLabel = maneuver.map { "\($0.destinationLabel) · \($0.impactLabel)" } ??
            stagePreview.map { "\($0.stageLabel) · \($0.focusLabel)" } ??
            situation.spaceLabel
        let strikeLabel = recommendation.map { "\($0.kindLabel) · \($0.report.command)" } ??
            countermeasurePreview?.targetStageCueLabel ??
            stagePreview?.attackStageCueLabel ??
            situation.opportunityLabel
        let commanderLabel = commanderBridge?.compactLabel ??
            commanderChain?.entryLabel ??
            commanderGuidance?.skillCueLabel ??
            "将令待确认"
        let counterLabel = countermeasurePreview.map { "\($0.summary.kindLabel) · \($0.nextStepLabel)" } ??
            engagementLoop?.countermeasureLabel ??
            "反制待确认"
        let nextStepLabel = countermeasurePreview?.nextStepLabel ??
            stagePreview?.nextStepLabel ??
            commanderBridge?.nextStepLabel ??
            recommendation?.report.command ??
            maneuver?.objectiveCueLabel ??
            situation.nextStepLabel
        let riskLabel = countermeasurePreview?.summary.riskLabel ??
            commanderBridge?.riskLabel ??
            convergence?.riskLabel ??
            engagementLoop?.riskLabel ??
            situation.riskLabel
        let statusLabel = countermeasurePreview?.statusLabel ??
            stagePreview?.statusLabel ??
            commanderBridge?.statusLabel ??
            situation.statusLabel
        let compactLabel = [
            openingLabel,
            postureLabel,
            nextStepLabel
        ].joined(separator: " · ")

        return SelectedUnitOrderWindowReadout(
            unitID: selectedUnit.id,
            title: "\(selectedUnit.kind.displayName)军令窗口",
            statusLabel: statusLabel,
            openingLabel: openingLabel,
            postureLabel: postureLabel,
            movementLabel: movementLabel,
            strikeLabel: strikeLabel,
            commanderLabel: commanderLabel,
            counterLabel: counterLabel,
            nextStepLabel: nextStepLabel,
            riskLabel: riskLabel,
            compactLabel: compactLabel,
            steps: steps,
            situationID: situation.unitID,
            countermeasurePreviewID: countermeasurePreview?.id,
            stagePreviewID: stagePreview?.id,
            commanderBridgeID: commanderBridge.map { "\($0.unitID)-\($0.compactLabel)" },
            commanderChainUnitID: commanderChain?.unitID,
            recommendationID: recommendation?.id,
            maneuverID: maneuver?.id,
            engagementLoopID: engagementLoop?.compactLabel,
            convergenceID: convergence?.id,
            tacticalOrderID: recommendedOrder?.order.rawValue
        )
    }

    var selectedCommanderBrief: SelectedCommanderBrief? {
        guard let selectedUnit else { return nil }

        let trait = selectedUnit.resolvedGeneralTrait
        let preview = selectedGeneralSkillPreview
        let warMeritStatus = selectedWarMeritStatus
        let passiveContributions = selectedGeneralPassiveContributions
        let skillStatusLabel: String

        if let preview {
            if preview.cooldownRemaining > 0 {
                skillStatusLabel = preview.cooldownText
            } else if preview.isExecutable {
                skillStatusLabel = "可发动"
            } else {
                skillStatusLabel = preview.blockedReason ?? "不可发动"
            }
        } else {
            skillStatusLabel = "无主动技能"
        }

        let skillEffectLabel = selectedSkillEffectLabel(preview)
        let warMeritProgressLabel = warMeritStatus.map { status in
            if let nextRankName = status.nextRankName,
               let nextRankExperience = status.nextRankExperience {
                return "战功 \(status.experience)/\(nextRankExperience) · 下一军阶 \(nextRankName)"
            }

            return "战功 \(status.experience) · 最高军阶"
        }

        let generalName = selectedUnit.generalName
        let traitName = trait?.displayName
        let accessibilityParts = [
            "\(selectedUnit.faction.displayName)\(selectedUnit.kind.displayName)",
            generalName.map { "将领\($0)" },
            traitName,
            passiveContributions.isEmpty ? "无被动贡献" : passiveContributions.map { "\($0.label)\($0.value)" }.joined(separator: "，"),
            preview.map { "\($0.trait.skillName)\(skillStatusLabel)" },
            warMeritStatus?.summary
        ].compactMap { $0 }

        return SelectedCommanderBrief(
            unitID: selectedUnit.id,
            title: "\(selectedUnit.faction.displayName) \(selectedUnit.kind.displayName)",
            generalName: generalName,
            traitName: traitName,
            passiveContributions: passiveContributions,
            skillName: trait?.skillName,
            skillSummary: preview?.summary,
            skillDetail: trait?.skillDetail,
            skillStatusLabel: skillStatusLabel,
            skillBlockedReason: preview?.blockedReason,
            skillEffectLabel: skillEffectLabel,
            warMeritSummary: warMeritStatus?.summary,
            warMeritProgressLabel: warMeritProgressLabel,
            accessibilityLabel: accessibilityParts.joined(separator: "，")
        )
    }

    var selectedGeneralPassiveContributions: [GeneralPassiveContribution] {
        guard let trait = selectedUnit?.resolvedGeneralTrait else { return [] }
        var contributions: [GeneralPassiveContribution] = []

        if trait.attackBonus != 0 {
            contributions.append(
                GeneralPassiveContribution(
                    id: "attack",
                    label: "攻击",
                    value: signedValue(trait.attackBonus),
                    detail: "普通战斗攻击"
                )
            )
        }

        if trait.siegeAttackBonus != 0 {
            contributions.append(
                GeneralPassiveContribution(
                    id: "siege",
                    label: "攻城",
                    value: signedValue(trait.siegeAttackBonus),
                    detail: "对城市伤害"
                )
            )
        }

        if trait.defenseBonus != 0 {
            contributions.append(
                GeneralPassiveContribution(
                    id: "defense",
                    label: "防御",
                    value: signedValue(trait.defenseBonus),
                    detail: "受击减伤"
                )
            )
        }

        if trait.movementBonus != 0 {
            contributions.append(
                GeneralPassiveContribution(
                    id: "movement",
                    label: "机动",
                    value: signedValue(trait.movementBonus),
                    detail: "移动范围"
                )
            )
        }

        return contributions
    }

    var selectedTacticalOrderPreviews: [SelectedTacticalOrderPreview] {
        guard let selectedUnit else { return [] }
        let currentAttack = state.effectiveAttack(for: selectedUnit)
        let currentDefense = state.effectiveDefense(for: selectedUnit)
        let currentMovement = state.effectiveMovement(for: selectedUnit)

        return TacticalOrder.allCases.map { order in
            var previewUnit = selectedUnit
            previewUnit.tacticalOrder = order == .balanced ? nil : order
            let attack = state.effectiveAttack(for: previewUnit)
            let defense = state.effectiveDefense(for: previewUnit)
            let movement = state.effectiveMovement(for: previewUnit)
            let isCurrent = order == selectedUnit.resolvedTacticalOrder
            let blockedReason = tacticalOrderBlockedReason(order, for: selectedUnit)
            let canSwitch = canSetSelectedTacticalOrder(order)
            let detail = "攻 \(attack) \(deltaLabel(attack - currentAttack)) · 防 \(defense) \(deltaLabel(defense - currentDefense)) · 移 \(movement) \(deltaLabel(movement - currentMovement))"

            return SelectedTacticalOrderPreview(
                order: order,
                attack: attack,
                defense: defense,
                movement: movement,
                attackDelta: attack - currentAttack,
                defenseDelta: defense - currentDefense,
                movementDelta: movement - currentMovement,
                isCurrent: isCurrent,
                canSwitch: canSwitch,
                blockedReason: blockedReason,
                detail: detail,
                accessibilityLabel: "\(order.displayName)，攻击\(attack)，防御\(defense)，机动\(movement)，\(isCurrent ? "当前姿态" : (blockedReason ?? "可切换"))"
            )
        }
    }

    func selectedTacticalOrderPreview(for order: TacticalOrder) -> SelectedTacticalOrderPreview? {
        selectedTacticalOrderPreviews.first { $0.order == order }
    }

    var canSkipSelectedUnit: Bool {
        guard !isCampaignOver else { return false }
        guard let selectedUnit else { return false }
        return selectedUnit.faction == state.activeFaction && (!selectedUnit.hasMoved || !selectedUnit.hasActed)
    }

    var canUseSelectedGeneralSkill: Bool {
        guard !isCampaignOver else { return false }
        guard selectedUnit != nil,
              let preview = selectedGeneralSkillPreview else { return false }
        return preview.isExecutable
    }

    var canTrainSelectedUnit: Bool {
        guard !isCampaignOver else { return false }
        return selectedUnitDevelopmentDecisionSummary?.trainingOption?.canExecute ?? false
    }

    var canAppointGeneralToSelectedUnit: Bool {
        guard !isCampaignOver else { return false }
        return selectedUnitDevelopmentDecisionSummary?.appointmentOption?.canExecute ?? false
    }

    var selectedTrainingButtonDetail: String? {
        selectedUnitDevelopmentDecisionSummary?.trainingOption?.buttonDetail
    }

    var selectedAppointmentButtonDetail: String? {
        selectedUnitDevelopmentDecisionSummary?.appointmentOption?.buttonDetail
    }

    func canSetSelectedTacticalOrder(_ order: TacticalOrder) -> Bool {
        guard !isCampaignOver else { return false }
        guard let selectedUnit else { return false }
        return selectedUnit.faction == state.activeFaction &&
            selectedUnit.resolvedTacticalOrder != order &&
            !selectedUnit.hasMoved &&
            !selectedUnit.hasActed
    }

    private func tacticalOrderBlockedReason(_ order: TacticalOrder, for unit: ArmyUnit) -> String? {
        if order == unit.resolvedTacticalOrder {
            return "当前姿态"
        }

        if isCampaignOver {
            return "战役已结束"
        }

        if unit.faction != state.activeFaction {
            return "非当前阵营"
        }

        if unit.hasMoved || unit.hasActed {
            return "已行动"
        }

        return nil
    }

    private func tacticalOrderCommandSymbol(_ order: TacticalOrder) -> String {
        switch order {
        case .balanced: return "circle.grid.cross.fill"
        case .assault: return "bolt.fill"
        case .defensive: return "shield.fill"
        case .forcedMarch: return "figure.walk.motion"
        }
    }

    private func selectedSkillEffectLabel(_ preview: GeneralSkillPreview?) -> String? {
        guard let preview else { return nil }

        if preview.projectedFortificationReduction > 0 {
            return "城防 -\(preview.projectedFortificationReduction) · 目标 \(preview.affectedCityIDs.count)"
        }

        if preview.projectedRecoveredHealth > 0 {
            return "恢复 \(preview.projectedRecoveredHealth) · 友军 \(preview.affectedUnitIDs.count)"
        }

        return preview.summary
    }

    private func signedValue(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }

    private func deltaLabel(_ value: Int) -> String {
        value == 0 ? "±0" : signedValue(value)
    }

    func start(mode: GameMode) {
        selectedMode = mode
        state = GameState.newCampaign(mode: mode)
        selectedUnitID = nil
        selectedCityID = nil
        selectedPosition = nil
        selectedAttackTargetID = nil
        selectedTechnology = nil
        focusedCountermeasureID = nil
        focusedBattleObjectiveRole = nil
        focusedEnemyCommanderThreatID = nil
        selectedMapReconPerspective = .enemyIntent
        isShowingMenu = false
        bannerMessage = "\(mode.displayName)开始：控制罗马军团扩张疆域。"
    }

    func openMenu() {
        isShowingMenu = true
    }

    func selectTile(_ position: Position) {
        focusedBattleObjectiveRole = nil
        focusedEnemyCommanderThreatID = nil

        if let unit = state.unit(at: position) {
            if let target = attackTargets.first(where: { $0.id == unit.id }) {
                focusAttackTarget(target.id)
                return
            }

            selectedAttackTargetID = nil
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
            selectedAttackTargetID = nil
            apply {
                try state.moveUnit(id: unit.id, to: position)
            }
            selectedCityID = state.city(at: position)?.id
            selectedPosition = position
            return
        }

        if let city = state.city(at: position) {
            selectedAttackTargetID = nil
            selectedCityID = city.id
            selectedUnitID = nil
            selectedPosition = position
            bannerMessage = "\(city.name)：\(city.owner.displayName)控制。"
            return
        }

        selectedAttackTargetID = nil
        selectedUnitID = nil
        selectedCityID = nil
        selectedPosition = position
        if let tile = state.tile(at: position) {
            bannerMessage = "\(tile.terrain.displayName)地块：移动 \(tile.terrain.movementCost)，防御 +\(tile.terrain.defenseBonus)。"
        } else {
            bannerMessage = "战场边界外。"
        }
    }

    func focusPrimaryCountermeasure() {
        guard let summary = primaryCountermeasureSummary else { return }
        focusCountermeasure(summary.id)
    }

    func selectMapReconPerspective(_ kind: MapReconPerspectiveKind) {
        selectedMapReconPerspective = kind
        let readout = mapReconPerspectiveHUDReadout
        bannerMessage = "\(kind.displayName)侦察：\(readout.nextStepLabel)。风险：\(readout.riskLabel)。"
    }

    func focusCountermeasure(_ id: String) {
        guard let preview = countermeasureCommandPreviews.first(where: { $0.id == id }),
              let responseUnit = preview.responseUnit,
              preview.canFocus else {
            bannerMessage = "反制回应单位暂不可定位。"
            return
        }

        selectedAttackTargetID = nil
        focusedEnemyCommanderThreatID = nil
        selectedUnitID = responseUnit.id
        selectedCityID = state.city(at: responseUnit.position)?.id
        selectedPosition = responseUnit.position
        focusedCountermeasureID = preview.id
        focusedBattleObjectiveRole = nil
        bannerMessage = "\(preview.summary.unitLabel)反制：\(preview.nextStepLabel)。\(preview.destinationLabel)，目标\(preview.targetLabel)。"
    }

    func focusPrimaryBattleObjectiveStage(_ role: BattleObjectiveMapRole) {
        guard let overlay = primaryBattleObjectiveMapOverlay?.positionOverlays.first(where: { $0.role == role }) else {
            bannerMessage = "\(role.stageLabel)目标线阶段暂不可定位。"
            return
        }

        selectedAttackTargetID = nil
        focusedEnemyCommanderThreatID = nil
        selectedPosition = overlay.position
        focusedBattleObjectiveRole = role
        focusedCountermeasureID = nil

        selectedUnitID = battleObjectiveFocusUnit(for: overlay)?.id
        if let city = state.city(at: overlay.position) {
            selectedCityID = city.id
        } else if let selectedUnitID,
                  let unit = state.unit(withID: selectedUnitID) {
            selectedCityID = state.city(at: unit.position)?.id
        } else {
            selectedCityID = nil
        }

        bannerMessage = "目标线\(overlay.stageLabel)：\(overlay.focusLabel)。位置\(overlay.position.description)。"
    }

    private func battleObjectiveFocusUnit(for overlay: BattleObjectivePositionOverlay) -> ArmyUnit? {
        let unit: ArmyUnit?

        switch overlay.role {
        case .focus:
            unit = overlay.chain.focus.unit
        case .synergy:
            unit = overlay.chain.synergy?.unit ?? overlay.chain.synergy?.commanderUnit
        case .maneuver:
            unit = overlay.chain.maneuver?.unit
        case .recommendation:
            unit = overlay.chain.recommendation?.unit
        }

        return unit?.faction == .rome ? unit : nil
    }

    func focusAttackTarget(_ defenderID: String) {
        guard let attacker = selectedUnit,
              attacker.faction == state.activeFaction,
              let target = attackTargets.first(where: { $0.id == defenderID }) else {
            bannerMessage = "当前军团无法锁定该攻击目标。"
            selectedAttackTargetID = nil
            return
        }

        selectedAttackTargetID = target.id
        focusedEnemyCommanderThreatID = nil
        selectedPosition = target.position
        focusedCountermeasureID = nil
        focusedBattleObjectiveRole = nil

        if let preview = attackPreview(for: target.id) {
            let result = preview.defeatsDefender ? "可歼灭" : (preview.attackerFalls ? "高风险" : "可执行")
            bannerMessage = "已锁定\(target.faction.displayName)\(target.kind.displayName)：伤害 \(preview.damage) · 反击 \(preview.retaliation) · \(result)。"
        } else {
            bannerMessage = "已锁定\(target.faction.displayName)\(target.kind.displayName)，请确认攻击。"
        }
    }

    /// Clears only the target lock and restores the attacker's map focus.
    func cancelSelectedAttackTarget() {
        guard selectedAttackTargetID != nil else { return }

        let attacker = selectedUnit
        let forecast = selectedCombatForecast
        selectedAttackTargetID = nil
        focusedEnemyCommanderThreatID = nil
        focusedCountermeasureID = nil
        focusedBattleObjectiveRole = nil

        if let attacker {
            selectedPosition = attacker.position
            if attacker.faction == state.activeFaction {
                bannerMessage = "已取消\(forecast.map { $0.defenderLabel } ?? "攻击目标")锁定，保留\(attacker.faction.displayName)\(attacker.kind.displayName)选择。"
            } else {
                bannerMessage = "已取消攻击目标锁定。"
            }
        } else {
            selectedPosition = selectedCity?.position
            bannerMessage = "已取消攻击目标锁定。"
        }
    }

    func confirmSelectedAttack() {
        guard let defenderID = selectedCombatForecast?.defender.id else {
            bannerMessage = "请先从地图或选敌菜单锁定攻击目标。"
            return
        }

        attack(defenderID)
    }

    func focusEnemyCommanderThreat(_ id: String) {
        guard let summary = enemyCommanderThreatSummaries.first(where: { $0.id == id }) else {
            bannerMessage = "敌将威胁已失效，无法定位。"
            return
        }

        selectedAttackTargetID = nil
        focusedCountermeasureID = nil
        focusedBattleObjectiveRole = nil
        focusedEnemyCommanderThreatID = summary.id
        selectedUnitID = nil
        selectedCityID = nil
        selectedPosition = summary.originPosition
        selectedMapReconPerspective = .enemyIntent
        bannerMessage = "已定位敌将\(summary.commanderLabel)：\(summary.skillName) · \(summary.spaceChainLabel)。仅供侦察，不会执行技能。"
    }

    func attack(_ defenderID: String) {
        guard let selectedUnitID = selectedUnitID else { return }
        let defenderPosition = state.unit(withID: defenderID)?.position
        selectedAttackTargetID = nil

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

        selectedAttackTargetID = nil

        apply {
            try state.skipUnit(id: selectedUnitID)
        }

        let nextReadyUnit = state.nextReadyUnit(for: .rome)
        self.selectedUnitID = nextReadyUnit?.id
        self.selectedCityID = nextReadyUnit.flatMap { state.city(at: $0.position)?.id }
        self.selectedPosition = nextReadyUnit?.position
    }

    func recruit(_ kind: UnitKind) {
        guard let cityID = commandCity?.id else { return }

        selectedAttackTargetID = nil

        apply {
            try state.recruit(kind, at: cityID)
        }
    }

    func developCommandCity() {
        guard let city = commandCity else { return }

        selectedAttackTargetID = nil

        apply {
            try state.developCity(id: city.id)
        }
    }

    func trainSelectedUnit() {
        guard let selectedUnitID = selectedUnitID else { return }

        selectedAttackTargetID = nil

        apply {
            try state.trainUnit(id: selectedUnitID)
        }
    }

    func appointGeneralToSelectedUnit() {
        guard let selectedUnitID = selectedUnitID else { return }

        selectedAttackTargetID = nil

        apply {
            try state.appointGeneral(unitID: selectedUnitID)
        }
    }

    func useSelectedGeneralSkill() {
        guard let selectedUnitID = selectedUnitID else { return }

        selectedAttackTargetID = nil

        apply {
            try state.useGeneralSkill(unitID: selectedUnitID)
        }

        if let unit = state.unit(withID: selectedUnitID) {
            selectedPosition = unit.position
        }
    }

    func setSelectedTacticalOrder(_ order: TacticalOrder) {
        guard let selectedUnitID = selectedUnitID else { return }

        selectedAttackTargetID = nil

        apply {
            try state.setTacticalOrder(unitID: selectedUnitID, order: order)
        }

        if let unit = state.unit(withID: selectedUnitID) {
            selectedPosition = unit.position
        }
    }

    func restSelectedUnit() {
        guard let selectedUnitID = selectedUnitID else { return }

        selectedAttackTargetID = nil

        apply {
            try state.restUnit(id: selectedUnitID)
        }
    }

    func sendEnvoy(to faction: Faction) {
        selectedAttackTargetID = nil
        apply {
            try state.sendEnvoy(to: faction)
        }
    }

    func research(_ technology: Technology) {
        selectedAttackTargetID = nil
        apply {
            try state.research(technology)
        }
    }

    func endTurn() {
        guard !isCampaignOver else {
            bannerMessage = "\(campaignStatusTitle)：\(campaignStatusDetail)"
            return
        }

        var messages = state.endTurn()

        while state.activeFaction != .rome && !state.campaignStatus.isGameOver {
            messages.append(contentsOf: state.performSimpleAI(for: state.activeFaction))
            guard !state.campaignStatus.isGameOver else {
                break
            }
            messages.append(contentsOf: state.endTurn())
        }

        selectedUnitID = nil
        selectedCityID = nil
        selectedPosition = nil
        selectedAttackTargetID = nil
        focusedEnemyCommanderThreatID = nil
        if state.campaignStatus.isGameOver {
            bannerMessage = messages.last ?? "\(campaignStatusTitle)：\(campaignStatusDetail)"
        } else {
            bannerMessage = messages.last ?? "新的罗马回合开始。"
        }
    }

    private func apply(_ operation: () throws -> [String]) {
        selectedAttackTargetID = nil
        focusedEnemyCommanderThreatID = nil
        do {
            let messages = try operation()
            let fallback = state.campaignStatus.isGameOver ? "\(campaignStatusTitle)：\(campaignStatusDetail)" : "命令已执行。"
            bannerMessage = messages.last ?? fallback
        } catch {
            if let ruleError = error as? GameRuleError {
                bannerMessage = ruleError.displayMessage
            } else {
                bannerMessage = error.localizedDescription
            }
        }
    }
}
