import SwiftUI

struct WarMapView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    @State private var viewport = MapViewportState()
    @GestureState private var gestureMagnification: CGFloat = 1
    @GestureState private var gestureTranslation: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            let metrics = HexMetrics(
                mapWidth: viewModel.state.width,
                mapHeight: viewModel.state.height,
                container: proxy.size
            )
            let attackTargets: [ArmyUnit] = viewModel.attackTargets
            let attackTargetIDs = Set(attackTargets.map(\.id))
            let enemyIntentSummaries = viewModel.enemyIntentSummaries
            let enemyIntentOverlays = viewModel.enemyIntentMapOverlays(for: enemyIntentSummaries)
            let enemyIntentsByUnit = Dictionary(uniqueKeysWithValues: enemyIntentSummaries.map { ($0.unit.id, $0) })
            let enemyIntentDestinations = viewModel.enemyIntentDestinationOverlays(for: enemyIntentOverlays)
            let enemyIntentTargets = viewModel.enemyIntentTargetOverlays(for: enemyIntentOverlays)
            let tacticalRecommendation = viewModel.selectedTacticalRecommendationSummary
            let tacticalRecommendationPathPositions = viewModel.selectedTacticalRecommendationPathPositions
            let tacticalRecommendationTargetPosition = viewModel.selectedTacticalRecommendationTargetPosition
            let maneuverOptionOverlays = viewModel.maneuverOptionOverlaysByPosition
            let battleObjectiveOverlay = viewModel.primaryBattleObjectiveMapOverlay
            let battleObjectiveOverlays = viewModel.battleObjectiveOverlaysByPosition
            let activeBattleObjectiveStageRole = viewModel.activeBattleObjectiveStageRole
            let countermeasureOverlay = viewModel.primaryCountermeasureMapOverlay
            let countermeasureOverlays = viewModel.countermeasureOverlaysByPosition
            let reconHUD = viewModel.mapReconPerspectiveHUDReadout
            let engagementLoop = viewModel.primaryEnemyEngagementLoopReadout
            let selectedPosition = viewModel.focusedPosition
            let selectedAttackSourceID = viewModel.selectedCombatForecast?.attacker.id
            let skillRangePositions = viewModel.selectedGeneralSkillRangePositions
            let skillTargetPositions = viewModel.selectedGeneralSkillTargetPositions
            let skillTargetUnitIDs = viewModel.selectedGeneralSkillTargetUnitIDs
            let skillTargetCityIDs = viewModel.selectedGeneralSkillTargetCityIDs
            let threatHeatOverlaysByPosition = viewModel.threatHeatZoneOverlaysByPosition
            let mapControlSummaries = Dictionary(uniqueKeysWithValues: viewModel.mapControlSummaries.map { ($0.position, $0) })
            let mapControlOverlayPositions = viewModel.mapControlOverlayPositions
            let overlayPresentation = MapOverlayPresentation(
                perspective: viewModel.selectedMapReconPerspective
            )
            let interactiveViewport = viewport.applying(
                magnification: gestureMagnification,
                translation: gestureTranslation,
                in: proxy.size
            )
            let coastlineSegments = CoastlineBuilder.segments(
                tiles: viewModel.state.tiles,
                metrics: metrics
            )

            ZStack {
                ZStack {
                    MapBackdropView()

                    CoastlineLayerView(segments: coastlineSegments, metrics: metrics)
                        .zIndex(0.5)

                    EnemyIntentRouteLayerView(overlays: enemyIntentOverlays, metrics: metrics)
                        .opacity(overlayPresentation.enemyRouteOpacity)
                        .allowsHitTesting(false)
                        .zIndex(1)

                    if let tacticalRecommendation {
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
                            tacticalRecommendation: tacticalRecommendation,
                            maneuverOption: maneuverOptionOverlays[tile.position],
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
                            isMapControlOverlay: overlayPresentation.showsTerrainPressure &&
                                mapControlOverlayPositions.contains(tile.position),
                            isTacticalRecommendationPath: tacticalRecommendationPathPositions.contains(tile.position),
                            isTacticalRecommendationTarget: tacticalRecommendationTargetPosition == tile.position,
                            isSelected: selectedPosition == tile.position,
                            isAttackOrigin: unit?.id == selectedAttackSourceID,
                            isReachable: viewModel.reachablePositions.contains(tile.position),
                            isAttackTarget: attackTargets.contains { $0.position == tile.position },
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
                    HStack {
                        BattlefieldStatusRibbonView()
                            .frame(
                                width: proxy.size.width < 620
                                    ? 132
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

                VStack {
                    Spacer()
                    MapIntelligenceDockView(
                        readout: reconHUD,
                        engagementLoop: engagementLoop,
                        legendItems: viewModel.activeMapOverlayLegendItems,
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
            .frame(minWidth: 44, minHeight: 44)
            .background(.black.opacity(0.30))
            .clipShape(.rect(cornerRadius: 6))
            .contentShape(Rectangle())
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
        .background(.black.opacity(0.52))
        .clipShape(.rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
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
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(.black.opacity(enabled ? 0.46 : 0.18))
            .clipShape(.rect(cornerRadius: 5))
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

    var body: some View {
        HStack(spacing: 6) {
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
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.black.opacity(0.50))
        .clipShape(.rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(red: 0.84, green: 0.66, blue: 0.32).opacity(0.30), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
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

        if let commanderThreat = viewModel.primaryEnemyCommanderThreatSummary {
            TacticalChipView(
                symbol: commanderThreat.trait.systemImage,
                label: "敌将",
                value: commanderThreat.compactTitle,
                tint: commanderThreat.level.tintColor,
                compact: compact,
                accessibilityLabel: commanderThreat.accessibilityLabel
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
    var usesTwoRows: Bool
    var onSelect: (MapReconPerspectiveKind) -> Void

    var body: some View {
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
                            items: legendItems,
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
                        items: legendItems,
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
                .stroke(Color(red: 0.84, green: 0.66, blue: 0.32).opacity(0.32), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.28), radius: 5, y: 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(readout.accessibilityLabel)
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
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 8)
        .frame(height: 24)
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

struct MapBackdropView: View {
    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.22, blue: 0.23)

            Canvas { context, size in
                var westernLand = Path()
                westernLand.move(to: CGPoint(x: 0, y: size.height * 0.08))
                westernLand.addCurve(
                    to: CGPoint(x: size.width * 0.46, y: size.height * 0.18),
                    control1: CGPoint(x: size.width * 0.15, y: size.height * 0.02),
                    control2: CGPoint(x: size.width * 0.31, y: size.height * 0.30)
                )
                westernLand.addCurve(
                    to: CGPoint(x: size.width * 0.39, y: size.height),
                    control1: CGPoint(x: size.width * 0.57, y: size.height * 0.50),
                    control2: CGPoint(x: size.width * 0.48, y: size.height * 0.82)
                )
                westernLand.addLine(to: CGPoint(x: 0, y: size.height))
                westernLand.closeSubpath()
                context.fill(westernLand, with: .color(Color(red: 0.31, green: 0.36, blue: 0.23).opacity(0.72)))

                var easternLand = Path()
                easternLand.move(to: CGPoint(x: size.width, y: 0))
                easternLand.addLine(to: CGPoint(x: size.width * 0.61, y: 0))
                easternLand.addCurve(
                    to: CGPoint(x: size.width * 0.56, y: size.height * 0.64),
                    control1: CGPoint(x: size.width * 0.50, y: size.height * 0.19),
                    control2: CGPoint(x: size.width * 0.68, y: size.height * 0.38)
                )
                easternLand.addCurve(
                    to: CGPoint(x: size.width, y: size.height * 0.78),
                    control1: CGPoint(x: size.width * 0.68, y: size.height * 0.88),
                    control2: CGPoint(x: size.width * 0.84, y: size.height * 0.67)
                )
                easternLand.closeSubpath()
                context.fill(easternLand, with: .color(Color(red: 0.37, green: 0.32, blue: 0.23).opacity(0.68)))

                var highlands = Path()
                highlands.move(to: CGPoint(x: size.width * 0.12, y: size.height * 0.58))
                highlands.addCurve(
                    to: CGPoint(x: size.width * 0.88, y: size.height * 0.30),
                    control1: CGPoint(x: size.width * 0.32, y: size.height * 0.34),
                    control2: CGPoint(x: size.width * 0.60, y: size.height * 0.47)
                )
                highlands.addCurve(
                    to: CGPoint(x: size.width * 0.16, y: size.height * 0.69),
                    control1: CGPoint(x: size.width * 0.64, y: size.height * 0.55),
                    control2: CGPoint(x: size.width * 0.37, y: size.height * 0.74)
                )
                highlands.closeSubpath()
                context.fill(highlands, with: .color(Color(red: 0.36, green: 0.30, blue: 0.22).opacity(0.28)))

                for offset in stride(from: 0.08, through: 0.92, by: 0.14) {
                    var contour = Path()
                    contour.move(to: CGPoint(x: 0, y: size.height * offset))
                    contour.addCurve(
                        to: CGPoint(x: size.width, y: size.height * max(0.04, offset - 0.08)),
                        control1: CGPoint(x: size.width * 0.28, y: size.height * (offset - 0.11)),
                        control2: CGPoint(x: size.width * 0.66, y: size.height * (offset + 0.10))
                    )
                    context.stroke(contour, with: .color(.white.opacity(0.045)), lineWidth: 1)
                }

                var strategicRoad = Path()
                strategicRoad.move(to: CGPoint(x: size.width * 0.03, y: size.height * 0.78))
                strategicRoad.addCurve(
                    to: CGPoint(x: size.width * 0.97, y: size.height * 0.18),
                    control1: CGPoint(x: size.width * 0.33, y: size.height * 0.42),
                    control2: CGPoint(x: size.width * 0.70, y: size.height * 0.63)
                )
                context.stroke(strategicRoad, with: .color(Color(red: 0.80, green: 0.64, blue: 0.40).opacity(0.15)), lineWidth: 3)
                context.stroke(
                    strategicRoad,
                    with: .color(.white.opacity(0.08)),
                    style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [8, 10])
                )

                for x in stride(from: 12.0, through: size.width, by: 31) {
                    for y in stride(from: 10.0, through: size.height, by: 29) {
                        let phase = Int(x + y).isMultiple(of: 2) ? 0.025 : 0.014
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: 1.3, height: 1.3)),
                            with: .color(.white.opacity(phase))
                        )
                    }
                }
            }

            LinearGradient(
                colors: [.black.opacity(0.18), .clear, .black.opacity(0.24)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
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
        // 视觉相邻用两格中心距离判定：相邻中心距 ≤ 0.87 倍 tileWidth，
        // 次近中心距 ≥ 1.27 倍 tileWidth，阈值取 0.95 倍稳定区分。
        let threshold = metrics.tileWidth * 0.95
        let waterTiles = tiles.filter { $0.terrain == .water }
        let landTiles = tiles.filter { $0.terrain != .water }
        var segments: [CoastlineSegment] = []
        for water in waterTiles {
            let waterCenter = metrics.center(for: water.position)
            for land in landTiles {
                let landCenter = metrics.center(for: land.position)
                let dx = landCenter.x - waterCenter.x
                let dy = landCenter.y - waterCenter.y
                guard (dx * dx + dy * dy).squareRoot() <= threshold else { continue }
                segments.append(CoastlineSegment(waterPosition: water.position, landPosition: land.position))
            }
        }
        return segments
    }
}

struct CoastlineLayerView: View {
    var segments: [CoastlineSegment]
    var metrics: HexMetrics

    private static let sandColor = Color(red: 0.82, green: 0.72, blue: 0.50)
    private static let foamColor = Color(red: 0.72, green: 0.86, blue: 0.90)

    var body: some View {
        Canvas { context, _ in
            for segment in segments {
                let water = metrics.center(for: segment.waterPosition)
                let land = metrics.center(for: segment.landPosition)
                let mid = CGPoint(x: (water.x + land.x) / 2, y: (water.y + land.y) / 2)
                let dx = land.x - water.x
                let dy = land.y - water.y
                let length = max(1, (dx * dx + dy * dy).squareRoot())
                let perpX = -dy / length
                let perpY = dx / length
                let half = metrics.tileHeight * 0.34

                var shore = Path()
                shore.move(to: CGPoint(x: mid.x - perpX * half, y: mid.y - perpY * half))
                shore.addLine(to: CGPoint(x: mid.x + perpX * half, y: mid.y + perpY * half))
                context.stroke(
                    shore,
                    with: .color(Self.sandColor.opacity(0.66)),
                    style: StrokeStyle(lineWidth: max(2.4, metrics.tileWidth * 0.075), lineCap: .round)
                )

                let towardWaterX = -dx / length * metrics.tileWidth * 0.075
                let towardWaterY = -dy / length * metrics.tileWidth * 0.075
                var foam = Path()
                foam.move(to: CGPoint(
                    x: mid.x - perpX * half * 0.82 + towardWaterX,
                    y: mid.y - perpY * half * 0.82 + towardWaterY
                ))
                foam.addLine(to: CGPoint(
                    x: mid.x + perpX * half * 0.82 + towardWaterX,
                    y: mid.y + perpY * half * 0.82 + towardWaterY
                ))
                context.stroke(
                    foam,
                    with: .color(Self.foamColor.opacity(0.34)),
                    style: StrokeStyle(lineWidth: max(1, metrics.tileWidth * 0.028), lineCap: .round)
                )
            }
        }
        .allowsHitTesting(false)
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
                .fill(tileColor)
                .overlay {
                    TerrainTextureView(terrain: tile.terrain, scale: scale)
                }
                .overlay {
                    if let faction = controlFaction {
                        Hexagon()
                            .stroke(faction.factionColor.opacity(0.48), lineWidth: max(1.2, 1.8 * scale))
                            .padding(2.4 * scale)
                    }
                }
                .overlay {
                    Hexagon()
                        .stroke(borderColor, lineWidth: isSelected || isAttackOrigin || isAttackTarget ? max(2.4, 3 * scale) : max(0.4, 0.55 * scale))
                }

            TerrainGlyphView(terrain: tile.terrain, scale: scale)
                .opacity(city == nil && unit == nil ? tile.terrain.materialProfile.landmarkOpacity : 0.08)
                .offset(x: 10 * scale, y: 8 * scale)

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
        .shadow(color: .black.opacity(isSelected || isAttackOrigin ? 0.38 : 0.18), radius: isSelected || isAttackOrigin ? 9 : 2, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityHidden(isAttackTarget)
    }

    private var tileColor: Color {
        let base: (red: Double, green: Double, blue: Double)
        switch tile.terrain {
        case .plains: base = (0.43, 0.49, 0.27)
        case .forest: base = (0.13, 0.32, 0.19)
        case .hills: base = (0.47, 0.38, 0.27)
        case .water: base = (0.12, 0.37, 0.52)
        case .road: base = (0.51, 0.43, 0.29)
        case .city: base = (0.43, 0.35, 0.27)
        }

        // 按坐标确定性微调明度，弱化逐格填色的棋盘感。
        let phase = Double((tile.position.x * 7 + tile.position.y * 13) % 5) - 2
        let tone = 1 + phase * 0.015
        return Color(
            red: min(1, max(0, base.red * tone)),
            green: min(1, max(0, base.green * tone)),
            blue: min(1, max(0, base.blue * tone))
        )
    }

    private var borderColor: Color {
        if isAttackTarget { return .red }
        if isSelected { return .white }
        if isAttackOrigin { return .cyan }
        if isReachable { return .yellow.opacity(0.8) }
        return .black.opacity(0.05)
    }

    private var controlFaction: Faction? {
        if let city, city.owner != .neutral {
            return city.owner
        }

        if let unit, unit.faction != .neutral {
            return unit.faction
        }

        return nil
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

    var body: some View {
        ZStack {
            switch terrain {
            case .road:
                RoadTextureView(scale: scale)
            case .water:
                WaterTextureView(scale: scale)
            case .city:
                CityTileTextureView(scale: scale)
            case .forest:
                ForestTextureView(scale: scale)
            case .hills:
                HillsTextureView(scale: scale)
            case .plains:
                PlainsTextureView(scale: scale)
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
                .fill(Color(red: 0.92, green: 0.76, blue: 0.28).opacity(0.17))
            Hexagon()
                .stroke(
                    Color(red: 0.96, green: 0.82, blue: 0.36).opacity(0.95),
                    style: StrokeStyle(lineWidth: max(1.3, 1.9 * scale), lineCap: .round, dash: [5 * scale, 4 * scale])
                )
                .padding(4 * scale)
            Circle()
                .fill(Color(red: 0.96, green: 0.82, blue: 0.36))
                .frame(width: 7 * scale, height: 7 * scale)
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
        }
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

struct RoadTextureView: View {
    var scale: CGFloat

    var body: some View {
        ZStack {
            RouteLineShape()
                .stroke(.black.opacity(0.30), style: StrokeStyle(lineWidth: max(5, 7 * scale), lineCap: .round))
            RouteLineShape()
                .stroke(Color(red: 0.84, green: 0.66, blue: 0.38).opacity(0.82), style: StrokeStyle(lineWidth: max(2.8, 4.4 * scale), lineCap: .round))
            RouteLineShape()
                .stroke(.white.opacity(0.24), style: StrokeStyle(lineWidth: max(0.8, 1.1 * scale), lineCap: .round, dash: [4 * scale, 5 * scale]))

            HStack(spacing: 5 * scale) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(.black.opacity(index.isMultiple(of: 2) ? 0.14 : 0.08))
                        .frame(width: 2.2 * scale, height: 2.2 * scale)
                }
            }
            .offset(y: 12 * scale)
        }
        .padding(6 * scale)
    }
}

struct WaterTextureView: View {
    var scale: CGFloat

    var body: some View {
        Canvas { context, size in
            for index in 0..<4 {
                let y = size.height * (0.24 + CGFloat(index) * 0.18)
                var wave = Path()
                wave.move(to: CGPoint(x: size.width * 0.12, y: y))
                wave.addCurve(
                    to: CGPoint(x: size.width * 0.88, y: y - 1.5 * scale),
                    control1: CGPoint(x: size.width * 0.34, y: y - 5 * scale),
                    control2: CGPoint(x: size.width * 0.62, y: y + 5 * scale)
                )
                context.stroke(
                    wave,
                    with: .color(.white.opacity(index.isMultiple(of: 2) ? 0.22 : 0.11)),
                    lineWidth: max(0.8, 1.2 * scale)
                )
            }
        }
    }
}

struct CityTileTextureView: View {
    var scale: CGFloat

    var body: some View {
        ZStack {
            VStack(spacing: 4 * scale) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 4 * scale) {
                        ForEach(0..<4, id: \.self) { column in
                            Rectangle()
                                .fill(.black.opacity((row + column).isMultiple(of: 2) ? 0.13 : 0.07))
                                .frame(width: 7 * scale, height: 5 * scale)
                        }
                    }
                }
            }

            RoundedRectangle(cornerRadius: 2 * scale)
                .stroke(Color(red: 0.88, green: 0.70, blue: 0.36).opacity(0.34), lineWidth: max(1, 1.5 * scale))
                .frame(width: 43 * scale, height: 30 * scale)
        }
    }
}

struct ForestTextureView: View {
    var scale: CGFloat

    var body: some View {
        ZStack {
            HStack(alignment: .bottom, spacing: 6 * scale) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(.black.opacity(0.18))
                        .frame(width: max(1, 1.8 * scale), height: (9 + CGFloat(index % 2) * 3) * scale)
                }
            }
            .offset(y: 8 * scale)

            HStack(spacing: -1 * scale) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index.isMultiple(of: 2) ? .black.opacity(0.18) : .white.opacity(0.08))
                        .frame(width: (10 + CGFloat(index % 3) * 2) * scale, height: (10 + CGFloat(index % 3) * 2) * scale)
                        .offset(y: CGFloat(index % 2) * 5 * scale)
                }
            }
        }
    }
}

struct HillsTextureView: View {
    var scale: CGFloat

    var body: some View {
        ZStack {
            HStack(alignment: .bottom, spacing: -8 * scale) {
                TriangleHillShape()
                    .fill(.white.opacity(0.11))
                    .frame(width: 28 * scale, height: 17 * scale)
                TriangleHillShape()
                    .fill(.black.opacity(0.16))
                    .frame(width: 34 * scale, height: 22 * scale)
            }
            .offset(y: 7 * scale)

            VStack(spacing: 5 * scale) {
                Capsule()
                    .fill(.white.opacity(0.10))
                    .frame(width: 42 * scale, height: max(1, 1.3 * scale))
                Capsule()
                    .fill(.black.opacity(0.10))
                    .frame(width: 30 * scale, height: max(1, 1.3 * scale))
                    .offset(x: 7 * scale)
            }
            .offset(y: 16 * scale)
        }
    }
}

struct PlainsTextureView: View {
    var scale: CGFloat

    var body: some View {
        ZStack {
            VStack(spacing: 5 * scale) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index.isMultiple(of: 2) ? .white.opacity(0.12) : .black.opacity(0.08))
                        .frame(width: (38 - CGFloat(index) * 3) * scale, height: max(1, 1.5 * scale))
                        .offset(x: CGFloat(index % 2) * 5 * scale)
                }
            }
            .rotationEffect(.degrees(-9))

            HStack(spacing: 12 * scale) {
                ForEach(0..<3, id: \.self) { _ in
                    Image(systemName: "line.diagonal")
                        .font(.system(size: 5 * scale, weight: .bold))
                        .foregroundStyle(.white.opacity(0.16))
                }
            }
            .offset(y: 13 * scale)
        }
    }
}

struct RouteLineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.10))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY - rect.height * 0.08),
            control1: CGPoint(x: rect.minX + rect.width * 0.32, y: rect.minY + rect.height * 0.18),
            control2: CGPoint(x: rect.minX + rect.width * 0.66, y: rect.maxY - rect.height * 0.12)
        )
        return path
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

        ZStack(alignment: .bottom) {
            CityWallShape()
                .fill(owner.factionColor)

            HStack(alignment: .bottom, spacing: compact ? 1 : 2) {
                Rectangle()
                    .frame(width: width * 0.18, height: height * 0.46)
                Rectangle()
                    .frame(width: width * 0.22, height: height * 0.68)
                Rectangle()
                    .frame(width: width * 0.18, height: height * 0.52)
            }
            .foregroundStyle(.white.opacity(0.82))
            .padding(.bottom, height * 0.16)

            Rectangle()
                .fill(Color(red: 0.90, green: 0.72, blue: 0.34))
                .frame(height: compact ? 3 : 4)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(width: width, height: height)
        .overlay {
            CityWallShape()
                .stroke(.black.opacity(0.34), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.34), radius: 2, y: 1)
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

struct UnitTokenView: View {
    var unit: ArmyUnit

    var body: some View {
        VStack(spacing: 1) {
            LegionStandardShape()
                .fill(unit.faction.factionColor)
                .frame(width: 38, height: 29)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color(red: 0.86, green: 0.68, blue: 0.34))
                        .frame(height: 4)
                }
                .overlay {
                    HStack(spacing: 3) {
                        Image(systemName: unit.kind.tokenSystemImage)
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(.white.opacity(0.88))
                        Text(unit.kind.shortLabel)
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
                    }
                    .offset(y: 1)
                }
                .overlay {
                    LegionStandardShape()
                        .stroke(.white.opacity(unit.faction == .rome ? 0.34 : 0.18), lineWidth: 1)
                }
                .overlay(alignment: .topTrailing) {
                    if let generalName = unit.generalName {
                        CommanderTokenBadgeView(name: generalName)
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
                    Capsule().fill(.black.opacity(0.5))
                    Capsule()
                        .fill(unit.healthRatio > 0.42 ? Color.green : Color.red)
                        .frame(width: proxy.size.width * unit.healthRatio)
                    Text("\(unit.health)")
                        .font(.system(size: 6, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(width: 38, height: 7)
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

    var body: some View {
        ZStack {
            CommanderShieldShape()
                .fill(Color(red: 0.93, green: 0.72, blue: 0.24))
            CommanderShieldShape()
                .stroke(.white.opacity(0.92), lineWidth: 1)
            Image(systemName: "person.fill")
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
