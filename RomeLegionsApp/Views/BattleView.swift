import SwiftUI

struct BattleInterfaceMetrics: Equatable {
    static let controlSize: CGFloat = 44

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
        commandDockHeight = isPortrait ? 102 : (isShortLandscape ? 56 : 64)
        mapInset = isShortLandscape ? 2 : 4
        edgeToolVisualSize = isShortLandscape ? 31 : 34
        edgeToolSpacing = 0
        commandIdentityWidth = container.width < 700 ? 128 : 220
    }

    var fixedChromeHeight: CGFloat {
        topBarHeight + commandDockHeight
    }
}

struct BattleView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    @State private var activeDrawer: BattleDrawerCategory?
    private let drawerUsesScrollView: Bool

    init(
        initialDrawer: BattleDrawerCategory? = nil,
        drawerUsesScrollView: Bool = true
    ) {
        _activeDrawer = State(initialValue: initialDrawer)
        self.drawerUsesScrollView = drawerUsesScrollView
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = BattleInterfaceMetrics(container: proxy.size)
            let drawerHeight = metrics.isPortrait
                ? min(520, proxy.size.height * 0.56)
                : max(180, min(620, proxy.size.height - metrics.fixedChromeHeight - 58))
            let drawerWidth = metrics.isPortrait
                ? max(280, proxy.size.width - 20)
                : min(380, proxy.size.width * 0.42)

            ZStack {
                BattlePalette.canvas
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
                                isPortrait: metrics.isPortrait,
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
                                drawerUsesScrollView: drawerUsesScrollView,
                                layoutSize: CGSize(width: drawerWidth, height: drawerHeight),
                                onClose: { self.activeDrawer = nil }
                            )
                            .frame(
                                width: drawerWidth,
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
