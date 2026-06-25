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
        viewModel.state.units.removeAll { $0.id == "preview-carthage-adjacent" }
        viewModel.state.units.append(
            ArmyUnit(
                id: "preview-carthage-adjacent",
                kind: .archer,
                faction: .carthage,
                position: Position(x: 4, y: 3),
                health: 60
            )
        )
        viewModel.selectedUnitID = "rome-legion-1"
        viewModel.selectedPosition = Position(x: 3, y: 3)
        viewModel.bannerMessage = "预览战斗：选择敌军头顶徽标发起攻击。"

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
}
