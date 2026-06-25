import SwiftUI

struct RootView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        Group {
            if viewModel.isShowingMenu {
                MainMenuView()
            } else {
                BattleView()
            }
        }
        .preferredColorScheme(.dark)
    }
}
