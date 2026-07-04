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
        let orderPreviews = viewModel.selectedTacticalOrderPreviews
        guard orderPreviews.count == TacticalOrder.allCases.count,
              orderPreviews.contains(where: { !$0.isCurrent && ($0.attackDelta != 0 || $0.defenseDelta != 0 || $0.movementDelta != 0) }),
              orderPreviews.contains(where: { $0.order == .assault && $0.attackDelta > 0 }),
              orderPreviews.contains(where: { $0.order == .forcedMarch && $0.movementDelta > 0 }) else {
            throw PreviewRenderError.missingTacticalOrderPreview
        }

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

        guard !isCompactViewport(width: width, height: height) ||
                hasVisibleCompactCommandContent(in: bitmap, logicalWidth: width, logicalHeight: height) else {
            throw PreviewRenderError.missingCompactCommandRender
        }

        try png.write(to: URL(fileURLWithPath: outputPath))
        print(outputPath)
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
}

enum PreviewRenderError: Error {
    case renderFailed
    case missingIntentOverlay
    case missingHexIntentRoute
    case missingCommanderBrief
    case missingTacticalOrderPreview
    case missingCompactCommandRender
}
