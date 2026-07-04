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
            ArmyUnit(id: "rome-legion-1", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), generalName: "凯撒", generalTrait: .eagleStandard),
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
        viewModel.bannerMessage = "预览战斗：敌军路线和目标叠层已显示。"

        let overlays = viewModel.enemyIntentMapOverlays
        guard let advanceOverlay = overlays.first(where: { $0.kind == .advanceAttack && $0.unitID == "carthage-hunter" }),
              advanceOverlay.destinationPosition != advanceOverlay.originPosition,
              advanceOverlay.targetPosition == Position(x: 3, y: 3),
              !advanceOverlay.routeSegments.isEmpty,
              advanceOverlay.impactLabel.contains("预计伤害") else {
            throw PreviewRenderError.missingIntentOverlay
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

        try png.write(to: URL(fileURLWithPath: outputPath))
        print(outputPath)
    }
}

enum PreviewRenderError: Error {
    case renderFailed
    case missingIntentOverlay
}
