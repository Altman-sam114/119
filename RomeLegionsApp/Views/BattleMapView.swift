import SwiftUI

func isMapAttackOrigin(unitID: String?, sourceID: String?) -> Bool {
    guard let sourceID else { return false }
    return unitID == sourceID
}

struct WarMapView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    @State private var viewport = MapViewportState()
    @GestureState private var gestureMagnification: CGFloat = 1
    @GestureState private var gestureTranslation: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            let attackTargets: [ArmyUnit] = viewModel.attackTargets
            let attackTargetIDs = Set(attackTargets.map(\.id))
            let enemyIntentSummaries = viewModel.enemyIntentSummaries
            let enemyIntentOverlays = viewModel.enemyIntentMapOverlays(for: enemyIntentSummaries)
            let enemyIntentsByUnit = Dictionary(uniqueKeysWithValues: enemyIntentSummaries.map { ($0.unit.id, $0) })
            let enemyIntentDestinations = viewModel.enemyIntentDestinationOverlays(for: enemyIntentOverlays)
            let enemyIntentTargets = viewModel.enemyIntentTargetOverlays(for: enemyIntentOverlays)
            let enemyCommanderThreatOverlay = viewModel.activeEnemyCommanderThreatMapOverlay
            let enemyCommanderThreatOverlaysByPosition = viewModel.enemyCommanderThreatOverlaysByPosition
            let enemyCommanderThreatFocusReadout = viewModel.activeEnemyCommanderThreatFocusReadout
            let tacticalRecommendation = viewModel.selectedTacticalRecommendationSummary
            let tacticalRecommendationPathPositions = viewModel.selectedTacticalRecommendationPathPositions
            let tacticalRecommendationTargetPosition = viewModel.selectedTacticalRecommendationTargetPosition
            let maneuverOptionOverlays = viewModel.maneuverOptionOverlaysByPosition
            let battleObjectiveOverlay = viewModel.primaryBattleObjectiveMapOverlay
            let battleObjectiveOverlays = viewModel.battleObjectiveOverlaysByPosition
            let activeBattleObjectiveStageRole = viewModel.activeBattleObjectiveStageRole
            let countermeasureOverlay = viewModel.activeCountermeasureMapOverlay
            let countermeasureOverlays = viewModel.activeCountermeasureOverlaysByPosition
            let countermeasureContext = viewModel.activeCountermeasureCommandContextReadout
            let reconHUD = viewModel.mapReconPerspectiveHUDReadout
            let engagementLoop = viewModel.primaryEnemyEngagementLoopReadout
            let selectedPosition = viewModel.focusedPosition
            let selectedAttackSourceID = viewModel.selectedCombatForecast?.attacker.id
            let displayContext = viewModel.battleDisplayContextReadout
            let hasFocusReadout = displayContext.mode == .attackLock ||
                displayContext.mode == .countermeasureFocus || displayContext.mode == .enemyCommanderFocus
            let metrics = HexMetrics(
                mapWidth: viewModel.state.width,
                mapHeight: viewModel.state.height,
                container: proxy.size,
                topClearance: hasFocusReadout ? (proxy.size.width < 620 ? 140 : 112) : 0
            )
            // One pathfinding read per map update, shared by every tile.
            let reachablePositions: Set<Position> = displayContext.mode == .unitExecution
                ? viewModel.reachablePositions : []
            let skillRangePositions = displayContext.mode == .unitExecution
                ? viewModel.selectedGeneralSkillRangePositions : []
            let skillTargetPositions = displayContext.mode == .unitExecution
                ? viewModel.selectedGeneralSkillTargetPositions : []
            let skillTargetUnitIDs = displayContext.mode == .unitExecution
                ? viewModel.selectedGeneralSkillTargetUnitIDs : []
            let skillTargetCityIDs = displayContext.mode == .unitExecution
                ? viewModel.selectedGeneralSkillTargetCityIDs : []
            let threatHeatOverlaysByPosition = viewModel.threatHeatZoneOverlaysByPosition
            let mapControlSummaries = Dictionary(uniqueKeysWithValues: viewModel.mapControlSummaries.map { ($0.position, $0) })
            let mapControlOverlayPositions = viewModel.mapControlOverlayPositions
            let overlayPresentation = MapOverlayPresentation(
                perspective: viewModel.selectedMapReconPerspective,
                context: displayContext
            )
            let interactiveViewport = viewport.applying(
                magnification: gestureMagnification,
                translation: gestureTranslation,
                in: proxy.size
            )
            let terrainGeometry = MapTerrainGeometry(tiles: viewModel.state.tiles, metrics: metrics)
            let terrainContours = terrainGeometry.contours(in: proxy.size)

            ZStack {
                ZStack {
                    MapBackdropView()
                        .zIndex(-2)

                    MapTerrainSurfaceView(tiles: viewModel.state.tiles, metrics: metrics, contours: terrainContours)
                        .zIndex(-1)

                    MapFogOfWarEdgeView()
                        .zIndex(0.6)

                    MapCartographyGridView(metrics: metrics)
                        .opacity(0.18)
                        .zIndex(0.35)

                    CoastlineLayerView(contours: terrainContours, metrics: metrics)
                        .zIndex(0.5)

                    if overlayPresentation.enemyRouteOpacity > 0 {
                        EnemyIntentRouteLayerView(overlays: enemyIntentOverlays, metrics: metrics)
                            .opacity(overlayPresentation.enemyRouteOpacity)
                            .allowsHitTesting(false)
                            .zIndex(1)
                    }

                    if let enemyCommanderThreatOverlay,
                       overlayPresentation.showsEnemyCommanderThreatDetails {
                        EnemyCommanderThreatRouteLayerView(
                            overlay: enemyCommanderThreatOverlay,
                            metrics: metrics
                        )
                        .opacity(overlayPresentation.enemyCommanderThreatOpacity)
                        .allowsHitTesting(false)
                        .zIndex(2.15)
                    }

                    if let tacticalRecommendation,
                       displayContext.mode == .unitExecution {
                        TacticalRecommendationRouteLayerView(summary: tacticalRecommendation, metrics: metrics)
                            .opacity(overlayPresentation.tacticalRouteOpacity)
                            .allowsHitTesting(false)
                            .zIndex(2)
                    }

                    if let battleObjectiveOverlay,
                       overlayPresentation.showsBattleObjective {
                        BattleObjectiveRouteLayerView(overlay: battleObjectiveOverlay, metrics: metrics)
                            .allowsHitTesting(false)
                            .zIndex(2.35)
                    }

                    if let countermeasureOverlay,
                       overlayPresentation.showsCountermeasure {
                        CountermeasureRouteLayerView(overlay: countermeasureOverlay, metrics: metrics)
                            .allowsHitTesting(false)
                            .zIndex(2.5)
                    }

                    ForEach(viewModel.state.tiles) { tile in
                        let city = viewModel.state.city(at: tile.position)
                        let unit = viewModel.state.unit(at: tile.position)
                        let center = metrics.center(for: tile.position)
                        HexTileView(
                            tile: tile,
                            city: city,
                            unit: unit,
                            enemyIntent: overlayPresentation.showsEnemyIntentDetails
                                ? unit.flatMap { enemyIntentsByUnit[$0.id] }
                                : nil,
                            enemyIntentDestination: overlayPresentation.showsEnemyIntentDetails
                                ? enemyIntentDestinations[tile.position]
                                : nil,
                            enemyIntentTarget: overlayPresentation.showsEnemyIntentDetails
                                ? enemyIntentTargets[tile.position]
                                : nil,
                            tacticalRecommendation: displayContext.mode == .unitExecution ? tacticalRecommendation : nil,
                            maneuverOption: displayContext.mode == .unitExecution ? maneuverOptionOverlays[tile.position] : nil,
                            battleObjectiveOverlays: overlayPresentation.showsBattleObjective
                                ? battleObjectiveOverlays[tile.position, default: []]
                                : [],
                            focusedBattleObjectiveRole: activeBattleObjectiveStageRole,
                            countermeasureOverlay: overlayPresentation.showsCountermeasure
                                ? countermeasureOverlays[tile.position]
                                : nil,
                            mapControlSummary: overlayPresentation.showsTerrainPressure
                                ? mapControlSummaries[tile.position]
                                : nil,
                            threatHeatZoneSummary: overlayPresentation.showsTerrainPressure
                                ? threatHeatOverlaysByPosition[tile.position]
                                : nil,
                            enemyCommanderThreatOverlays: overlayPresentation.showsEnemyCommanderThreatDetails
                                ? enemyCommanderThreatOverlaysByPosition[tile.position, default: []]
                                : [],
                            enemyCommanderThreatOpacity: overlayPresentation.enemyCommanderThreatOpacity,
                            isMapControlOverlay: overlayPresentation.showsTerrainPressure &&
                                mapControlOverlayPositions.contains(tile.position),
                            isTacticalRecommendationPath: displayContext.mode == .unitExecution && tacticalRecommendationPathPositions.contains(tile.position),
                            isTacticalRecommendationTarget: displayContext.mode == .unitExecution && tacticalRecommendationTargetPosition == tile.position,
                            isSelected: selectedPosition == tile.position,
                            isAttackOrigin: isMapAttackOrigin(
                                unitID: unit?.id,
                                sourceID: selectedAttackSourceID
                            ),
                            isReachable: reachablePositions.contains(tile.position),
                            isAttackTarget: (displayContext.mode == .unitExecution || displayContext.mode == .attackLock) && attackTargets.contains { $0.position == tile.position },
                            isSkillRange: skillRangePositions.contains(tile.position),
                            isSkillTarget: skillTargetPositions.contains(tile.position) ||
                                unit.map { skillTargetUnitIDs.contains($0.id) } == true ||
                                city.map { skillTargetCityIDs.contains($0.id) } == true,
                            scale: metrics.tileScale
                        )
                        .frame(width: metrics.tileWidth, height: metrics.tileHeight)
                        .position(center)
                        .onTapGesture {
                            viewModel.selectTile(tile.position)
                        }
                    }

                    ForEach(attackTargets) { target in
                        let center = metrics.center(for: target.position)
                        AttackTargetButton(
                            preview: viewModel.attackPreview(for: target.id),
                            scale: metrics.actionScale,
                            isFocused: viewModel.isSelectedAttackTarget(target.id),
                            accessibilityLabel: viewModel.attackTargetAccessibilityLabel(for: target),
                            action: {
                                if viewModel.isSelectedAttackTarget(target.id) {
                                    viewModel.cancelSelectedAttackTarget()
                                } else {
                                    viewModel.focusAttackTarget(target.id)
                                }
                            }
                        )
                        .position(x: center.x, y: center.y - metrics.tileHeight * 0.57)
                        .zIndex(4)
                    }

                    ForEach(viewModel.state.units.filter { attackTargetIDs.contains($0.id) }) { target in
                        let center = metrics.center(for: target.position)
                        AttackTargetRing(isFocused: viewModel.isSelectedAttackTarget(target.id))
                            .frame(width: metrics.tileWidth * 0.92, height: metrics.tileHeight * 0.92)
                            .position(center)
                            .allowsHitTesting(false)
                            .zIndex(3)
                    }
                }
                .scaleEffect(interactiveViewport.scale)
                .offset(interactiveViewport.offset)
                .contentShape(Rectangle())
                .simultaneousGesture(mapMagnificationGesture(container: proxy.size))
                .simultaneousGesture(mapDragGesture(container: proxy.size))

                VStack {
                    Spacer(minLength: 62)
                    HStack {
                        MapCameraControlsView(
                            usesHorizontalLayout: proxy.size.height < 390,
                            canFocus: selectedPosition != nil,
                            canZoomIn: viewport.scale < MapViewportState.maximumScale,
                            canZoomOut: viewport.scale > MapViewportState.minimumScale,
                            canReset: !viewport.isDefault,
                            onZoomIn: {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    viewport.setScale(viewport.scale + 0.2, in: proxy.size)
                                }
                            },
                            onZoomOut: {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    viewport.setScale(viewport.scale - 0.2, in: proxy.size)
                                }
                            },
                            onFocus: {
                                guard let selectedPosition else { return }
                                focusViewport(on: selectedPosition, metrics: metrics, container: proxy.size)
                            },
                            onReset: {
                                withAnimation(.easeInOut(duration: 0.22)) {
                                    viewport.reset()
                                }
                            }
                        )
                        Spacer()
                    }
                    Spacer(minLength: 70)
                }
                .padding(.leading, 8)
                .zIndex(5.05)

                VStack {
                    Spacer()
                    HStack {
                        MapScaleBarView(metrics: metrics)
                        Spacer(minLength: 0)
                    }
                    .padding(.leading, 12)
                    .padding(.bottom, proxy.size.width < 620 ? 122 : 76)
                }
                .allowsHitTesting(false)
                .zIndex(4.9)

                VStack {
                    HStack {
                        BattlefieldStatusRibbonView(isCompact: proxy.size.width < 620)
                            .frame(
                                width: proxy.size.width < 620
                                    ? max(80, proxy.size.width - 250)
                                    : max(180, min(proxy.size.width - 250, 520)),
                                alignment: .leading
                            )
                            .clipped()
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    Spacer()
                }
                .allowsHitTesting(false)
                .zIndex(5)

                if let forecast = viewModel.selectedCombatForecast {
                    VStack {
                        HStack {
                            AttackLockMapReadoutView(forecast: forecast)
                                .frame(maxWidth: proxy.size.width - 20, alignment: .leading)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 56)
                        Spacer()
                    }
                    .zIndex(5.15)
                }

                if viewModel.selectedCombatForecast == nil,
                   let countermeasureContext,
                   countermeasureContext.isFocused {
                    VStack {
                        HStack {
                            CountermeasureCommandContextMapReadoutView(context: countermeasureContext)
                                .frame(maxWidth: proxy.size.width - 20, alignment: .leading)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 56)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                    .zIndex(5.16)
                    .accessibilityIdentifier(countermeasureContext.automationIdentifier)
                }

                if viewModel.selectedCombatForecast == nil,
                   countermeasureContext?.isFocused != true,
                   viewModel.focusedEnemyCommanderThreatID != nil,
                   let enemyCommanderThreatFocusReadout {
                    VStack {
                        HStack {
                            EnemyCommanderThreatFocusMapReadoutView(
                                readout: enemyCommanderThreatFocusReadout,
                                isCompact: proxy.size.width < 620
                            )
                                .frame(maxWidth: proxy.size.width - 20, alignment: .leading)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 56)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                    .zIndex(5.15)
                }

                VStack {
                    Spacer()
                    MapIntelligenceDockView(
                        readout: reconHUD,
                        engagementLoop: displayContext.mode == .baselineRecon ? engagementLoop : nil,
                        legendItems: viewModel.activeMapOverlayLegendItems,
                        displayContext: displayContext,
                        usesTwoRows: proxy.size.width < 620,
                        onSelect: viewModel.selectMapReconPerspective
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
                .zIndex(5.1)
            }
            .onChange(of: selectedPosition) { _, newPosition in
                guard let newPosition else { return }
                focusViewport(on: newPosition, metrics: metrics, container: proxy.size)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private func mapMagnificationGesture(container: CGSize) -> some Gesture {
        MagnificationGesture()
            .updating($gestureMagnification) { value, state, _ in
                state = value
            }
            .onEnded { value in
                viewport.setScale(viewport.scale * value, in: container)
            }
    }

    private func mapDragGesture(container: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($gestureTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                viewport.pan(by: value.translation, in: container)
            }
    }

    private func focusViewport(on position: Position, metrics: HexMetrics, container: CGSize) {
        let workingCenter = CGPoint(x: container.width / 2, y: max(58, (container.height - 66) / 2))
        withAnimation(.easeInOut(duration: 0.28)) {
            viewport.focus(
                on: metrics.center(for: position),
                in: container,
                viewportCenter: workingCenter
            )
        }
    }
}

struct CountermeasureCommandContextMapReadoutView: View {
    var context: CountermeasureCommandContextReadout

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: context.kind.systemImage)
                .font(.caption.weight(.black))
                .foregroundStyle(context.priority.tintColor)
                .frame(width: 24, height: 24)
                .background(context.priority.tintColor.opacity(0.14))
                .clipShape(.rect(cornerRadius: 5))

            VStack(alignment: .leading, spacing: 1) {
                Text("\(context.focusStateLabel) · \(context.responseUnitLabel)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.60)
                Text(context.commandCueLabel)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white.opacity(0.66))
                    .lineLimit(2)
                    .minimumScaleFactor(0.58)
                Text("\(context.nextStepLabel) · \(context.commandAvailabilityLabel)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(context.priority.tintColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.58)
            }
            .layoutPriority(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background {
            LinearGradient(
                colors: [BattlePalette.panelRaised.opacity(0.96), .black.opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(.rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(context.priority.tintColor.opacity(0.54), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(context.userFacingAccessibilityLabel)
        .accessibilityIdentifier(context.automationIdentifier)
    }
}

struct AttackLockMapReadoutView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    var forecast: SelectedCombatForecast

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "scope")
                .font(.caption.weight(.black))
                .foregroundStyle(.yellow)
                .frame(width: 24, height: 24)
                .background(.yellow.opacity(0.14))
                .clipShape(.rect(cornerRadius: 5))

            VStack(alignment: .leading, spacing: 1) {
                Text("已锁定 · \(forecast.identityChainLabel)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.64)
                Text("\(forecast.positionChainLabel) · \(forecast.outcomeLabel)")
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white.opacity(0.64))
                    .lineLimit(1)
                    .minimumScaleFactor(0.64)
            }
            .layoutPriority(1)

            Button("取消", systemImage: "xmark.circle") {
                viewModel.cancelSelectedAttackTarget()
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .fixedSize(horizontal: true, vertical: false)
            .frame(minWidth: 60, minHeight: 44)
            .background(.black.opacity(0.30))
            .clipShape(.rect(cornerRadius: 6))
            .contentShape(Rectangle())
            .layoutPriority(2)
            .accessibilityLabel(forecast.cancelAccessibilityLabel)
            .accessibilityHint("清除目标锁定，不会结算攻击")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.black.opacity(0.72))
        .clipShape(.rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color.yellow.opacity(0.60), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(forecast.accessibilityLabel)
    }
}

struct EnemyCommanderThreatFocusMapReadoutView: View {
    var readout: EnemyCommanderThreatFocusReadout
    var isCompact = false

    var body: some View {
        HStack(alignment: isCompact ? .top : .center, spacing: 8) {
            Image(systemName: readout.skillSymbol)
                .font(.caption.weight(.black))
                .foregroundStyle(readout.isFocused ? .orange : .white.opacity(0.80))
                .frame(width: 24, height: 24)
                .background(readout.isFocused ? .orange.opacity(0.16) : .white.opacity(0.10))
                .clipShape(.rect(cornerRadius: 5))

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(readout.mapHeadlineLabel)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .layoutPriority(1)

                    if isCompact {
                        Spacer(minLength: 0)
                        statusBadge
                    }
                }

                Text(isCompact ? readout.mapSpatialLabel : "\(readout.skillName) · 目标\(readout.targetLabel) · \(readout.routeLabel)")
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white.opacity(0.66))
                    .lineLimit(isCompact ? 1 : 2)
                    .minimumScaleFactor(isCompact ? 0.72 : 0.58)
            }
            .layoutPriority(1)

            if !isCompact {
                statusBadge
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.black.opacity(0.72))
        .clipShape(.rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke((readout.isFocused ? Color.orange : Color.white).opacity(0.56), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(readout.accessibilityLabel)
        .accessibilityHint("地图焦点只用于查看敌将威胁，不会执行敌将命令")
    }

    private var statusBadge: some View {
        Text(readout.mapStatusLabel)
            .font(.caption2.weight(.black))
            .foregroundStyle(.white.opacity(0.82))
            .padding(.horizontal, 5)
            .frame(minWidth: 48, minHeight: 22)
            .background(.black.opacity(0.28))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(2)
    }
}

struct MapCameraControlsView: View {
    var usesHorizontalLayout: Bool
    var canFocus: Bool
    var canZoomIn: Bool
    var canZoomOut: Bool
    var canReset: Bool
    var onZoomIn: () -> Void
    var onZoomOut: () -> Void
    var onFocus: () -> Void
    var onReset: () -> Void

    var body: some View {
        Group {
            if usesHorizontalLayout {
                HStack(spacing: 2) {
                    cameraButtons
                }
            } else {
                VStack(spacing: 2) {
                    cameraButtons
                }
            }
        }
        .padding(2)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var cameraButtons: some View {
        cameraButton("放大战略地图", symbol: "plus.magnifyingglass", enabled: canZoomIn, action: onZoomIn)
        cameraButton("缩小战略地图", symbol: "minus.magnifyingglass", enabled: canZoomOut, action: onZoomOut)
        cameraButton("聚焦当前选择", symbol: "scope", enabled: canFocus, action: onFocus)
        cameraButton("复位地图镜头", symbol: "arrow.counterclockwise", enabled: canReset, action: onReset)
    }

    private func cameraButton(
        _ label: String,
        symbol: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(label, systemImage: symbol, action: action)
            .labelStyle(.iconOnly)
            .font(.caption.weight(.black))
            .buttonStyle(BattleMetalButtonStyle())
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .disabled(!enabled)
            .opacity(enabled ? 1 : 0.42)
            .help(label)
            .accessibilityLabel(label)
            .accessibilityHint("地图镜头操作，不会改变战局命令")
    }
}

struct AttackTargetButton: View {
    var preview: CombatPreview?
    var scale: CGFloat
    var isFocused: Bool
    var accessibilityLabel: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isFocused ? Color(red: 0.90, green: 0.60, blue: 0.08) : Color(red: 0.78, green: 0.08, blue: 0.05))
                    Circle()
                        .stroke(.white.opacity(0.92), lineWidth: 2)
                    Image(systemName: isFocused ? "xmark.circle.fill" : "bolt.fill")
                        .font(.system(size: 15 * scale, weight: .black))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                        .offset(y: preview == nil ? 0 : -3 * scale)

                    if let preview {
                        Text(isFocused ? "取消" : (preview.defeatsDefender ? "破" : "-\(preview.damage)"))
                            .font(.system(size: 8 * scale, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                            .offset(y: 9 * scale)
                    }
                }
                .frame(width: 36 * scale, height: 36 * scale)
                .shadow(color: (isFocused ? Color.yellow : Color.red).opacity(0.65), radius: 8, y: 2)

                TrianglePointer()
                    .fill(isFocused ? Color(red: 0.90, green: 0.60, blue: 0.08) : Color(red: 0.78, green: 0.08, blue: 0.05))
                    .frame(width: 13 * scale, height: 7 * scale)
                    .offset(y: -1)
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isFocused ? "点击取消锁定，保留当前攻击者选择" : "点击锁定目标并查看攻击预演")
        .accessibilityAddTraits(isFocused ? .isSelected : AccessibilityTraits())
        .accessibilityHidden(isFocused)
    }
}

struct BattlefieldStatusRibbonView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    var isCompact = false

    var body: some View {
        HStack(spacing: 6) {
            if isCompact {
                Image(systemName: "flag.fill")
                    .foregroundStyle(viewModel.state.activeFaction.factionColor)
                Text(viewModel.state.activeFaction.displayName)
                    .font(.caption.weight(.bold))
                Label("\(viewModel.hostileUnitCount)", systemImage: "flame.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BattlePalette.brassBright)
            } else {
                Label(viewModel.campaignStatusTitle, systemImage: viewModel.campaignStatus.kind.systemImage)
                    .font(.caption.weight(.black))
                    .foregroundStyle(viewModel.campaignStatus.kind.tintColor)
                    .lineLimit(1)

                Divider()
                    .frame(height: 20)
                    .overlay {
                        Color.white.opacity(0.14)
                    }

                TacticalChipView(
                    symbol: "flag.fill",
                    label: "行动",
                    value: viewModel.state.activeFaction.displayName,
                    tint: viewModel.state.activeFaction.factionColor,
                    compact: true
                )

                TacticalChipView(
                    symbol: "flame.fill",
                    label: "敌军",
                    value: "\(viewModel.hostileUnitCount)",
                    tint: .red,
                    compact: true
                )

                TacticalChipView(
                    symbol: viewModel.selectedMapReconPerspective.systemImage,
                    label: "侦察",
                    value: viewModel.mapReconPerspectiveHUDReadout.statusLabel,
                    tint: viewModel.selectedMapReconPerspective.mapReconTint,
                    compact: true,
                    accessibilityLabel: viewModel.mapReconPerspectiveHUDReadout.accessibilityLabel
                )
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            LinearGradient(
                colors: [BattlePalette.panelRaised.opacity(0.94), BattlePalette.romanRed.opacity(0.42), .black.opacity(0.70)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .clipShape(.rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(BattlePalette.parchment.opacity(0.42), lineWidth: 1)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(BattlePalette.brassBright.opacity(0.62))
                .frame(height: 1)
                .padding(.horizontal, 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(viewModel.campaignStatusTitle)，\(viewModel.state.activeFaction.displayName)行动，敌军\(viewModel.hostileUnitCount)，\(viewModel.mapReconPerspectiveHUDReadout.statusLabel)")
    }
}

struct TacticalStatusStripView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 7) {
                    tacticalChips(compact: false)
                }
                .fixedSize(horizontal: true, vertical: false)

                HStack(spacing: 6) {
                    tacticalChips(compact: true)
                }
                .fixedSize(horizontal: true, vertical: false)
            }

            HStack(spacing: 6) {
                Image(systemName: viewModel.campaignStatus.kind.systemImage)
                    .foregroundStyle(viewModel.campaignStatus.kind.tintColor)
                Text(viewModel.campaignStatusTitle)
                    .font(.caption.weight(.heavy))
                Text(viewModel.isCampaignOver ? viewModel.campaignStatusDetail : (viewModel.campaignStatus.progressText ?? viewModel.campaignStatusDetail))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.70))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.black.opacity(0.38))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.84, green: 0.66, blue: 0.32).opacity(0.34), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func tacticalChips(compact: Bool) -> some View {
        TacticalChipView(
            symbol: "flag.fill",
            label: "行动",
            value: viewModel.state.activeFaction.displayName,
            tint: viewModel.state.activeFaction.factionColor,
            compact: compact
        )
        TacticalChipView(
            symbol: "shield.lefthalf.filled",
            label: "待命",
            value: "\(viewModel.readyRomanUnitCount)",
            tint: Color(red: 0.84, green: 0.66, blue: 0.32),
            compact: compact
        )

        if let tile = viewModel.selectedTile {
            TacticalChipView(
                symbol: tile.terrain.systemImage,
                label: "地形",
                value: tile.terrain.displayName,
                tint: tile.terrain.accentColor,
                compact: compact
            )
        }

        TacticalChipView(
            symbol: "flame.fill",
            label: "敌军",
            value: "\(viewModel.hostileUnitCount)",
            tint: .red,
            compact: compact
        )

        if let intent = viewModel.primaryEnemyIntent {
            TacticalChipView(
                symbol: intent.intent.kind.systemImage,
                label: "敌情",
                value: intent.shortTitle,
                tint: intent.intent.kind.tintColor,
                compact: compact
            )
        }

        if let plan = viewModel.primaryAIOperationalPlanSummary {
            TacticalChipView(
                symbol: plan.kind.systemImage,
                label: "计划",
                value: plan.compactTitle,
                tint: plan.kind.tintColor,
                compact: compact,
                accessibilityLabel: plan.accessibilityLabel
            )
        }

        if let commanderThreat = viewModel.activeEnemyCommanderThreatSummary {
            TacticalChipView(
                symbol: commanderThreat.trait.systemImage,
                label: "敌将",
                value: commanderThreat.compactTitle,
                tint: commanderThreat.level.tintColor,
                compact: compact,
                accessibilityLabel: commanderThreat.accessibilityLabel,
                allowsValueWrapping: true
            )
        }

        if let countermeasure = viewModel.primaryCountermeasureSummary {
            TacticalChipView(
                symbol: countermeasure.kind.systemImage,
                label: "反制",
                value: countermeasure.compactTitle,
                tint: countermeasure.priority.tintColor,
                compact: compact,
                accessibilityLabel: countermeasure.accessibilityLabel
            )
        }

        if let advance = viewModel.primaryCampaignAdvanceReadout {
            TacticalChipView(
                symbol: "map.fill",
                label: "推进",
                value: compact ? advance.statusLabel : advance.missionTitle,
                tint: Color(red: 0.84, green: 0.66, blue: 0.32),
                compact: compact,
                accessibilityLabel: advance.accessibilityLabel
            )
        }

        TacticalChipView(
            symbol: viewModel.selectedMapReconPerspective.systemImage,
            label: "侦察",
            value: compact ? viewModel.selectedMapReconPerspective.shortLabel : viewModel.mapReconPerspectiveHUDReadout.selectorLabel,
            tint: reconTint(for: viewModel.selectedMapReconPerspective),
            compact: compact,
            accessibilityLabel: viewModel.mapReconPerspectiveHUDReadout.accessibilityLabel
        )

        if let pressure = viewModel.primaryFrontlinePressureSummary {
            TacticalChipView(
                symbol: pressure.level.systemImage,
                label: "战线",
                value: pressure.compactTitle,
                tint: pressure.level.tintColor,
                compact: compact
            )
        }

        if let heat = viewModel.primaryThreatHeatZoneSummary {
            TacticalChipView(
                symbol: heat.threatLevel.systemImage,
                label: "热区",
                value: heat.compactTitle,
                tint: heat.threatLevel.tintColor,
                compact: compact
            )
        }

        if let synergy = viewModel.primaryCommanderSynergySummary {
            TacticalChipView(
                symbol: synergy.kind.systemImage,
                label: "将令",
                value: synergy.compactTitle,
                tint: synergy.kind.tintColor,
                compact: compact,
                accessibilityLabel: synergy.accessibilityLabel
            )
        }

        if let focus = viewModel.primaryBattlefieldFocusSummary {
            TacticalChipView(
                symbol: focus.kind.systemImage,
                label: "焦点",
                value: focus.compactTitle,
                tint: focus.severity.tintColor,
                compact: compact
            )
        }

        if let formation = viewModel.primaryLegionFormationSummary {
            TacticalChipView(
                symbol: formation.report.readiness.systemImage,
                label: "军团",
                value: formation.compactTitle,
                tint: formation.report.readiness.tintColor,
                compact: compact
            )
        }

        if let development = viewModel.primaryUnitDevelopmentRecommendationSummary {
            TacticalChipView(
                symbol: development.kind.systemImage,
                label: "成长",
                value: development.compactTitle,
                tint: development.priority.tintColor,
                compact: compact,
                accessibilityLabel: development.accessibilityLabel
            )
        }

        if let recommendation = viewModel.selectedTacticalRecommendationSummary {
            TacticalChipView(
                symbol: recommendation.kind.systemImage,
                label: "军议",
                value: recommendation.kindLabel,
                tint: recommendation.kind.tintColor,
                compact: compact
            )
        }

        if let maneuver = viewModel.primaryManeuverOptionSummary {
            TacticalChipView(
                symbol: maneuver.kind.systemImage,
                label: "机动",
                value: maneuver.kindLabel,
                tint: maneuver.kind.tintColor,
                compact: compact,
                accessibilityLabel: maneuver.accessibilityLabel
            )
        }
    }

    private func reconTint(for kind: MapReconPerspectiveKind) -> Color {
        switch kind {
        case .enemyIntent:
            return .red
        case .countermeasure:
            return .cyan
        case .objective:
            return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .terrainPressure:
            return Color(red: 0.96, green: 0.58, blue: 0.24)
        }
    }
}

struct MapIntelligenceDockView: View {
    var readout: MapReconPerspectiveHUDReadout
    var engagementLoop: EnemyEngagementLoopReadout?
    var legendItems: [MapOverlayLegendItem]
    var displayContext: BattleDisplayContextReadout
    var usesTwoRows: Bool
    var onSelect: (MapReconPerspectiveKind) -> Void

    var body: some View {
        let filteredLegendItems = legendItems.filter { displayContext.visibleLegendKinds.contains($0.kind) }
        Group {
            if usesTwoRows {
                VStack(spacing: 5) {
                    HStack(spacing: 6) {
                        MapReconModeSelectorView(readout: readout, onSelect: onSelect)
                        Spacer(minLength: 0)
                        MapReconContextBadgeView(readout: readout)
                    }

                    HStack(spacing: 6) {
                        if let engagementLoop {
                            EnemyEngagementCompactBadgeView(readout: engagementLoop)
                        }
                        MapOverlayLegendView(
                            items: filteredLegendItems,
                            perspective: readout.selectedKind,
                            compact: true
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                HStack(spacing: 7) {
                    MapReconModeSelectorView(readout: readout, onSelect: onSelect)
                    MapReconContextBadgeView(readout: readout)
                    if let engagementLoop,
                       readout.selectedKind == .enemyIntent || readout.selectedKind == .countermeasure {
                        EnemyEngagementCompactBadgeView(readout: engagementLoop)
                    }
                    MapOverlayLegendView(
                        items: filteredLegendItems,
                        perspective: readout.selectedKind,
                        compact: true
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(6)
        .background(.black.opacity(0.72))
        .clipShape(.rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(BattlePalette.brass.opacity(0.42), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.28), radius: 5, y: 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(displayContext.title)，\(displayContext.statusLabel)，\(readout.selectorLabel)")
    }
}

struct MapReconModeSelectorView: View {
    var readout: MapReconPerspectiveHUDReadout
    var onSelect: (MapReconPerspectiveKind) -> Void

    var body: some View {
        HStack(spacing: 3) {
            ForEach(readout.availableKinds) { kind in
                Button {
                    onSelect(kind)
                } label: {
                    VStack(spacing: 1) {
                        Image(systemName: kind.systemImage)
                            .font(.caption.weight(.black))
                        Text(kind.shortLabel)
                            .font(.caption2.weight(.bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(readout.selectedKind == kind ? .black : .white.opacity(0.76))
                    .frame(width: 44, height: 44)
                    .background(
                        readout.selectedKind == kind
                            ? kind.mapReconTint
                            : kind.mapReconTint.opacity(0.16)
                    )
                    .clipShape(.rect(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                readout.selectedKind == kind ? .white.opacity(0.82) : .white.opacity(0.08),
                                lineWidth: readout.selectedKind == kind ? 1.5 : 1
                            )
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("切换\(kind.displayName)侦察")
                .accessibilityValue(readout.selectedKind == kind ? "已选择" : "未选择")
            }
        }
    }
}

struct MapReconContextBadgeView: View {
    var readout: MapReconPerspectiveHUDReadout

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: readout.selectedKind.systemImage)
                .foregroundStyle(readout.selectedKind.mapReconTint)
            VStack(alignment: .leading, spacing: 1) {
                Text(readout.selectedKind.displayName)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
                Text(readout.statusLabel)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
        }
        .padding(.horizontal, 7)
        .frame(minWidth: 96, minHeight: 44, alignment: .leading)
        .background(readout.selectedKind.mapReconTint.opacity(0.13))
        .clipShape(.rect(cornerRadius: 6))
        .accessibilityLabel("\(readout.selectedKind.displayName)，\(readout.statusLabel)")
    }
}

struct EnemyEngagementCompactBadgeView: View {
    var readout: EnemyEngagementLoopReadout

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(Color(red: 0.96, green: 0.42, blue: 0.22))
            VStack(alignment: .leading, spacing: 1) {
                Text(readout.statusLabel)
                    .font(.caption.weight(.black))
                    .lineLimit(1)
                Text(readout.riskLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.64))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .frame(minWidth: 108, minHeight: 44, alignment: .leading)
        .background(Color(red: 0.96, green: 0.42, blue: 0.22).opacity(0.13))
        .clipShape(.rect(cornerRadius: 6))
        .accessibilityLabel(readout.accessibilityLabel)
    }
}

struct MapReconPerspectiveHUDView: View {
    var readout: MapReconPerspectiveHUDReadout
    var onSelect: (MapReconPerspectiveKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 7) {
                header
                selector
                Spacer(minLength: 0)
                statusPill
            }

            HStack(spacing: 5) {
                signalStrip(limit: 3)
                Text(readout.compactLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                Spacer(minLength: 0)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .frame(minHeight: 34)
        .background(.black.opacity(0.48))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(tint(for: readout.selectedKind).opacity(0.42), lineWidth: 1)
        }
        .accessibilityLabel(readout.accessibilityLabel)
    }

    private var header: some View {
        HStack(spacing: 5) {
            Image(systemName: "binoculars.fill")
                .foregroundStyle(tint(for: readout.selectedKind))
                .accessibilityHidden(true)
            Text("侦察")
                .font(.caption2.weight(.black))
                .foregroundStyle(.white.opacity(0.78))
        }
        .lineLimit(1)
    }

    private var selector: some View {
        HStack(spacing: 4) {
            ForEach(readout.availableKinds) { kind in
                MapReconPerspectiveButton(
                    kind: kind,
                    isSelected: readout.selectedKind == kind,
                    tint: tint(for: kind),
                    onSelect: onSelect
                )
            }
        }
    }

    private var statusPill: some View {
        Text(readout.statusLabel)
            .font(.caption2.weight(.black))
            .foregroundStyle(.black.opacity(0.78))
            .lineLimit(1)
            .minimumScaleFactor(0.58)
            .padding(.horizontal, 6)
            .frame(height: 20)
            .background(tint(for: readout.selectedKind))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private func signalStrip(limit: Int) -> some View {
        HStack(spacing: 5) {
            ForEach(Array(readout.signals.prefix(limit))) { signal in
                MapReconPerspectiveSignalPill(
                    symbol: symbol(for: signal.kind),
                    title: signal.title,
                    tint: tint(for: signal.kind)
                )
            }
        }
    }

    private func symbol(for kind: MapReconPerspectiveSignalKind) -> String {
        switch kind {
        case .enemyIntent:
            return "arrow.right.circle.fill"
        case .enemyCommander:
            return "person.crop.circle.badge.exclamationmark"
        case .engagementLoop:
            return "arrow.triangle.2.circlepath"
        case .countermeasure:
            return "scope"
        case .counterCommand:
            return "checkmark.shield.fill"
        case .objectiveChain:
            return "point.topleft.down.curvedto.point.bottomright.up.fill"
        case .objectiveStage:
            return "flag.checkered"
        case .threatHeat:
            return "flame.fill"
        case .mapControl:
            return "shield.fill"
        case .convergence:
            return "link.circle.fill"
        }
    }

    private func tint(for kind: MapReconPerspectiveKind) -> Color {
        switch kind {
        case .enemyIntent:
            return .red
        case .countermeasure:
            return .cyan
        case .objective:
            return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .terrainPressure:
            return Color(red: 0.96, green: 0.58, blue: 0.24)
        }
    }

    private func tint(for kind: MapReconPerspectiveSignalKind) -> Color {
        switch kind {
        case .enemyIntent:
            return .red
        case .enemyCommander:
            return .purple
        case .engagementLoop:
            return Color(red: 0.96, green: 0.42, blue: 0.22)
        case .countermeasure, .counterCommand:
            return .cyan
        case .objectiveChain, .objectiveStage:
            return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .threatHeat:
            return Color(red: 0.96, green: 0.58, blue: 0.24)
        case .mapControl:
            return .green
        case .convergence:
            return .mint
        }
    }
}

struct MapReconPerspectiveButton: View {
    var kind: MapReconPerspectiveKind
    var isSelected: Bool
    var tint: Color
    var onSelect: (MapReconPerspectiveKind) -> Void

    var body: some View {
        Button {
            onSelect(kind)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: kind.systemImage)
                    .font(.caption2.weight(.heavy))
                    .accessibilityHidden(true)
                Text(kind.shortLabel)
                    .font(.caption2.weight(.black))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            .foregroundStyle(isSelected ? .black.opacity(0.82) : .white.opacity(0.72))
            .padding(.horizontal, 6)
            .frame(height: 21)
            .background(isSelected ? tint : tint.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("切换\(kind.displayName)侦察")
    }
}

struct MapReconPerspectiveSignalPill: View {
    var symbol: String
    var title: String
    var tint: Color

    var body: some View {
        ReadoutSignalPill(symbol: symbol, title: title, tint: tint)
    }
}

struct ReadoutSignalPill: View {
    var symbol: String
    var title: String
    var tint: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(title)
                .font(.caption2.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.58)
        }
        .foregroundStyle(.white.opacity(0.72))
        .padding(.horizontal, 5)
        .frame(height: 20)
        .background(tint.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

struct EnemyEngagementLoopHUDView: View {
    var readout: EnemyEngagementLoopReadout

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 7) {
                header
                signalStrip(limit: 5)
                Spacer(minLength: 0)
                statusPill
            }

            HStack(spacing: 6) {
                header
                Text(readout.compactLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                Spacer(minLength: 0)
                statusPill
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .frame(minHeight: 32)
        .background(.black.opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(red: 0.96, green: 0.42, blue: 0.22).opacity(0.34), lineWidth: 1)
        }
        .accessibilityLabel(readout.accessibilityLabel)
    }

    private var header: some View {
        HStack(spacing: 5) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(Color(red: 0.96, green: 0.42, blue: 0.22))
                .accessibilityHidden(true)
            Text("闭环")
                .font(.caption2.weight(.black))
                .foregroundStyle(.white.opacity(0.76))
        }
        .lineLimit(1)
    }

    private var statusPill: some View {
        Text(readout.statusLabel)
            .font(.caption2.weight(.black))
            .foregroundStyle(.black.opacity(0.78))
            .lineLimit(1)
            .minimumScaleFactor(0.58)
            .padding(.horizontal, 6)
            .frame(height: 20)
            .background(Color(red: 0.96, green: 0.42, blue: 0.22))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private func signalStrip(limit: Int) -> some View {
        HStack(spacing: 5) {
            ForEach(Array(readout.signals.prefix(limit))) { signal in
                ReadoutSignalPill(
                    symbol: symbol(for: signal.kind),
                    title: signal.title,
                    tint: tint(for: signal.kind)
                )
            }
        }
    }

    private func symbol(for kind: EnemyEngagementLoopSignalKind) -> String {
        switch kind {
        case .intentRoute:
            return "arrow.right.circle.fill"
        case .frontline:
            return "shield.lefthalf.filled"
        case .enemyCommander:
            return "bolt.shield.fill"
        case .countermeasure:
            return "scope"
        case .counterCommand:
            return "checkmark.shield.fill"
        case .responseCommander:
            return "link.circle.fill"
        case .convergence:
            return "arrow.triangle.2.circlepath"
        }
    }

    private func tint(for kind: EnemyEngagementLoopSignalKind) -> Color {
        switch kind {
        case .intentRoute:
            return .red
        case .frontline:
            return Color(red: 0.96, green: 0.58, blue: 0.24)
        case .enemyCommander:
            return .purple
        case .countermeasure:
            return .cyan
        case .counterCommand:
            return .green
        case .responseCommander:
            return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .convergence:
            return .mint
        }
    }
}

struct TacticalChipView: View {
    var symbol: String
    var label: String
    var value: String
    var tint: Color
    var compact = false
    var accessibilityLabel: String? = nil
    var allowsValueWrapping = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.caption2.weight(.heavy))
                .foregroundStyle(tint)
            if !compact {
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
            }
            Text(value)
                .font(.caption.monospacedDigit().weight(.heavy))
                .lineLimit(allowsValueWrapping ? 2 : 1)
                .minimumScaleFactor(allowsValueWrapping ? 0.62 : 0.7)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: allowsValueWrapping)
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 24)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityLabel(accessibilityLabel ?? "\(label)，\(value)")
    }
}

struct AttackTargetRing: View {
    var isFocused: Bool

    var body: some View {
        ZStack {
            Hexagon()
                .stroke(
                    isFocused ? Color.white.opacity(0.98) : Color.red.opacity(0.95),
                    style: StrokeStyle(lineWidth: isFocused ? 3.5 : 3, lineCap: .round, dash: [7, 5])
                )
            Hexagon()
                .stroke(isFocused ? Color.yellow.opacity(0.92) : Color.yellow.opacity(0.55), lineWidth: isFocused ? 2 : 1)
                .padding(4)
        }
        .shadow(color: (isFocused ? Color.white : Color.red).opacity(0.55), radius: isFocused ? 9 : 6)
        .accessibilityHidden(true)
    }
}

struct BattlefieldRoadSegment: Hashable {
    let start: Position
    let end: Position
}

private struct BattlefieldTerrainVertex: Hashable, Comparable {
    let x: Int
    let y: Int

    static func < (left: Self, right: Self) -> Bool {
        left.y == right.y ? left.x < right.x : left.y < right.y
    }

    func point(using metrics: HexMetrics) -> CGPoint {
        CGPoint(
            x: metrics.origin.x - metrics.tileWidth / 2 + CGFloat(x) * metrics.tileWidth / 2,
            y: metrics.origin.y - metrics.tileHeight / 2 + CGFloat(y) * metrics.tileHeight / 4
        )
    }

    static func vertices(for position: Position) -> [Self] {
        let x = position.x * 2 + (position.y.isMultiple(of: 2) ? 0 : 1)
        let y = position.y * 3
        return [Self(x: x + 1, y: y), Self(x: x + 2, y: y + 1),
                Self(x: x + 2, y: y + 3), Self(x: x + 1, y: y + 4),
                Self(x: x, y: y + 3), Self(x: x, y: y + 1)]
    }
}

private struct BattlefieldTerrainEdge: Hashable {
    let start: BattlefieldTerrainVertex
    let end: BattlefieldTerrainVertex
}

struct BattlefieldTerrainContours {
    let loops: [[CGPoint]]
    let boundaryEdgeCount: Int
    let path: Path

    init(loops: [[CGPoint]], boundaryEdgeCount: Int) {
        self.loops = loops
        self.boundaryEdgeCount = boundaryEdgeCount
        var shoreline = Path()
        for loop in loops where loop.count >= 3 {
            for index in loop.indices {
                let corner = loop[index]
                let previous = loop[(index + loop.count - 1) % loop.count]
                let next = loop[(index + 1) % loop.count]
                let entry = CGPoint(x: corner.x + (previous.x - corner.x) * 0.45,
                                    y: corner.y + (previous.y - corner.y) * 0.45)
                let exit = CGPoint(x: corner.x + (next.x - corner.x) * 0.45,
                                   y: corner.y + (next.y - corner.y) * 0.45)
                if index == 0 { shoreline.move(to: entry) } else { shoreline.addLine(to: entry) }
                shoreline.addQuadCurve(to: exit, control: corner)
            }
            shoreline.closeSubpath()
        }
        path = shoreline
    }
}

/// Pure presentation geometry. The surface and interactive tiles share vertices;
/// roads connect only neighboring road/city cells from the actual scenario.
struct MapTerrainGeometry {
    let tiles: [Tile]
    let metrics: HexMetrics

    func landPath(in size: CGSize) -> Path {
        contours(in: size).path
    }

    func contours(in size: CGSize) -> BattlefieldTerrainContours {
        let terrain = Dictionary(uniqueKeysWithValues: tiles.map { ($0.position, $0.terrain) })
        let lastColumn = tiles.map(\.position.x).max() ?? 0
        let lastRow = tiles.map(\.position.y).max() ?? 0
        let firstSceneryColumn = min(0, Int(floor(-metrics.origin.x / metrics.tileWidth)) - 1)
        let lastSceneryColumn = max(lastColumn, Int(ceil((size.width - metrics.origin.x) / metrics.tileWidth)) + 1)
        let firstSceneryRow = min(0, Int(floor(-metrics.origin.y / (metrics.tileHeight * 0.75))) - 1)
        var edges = Set<BattlefieldTerrainEdge>()
        // Integer lattice keys cancel internal edges without rounding screen
        // coordinates. Opposite winding preserves lakes inside the land path.
        for y in firstSceneryRow...lastRow {
            for x in firstSceneryColumn...lastSceneryColumn {
                let source = Position(x: min(lastColumn, max(0, x)), y: max(0, y))
                guard let sourceTerrain = terrain[source], sourceTerrain != .water else { continue }
                let vertices = BattlefieldTerrainVertex.vertices(for: Position(x: x, y: y))
                for index in vertices.indices {
                    let edge = BattlefieldTerrainEdge(start: vertices[index], end: vertices[(index + 1) % 6])
                    if edges.remove(BattlefieldTerrainEdge(start: edge.end, end: edge.start)) == nil {
                        edges.insert(edge)
                    }
                }
            }
        }
        var outgoing = Dictionary(uniqueKeysWithValues: edges.map { ($0.start, $0.end) })
        var loops: [[CGPoint]] = []
        for start in outgoing.keys.sorted() where outgoing[start] != nil {
            var current = start
            var loop: [CGPoint] = []
            repeat {
                loop.append(current.point(using: metrics))
                guard let next = outgoing.removeValue(forKey: current) else { break }
                current = next
            } while current != start
            if current == start && loop.count >= 3 { loops.append(loop) }
        }
        return BattlefieldTerrainContours(loops: loops, boundaryEdgeCount: edges.count)
    }

    var roadSegments: [BattlefieldRoadSegment] {
        let terrain = Dictionary(uniqueKeysWithValues: tiles.map { ($0.position, $0.terrain) })
        let width = (tiles.map(\.position.x).max() ?? -1) + 1
        let height = (tiles.map(\.position.y).max() ?? -1) + 1
        return tiles.filter { $0.terrain == .road || $0.terrain == .city }.flatMap { tile -> [BattlefieldRoadSegment] in
            tile.position.neighbors(width: width, height: height).compactMap { neighbor -> BattlefieldRoadSegment? in
                guard terrain[neighbor] == .road || terrain[neighbor] == .city,
                      tile.position.y < neighbor.y ||
                        tile.position.y == neighbor.y && tile.position.x < neighbor.x else {
                    return nil
                }
                return BattlefieldRoadSegment(start: tile.position, end: neighbor)
            }
        }
    }

    var roadPath: Path {
        var path = Path()
        for road in roadSegments {
            let start = metrics.center(for: road.start)
            let end = metrics.center(for: road.end)
            path.move(to: start)
            path.addQuadCurve(
                to: end,
                control: CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2 - metrics.tileHeight * 0.06)
            )
        }
        return path
    }
}

struct MapTerrainSurfaceView: View {
    var tiles: [Tile]
    var metrics: HexMetrics
    var contours: BattlefieldTerrainContours

    var body: some View {
        Canvas { context, size in
            let geometry = MapTerrainGeometry(tiles: tiles, metrics: metrics)
            let land = contours.path
            drawSea(in: &context, size: size)
            context.fill(land, with: .linearGradient(
                Gradient(colors: [Color(red: 0.46, green: 0.51, blue: 0.35), Color(red: 0.34, green: 0.42, blue: 0.30)]),
                startPoint: .zero, endPoint: CGPoint(x: size.width * 0.3, y: size.height)
            ))
            context.drawLayer { ground in
                ground.clip(to: land)
                drawRelief(in: &ground, size: size)
                let roads = geometry.roadPath
                let roadWidth = max(2.2, metrics.tileWidth * 0.07)
                ground.stroke(roads, with: .color(Color(red: 0.28, green: 0.29, blue: 0.20).opacity(0.50)),
                              style: StrokeStyle(lineWidth: roadWidth + 1.8, lineCap: .round, lineJoin: .round))
                ground.stroke(roads, with: .color(Color(red: 0.72, green: 0.65, blue: 0.45)),
                              style: StrokeStyle(lineWidth: roadWidth, lineCap: .round, lineJoin: .round))
                ground.stroke(roads, with: .color(BattlePalette.ivory.opacity(0.26)),
                              style: StrokeStyle(lineWidth: max(0.5, roadWidth * 0.22), lineCap: .round))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drawSea(in context: inout GraphicsContext, size: CGSize) {
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
            Gradient(colors: [Color(red: 0.30, green: 0.43, blue: 0.44), Color(red: 0.19, green: 0.33, blue: 0.38)]),
            startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)
        ))
        context.stroke(contours.path, with: .color(Color(red: 0.53, green: 0.66, blue: 0.59).opacity(0.20)),
                       style: StrokeStyle(lineWidth: metrics.tileWidth * 0.30, lineCap: .round, lineJoin: .round))
        context.stroke(contours.path, with: .color(Color(red: 0.59, green: 0.70, blue: 0.64).opacity(0.18)),
                       style: StrokeStyle(lineWidth: metrics.tileWidth * 0.14, lineCap: .round, lineJoin: .round))
        for row in 0..<Int(size.height / 18) + 1 {
            let y = CGFloat(row) * 18 + CGFloat((row * 11) % 13)
            let phase = CGFloat((row * 17) % 29)
            for column in 0..<Int(size.width / 62) + 1 {
                let x = CGFloat(column) * 62 + phase + CGFloat((row * 7 + column * 13) % 23)
                var wave = Path()
                wave.move(to: CGPoint(x: x, y: y))
                wave.addCurve(to: CGPoint(x: x + 38, y: y - 1),
                              control1: CGPoint(x: x + 12, y: y - 3), control2: CGPoint(x: x + 26, y: y + 2))
                context.stroke(wave, with: .color(BattlePalette.ivory.opacity(row.isMultiple(of: 3) ? 0.085 : 0.035)), lineWidth: 0.7)
            }
        }
    }

    private func drawRelief(in context: inout GraphicsContext, size: CGSize) {
        drawGroundVariation(in: &context, size: size)
        for tile in tiles where tile.terrain != .water {
            let center = metrics.center(for: tile.position)
            let tint: Color
            switch tile.terrain {
            case .forest: tint = Color(red: 0.18, green: 0.32, blue: 0.23).opacity(0.56)
            case .hills: tint = Color(red: 0.61, green: 0.55, blue: 0.39).opacity(0.68)
            case .city, .road: tint = Color(red: 0.66, green: 0.60, blue: 0.42).opacity(0.25)
            default: tint = Color(red: 0.65, green: 0.64, blue: 0.39).opacity(0.12)
            }
            let radius = metrics.tileWidth * 0.78
            context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                               width: radius * 2, height: radius * 2)),
                         with: .radialGradient(Gradient(colors: [tint, .clear, .clear]), center: center,
                                               startRadius: 0, endRadius: radius))
        }
        for row in 0..<Int(size.height / 12) + 1 {
            for column in 0..<Int(size.width / 14) + 1 {
                let seed = (row * 37 + column * 19) % 43
                let point = CGPoint(x: CGFloat(column * 14 + seed % 9), y: CGFloat(row * 12 + seed % 7))
                let color = seed.isMultiple(of: 3) ? BattlePalette.ivory.opacity(0.10) : Color.black.opacity(0.065)
                context.fill(Path(ellipseIn: CGRect(x: point.x, y: point.y, width: CGFloat(1 + seed % 3), height: 0.8)), with: .color(color))
                if seed.isMultiple(of: 7) {
                    var grass = Path()
                    grass.move(to: point)
                    grass.addLine(to: CGPoint(x: point.x - 1.5, y: point.y - 2.4))
                    context.stroke(grass, with: .color(Color(red: 0.26, green: 0.35, blue: 0.22).opacity(0.25)), lineWidth: 0.6)
                }
            }
        }
    }

    private func drawGroundVariation(in context: inout GraphicsContext, size: CGSize) {
        for row in 0..<Int(size.height / 36) + 1 {
            for column in 0..<Int(size.width / 48) + 1 {
                let seed = (row * 97 + column * 61 + row * column * 7) % 101
                let center = CGPoint(x: CGFloat(column * 48 + seed % 37), y: CGFloat(row * 36 + seed % 29))
                let radius = CGFloat(24 + seed % 46)
                let tint = seed.isMultiple(of: 3)
                    ? Color(red: 0.73, green: 0.67, blue: 0.43).opacity(0.13)
                    : Color(red: 0.22, green: 0.32, blue: 0.20).opacity(0.12)
                context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                                   width: radius * 2, height: radius * 2)),
                             with: .radialGradient(Gradient(colors: [tint, .clear]), center: center,
                                                   startRadius: 0, endRadius: radius))
                if seed.isMultiple(of: 4) {
                    var contour = Path()
                    contour.move(to: CGPoint(x: center.x - 18, y: center.y + 3))
                    contour.addCurve(to: CGPoint(x: center.x + 24, y: center.y - 2),
                                     control1: CGPoint(x: center.x - 6, y: center.y - 7),
                                     control2: CGPoint(x: center.x + 9, y: center.y + 6))
                    context.stroke(contour, with: .color(BattlePalette.parchment.opacity(0.12)), lineWidth: 0.65)
                }
            }
        }
    }
}

struct MapBackdropView: View {
    var body: some View {
        LinearGradient(
            colors: [Color(red: 0.32, green: 0.46, blue: 0.47), Color(red: 0.23, green: 0.38, blue: 0.43)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .allowsHitTesting(false)
    }
}

/// Soft edge haze borrowed from campaign-map presentation: it frames the
/// playable area without hiding terrain or changing any overlay semantics.
struct MapFogOfWarEdgeView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [BattlePalette.parchment.opacity(0.16), .clear, .clear, BattlePalette.parchment.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            HStack(spacing: 0) {
                RadialGradient(
                    colors: [BattlePalette.parchment.opacity(0.20), .clear],
                    center: .leading,
                    startRadius: 8,
                    endRadius: 170
                )
                Spacer(minLength: 0)
                RadialGradient(
                    colors: [BattlePalette.parchment.opacity(0.16), .clear],
                    center: .trailing,
                    startRadius: 8,
                    endRadius: 170
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A quiet cartographic reference layer. It stays in map space with the tiles,
/// so zooming and panning never make the strategic frame feel detached from the
/// terrain. It is deliberately low contrast and never participates in hit tests.
struct MapCartographyGridView: View {
    var metrics: HexMetrics

    var body: some View {
        Canvas { context, size in
            let inset = max(8, metrics.tileWidth * 0.42)
            let frame = CGRect(
                x: inset,
                y: inset,
                width: max(1, size.width - inset * 2),
                height: max(1, size.height - inset * 2)
            )

            for index in 1...6 {
                let progress = CGFloat(index) / 7
                let x = frame.minX + frame.width * progress
                var meridian = Path()
                meridian.move(to: CGPoint(x: x, y: frame.minY))
                meridian.addCurve(
                    to: CGPoint(x: x, y: frame.maxY),
                    control1: CGPoint(x: x - frame.width * 0.035, y: frame.height * 0.32 + frame.minY),
                    control2: CGPoint(x: x + frame.width * 0.035, y: frame.height * 0.68 + frame.minY)
                )
                context.stroke(
                    meridian,
                    with: .color(BattlePalette.brass.opacity(0.055)),
                    lineWidth: 0.7
                )
            }

            for index in 1...5 {
                let progress = CGFloat(index) / 6
                let y = frame.minY + frame.height * progress
                var parallel = Path()
                parallel.move(to: CGPoint(x: frame.minX, y: y))
                parallel.addCurve(
                    to: CGPoint(x: frame.maxX, y: y),
                    control1: CGPoint(x: frame.width * 0.32 + frame.minX, y: y - frame.height * 0.028),
                    control2: CGPoint(x: frame.width * 0.68 + frame.minX, y: y + frame.height * 0.028)
                )
                context.stroke(
                    parallel,
                    with: .color(.white.opacity(0.045)),
                    lineWidth: 0.7
                )
            }

            context.stroke(
                Path(roundedRect: frame, cornerRadius: max(5, metrics.tileWidth * 0.18)),
                with: .color(BattlePalette.brass.opacity(0.18)),
                lineWidth: 1
            )

            let compassCenter = CGPoint(x: frame.maxX - 18, y: frame.minY + 18)
            var compass = Path()
            compass.move(to: CGPoint(x: compassCenter.x, y: compassCenter.y - 7))
            compass.addLine(to: CGPoint(x: compassCenter.x - 3, y: compassCenter.y + 4))
            compass.addLine(to: CGPoint(x: compassCenter.x, y: compassCenter.y + 2))
            compass.addLine(to: CGPoint(x: compassCenter.x + 3, y: compassCenter.y + 4))
            compass.closeSubpath()
            context.fill(compass, with: .color(BattlePalette.brass.opacity(0.30)))
            context.draw(
                Text("N")
                    .font(.system(size: 7, weight: .black, design: .serif))
                    .foregroundColor(BattlePalette.parchment.opacity(0.70)),
                at: CGPoint(x: compassCenter.x, y: compassCenter.y - 13)
            )
            context.stroke(
                Path(ellipseIn: CGRect(x: compassCenter.x - 9, y: compassCenter.y - 9, width: 18, height: 18)),
                with: .color(BattlePalette.brass.opacity(0.16)),
                lineWidth: 0.8
            )

            // Coordinate ticks make the battlefield feel like a campaign map
            // while remaining subordinate to units and tactical overlays.
            for index in 0...6 {
                let progress = CGFloat(index) / 6
                let x = frame.minX + frame.width * progress
                context.fill(
                    Path(CGRect(x: x - 0.5, y: frame.minY - 3, width: 1, height: 4)),
                    with: .color(BattlePalette.brass.opacity(0.24))
                )
                context.draw(
                    Text("\(index + 1)")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(BattlePalette.brass.opacity(0.38)),
                    at: CGPoint(x: x, y: frame.minY - 8)
                )
            }
            for index in 0...4 {
                let progress = CGFloat(index) / 4
                let y = frame.minY + frame.height * progress
                context.fill(
                    Path(CGRect(x: frame.minX - 3, y: y - 0.5, width: 4, height: 1)),
                    with: .color(BattlePalette.brass.opacity(0.24))
                )
                context.draw(
                    Text("\(index + 1)")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(BattlePalette.brass.opacity(0.38)),
                    at: CGPoint(x: frame.minX - 8, y: y)
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct MapScaleBarView: View {
    var metrics: HexMetrics

    var body: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Rectangle().fill(BattlePalette.brassBright).frame(width: max(20, metrics.tileWidth * 0.52), height: 2)
                    Rectangle().fill(BattlePalette.ivory.opacity(0.78)).frame(width: max(20, metrics.tileWidth * 0.52), height: 2)
                }
                Text("1格 · 战区比例")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(BattlePalette.ivory.opacity(0.70))
            }
            Image(systemName: "location.north.fill")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(BattlePalette.brassBright)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(.black.opacity(0.52))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay {
            RoundedRectangle(cornerRadius: 5)
                .stroke(BattlePalette.brass.opacity(0.24), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

struct TerrainMaterialProfile: Hashable {
    let signature: String
    let layerCount: Int
    let landmarkOpacity: Double
}

struct CoastlineSegment: Identifiable, Hashable {
    let waterPosition: Position
    let landPosition: Position

    var id: String { "\(waterPosition.description)->\(landPosition.description)" }
}

enum CoastlineBuilder {
    static func segments(tiles: [Tile], metrics: HexMetrics) -> [CoastlineSegment] {
        let terrain = Dictionary(uniqueKeysWithValues: tiles.map { ($0.position, $0.terrain) })
        let width = (tiles.map(\.position.x).max() ?? -1) + 1
        let height = (tiles.map(\.position.y).max() ?? -1) + 1
        return tiles.filter { $0.terrain == .water }.flatMap { water -> [CoastlineSegment] in
            water.position.neighbors(width: width, height: height).compactMap { neighbor -> CoastlineSegment? in
                guard let neighborTerrain = terrain[neighbor], neighborTerrain != .water else { return nil }
                return CoastlineSegment(waterPosition: water.position, landPosition: neighbor)
            }
        }
    }
}

struct CoastlineLayerView: View {
    var contours: BattlefieldTerrainContours
    var metrics: HexMetrics

    private static let sandColor = Color(red: 0.82, green: 0.72, blue: 0.50)
    private static let foamColor = Color(red: 0.72, green: 0.86, blue: 0.90)

    var body: some View {
        Canvas { context, size in
            let shore = contours.path
            context.stroke(shore, with: .color(Color(red: 0.18, green: 0.25, blue: 0.19).opacity(0.42)),
                           style: StrokeStyle(lineWidth: max(3, metrics.tileWidth * 0.07), lineCap: .round, lineJoin: .round))
            context.stroke(shore, with: .color(Self.sandColor.opacity(0.74)),
                           style: StrokeStyle(lineWidth: max(1.4, metrics.tileWidth * 0.033), lineCap: .round, lineJoin: .round))
            context.drawLayer { foam in
                var water = Path(CGRect(origin: .zero, size: size))
                water.addPath(shore)
                foam.clip(to: water, style: FillStyle(eoFill: true))
                foam.stroke(shore, with: .color(Self.foamColor.opacity(0.38)),
                            style: StrokeStyle(lineWidth: max(3, metrics.tileWidth * 0.09), lineCap: .round, lineJoin: .round))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct HexTileView: View {
    var tile: Tile
    var city: City?
    var unit: ArmyUnit?
    var enemyIntent: EnemyIntentSummary?
    var enemyIntentDestination: EnemyIntentMapOverlay?
    var enemyIntentTarget: EnemyIntentMapOverlay?
    var tacticalRecommendation: TacticalRecommendationSummary?
    var maneuverOption: ManeuverOptionSummary?
    var battleObjectiveOverlays: [BattleObjectivePositionOverlay]
    var focusedBattleObjectiveRole: BattleObjectiveMapRole?
    var countermeasureOverlay: CountermeasurePositionOverlay?
    var mapControlSummary: MapControlSummary?
    var threatHeatZoneSummary: ThreatHeatZoneSummary?
    var enemyCommanderThreatOverlays: [EnemyCommanderThreatPositionOverlay]
    var enemyCommanderThreatOpacity: Double = 1
    var isMapControlOverlay: Bool
    var isTacticalRecommendationPath: Bool
    var isTacticalRecommendationTarget: Bool
    var isSelected: Bool
    var isAttackOrigin: Bool
    var isReachable: Bool
    var isAttackTarget: Bool
    var isSkillRange: Bool
    var isSkillTarget: Bool
    var scale: CGFloat = 1

    var body: some View {
        ZStack {
            Hexagon()
                .fill(.clear)
                .overlay {
                    if tile.terrain == .forest || tile.terrain == .hills {
                        TerrainTextureView(
                            terrain: tile.terrain, scale: scale,
                            variation: tile.position.x * 17 + tile.position.y * 29
                        )
                    }
                }
                .overlay {
                    Hexagon()
                        .stroke(borderColor, lineWidth: isSelected || isAttackOrigin || isAttackTarget ? max(2.4, 3 * scale) : max(0.4, 0.55 * scale))
                }

            if let threatHeatZoneSummary {
                ThreatHeatTileOverlay(
                    summary: threatHeatZoneSummary,
                    isZoneCenter: threatHeatZoneSummary.targetPosition == tile.position,
                    scale: scale
                )
                    .allowsHitTesting(false)
            } else if let mapControlSummary,
                      isMapControlOverlay {
                MapControlTileOverlay(summary: mapControlSummary, scale: scale)
                    .allowsHitTesting(false)
            }

            if !enemyCommanderThreatOverlays.isEmpty {
                EnemyCommanderThreatTileOverlay(
                    overlays: enemyCommanderThreatOverlays,
                    scale: scale
                )
                .opacity(enemyCommanderThreatOpacity)
                .allowsHitTesting(false)
            }

            if isSkillRange && !isAttackTarget {
                SkillRangeOverlay(scale: scale)
            }

            if isReachable {
                ReachableTileOverlay(scale: scale)
            }

            if let maneuverOption,
               !isSelected,
               !isAttackTarget {
                ManeuverOptionTileOverlay(summary: maneuverOption, scale: scale)
                    .allowsHitTesting(false)
            }

            if isTacticalRecommendationPath && !isSelected && !isAttackTarget {
                TacticalRecommendationPathOverlay(scale: scale)
            }

            if !battleObjectiveOverlays.isEmpty,
               !isAttackTarget,
               !isSkillTarget {
                BattleObjectiveTileOverlay(
                    overlays: battleObjectiveOverlays,
                    focusedRole: focusedBattleObjectiveRole,
                    scale: scale
                )
                    .allowsHitTesting(false)
            }

            if let countermeasureOverlay,
               !isAttackTarget,
               !isSkillTarget {
                CountermeasureTileOverlay(overlay: countermeasureOverlay, scale: scale)
            }

            if isSkillTarget && !isAttackTarget {
                SkillTargetOverlay(scale: scale)
            }

            if isTacticalRecommendationTarget && !isAttackTarget && !isSkillTarget {
                TacticalRecommendationTargetOverlay(summary: tacticalRecommendation, scale: scale)
            }

            if let enemyIntentDestination, !isAttackTarget {
                EnemyIntentDestinationOverlay(overlay: enemyIntentDestination, scale: scale)
            }

            if let enemyIntentTarget, !isAttackTarget && !isSkillTarget {
                EnemyIntentTargetOverlay(overlay: enemyIntentTarget, scale: scale)
            }

            if let city = city {
                CityBadgeView(city: city, compact: true)
                    .scaleEffect(scale)
                    .offset(y: unit == nil ? 0 : -14 * scale)
            }

            if let unit = unit {
                UnitTokenView(unit: unit)
                    .scaleEffect(scale)
                    .offset(y: city == nil ? 0 : 14 * scale)

                if let enemyIntent {
                    EnemyIntentMapBadgeView(summary: enemyIntent)
                        .scaleEffect(scale)
                        .offset(x: 24 * scale, y: city == nil ? -18 * scale : -4 * scale)
                }
            }

            if isSelected {
                SelectedTileOverlay(scale: scale)
            }

            if isAttackOrigin && !isSelected {
                SelectedTileOverlay(scale: scale)
                    .opacity(0.82)
            }

            if isAttackTarget {
                AttackTileOverlay(scale: scale)
            }

            if let countermeasureOverlay,
               isAttackTarget,
               countermeasureOverlay.role == .target {
                CountermeasureTileOverlay(overlay: countermeasureOverlay, scale: scale)
            }
        }
        .contentShape(Hexagon())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityHidden(isAttackTarget)
    }

    private var borderColor: Color {
        if isAttackTarget { return .red }
        if isSelected { return .white }
        if isAttackOrigin { return .cyan }
        if isReachable { return .yellow.opacity(0.24) }
        return .clear
    }

    private var accessibilityLabel: String {
        var parts = [tile.terrain.displayName]
        if let city {
            parts.append("\(city.owner.displayName)\(city.name)")
        }
        if let unit {
            parts.append("\(unit.faction.displayName)\(unit.kind.displayName)")
        }
        if isSelected {
            parts.append("已选中")
        }
        if isAttackOrigin {
            parts.append("攻击发起单位")
        }
        if isReachable {
            parts.append("可移动")
        }
        if isSkillRange {
            parts.append("技能范围")
        }
        if isSkillTarget {
            parts.append("技能目标")
        }
        if isAttackTarget {
            parts.append("可攻击")
        }
        if isTacticalRecommendationPath {
            parts.append("战术建议路径")
        }
        if isTacticalRecommendationTarget,
           let tacticalRecommendation {
            parts.append("战术建议目标\(tacticalRecommendation.targetLabel)")
        }
        if let maneuverOption {
            parts.append("机动\(maneuverOption.kindLabel)，\(maneuverOption.impactLabel)，风险\(maneuverOption.riskLabel)")
        }
        if !battleObjectiveOverlays.isEmpty {
            let labels = battleObjectiveOverlays.map { "\($0.stageLabel)\($0.position.description)" }
            parts.append("目标线\(labels.joined(separator: "、"))")
            if let chainLabel = battleObjectiveOverlays.first?.chainLabel,
               !chainLabel.isEmpty {
                parts.append(chainLabel)
            }
        }
        if let countermeasureOverlay {
            parts.append(countermeasureOverlay.accessibilityLabel)
        }
        if let mapControlSummary {
            parts.append("控区\(mapControlSummary.controlLabel)")
        }
        if let threatHeatZoneSummary {
            parts.append("热区\(threatHeatZoneSummary.levelLabel)，\(threatHeatZoneSummary.impactLabel)")
        }
        if !enemyCommanderThreatOverlays.isEmpty {
            parts.append(enemyCommanderThreatOverlays.map(\.accessibilityLabel).joined(separator: "、"))
        }
        if let enemyIntentDestination {
            parts.append("敌军意图目的地\(enemyIntentDestination.summary.destinationLabel)")
        }
        if let enemyIntentTarget {
            parts.append("敌军意图目标\(enemyIntentTarget.targetLabel)")
        }
        return parts.joined(separator: "，")
    }
}

struct TerrainTextureView: View {
    var terrain: TerrainType
    var scale: CGFloat
    var variation = 0

    var body: some View {
        Group {
            switch terrain {
            case .forest:
                ForestTextureView(scale: scale, variation: variation)
            case .hills:
                HillsTextureView(scale: scale, variation: variation)
            default:
                EmptyView()
            }
        }
        .clipShape(Hexagon())
    }
}

struct ReachableTileOverlay: View {
    var scale: CGFloat

    var body: some View {
        ZStack {
            Hexagon()
                .fill(Color(red: 0.92, green: 0.76, blue: 0.28).opacity(0.07))
            Hexagon()
                .stroke(
                    Color(red: 0.96, green: 0.82, blue: 0.36).opacity(0.42),
                    style: StrokeStyle(lineWidth: max(0.8, 1.15 * scale), lineCap: .round, dash: [4 * scale, 5 * scale])
                )
                .padding(6 * scale)
            Circle()
                .fill(Color(red: 0.96, green: 0.82, blue: 0.36).opacity(0.62))
                .frame(width: 4 * scale, height: 4 * scale)
        }
        .accessibilityHidden(true)
    }
}

struct ThreatHeatTileOverlay: View {
    var summary: ThreatHeatZoneSummary
    var isZoneCenter: Bool
    var scale: CGFloat

    var body: some View {
        ZStack {
            Hexagon()
                .fill(summary.threatLevel.tintColor.opacity(0.12))
            Hexagon()
                .stroke(
                    summary.threatLevel.tintColor.opacity(0.42),
                    style: StrokeStyle(lineWidth: max(0.8, 1.1 * scale), lineCap: .round)
                )
                .padding(6 * scale)
            if isZoneCenter {
                Image(systemName: summary.threatLevel.systemImage)
                    .font(.system(size: 10 * scale, weight: .black))
                    .foregroundStyle(summary.threatLevel.tintColor)
                    .shadow(color: .black.opacity(0.38), radius: 2, y: 1)
                    .offset(y: 22 * scale)
            }
        }
        .accessibilityHidden(true)
    }
}

struct MapControlTileOverlay: View {
    var summary: MapControlSummary
    var scale: CGFloat

    var body: some View {
        ZStack {
            Hexagon()
                .fill(summary.controlState.tintColor.opacity(0.08))
            Hexagon()
                .stroke(
                    summary.controlState.tintColor.opacity(0.36),
                    style: StrokeStyle(lineWidth: max(0.8, 1 * scale), lineCap: .round)
                )
                .padding(9 * scale)
        }
        .accessibilityHidden(true)
    }
}

struct SkillRangeOverlay: View {
    var scale: CGFloat

    var body: some View {
        ZStack {
            Hexagon()
                .fill(Color(red: 0.28, green: 0.72, blue: 0.82).opacity(0.13))
            Hexagon()
                .stroke(
                    Color(red: 0.36, green: 0.86, blue: 0.92).opacity(0.72),
                    style: StrokeStyle(lineWidth: max(1, 1.4 * scale), lineCap: .round, dash: [3 * scale, 4 * scale])
                )
                .padding(7 * scale)
        }
    }
}

struct SkillTargetOverlay: View {
    var scale: CGFloat

    var body: some View {
        ZStack {
            Hexagon()
                .fill(Color(red: 0.98, green: 0.82, blue: 0.36).opacity(0.20))
            Hexagon()
                .stroke(Color(red: 0.98, green: 0.82, blue: 0.36).opacity(0.95), lineWidth: max(1.7, 2.2 * scale))
                .padding(5 * scale)
            Image(systemName: "sparkles")
                .font(.system(size: 13 * scale, weight: .black))
                .foregroundStyle(Color(red: 0.98, green: 0.82, blue: 0.36))
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                .offset(y: -22 * scale)
        }
        .shadow(color: Color(red: 0.98, green: 0.82, blue: 0.36).opacity(0.38), radius: 4 * scale)
    }
}

struct SelectedTileOverlay: View {
    var scale: CGFloat

    var body: some View {
        ZStack {
            Hexagon()
                .fill(.white.opacity(0.12))
            Hexagon()
                .stroke(.white.opacity(0.95), lineWidth: max(1.8, 2.6 * scale))
                .padding(1.5 * scale)
            Hexagon()
                .stroke(Color(red: 0.94, green: 0.76, blue: 0.30).opacity(0.75), lineWidth: max(1, 1.2 * scale))
                .padding(6 * scale)
        }
        .shadow(color: .white.opacity(0.45), radius: 5 * scale)
    }
}

struct AttackTileOverlay: View {
    var scale: CGFloat

    var body: some View {
        ZStack {
            Hexagon()
                .fill(Color.red.opacity(0.16))
            Hexagon()
                .stroke(Color.red.opacity(0.95), style: StrokeStyle(lineWidth: max(2, 2.5 * scale), lineCap: .round, dash: [7 * scale, 4 * scale]))
                .padding(2 * scale)
        }
        .shadow(color: .red.opacity(0.42), radius: 5 * scale)
    }
}

struct TacticalRecommendationPathOverlay: View {
    var scale: CGFloat

    var body: some View {
        ZStack {
            Hexagon()
                .fill(Color(red: 0.24, green: 0.70, blue: 0.58).opacity(0.13))
            Hexagon()
                .stroke(
                    Color(red: 0.48, green: 0.90, blue: 0.74).opacity(0.72),
                    style: StrokeStyle(lineWidth: max(1, 1.5 * scale), lineCap: .round, dash: [4 * scale, 4 * scale])
                )
                .padding(8 * scale)
        }
    }
}

struct ManeuverOptionTileOverlay: View {
    var summary: ManeuverOptionSummary
    var scale: CGFloat

    var body: some View {
        ZStack {
            Hexagon()
                .fill(summary.kind.tintColor.opacity(0.12))
            Hexagon()
                .stroke(
                    summary.risk.tintColor.opacity(0.74),
                    style: StrokeStyle(lineWidth: max(1, 1.45 * scale), lineCap: .round, dash: [2 * scale, 4 * scale])
                )
                .padding(11 * scale)
            Image(systemName: summary.kind.systemImage)
                .font(.system(size: 10 * scale, weight: .black))
                .foregroundStyle(summary.kind.tintColor)
                .padding(4 * scale)
                .background(.black.opacity(0.34))
                .clipShape(Circle())
                .offset(x: -20 * scale, y: 20 * scale)
        }
        .accessibilityHidden(true)
    }
}

struct TacticalRecommendationTargetOverlay: View {
    var summary: TacticalRecommendationSummary?
    var scale: CGFloat

    var body: some View {
        let tint = summary?.kind.tintColor ?? Color(red: 0.48, green: 0.90, blue: 0.74)

        ZStack {
            Hexagon()
                .fill(tint.opacity(0.16))
            Hexagon()
                .stroke(tint.opacity(0.90), lineWidth: max(1.5, 2.1 * scale))
                .padding(5 * scale)
            Image(systemName: summary?.kind.systemImage ?? "location.fill")
                .font(.system(size: 13 * scale, weight: .black))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                .offset(y: -21 * scale)
        }
        .shadow(color: tint.opacity(0.34), radius: 4 * scale)
        .accessibilityLabel(summary?.accessibilityLabel ?? "战术建议目标")
    }
}

struct TacticalRecommendationRouteLayerView: View {
    var summary: TacticalRecommendationSummary
    var metrics: HexMetrics

    var body: some View {
        ZStack {
            ForEach(summary.routeSegments) { segment in
                TacticalRecommendationRouteSegmentView(segment: segment, kind: summary.kind, metrics: metrics)
            }
        }
    }
}

struct BattleObjectiveRouteLayerView: View {
    var overlay: BattleObjectiveMapOverlay
    var metrics: HexMetrics

    var body: some View {
        ZStack {
            ForEach(overlay.routeSegments) { segment in
                BattleObjectiveRouteSegmentView(segment: segment, metrics: metrics)
            }
        }
        .accessibilityLabel(overlay.accessibilityLabel)
    }
}

struct BattleObjectiveRouteSegmentView: View {
    var segment: BattleObjectiveRouteSegment
    var metrics: HexMetrics

    var body: some View {
        let start = metrics.center(for: segment.from)
        let end = metrics.center(for: segment.to)
        let color = segment.toRole.tintColor.opacity(segment.isTargetLeg ? 0.78 : 0.92)
        let width = max(1.5, 2.35 * metrics.tileScale)
        let dash = segment.isTargetLeg ? [4 * metrics.tileScale, 4 * metrics.tileScale] : [8 * metrics.tileScale, 3 * metrics.tileScale]
        let angle = Angle(radians: atan2(Double(end.y - start.y), Double(end.x - start.x)))

        ZStack {
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(.black.opacity(0.34), style: StrokeStyle(lineWidth: width + 2.2, lineCap: .round, lineJoin: .round, dash: dash))

            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash))

            Image(systemName: segment.toRole.symbol)
                .font(.system(size: max(8, 10 * metrics.tileScale), weight: .black))
                .foregroundStyle(color)
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                .rotationEffect(segment.from == segment.to ? Angle.zero : angle)
                .position(end)
        }
        .accessibilityHidden(true)
    }
}

struct TacticalRecommendationRouteSegmentView: View {
    var segment: TacticalRecommendationRouteSegment
    var kind: TacticalRecommendationKind
    var metrics: HexMetrics

    var body: some View {
        let start = metrics.center(for: segment.from)
        let end = metrics.center(for: segment.to)
        let color = kind.tintColor.opacity(segment.isTargetLeg ? 0.66 : 0.88)
        let width = max(1.6, (segment.risk == .critical ? 3.2 : 2.5) * metrics.tileScale)
        let dash = segment.isTargetLeg ? [4 * metrics.tileScale, 4 * metrics.tileScale] : []
        let angle = Angle(radians: atan2(Double(end.y - start.y), Double(end.x - start.x)))

        ZStack {
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(.black.opacity(0.34), style: StrokeStyle(lineWidth: width + 2.4, lineCap: .round, lineJoin: .round, dash: dash))

            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash))

            Image(systemName: segment.isTargetLeg ? "scope" : "arrowtriangle.right.fill")
                .font(.system(size: max(8, 10 * metrics.tileScale), weight: .black))
                .foregroundStyle(color)
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                .rotationEffect(segment.isTargetLeg ? .zero : angle)
                .position(end)
        }
        .accessibilityHidden(true)
    }
}

struct CountermeasureRouteLayerView: View {
    var overlay: CountermeasureMapOverlay
    var metrics: HexMetrics

    var body: some View {
        ZStack {
            ForEach(overlay.routeSegments) { segment in
                CountermeasureRouteSegmentView(segment: segment, metrics: metrics)
            }
        }
        .accessibilityLabel(overlay.accessibilityLabel)
    }
}

struct CountermeasureRouteSegmentView: View {
    var segment: CountermeasureRouteSegment
    var metrics: HexMetrics

    var body: some View {
        let start = metrics.center(for: segment.from)
        let end = metrics.center(for: segment.to)
        let color = segment.priority.tintColor.opacity(segment.isTargetLeg ? 0.72 : 0.88)
        let width = max(1.5, (segment.priority == .decisive ? 3.2 : 2.5) * metrics.tileScale)
        let dash = segment.isTargetLeg ? [4 * metrics.tileScale, 4 * metrics.tileScale] : [7 * metrics.tileScale, 3 * metrics.tileScale]
        let angle = Angle(radians: atan2(Double(end.y - start.y), Double(end.x - start.x)))

        ZStack {
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(.black.opacity(0.36), style: StrokeStyle(lineWidth: width + 2.4, lineCap: .round, lineJoin: .round, dash: dash))

            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash))

            Image(systemName: segment.isTargetLeg ? "scope" : "shield.lefthalf.filled")
                .font(.system(size: max(8, 10 * metrics.tileScale), weight: .black))
                .foregroundStyle(color)
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                .rotationEffect(segment.isTargetLeg ? .zero : angle)
                .position(end)
        }
        .accessibilityHidden(true)
    }
}

struct EnemyIntentRouteLayerView: View {
    var overlays: [EnemyIntentMapOverlay]
    var metrics: HexMetrics

    var body: some View {
        ZStack {
            ForEach(overlays) { overlay in
                ForEach(overlay.routeSegments) { segment in
                    EnemyIntentRouteSegmentView(segment: segment, metrics: metrics)
                }
            }
        }
    }
}

struct EnemyIntentRouteSegmentView: View {
    var segment: EnemyIntentRouteSegment
    var metrics: HexMetrics

    var body: some View {
        let start = metrics.center(for: segment.from)
        let end = metrics.center(for: segment.to)
        let color = segment.kind.tintColor.opacity(segment.isTargetLeg ? 0.70 : 0.86)
        let width = max(1.4, (segment.isHighThreat ? 3.2 : 2.3) * metrics.tileScale)
        let dash = segment.isTargetLeg ? [4 * metrics.tileScale, 4 * metrics.tileScale] : []
        let angle = Angle(radians: atan2(Double(end.y - start.y), Double(end.x - start.x)))

        ZStack {
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(.black.opacity(0.34), style: StrokeStyle(lineWidth: width + 2.2, lineCap: .round, lineJoin: .round, dash: dash))

            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash))

            Image(systemName: segment.isTargetLeg ? "scope" : "arrowtriangle.right.fill")
                .font(.system(size: max(8, 10 * metrics.tileScale), weight: .black))
                .foregroundStyle(color)
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                .rotationEffect(segment.isTargetLeg ? .zero : angle)
                .position(end)
        }
        .accessibilityHidden(true)
    }
}

struct EnemyIntentDestinationOverlay: View {
    var overlay: EnemyIntentMapOverlay
    var scale: CGFloat

    var body: some View {
        ZStack {
            Hexagon()
                .fill(overlay.kind.tintColor.opacity(0.11))
            Hexagon()
                .stroke(
                    overlay.kind.tintColor.opacity(0.78),
                    style: StrokeStyle(lineWidth: max(1.2, 1.7 * scale), lineCap: .round, dash: [5 * scale, 4 * scale])
                )
                .padding(7 * scale)
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 12 * scale, weight: .black))
                .foregroundStyle(overlay.kind.tintColor)
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                .offset(y: 20 * scale)
        }
        .accessibilityLabel(overlay.accessibilityLabel)
    }
}

struct EnemyIntentTargetOverlay: View {
    var overlay: EnemyIntentMapOverlay
    var scale: CGFloat

    var body: some View {
        ZStack {
            Hexagon()
                .fill(Color(red: 0.82, green: 0.12, blue: 0.10).opacity(overlay.isHighThreat ? 0.18 : 0.10))
            Hexagon()
                .stroke(Color(red: 0.96, green: 0.34, blue: 0.24).opacity(0.90), lineWidth: max(1.4, 2 * scale))
                .padding(4 * scale)
            Circle()
                .stroke(.white.opacity(0.88), lineWidth: max(1, 1.4 * scale))
                .frame(width: 19 * scale, height: 19 * scale)
            Image(systemName: "scope")
                .font(.system(size: 13 * scale, weight: .black))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                .offset(y: -21 * scale)
        }
        .shadow(color: Color.red.opacity(0.30), radius: 4 * scale)
        .accessibilityLabel(overlay.accessibilityLabel)
    }
}

struct EnemyCommanderThreatRouteLayerView: View {
    var overlay: EnemyCommanderThreatMapOverlay
    var metrics: HexMetrics

    var body: some View {
        ZStack {
            ForEach(overlay.routeSegments) { segment in
                EnemyCommanderThreatRouteSegmentView(segment: segment, metrics: metrics)
            }
        }
        .accessibilityLabel(overlay.accessibilityLabel)
    }
}

struct EnemyCommanderThreatRouteSegmentView: View {
    var segment: EnemyCommanderThreatRouteSegment
    var metrics: HexMetrics

    private let threatTint = Color(red: 0.68, green: 0.38, blue: 0.86)

    var body: some View {
        let start = metrics.center(for: segment.from)
        let end = metrics.center(for: segment.to)
        let width = max(1.4, 2.25 * metrics.tileScale)
        let dash = segment.isTargetLeg
            ? [4 * metrics.tileScale, 4 * metrics.tileScale]
            : [8 * metrics.tileScale, 3 * metrics.tileScale]
        let color = threatTint.opacity(segment.isTargetLeg ? 0.78 : 0.90)
        let angle = Angle(radians: atan2(Double(end.y - start.y), Double(end.x - start.x)))

        ZStack {
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(
                .black.opacity(0.36),
                style: StrokeStyle(
                    lineWidth: width + 2.2,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: dash
                )
            )

            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: width,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: dash
                )
            )

            Image(systemName: segment.isTargetLeg ? "scope" : "bolt.fill")
                .font(.system(size: max(8, 10 * metrics.tileScale), weight: .black))
                .foregroundStyle(color)
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                .rotationEffect(segment.isTargetLeg ? .zero : angle)
                .position(end)
        }
        .accessibilityHidden(true)
    }
}

struct EnemyCommanderThreatTileOverlay: View {
    var overlays: [EnemyCommanderThreatPositionOverlay]
    var scale: CGFloat

    var body: some View {
        ZStack {
            ForEach(overlays) { overlay in
                marker(for: overlay)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(overlays.map(\.accessibilityLabel).joined(separator: "、"))
    }

    @ViewBuilder
    private func marker(for overlay: EnemyCommanderThreatPositionOverlay) -> some View {
        let tint = Color(red: 0.68, green: 0.38, blue: 0.86)
        let focusOpacity = overlay.isFocused ? 1.0 : 0.72

        switch overlay.role {
        case .range:
            Hexagon()
                .fill(tint.opacity(0.10 * focusOpacity))
                .overlay {
                    Hexagon()
                        .stroke(
                            tint.opacity(0.58 * focusOpacity),
                            style: StrokeStyle(
                                lineWidth: max(0.9, 1.25 * scale),
                                lineCap: .round,
                                dash: [4 * scale, 4 * scale]
                            )
                        )
                        .padding(7 * scale)
                }

        case .affected:
            Hexagon()
                .fill(Color.pink.opacity(0.14 * focusOpacity))
                .overlay {
                    Hexagon()
                        .stroke(
                            Color.pink.opacity(0.84 * focusOpacity),
                            lineWidth: max(1.2, 1.8 * scale)
                        )
                        .padding(4 * scale)
                }
                .overlay {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: max(9, 12 * scale), weight: .black))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                        .offset(y: 20 * scale)
                }

        case .origin:
            Hexagon()
                .stroke(tint.opacity(0.92 * focusOpacity), lineWidth: max(1.5, 2.2 * scale))
                .padding(3 * scale)
                .overlay {
                    ZStack {
                        Circle()
                            .fill(tint.opacity(0.92 * focusOpacity))
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: max(10, 13 * scale), weight: .black))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 24 * scale, height: 24 * scale)
                    .shadow(color: .black.opacity(0.42), radius: 3, y: 1)
                    .offset(x: -21 * scale, y: -20 * scale)
                }

        case .target:
            Hexagon()
                .fill(Color.white.opacity(0.08 * focusOpacity))
                .overlay {
                    Hexagon()
                        .stroke(.white.opacity(0.88 * focusOpacity), lineWidth: max(1.4, 2 * scale))
                        .padding(4 * scale)
                }
                .overlay {
                    Circle()
                        .stroke(tint.opacity(0.96 * focusOpacity), lineWidth: max(1, 1.45 * scale))
                        .frame(width: 20 * scale, height: 20 * scale)
                        .overlay {
                            Image(systemName: "scope")
                                .font(.system(size: max(10, 13 * scale), weight: .black))
                                .foregroundStyle(tint)
                                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                        }
                        .offset(y: -21 * scale)
                }

        case .destination:
            Hexagon()
                .fill(tint.opacity(0.10 * focusOpacity))
                .overlay {
                    Hexagon()
                        .stroke(
                            tint.opacity(0.76 * focusOpacity),
                            style: StrokeStyle(
                                lineWidth: max(1.1, 1.6 * scale),
                                lineCap: .round,
                                dash: [5 * scale, 4 * scale]
                            )
                        )
                        .padding(7 * scale)
                }
                .overlay {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: max(10, 13 * scale), weight: .black))
                        .foregroundStyle(tint)
                        .shadow(color: .black.opacity(0.38), radius: 2, y: 1)
                        .offset(y: 20 * scale)
                }
        }
    }
}

struct CountermeasureTileOverlay: View {
    var overlay: CountermeasurePositionOverlay
    var scale: CGFloat

    var body: some View {
        let tint = overlay.summary.priority.tintColor

        ZStack {
            Hexagon()
                .fill(tint.opacity(0.13))
            Hexagon()
                .stroke(
                    tint.opacity(overlay.role == .target ? 0.92 : 0.74),
                    style: StrokeStyle(lineWidth: max(1.2, 1.8 * scale), lineCap: .round, dash: overlay.role == .destination ? [3 * scale, 4 * scale] : [])
                )
                .padding(overlay.role == .target ? 4 * scale : 9 * scale)
            ZStack {
                Circle()
                    .fill(tint.opacity(0.90))
                Image(systemName: symbol)
                    .font(.system(size: 10 * scale, weight: .black))
                    .foregroundStyle(.white)
                    .offset(y: -2 * scale)
                Text("\(overlay.role.stageNumber)")
                    .font(.system(size: max(7, 8 * scale), weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.78))
                    .offset(y: 6 * scale)
            }
            .frame(width: 23 * scale, height: 23 * scale)
            .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
            .offset(offset)
        }
        .shadow(color: tint.opacity(0.26), radius: 4 * scale)
        .accessibilityLabel(overlay.accessibilityLabel)
    }

    private var symbol: String {
        switch overlay.role {
        case .response: return "shield.lefthalf.filled"
        case .destination: return overlay.summary.kind.systemImage
        case .target: return "scope"
        }
    }

    private var offset: CGSize {
        switch overlay.role {
        case .response: return CGSize(width: -18 * scale, height: -18 * scale)
        case .destination: return CGSize(width: -20 * scale, height: 20 * scale)
        case .target: return CGSize(width: 18 * scale, height: -20 * scale)
        }
    }
}

struct ForestTextureView: View {
    var scale: CGFloat
    var variation = 0

    var body: some View {
        Canvas { context, size in
            let paint = BattlefieldMiniaturePainter(size: size)
            for tree in treeSamples {
                let x = tree.x
                let y = tree.y
                let crown = tree.size
                paint.ellipse(&context, x: x - 2, y: y + 3, width: crown + 4, height: 4, color: .black.opacity(0.20))
                paint.line(&context, [(x, y), (x, y + 6)], color: Color(red: 0.25, green: 0.24, blue: 0.15), width: 1)
                paint.ellipse(&context, x: x - crown / 2, y: y - crown, width: crown, height: crown + 2,
                              color: Color(red: 0.17, green: 0.28, blue: 0.16))
                paint.ellipse(&context, x: x - crown / 2, y: y - crown, width: crown * 0.78, height: crown * 0.72,
                              color: Color(red: 0.31, green: 0.40, blue: 0.21))
                paint.ellipse(&context, x: x - crown * 0.24, y: y - crown * 0.92,
                              width: crown * 0.35, height: crown * 0.28,
                              color: Color(red: 0.46, green: 0.49, blue: 0.29).opacity(0.75))
            }
        }
    }

    private var treeSamples: [(x: CGFloat, y: CGFloat, size: CGFloat)] {
        var samples: [(x: CGFloat, y: CGFloat, size: CGFloat)] = []
        for index in 0..<17 {
            let squared: Int = index * index
            let horizontalSeed: Int = variation + index * 13 + squared * 7
            let verticalSeed: Int = variation * 3 + index * 19 + squared
            let crownSeed: Int = variation + index * 7
            let x = CGFloat(8 + horizontalSeed % 37)
            let y = CGFloat(9 + verticalSeed % 22)
            let crown = CGFloat(5 + crownSeed % 4)
            samples.append((x: x, y: y, size: crown))
        }
        return samples.sorted { $0.y < $1.y }
    }
}

struct HillsTextureView: View {
    var scale: CGFloat
    var variation = 0

    var body: some View {
        Canvas { context, size in
            let paint = BattlefieldMiniaturePainter(size: size)
            let rise = CGFloat(variation % 5)
            paint.ellipse(&context, x: 5, y: 25, width: 44, height: 9, color: .black.opacity(0.13))
            paint.polygon(&context, [(3, 28), (12, 17), (18, 20), (29, 7 + rise), (35, 14), (40, 13), (50, 29), (32, 33), (16, 30)],
                          color: Color(red: 0.48, green: 0.48, blue: 0.37))
            paint.polygon(&context, [(18, 20), (29, 7 + rise), (27, 21), (35, 31), (22, 28)],
                          color: Color(red: 0.66, green: 0.62, blue: 0.46))
            paint.polygon(&context, [(29, 7 + rise), (35, 14), (40, 13), (50, 29), (35, 31), (27, 21)],
                          color: Color(red: 0.31, green: 0.35, blue: 0.28))
            paint.polygon(&context, [(3, 28), (12, 17), (11, 25), (22, 28), (16, 30)],
                          color: Color(red: 0.60, green: 0.57, blue: 0.42))
            paint.line(&context, [(8, 24), (12, 17), (18, 20), (29, 7 + rise), (32, 14)],
                       color: BattlefieldMiniaturePainter.ivory.opacity(0.46), width: 0.8)
            paint.line(&context, [(29, 13 + rise), (24, 23), (31, 27)], color: Color.black.opacity(0.22), width: 0.7)
            paint.line(&context, [(39, 18), (36, 24), (43, 28)], color: BattlefieldMiniaturePainter.ivory.opacity(0.18), width: 0.7)
        }
    }
}

struct TriangleHillShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct EnemyIntentMapBadgeView: View {
    var summary: EnemyIntentSummary

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: summary.intent.kind.systemImage)
                .font(.system(size: 7, weight: .black))
            Text(summary.badgeText)
                .font(.system(size: 7, weight: .black, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .foregroundStyle(summary.isHighThreat ? .white : .black.opacity(0.76))
        .padding(.horizontal, 4)
        .frame(height: 15)
        .background(summary.intent.kind.tintColor)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(.black.opacity(0.28), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
        .accessibilityLabel("\(summary.actorLabel)，\(summary.title)，\(summary.routeDetail)，\(summary.impactLabel)")
    }
}

struct TerrainGlyphView: View {
    var terrain: TerrainType
    var scale: CGFloat

    var body: some View {
        Image(systemName: terrain.systemImage)
            .font(.system(size: 10 * scale, weight: .black))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.18), radius: 1, y: 1)
    }
}

struct CityBadgeView: View {
    var city: City
    var compact = false

    var body: some View {
        VStack(spacing: compact ? 1 : 3) {
            ZStack(alignment: .bottomTrailing) {
                FortifiedCitySilhouetteView(owner: city.owner, compact: compact)

                HStack(spacing: 1) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: compact ? 5 : 7, weight: .black))
                    Text("\(city.fortification)")
                        .font(.system(size: compact ? 6 : 8, weight: .black, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundStyle(.black.opacity(0.72))
                .padding(.horizontal, compact ? 2 : 3)
                .frame(height: compact ? 9 : 12)
                .background(Color(red: 0.86, green: 0.68, blue: 0.34))
                .clipShape(RoundedRectangle(cornerRadius: compact ? 3 : 4))
                .offset(x: compact ? 5 : 7, y: compact ? 3 : 4)
            }

            Text(city.name)
                .font(.system(size: compact ? 8 : 11, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, compact ? 4 : 6)
                .frame(minHeight: compact ? 12 : 16)
                .background(.black.opacity(0.58))
                .clipShape(.rect(cornerRadius: compact ? 3 : 4))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }
}

struct FortifiedCitySilhouetteView: View {
    var owner: Faction
    var compact: Bool

    var body: some View {
        let width: CGFloat = compact ? 34 : 44
        let height: CGFloat = compact ? 22 : 31

        Canvas { context, size in
            let paint = BattlefieldMiniaturePainter(size: size)
            paint.ellipse(&context, x: 4, y: 27, width: 44, height: 11, color: .black.opacity(0.28))
            paint.building(&context, x: 9, y: 16, width: 16, height: 12)
            paint.building(&context, x: 26, y: 11, width: 17, height: 15)
            paint.building(&context, x: 19, y: 24, width: 13, height: 9)
            let wallRect = paint.rect(x: 6, y: 26, width: 39, height: 10)
            context.fill(CityWallShape().path(in: wallRect), with: .color(BattlefieldMiniaturePainter.stone))
            paint.polygon(&context, [(6, 34), (45, 34), (45, 38), (6, 38)], color: BattlefieldMiniaturePainter.stoneShadow)
            paint.polygon(&context, [(22, 38), (22, 30), (25, 28), (28, 30), (28, 38)], color: .black.opacity(0.65))
            paint.line(&context, [(35, 14), (35, 1)], color: BattlefieldMiniaturePainter.ivory, width: 0.8)
            paint.polygon(&context, [(35, 1), (45, 3), (44, 9), (35, 7)], color: owner.factionColor)
        }
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(0.34), radius: 2, y: 1)
        .accessibilityHidden(true)
    }
}

struct CityWallShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.25))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.25))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.minY + rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.64, y: rect.minY + rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.64, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.82, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.82, y: rect.minY + rect.height * 0.25))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.25))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Original vector miniatures, normalized to a 52 x 40 artboard. The painter
/// knows neither units nor commands; map identity and hit testing stay outside.
struct BattlefieldMiniaturePainter {
    let size: CGSize
    static let ivory = Color(red: 0.88, green: 0.83, blue: 0.66)
    static let stone = Color(red: 0.70, green: 0.67, blue: 0.53)
    static let stoneShadow = Color(red: 0.36, green: 0.37, blue: 0.31)
    static let roof = Color(red: 0.55, green: 0.24, blue: 0.14)
    static let steel = Color(red: 0.67, green: 0.71, blue: 0.66)

    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x * size.width / 52, y: y * size.height / 40)
    }

    func rect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
        CGRect(x: x * size.width / 52, y: y * size.height / 40,
               width: width * size.width / 52, height: height * size.height / 40)
    }

    func polygon(_ context: inout GraphicsContext, _ points: [(CGFloat, CGFloat)], color: Color) {
        guard let first = points.first else { return }
        var path = Path()
        path.move(to: point(first.0, first.1))
        for p in points.dropFirst() { path.addLine(to: point(p.0, p.1)) }
        path.closeSubpath()
        context.fill(path, with: .color(color))
    }

    func line(_ context: inout GraphicsContext, _ points: [(CGFloat, CGFloat)], color: Color, width: CGFloat) {
        guard let first = points.first else { return }
        var path = Path()
        path.move(to: point(first.0, first.1))
        for p in points.dropFirst() { path.addLine(to: point(p.0, p.1)) }
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: max(0.5, width * size.width / 52), lineCap: .round))
    }

    func ellipse(_ context: inout GraphicsContext, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: Color) {
        context.fill(Path(ellipseIn: rect(x: x, y: y, width: width, height: height)), with: .color(color))
    }

    func building(_ context: inout GraphicsContext, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        polygon(&context, [(x, y), (x + width, y), (x + width, y + height), (x, y + height)], color: Self.stone)
        polygon(&context, [(x + width, y), (x + width + 4, y - 3), (x + width + 4, y + height - 3), (x + width, y + height)], color: Self.stoneShadow)
        polygon(&context, [(x - 2, y), (x + width / 2, y - 6), (x + width + 2, y)], color: Self.roof)
        line(&context, [(x - 2, y), (x + width / 2, y - 6)], color: Self.ivory.opacity(0.75), width: 0.8)
        for offset in stride(from: CGFloat(3), to: width, by: 5) {
            line(&context, [(x + offset, y + 3), (x + offset, y + 6)], color: Self.stoneShadow, width: 1.4)
        }
    }

    func soldier(_ context: inout GraphicsContext, x: CGFloat, y: CGFloat, tint: Color, archer: Bool) {
        ellipse(&context, x: x - 4, y: y + 10, width: 12, height: 4, color: .black.opacity(0.30))
        line(&context, [(x, y + 6), (x - 1, y + 12)], color: Self.stoneShadow, width: 2)
        line(&context, [(x + 3, y + 6), (x + 5, y + 12)], color: Self.stoneShadow, width: 2)
        polygon(&context, [(x - 2, y - 1), (x + 5, y - 1), (x + 6, y + 8), (x - 3, y + 8)], color: tint)
        polygon(&context, [(x - 1, y), (x + 4, y), (x + 4, y + 5), (x - 1, y + 4)], color: Self.steel)
        ellipse(&context, x: x - 1, y: y - 5, width: 5, height: 6, color: Self.ivory)
        ellipse(&context, x: x - 2, y: y - 6, width: 7, height: 4, color: Self.steel)
        if archer {
            line(&context, [(x + 7, y - 4), (x + 10, y + 1), (x + 10, y + 5), (x + 7, y + 9)], color: Self.ivory, width: 1.3)
            line(&context, [(x + 7, y - 4), (x + 7, y + 9)], color: .black.opacity(0.7), width: 0.6)
        } else {
            polygon(&context, [(x - 4, y + 1), (x + 1, y), (x + 2, y + 9), (x - 4, y + 10)], color: tint)
            line(&context, [(x - 2, y + 2), (x - 1, y + 8)], color: Self.ivory, width: 0.8)
            line(&context, [(x + 7, y + 8), (x + 7, y - 10)], color: Self.ivory, width: 0.9)
        }
    }

    func horse(_ context: inout GraphicsContext, x: CGFloat, y: CGFloat, tint: Color) {
        let hide = Color(red: 0.42, green: 0.28, blue: 0.17)
        ellipse(&context, x: x - 2, y: y + 12, width: 23, height: 5, color: .black.opacity(0.32))
        for offset in [CGFloat(2), 6, 13, 17] {
            line(&context, [(x + offset, y + 5), (x + offset - 2, y + 14)], color: hide, width: 2)
        }
        ellipse(&context, x: x, y: y, width: 19, height: 10, color: hide)
        polygon(&context, [(x + 13, y + 3), (x + 17, y - 9), (x + 22, y - 8), (x + 24, y - 3), (x + 19, y - 2), (x + 18, y + 6)], color: hide)
        polygon(&context, [(x + 5, y), (x + 13, y), (x + 14, y + 8), (x + 4, y + 7)], color: tint)
        polygon(&context, [(x + 7, y - 8), (x + 12, y - 8), (x + 13, y), (x + 5, y)], color: Self.steel)
        ellipse(&context, x: x + 7, y: y - 14, width: 6, height: 6, color: Self.ivory)
        line(&context, [(x + 13, y - 4), (x + 22, y - 17)], color: Self.ivory, width: 0.9)
        line(&context, [(x, y + 2), (x - 3, y + 8)], color: Self.stoneShadow, width: 2)
    }

    func ship(_ context: inout GraphicsContext, x: CGFloat, y: CGFloat, tint: Color) {
        polygon(&context, [(x, y), (x + 31, y - 2), (x + 24, y + 7), (x + 6, y + 8)], color: Self.stoneShadow)
        line(&context, [(x, y), (x + 31, y - 2)], color: Self.ivory, width: 1.2)
        line(&context, [(x + 14, y + 1), (x + 14, y - 24)], color: Self.roof, width: 1.2)
        polygon(&context, [(x + 15, y - 23), (x + 28, y - 5), (x + 15, y - 7)], color: Self.ivory)
        polygon(&context, [(x + 12, y - 21), (x + 3, y - 7), (x + 12, y - 8)], color: .white.opacity(0.76))
        polygon(&context, [(x + 14, y - 24), (x + 23, y - 23), (x + 14, y - 19)], color: tint)
        for offset in [CGFloat(7), 12, 17, 22] {
            line(&context, [(x + offset, y + 4), (x + offset - 4, y + 10)], color: Self.ivory, width: 0.8)
        }
    }
}

struct ArmyMiniatureView: View {
    let kind: UnitKind
    let faction: Faction

    var body: some View {
        Group {
            if let image = BattleUnitArtwork.image(for: kind) {
                paintedMiniature(image)
            } else {
                VectorArmyMiniatureView(kind: kind, faction: faction)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func paintedMiniature(_ image: CGImage) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Ellipse()
                    .fill(.black.opacity(0.24))
                    .frame(width: proxy.size.width * 0.84, height: proxy.size.height * 0.18)
                Ellipse()
                    .stroke(faction.factionColor.opacity(0.94), lineWidth: 1.4)
                    .frame(width: proxy.size.width * 0.84, height: proxy.size.height * 0.18)

                Image(decorative: image, scale: 1, orientation: .up)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .padding(.horizontal, 2)
                    .padding(.bottom, proxy.size.height * 0.04)
                    .shadow(color: .black.opacity(0.34), radius: 0.8, x: 0.6, y: 1)

                Canvas { context, size in
                    let paint = BattlefieldMiniaturePainter(size: size)
                    paint.line(&context, [(5, 34), (5, 12)], color: BattlefieldMiniaturePainter.ivory, width: 0.9)
                    let flag = LegionStandardShape().path(in: paint.rect(x: 5, y: 12, width: 9, height: 11))
                    context.fill(flag, with: .color(faction.factionColor))
                    context.stroke(flag, with: .color(BattlePalette.brassBright.opacity(0.88)), lineWidth: 0.6)
                }
            }
        }
    }
}

struct VectorArmyMiniatureView: View {
    let kind: UnitKind
    let faction: Faction

    var body: some View {
        Canvas { context, size in
            let paint = BattlefieldMiniaturePainter(size: size)
            let tint = faction.factionColor
            paint.ellipse(&context, x: 3, y: 26, width: 44, height: 12, color: .black.opacity(0.24))
            let base = Path(ellipseIn: paint.rect(x: 3, y: 27, width: 44, height: 10))
            context.stroke(base, with: .color(tint.opacity(0.9)), lineWidth: 1.3)
            switch kind {
            case .legion, .archer:
                for position in [(CGFloat(14), CGFloat(12)), (29, 14), (21, 24)] {
                    paint.soldier(&context, x: position.0, y: position.1, tint: tint, archer: kind == .archer)
                }
            case .cavalry:
                paint.horse(&context, x: 8, y: 18, tint: tint)
                paint.horse(&context, x: 20, y: 25, tint: tint)
            case .navy:
                paint.ship(&context, x: 8, y: 25, tint: tint)
            }
            if kind != .navy {
                paint.line(&context, [(5, 25), (5, 2)], color: BattlefieldMiniaturePainter.ivory, width: 0.8)
                let flag = LegionStandardShape().path(in: paint.rect(x: 5, y: 2, width: 8, height: 10))
                context.fill(flag, with: .color(tint))
                paint.line(&context, [(5, 2), (13, 2)], color: BattlePalette.brassBright, width: 1)
            }
        }
        .accessibilityHidden(true)
    }
}

struct UnitTokenView: View {
    var unit: ArmyUnit
    var presentation: UnitTokenPresentation = .map

    var body: some View {
        VStack(spacing: 1) {
            ArmyMiniatureView(kind: unit.kind, faction: unit.faction)
                .frame(width: presentation.artSize.width, height: presentation.artSize.height)
                .overlay(alignment: .bottomTrailing) {
                    Text(unit.kind.shortLabel)
                        .font(.system(size: 6, weight: .black))
                        .foregroundStyle(BattlePalette.ivory)
                        .padding(.horizontal, 2)
                        .background(BattlePalette.panel.opacity(0.88))
                        .clipShape(.rect(cornerRadius: 2))
                }
                .overlay(alignment: .topTrailing) {
                    if let generalName = unit.generalName {
                        CommanderTokenBadgeView(name: generalName, trait: unit.generalTrait)
                            .offset(x: 5, y: -5)
                    }
                }
                .overlay(alignment: .topLeading) {
                    if unit.resolvedTacticalOrder != .balanced {
                        Image(systemName: unit.resolvedTacticalOrder.systemImage)
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.white)
                            .padding(2)
                            .background(unit.resolvedTacticalOrder.tintColor)
                            .clipShape(Circle())
                            .offset(x: -4, y: -4)
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    HStack(spacing: 1) {
                        ForEach(0..<min(unit.experience, 3), id: \.self) { _ in
                            Circle()
                                .fill(Color(red: 0.95, green: 0.78, blue: 0.36))
                                .frame(width: 4, height: 4)
                        }
                    }
                    .padding(3)
                }
                .overlay(alignment: .trailing) {
                    if unit.generalSkillCooldownRemaining > 0 {
                        Text("\(unit.generalSkillCooldownRemaining)")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundStyle(.black.opacity(0.78))
                            .frame(width: 13, height: 13)
                            .background(Color(red: 0.36, green: 0.86, blue: 0.92))
                            .clipShape(Circle())
                            .offset(x: 5)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if unit.hasMoved && unit.hasActed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white, .black.opacity(0.75))
                            .offset(x: 4, y: 4)
                    }
                }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(BattlePalette.panel.opacity(0.94))
                    Capsule()
                        .fill(LinearGradient(
                            colors: unit.healthRatio > 0.42
                                ? [Color(red: 0.60, green: 0.76, blue: 0.38), Color(red: 0.22, green: 0.46, blue: 0.24)]
                                : [Color(red: 0.90, green: 0.40, blue: 0.22), BattlePalette.danger],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .frame(width: proxy.size.width * unit.healthRatio)
                    Text("\(unit.health)")
                        .font(.system(size: presentation == .inspection ? 7 : 6, weight: .black, design: .rounded))
                        .foregroundStyle(BattlePalette.ivory)
                        .shadow(color: .black, radius: 0.6, y: 0.5)
                        .frame(maxWidth: .infinity)
                }
                .overlay { Capsule().stroke(BattlePalette.brass.opacity(0.55), lineWidth: 0.5) }
            }
            .frame(width: presentation.strengthWidth, height: presentation.strengthHeight)
        }
    }
}

struct LegionStandardShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.76))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.76))
        path.closeSubpath()
        return path
    }
}

struct CommanderTokenBadgeView: View {
    var name: String
    var trait: GeneralTrait?

    var body: some View {
        ZStack {
            CommanderShieldShape()
                .fill(Color(red: 0.93, green: 0.72, blue: 0.24))
            CommanderShieldShape()
                .stroke(.white.opacity(0.92), lineWidth: 1)
            Image(systemName: trait?.systemImage ?? "person.fill")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.black.opacity(0.14))
                .offset(y: 1)
            Text(String(name.prefix(1)))
                .font(.system(size: 7, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.24, green: 0.10, blue: 0.07))
                .minimumScaleFactor(0.7)
        }
        .frame(width: 17, height: 18)
        .shadow(color: .black.opacity(0.42), radius: 2, y: 1)
        .accessibilityHidden(true)
    }
}

struct CommanderShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.10, y: rect.minY + rect.height * 0.66))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.minY + rect.height * 0.86)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.10, y: rect.minY + rect.height * 0.66),
            control: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.86)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.18))
        path.closeSubpath()
        return path
    }
}
