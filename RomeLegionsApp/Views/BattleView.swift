import SwiftUI

struct BattleInterfaceMetrics: Equatable {
    let isPortrait: Bool
    let isShortLandscape: Bool
    let usesCondensedTopBar: Bool
    let topBarHeight: CGFloat
    let commandDockHeight: CGFloat
    let mapInset: CGFloat
    let edgeToolVisualSize: CGFloat
    let edgeToolSpacing: CGFloat
    let commandIdentityWidth: CGFloat

    init(container: CGSize) {
        isPortrait = container.height >= container.width
        isShortLandscape = container.width > container.height && container.height < 560
        usesCondensedTopBar = container.width < 900 || isShortLandscape
        topBarHeight = isShortLandscape ? 42 : 44
        commandDockHeight = isPortrait ? 102 : (isShortLandscape ? 80 : 88)
        mapInset = isShortLandscape ? 4 : 6
        edgeToolVisualSize = isShortLandscape ? 34 : 36
        edgeToolSpacing = 2
        commandIdentityWidth = container.width < 700 ? 128 : 220
    }

    var fixedChromeHeight: CGFloat {
        topBarHeight + commandDockHeight
    }
}

struct BattleView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    @State private var activeDrawer: BattleDrawerCategory?

    init(initialDrawer: BattleDrawerCategory? = nil) {
        _activeDrawer = State(initialValue: initialDrawer)
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = BattleInterfaceMetrics(container: proxy.size)
            let drawerHeight = metrics.isPortrait
                ? min(520, proxy.size.height * 0.56)
                : max(180, min(620, proxy.size.height - metrics.fixedChromeHeight - 58))

            ZStack {
                Color(red: 0.09, green: 0.10, blue: 0.10)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    TopBarView(
                        isCondensed: metrics.usesCondensedTopBar,
                        isNarrow: proxy.size.width < 520,
                        height: metrics.topBarHeight
                    )

                    ZStack(alignment: .topTrailing) {
                        VStack(spacing: 0) {
                            WarMapView()
                                .padding(metrics.mapInset)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)

                            SelectionCommandDockView(
                                isCompact: proxy.size.width < 700,
                                identityWidth: metrics.commandIdentityWidth
                            ) {
                                activeDrawer = .orders
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: metrics.commandDockHeight)
                        }

                        BattleEdgeToolsView(
                            activeDrawer: $activeDrawer,
                            visualSize: metrics.edgeToolVisualSize,
                            spacing: metrics.edgeToolSpacing
                        )
                        .padding(.top, metrics.mapInset + 4)
                        .padding(.trailing, metrics.mapInset + 4)

                        if let activeDrawer {
                            BattlefieldDrawerView(
                                category: activeDrawer,
                                onClose: { self.activeDrawer = nil }
                            )
                            .frame(
                                width: metrics.isPortrait ? max(280, proxy.size.width - 20) : min(380, proxy.size.width * 0.42),
                                height: drawerHeight
                            )
                            .padding(.top, 52)
                            .padding(.trailing, metrics.isPortrait ? 10 : 8)
                            .zIndex(10)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}
