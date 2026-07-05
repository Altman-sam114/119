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
            ArmyUnit(id: "rome-legion-1", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), experience: 2, generalName: "凯撒", generalTrait: .eagleStandard),
            ArmyUnit(id: "carthage-hunter", kind: .cavalry, faction: .carthage, position: Position(x: 7, y: 2))
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
    case missingThreatHeatSummary
    case missingMapControlSummary
    case missingCommanderBrief
    case missingLegionFormationSummary
    case missingTacticalRecommendationSummary
    case missingTacticalOrderPreview
    case missingCityReadout
    case missingCompactCommandRender
}
