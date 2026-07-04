import SwiftUI

struct BattleView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        GeometryReader { proxy in
            let isPhonePortrait = proxy.size.width < 700 && proxy.size.height >= proxy.size.width
            let isShortLandscape = proxy.size.width > proxy.size.height && proxy.size.height < 560
            let usesCondensedTopBar = proxy.size.width < 900 || isShortLandscape
            let panelWidth = min(340, max(270, proxy.size.width * (isShortLandscape ? 0.32 : 0.30)))
            let battlefieldHeight = max(0, proxy.size.height - (usesCondensedTopBar ? 54 : 64))
            let mapPadding: CGFloat = isShortLandscape ? 8 : 10
            let mapHeight = max(0, battlefieldHeight - mapPadding * 2)
            let phoneMapHeight = max(280, min(360, proxy.size.height * 0.45))
            let phoneContentWidth = max(0, proxy.size.width - 20)

            ZStack {
                Color(red: 0.09, green: 0.10, blue: 0.10)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    TopBarView(isCondensed: usesCondensedTopBar)

                    if isPhonePortrait {
                        VStack(spacing: 10) {
                            WarMapView()
                                .frame(width: phoneContentWidth, height: phoneMapHeight)

                            PhoneCommandDeckView()
                                .frame(width: phoneContentWidth)
                                .frame(maxHeight: .infinity, alignment: .top)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    } else {
                        HStack(alignment: .top, spacing: 0) {
                            WarMapView()
                                .frame(maxWidth: .infinity)
                                .frame(height: mapHeight)
                                .padding(mapPadding)

                            if isShortLandscape {
                                CompactCommandPanelView()
                                    .frame(width: panelWidth)
                                    .frame(maxHeight: .infinity, alignment: .top)
                            } else {
                                #if os(macOS)
                                CommandPanelView()
                                    .frame(width: panelWidth)
                                    .frame(height: battlefieldHeight, alignment: .top)
                                    .clipped()
                                #else
                                ScrollView(showsIndicators: false) {
                                    CommandPanelView()
                                        .frame(width: panelWidth)
                                }
                                .frame(width: panelWidth)
                                .frame(height: battlefieldHeight, alignment: .top)
                                .background(Color(red: 0.12, green: 0.12, blue: 0.11))
                                #endif
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: battlefieldHeight, alignment: .top)
                    }
                }
            }
        }
    }
}

struct PhoneCommandDeckView: View {
    var body: some View {
        VStack(spacing: 8) {
            CompactSelectionPanelView()
            BattlefieldFocusPanelView(isCompact: true)
            CompactActionsPanelView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct TopBarView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    var isCondensed = false

    var body: some View {
        HStack(spacing: isCondensed ? 8 : 12) {
            Button {
                viewModel.openMenu()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title3.weight(.bold))
                    .frame(width: isCondensed ? 38 : 42, height: isCondensed ? 38 : 42)
            }
            .buttonStyle(CommandIconButtonStyle())

            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.state.mode.displayName) · 第 \(viewModel.state.turn) 回合 · \(viewModel.campaignStatusTitle)")
                    .font(.headline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(viewModel.bannerMessage)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(.white)

            Spacer(minLength: 8)

            if isCondensed {
                CompactResourcePill(resources: viewModel.romanResources)
            } else {
                ResourcePill(symbol: "circle.stack.fill", value: viewModel.romanResources.gold, tint: .yellow)
                ResourcePill(symbol: "leaf.fill", value: viewModel.romanResources.grain, tint: .green)
                ResourcePill(symbol: "shield.fill", value: viewModel.romanResources.iron, tint: .gray)
                ResourcePill(symbol: "sparkle.magnifyingglass", value: viewModel.romanResources.science, tint: .cyan)
                ResourcePill(symbol: "star.fill", value: viewModel.romanResources.prestige, tint: .orange)
            }

            Button {
                viewModel.endTurn()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "arrow.clockwise")
                    Text(isCondensed ? "回合" : "结束")
                }
                .font(.subheadline.weight(.bold))
                .frame(height: isCondensed ? 36 : 38)
                .padding(.horizontal, isCondensed ? 10 : 12)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isCampaignOver)
        }
        .padding(.horizontal, isCondensed ? 8 : 12)
        .padding(.vertical, isCondensed ? 8 : 10)
        .background(Color(red: 0.14, green: 0.13, blue: 0.11))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1)
        }
    }
}

struct CompactResourcePill: View {
    var resources: EmpireResources

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "circle.stack.fill")
                .foregroundStyle(.yellow)
            Text(resources.gold, format: .number)
                .font(.caption.monospacedDigit().weight(.bold))
            Image(systemName: "shield.fill")
                .foregroundStyle(.gray)
            Text(resources.iron, format: .number)
                .font(.caption.monospacedDigit().weight(.bold))
        }
        .foregroundStyle(.white)
        .frame(minHeight: 32)
        .padding(.horizontal, 8)
        .background(.black.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ResourcePill: View {
    var symbol: String
    var value: Int
    var tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
            Text(value, format: .number)
                .font(.subheadline.monospacedDigit().weight(.bold))
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(.white)
        .frame(minWidth: 64, minHeight: 34)
        .padding(.horizontal, 8)
        .background(.black.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct WarMapView: View {
    @EnvironmentObject private var viewModel: GameViewModel

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
            let selectedPosition = viewModel.focusedPosition
            let skillRangePositions = viewModel.selectedGeneralSkillRangePositions
            let skillTargetPositions = viewModel.selectedGeneralSkillTargetPositions
            let skillTargetUnitIDs = viewModel.selectedGeneralSkillTargetUnitIDs
            let skillTargetCityIDs = viewModel.selectedGeneralSkillTargetCityIDs

            ZStack {
                MapBackdropView()

                EnemyIntentRouteLayerView(overlays: enemyIntentOverlays, metrics: metrics)
                    .allowsHitTesting(false)
                    .zIndex(1)

                ForEach(viewModel.state.tiles) { tile in
                    let city = viewModel.state.city(at: tile.position)
                    let unit = viewModel.state.unit(at: tile.position)
                    let center = metrics.center(for: tile.position)
                    HexTileView(
                        tile: tile,
                        city: city,
                        unit: unit,
                        enemyIntent: unit.flatMap { enemyIntentsByUnit[$0.id] },
                        enemyIntentDestination: enemyIntentDestinations[tile.position],
                        enemyIntentTarget: enemyIntentTargets[tile.position],
                        isSelected: selectedPosition == tile.position,
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
                        unit: target,
                        preview: viewModel.attackPreview(for: target.id),
                        scale: metrics.actionScale
                    )
                        .position(x: center.x, y: center.y - metrics.tileHeight * 0.57)
                        .onTapGesture {
                            viewModel.attack(target.id)
                        }
                        .zIndex(4)
                }

                ForEach(viewModel.state.units.filter { attackTargetIDs.contains($0.id) }) { target in
                    let center = metrics.center(for: target.position)
                    AttackTargetRing()
                        .frame(width: metrics.tileWidth * 0.92, height: metrics.tileHeight * 0.92)
                        .position(center)
                        .allowsHitTesting(false)
                        .zIndex(3)
                }

                VStack {
                    HStack {
                        TacticalStatusStripView()
                            .frame(maxWidth: min(proxy.size.width - 20, 560), alignment: .leading)
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    Spacer()
                }
                .allowsHitTesting(false)
                .zIndex(5)

                VStack {
                    Spacer()
                    HStack {
                        MiniLegendView()
                        Spacer()
                    }
                    .padding(12)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
        }
    }
}

struct AttackTargetButton: View {
    var unit: ArmyUnit
    var preview: CombatPreview?
    var scale: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.78, green: 0.08, blue: 0.05))
                Circle()
                    .stroke(.white.opacity(0.92), lineWidth: 2)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 15 * scale, weight: .black))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                    .offset(y: preview == nil ? 0 : -3 * scale)

                if let preview {
                    Text(preview.defeatsDefender ? "破" : "-\(preview.damage)")
                        .font(.system(size: 8 * scale, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .offset(y: 9 * scale)
                }
            }
            .frame(width: 36 * scale, height: 36 * scale)
            .shadow(color: .red.opacity(0.65), radius: 8, y: 2)

            TrianglePointer()
                .fill(Color(red: 0.78, green: 0.08, blue: 0.05))
                .frame(width: 13 * scale, height: 7 * scale)
                .offset(y: -1)
        }
        .accessibilityLabel("攻击\(unit.faction.displayName)\(unit.kind.displayName)")
        .accessibilityAddTraits(.isButton)
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
    }
}

struct TacticalChipView: View {
    var symbol: String
    var label: String
    var value: String
    var tint: Color
    var compact = false

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
    }
}

struct AttackTargetRing: View {
    var body: some View {
        ZStack {
            Hexagon()
                .stroke(Color.red.opacity(0.95), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [7, 5]))
            Hexagon()
                .stroke(Color.yellow.opacity(0.55), lineWidth: 1)
                .padding(4)
        }
        .shadow(color: .red.opacity(0.55), radius: 6)
    }
}

struct MapBackdropView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.25, blue: 0.22),
                    Color(red: 0.20, green: 0.31, blue: 0.33),
                    Color(red: 0.18, green: 0.16, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Canvas { context, size in
                var path = Path()
                for x in stride(from: 0, through: size.width, by: 42) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + 24, y: size.height))
                }
                for y in stride(from: 0, through: size.height, by: 38) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y + 16))
                }
                context.stroke(path, with: .color(.white.opacity(0.035)), lineWidth: 1)
            }
        }
    }
}

struct HexTileView: View {
    var tile: Tile
    var city: City?
    var unit: ArmyUnit?
    var enemyIntent: EnemyIntentSummary?
    var enemyIntentDestination: EnemyIntentMapOverlay?
    var enemyIntentTarget: EnemyIntentMapOverlay?
    var isSelected: Bool
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
                            .stroke(faction.factionColor.opacity(0.72), lineWidth: max(1.6, 2.4 * scale))
                            .padding(2.4 * scale)
                    }
                }
                .overlay {
                    Hexagon()
                        .stroke(borderColor, lineWidth: isSelected || isAttackTarget ? max(2.4, 3 * scale) : max(0.8, 1.1 * scale))
                }

            TerrainGlyphView(terrain: tile.terrain)
                .scaleEffect(scale)
                .opacity(city == nil && unit == nil ? 0.42 : 0.20)

            if isSkillRange && !isAttackTarget {
                SkillRangeOverlay(scale: scale)
            }

            if isReachable {
                ReachableTileOverlay(scale: scale)
            }

            if isSkillTarget && !isAttackTarget {
                SkillTargetOverlay(scale: scale)
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

            if isAttackTarget {
                AttackTileOverlay(scale: scale)
            }
        }
        .shadow(color: .black.opacity(isSelected ? 0.38 : 0.18), radius: isSelected ? 9 : 2, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var tileColor: Color {
        switch tile.terrain {
        case .plains: return Color(red: 0.40, green: 0.50, blue: 0.28)
        case .forest: return Color(red: 0.15, green: 0.36, blue: 0.21)
        case .hills: return Color(red: 0.48, green: 0.40, blue: 0.30)
        case .water: return Color(red: 0.15, green: 0.40, blue: 0.56)
        case .road: return Color(red: 0.53, green: 0.45, blue: 0.32)
        case .city: return Color(red: 0.46, green: 0.38, blue: 0.30)
        }
    }

    private var borderColor: Color {
        if isAttackTarget { return .red }
        if isSelected { return .white }
        if isReachable { return .yellow.opacity(0.8) }
        return .black.opacity(0.28)
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

struct RoadTextureView: View {
    var scale: CGFloat

    var body: some View {
        ZStack {
            RouteLineShape()
                .stroke(.black.opacity(0.24), style: StrokeStyle(lineWidth: max(4, 6 * scale), lineCap: .round))
            RouteLineShape()
                .stroke(Color(red: 0.88, green: 0.68, blue: 0.36).opacity(0.88), style: StrokeStyle(lineWidth: max(2.4, 4 * scale), lineCap: .round))
            RouteLineShape()
                .stroke(.white.opacity(0.20), style: StrokeStyle(lineWidth: max(0.8, 1.2 * scale), lineCap: .round, dash: [5 * scale, 5 * scale]))
        }
        .padding(6 * scale)
    }
}

struct WaterTextureView: View {
    var scale: CGFloat

    var body: some View {
        VStack(spacing: 5 * scale) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(0.14))
                    .frame(width: (index == 1 ? 34 : 26) * scale, height: max(1, 2 * scale))
                    .offset(x: index == 1 ? -4 * scale : 5 * scale)
            }
        }
        .rotationEffect(.degrees(-8))
    }
}

struct CityTileTextureView: View {
    var scale: CGFloat

    var body: some View {
        VStack(spacing: 3 * scale) {
            Rectangle()
                .fill(Color(red: 0.88, green: 0.70, blue: 0.36).opacity(0.30))
                .frame(width: 34 * scale, height: 4 * scale)
            Rectangle()
                .fill(Color(red: 0.88, green: 0.70, blue: 0.36).opacity(0.22))
                .frame(width: 44 * scale, height: 4 * scale)
        }
    }
}

struct ForestTextureView: View {
    var scale: CGFloat

    var body: some View {
        HStack(spacing: 5 * scale) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(.black.opacity(0.13))
                    .frame(width: (8 + CGFloat(index % 2) * 3) * scale, height: (8 + CGFloat(index % 2) * 3) * scale)
            }
        }
        .offset(y: 8 * scale)
    }
}

struct HillsTextureView: View {
    var scale: CGFloat

    var body: some View {
        HStack(spacing: -5 * scale) {
            TriangleHillShape()
                .fill(.white.opacity(0.12))
                .frame(width: 24 * scale, height: 14 * scale)
            TriangleHillShape()
                .fill(.black.opacity(0.12))
                .frame(width: 28 * scale, height: 16 * scale)
        }
        .offset(y: 8 * scale)
    }
}

struct PlainsTextureView: View {
    var scale: CGFloat

    var body: some View {
        HStack(spacing: 5 * scale) {
            ForEach(0..<3, id: \.self) { _ in
                Capsule()
                    .fill(.white.opacity(0.10))
                    .frame(width: 12 * scale, height: max(1, 2 * scale))
            }
        }
        .offset(y: 9 * scale)
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

    var body: some View {
        Image(systemName: terrain.systemImage)
            .font(.system(size: 21, weight: .black))
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
                RoundedRectangle(cornerRadius: compact ? 4 : 5)
                    .fill(city.owner.factionColor)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(Color(red: 0.86, green: 0.68, blue: 0.34))
                            .frame(height: compact ? 3 : 4)
                    }
                    .overlay {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: compact ? 10 : 13, weight: .black))
                            .foregroundStyle(.white)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: compact ? 4 : 5)
                            .stroke(.black.opacity(0.25), lineWidth: 1)
                    }
                    .frame(width: compact ? 32 : 40, height: compact ? 20 : 30)

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
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }
}

struct UnitTokenView: View {
    var unit: ArmyUnit

    var body: some View {
        VStack(spacing: 1) {
            RoundedRectangle(cornerRadius: 4)
                .fill(unit.faction.factionColor)
                .frame(width: 34, height: 26)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color(red: 0.86, green: 0.68, blue: 0.34))
                        .frame(height: 4)
                }
                .overlay {
                    ZStack {
                        Image(systemName: unit.kind.tokenSystemImage)
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(.white.opacity(0.18))
                            .offset(x: -7, y: 2)
                        Text(unit.kind.shortLabel)
                            .font(.caption.weight(.black))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.white.opacity(unit.faction == .rome ? 0.34 : 0.18), lineWidth: 1)
                }
                .overlay(alignment: .topTrailing) {
                    if unit.generalName != nil {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(Color(red: 0.98, green: 0.82, blue: 0.36))
                            .offset(x: 3, y: -3)
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
                }
            }
            .frame(width: 34, height: 4)
        }
    }
}

struct CommandPanelView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 10) {
            SelectionPanelView()
            BattlefieldFocusPanelView()
            EnemyIntentPanelView()
            StrategicBalancePanelView()
            ActionsPanelView()
            TechnologyPanelView()
            DiplomacyPanelView()
            MissionPanelView()
            LogPanelView()
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color(red: 0.12, green: 0.12, blue: 0.11))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 1)
        }
    }
}

struct CompactCommandPanelView: View {
    var body: some View {
        VStack(spacing: 8) {
            CompactSelectionPanelView()
            BattlefieldFocusPanelView(isCompact: true)
            CompactActionsPanelView()
            CompactLogPanelView()
            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(red: 0.12, green: 0.12, blue: 0.11))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 1)
        }
    }
}

struct CompactSelectionPanelView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        PanelView(title: "情报", symbol: "scope") {
            if let unit = viewModel.selectedUnit {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        UnitTokenView(unit: unit)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(unit.faction.displayName) \(unit.kind.displayName)")
                                .font(.subheadline.weight(.bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                            Text(unit.generalName ?? "无将领")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.64))
                        }
                        Spacer(minLength: 0)
                    }

                    HStack(spacing: 8) {
                        CompactStat(label: "生命", value: "\(unit.health)")
                        CompactStat(label: "攻", value: "\(viewModel.state.effectiveAttack(for: unit))")
                        CompactStat(label: "防", value: "\(viewModel.state.effectiveDefense(for: unit))")
                        CompactStat(label: "移", value: "\(viewModel.state.effectiveMovement(for: unit))")
                    }

                    if let status = viewModel.selectedWarMeritStatus {
                        HStack(spacing: 8) {
                            CompactStat(label: "阶", value: status.rankName)
                            CompactStat(label: "战功", value: "\(status.experience)")
                            CompactStat(label: "伤", value: "+\(status.damageBonus)")
                            CompactStat(label: "技能", value: viewModel.selectedGeneralSkillCooldownDetail ?? "无")
                        }
                    }

                    CompactOrderBadgeView(order: unit.resolvedTacticalOrder)

                    if let trait = unit.resolvedGeneralTrait {
                        CompactGeneralTraitView(
                            trait: trait,
                            preview: viewModel.selectedGeneralSkillPreview,
                            warMeritStatus: viewModel.selectedWarMeritStatus
                        )
                    }
                }
            } else if let city = viewModel.selectedCity {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        CityBadgeView(city: city, compact: true)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(city.name)
                                .font(.subheadline.weight(.bold))
                            Text(city.owner.displayName)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.64))
                        }
                        Spacer(minLength: 0)
                    }

                    HStack(spacing: 8) {
                        CompactStat(label: "金", value: "+\(city.production.gold)")
                        CompactStat(label: "粮", value: "+\(city.production.grain)")
                        CompactStat(label: "铁", value: "+\(city.production.iron)")
                        CompactStat(label: "防", value: "\(city.fortification)")
                    }
                }
            } else {
                Text("选择军团、城市或目标。")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct CompactActionsPanelView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        PanelView(title: "军令", symbol: "flag.fill") {
            VStack(spacing: 7) {
                if let target = viewModel.attackTargets.first {
                    let preview = viewModel.attackPreview(for: target.id)
                    Button {
                        viewModel.attack(target.id)
                    } label: {
                        CommandButtonLabel(
                            symbol: "bolt.fill",
                            text: preview.map { "攻击 \(target.faction.displayName)\(target.kind.displayName) · 伤\($0.damage)" } ?? "攻击 \(target.faction.displayName)\(target.kind.displayName)",
                            detail: preview?.commandModifierSummary
                        )
                    }
                    .buttonStyle(PrimaryButtonStyle())
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.slash.fill")
                            .foregroundStyle(.white.opacity(0.5))
                        Text("当前没有可攻击目标。")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: 30)
                }

                if let unit = viewModel.selectedUnit, unit.faction == .rome {
                    TacticalOrderControlView(unit: unit, isCompact: true)

                    if let trait = unit.resolvedGeneralTrait {
                        Button {
                            viewModel.useSelectedGeneralSkill()
                        } label: {
                            CommandButtonLabel(
                                symbol: trait.systemImage,
                                text: trait.skillName,
                                detail: viewModel.selectedGeneralSkillButtonDetail
                            )
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(!viewModel.canUseSelectedGeneralSkill)
                    }

                    HStack(spacing: 7) {
                        Button {
                            viewModel.restSelectedUnit()
                        } label: {
                            CommandButtonLabel(symbol: "cross.case.fill", text: "休整")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(unit.hasActed || viewModel.isCampaignOver)

                        Button {
                            viewModel.skipSelectedUnit()
                        } label: {
                            CommandButtonLabel(symbol: "forward.end.fill", text: "跳过")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(!viewModel.canSkipSelectedUnit)
                    }
                }

                if let city = viewModel.commandCity, city.owner == .rome {
                    Button {
                        viewModel.developCommandCity()
                    } label: {
                        CommandButtonLabel(symbol: "building.2.crop.circle.fill", text: "扩建")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(viewModel.isCampaignOver)
                }
            }
        }
    }
}

struct CompactGeneralTraitView: View {
    var trait: GeneralTrait
    var preview: GeneralSkillPreview?
    var warMeritStatus: WarMeritStatus?

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: trait.systemImage)
                .foregroundStyle(Color(red: 0.86, green: 0.68, blue: 0.34))
            Text(trait.displayName)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Spacer(minLength: 0)
            Text(trait.skillName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 28)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        if let warMeritStatus {
            HStack(spacing: 6) {
                Image(systemName: "chevron.up.circle.fill")
                    .foregroundStyle(Color(red: 0.98, green: 0.82, blue: 0.36))
                Text(warMeritStatus.summary)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .frame(minHeight: 24)
            .background(.black.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        if let preview {
            HStack(spacing: 6) {
                Image(systemName: preview.isExecutable ? "sparkles" : "exclamationmark.triangle.fill")
                    .foregroundStyle(preview.isExecutable ? Color(red: 0.36, green: 0.86, blue: 0.92) : .orange)
                Text(preview.blockedReason ?? "\(preview.summary) · \(preview.cooldownText)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .frame(minHeight: 24)
            .background(.black.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}

struct CompactOrderBadgeView: View {
    var order: TacticalOrder

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: order.systemImage)
                .foregroundStyle(order.tintColor)
            Text("姿态")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.56))
            Text(order.displayName)
                .font(.caption.weight(.bold))
            Spacer(minLength: 0)
            Text(order.detail)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.56))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 28)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct CompactLogPanelView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        PanelView(title: "战报", symbol: "scroll.fill") {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(viewModel.state.eventLog.suffix(3).enumerated()), id: \.offset) { _, message in
                    Text(message)
                        .font(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(.white.opacity(0.68))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct CompactStat: View {
    var label: String
    var value: String

    var body: some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.56))
            Text(value)
                .font(.caption.monospacedDigit().weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, minHeight: 32)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct BattlefieldFocusPanelView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    var isCompact = false

    var body: some View {
        PanelView(title: "战场", symbol: "map.fill") {
            if let tile = viewModel.selectedTile {
                let city = viewModel.state.city(at: tile.position)
                let totalDefense = tile.terrain.defenseBonus + (city?.fortification ?? 0)

                if isCompact {
                    HStack(spacing: 7) {
                        CompactStat(label: "地形", value: tile.terrain.displayName)
                        CompactStat(label: "移", value: "\(tile.terrain.movementCost)")
                        CompactStat(label: "防", value: "+\(totalDefense)")
                        CompactStat(label: "补", value: viewModel.selectedSupplyLabel)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack(spacing: 9) {
                            Image(systemName: tile.terrain.systemImage)
                                .font(.title3.weight(.heavy))
                                .foregroundStyle(tile.terrain.accentColor)
                                .frame(width: 30, height: 30)
                                .background(.black.opacity(0.24))
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(tile.terrain.displayName)
                                    .font(.subheadline.weight(.heavy))
                                Text("坐标 \(tile.position.description)")
                                    .font(.caption2.monospacedDigit().weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.58))
                            }
                            Spacer(minLength: 0)
                        }

                        HStack(spacing: 8) {
                            BattlefieldStatPill(label: "移动", value: "\(tile.terrain.movementCost)")
                            BattlefieldStatPill(label: "防御", value: "+\(totalDefense)")
                            BattlefieldStatPill(label: "补给", value: viewModel.selectedSupplyLabel)
                        }

                        if let city {
                            HStack(spacing: 8) {
                                Image(systemName: "shield.fill")
                                    .foregroundStyle(Color(red: 0.86, green: 0.68, blue: 0.34))
                                Text("\(city.name) 城防 \(city.fortification)")
                                    .font(.caption.weight(.bold))
                                Spacer(minLength: 0)
                            }
                            .foregroundStyle(.white.opacity(0.76))
                        }

                        if let target = viewModel.attackTargets.first,
                           let preview = viewModel.attackPreview(for: target.id) {
                            VStack(alignment: .leading, spacing: 7) {
                                HStack(spacing: 8) {
                                    Image(systemName: preview.defeatsDefender ? "flame.fill" : "bolt.fill")
                                        .foregroundStyle(preview.defeatsDefender ? .orange : .red)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("\(target.faction.displayName)\(target.kind.displayName)")
                                            .font(.caption.weight(.bold))
                                        Text("伤害 \(preview.damage) · 反击 \(preview.retaliation)")
                                            .font(.caption2.monospacedDigit().weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.64))
                                    }
                                    Spacer(minLength: 0)
                                    if preview.defeatsDefender {
                                        Text("击溃")
                                            .font(.caption2.weight(.black))
                                            .foregroundStyle(.black.opacity(0.72))
                                            .padding(.horizontal, 6)
                                            .frame(height: 20)
                                            .background(Color(red: 0.86, green: 0.68, blue: 0.34))
                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                    }
                                }
                                CombatModifierStripView(preview: preview)
                            }
                            .padding(8)
                            .background(.black.opacity(0.20))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                        }
                    }
                }
            } else {
                Text("尚未标定战场焦点。")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct CombatModifierStripView: View {
    var preview: CombatPreview

    var body: some View {
        let modifiers = combatModifiers
        if !modifiers.isEmpty {
            HStack(spacing: 6) {
                ForEach(modifiers) { modifier in
                    HStack(spacing: 3) {
                        Image(systemName: modifier.symbol)
                            .font(.caption2.weight(.heavy))
                        Text(modifier.text)
                            .font(.caption2.monospacedDigit().weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .foregroundStyle(modifier.tint)
                    .padding(.horizontal, 6)
                    .frame(height: 22)
                    .background(.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var combatModifiers: [CombatModifierPill] {
        var values: [CombatModifierPill] = []

        if preview.supportBonus > 0 {
            values.append(CombatModifierPill(symbol: "person.2.fill", text: "+\(preview.supportBonus)", tint: .cyan))
        }

        if preview.flankingBonus > 0 {
            values.append(CombatModifierPill(symbol: "arrow.triangle.branch", text: "+\(preview.flankingBonus)", tint: .orange))
        }

        if preview.commandBonus > 0 {
            values.append(CombatModifierPill(symbol: "flag.2.crossed.fill", text: "+\(preview.commandBonus)", tint: Color(red: 0.86, green: 0.68, blue: 0.34)))
        }

        if preview.defenderSupportBonus > 0 {
            values.append(CombatModifierPill(symbol: "shield.fill", text: "-\(preview.defenderSupportBonus)", tint: .blue))
        }

        return values
    }
}

struct CombatModifierPill: Identifiable {
    var symbol: String
    var text: String
    var tint: Color

    var id: String { "\(symbol)-\(text)" }
}

extension CombatPreview {
    var commandModifierSummary: String? {
        var parts: [String] = []

        if supportBonus > 0 {
            parts.append("支援+\(supportBonus)")
        }

        if flankingBonus > 0 {
            parts.append("包夹+\(flankingBonus)")
        }

        if commandBonus > 0 {
            parts.append("指挥+\(commandBonus)")
        }

        if defenderSupportBonus > 0 {
            parts.append("守援-\(defenderSupportBonus)")
        }

        return parts.isEmpty ? nil : parts.joined(separator: "  ")
    }
}

struct BattlefieldStatPill: View {
    var label: String
    var value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.56))
            Text(value)
                .font(.caption.monospacedDigit().weight(.heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 40)
        .background(.black.opacity(0.20))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

struct StrategicBalancePanelView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        PanelView(title: "战局", symbol: "chart.bar.xaxis") {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 8) {
                    StrategicScorePill(
                        label: "兵力",
                        value: "\(viewModel.romanUnitCount):\(viewModel.hostileUnitCount)",
                        symbol: "shield.fill",
                        tint: Color(red: 0.84, green: 0.66, blue: 0.32)
                    )
                    StrategicScorePill(
                        label: "城池",
                        value: "\(viewModel.romanCityCount):\(viewModel.hostileCityCount)",
                        symbol: "building.columns.fill",
                        tint: .cyan
                    )
                    StrategicScorePill(
                        label: "态势",
                        value: viewModel.warPressureLabel,
                        symbol: "flag.2.crossed.fill",
                        tint: viewModel.warPressureLabel == "受压" ? .red : .green
                    )
                }

                let income = viewModel.state.income(for: .rome)
                HStack(spacing: 8) {
                    ResourceDeltaView(symbol: "circle.stack.fill", value: income.gold, tint: .yellow)
                    ResourceDeltaView(symbol: "leaf.fill", value: income.grain, tint: .green)
                    ResourceDeltaView(symbol: "shield.fill", value: income.iron, tint: .gray)
                    ResourceDeltaView(symbol: "sparkle.magnifyingglass", value: income.science, tint: .cyan)
                    Spacer(minLength: 0)
                }

                VStack(spacing: 6) {
                    ForEach(viewModel.factionSituations.filter { $0.faction != .rome }) { situation in
                        FactionSituationRowView(situation: situation)
                    }
                }
            }
        }
    }
}

struct StrategicScorePill: View {
    var label: String
    var value: String
    var symbol: String
    var tint: Color

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.caption.weight(.heavy))
                .foregroundStyle(tint)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
            Text(value)
                .font(.caption.monospacedDigit().weight(.heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(.black.opacity(0.20))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

struct ResourceDeltaView: View {
    var symbol: String
    var value: Int
    var tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
            Text("+\(value)")
                .font(.caption2.monospacedDigit().weight(.heavy))
        }
        .padding(.horizontal, 7)
        .frame(height: 24)
        .background(.black.opacity(0.20))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct FactionSituationRowView: View {
    var situation: FactionSituation

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(situation.faction.factionColor)
                .frame(width: 15, height: 15)
                .clipShape(RoundedRectangle(cornerRadius: 3))

            Text(situation.faction.displayName)
                .font(.caption.weight(.bold))
                .lineLimit(1)

            Spacer(minLength: 0)

            Label("\(situation.unitCount)", systemImage: "shield.fill")
                .font(.caption2.monospacedDigit().weight(.bold))
                .foregroundStyle(.white.opacity(0.72))
            Label("\(situation.cityCount)", systemImage: "building.columns.fill")
                .font(.caption2.monospacedDigit().weight(.bold))
                .foregroundStyle(.white.opacity(0.72))

            Text(situation.relationToRome.displayName)
                .font(.caption2.weight(.black))
                .foregroundStyle(.black.opacity(0.76))
                .padding(.horizontal, 6)
                .frame(height: 20)
                .background(situation.relationToRome.statusColor)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .frame(minHeight: 28)
    }
}

struct EnemyIntentPanelView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        PanelView(title: "敌情", symbol: "eye.trianglebadge.exclamationmark.fill") {
            if viewModel.enemyIntentSummaries.isEmpty {
                Text("暂无明确敌军动向。")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 7) {
                    ForEach(viewModel.enemyIntentSummaries.prefix(4)) { summary in
                        EnemyIntentRowView(summary: summary)
                    }
                }
            }
        }
    }
}

struct EnemyIntentRowView: View {
    var summary: EnemyIntentSummary

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(summary.unit.faction.factionColor)
                    .frame(width: 28, height: 28)
                Image(systemName: summary.intent.kind.systemImage)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(summary.title)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(summary.detail)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
                    .minimumScaleFactor(0.70)
            }

            Spacer(minLength: 0)

            Text(summary.threatLabel)
                .font(.caption2.weight(.black))
                .foregroundStyle(summary.isHighThreat ? .white : .black.opacity(0.76))
                .padding(.horizontal, 6)
                .frame(height: 20)
                .background(summary.isHighThreat ? Color(red: 0.74, green: 0.10, blue: 0.08) : summary.intent.kind.tintColor)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 44)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

struct SelectionPanelView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        PanelView(title: "情报", symbol: "scope") {
            if let unit = viewModel.selectedUnit {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        UnitTokenView(unit: unit)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(unit.faction.displayName) \(unit.kind.displayName)")
                                .font(.headline.weight(.bold))
                            Text(unit.generalName ?? "无将领")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.68))
                        }
                        Spacer()
                    }

                    StatRow(label: "生命", value: "\(unit.health)/\(unit.kind.maxHealth)")
                    StatRow(label: "攻击", value: "\(viewModel.state.effectiveAttack(for: unit))")
                    StatRow(label: "防御", value: "\(viewModel.state.effectiveDefense(for: unit))")
                    StatRow(label: "机动", value: "\(viewModel.state.effectiveMovement(for: unit))")
                    StatRow(label: "射程", value: "\(unit.kind.range)")
                    if let status = viewModel.selectedWarMeritStatus {
                        StatRow(label: "军阶", value: status.rankName)
                        StatRow(label: "战功", value: "\(status.experience) · 伤害 +\(status.damageBonus)")
                    } else {
                        StatRow(label: "经验", value: "\(unit.experience)")
                    }
                    StatRow(label: "姿态", value: unit.resolvedTacticalOrder.displayName)

                    if let trait = unit.resolvedGeneralTrait {
                        GeneralTraitCardView(
                            trait: trait,
                            preview: viewModel.selectedGeneralSkillPreview,
                            warMeritStatus: viewModel.selectedWarMeritStatus
                        )
                    }
                }
            } else if let city = viewModel.selectedCity {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        CityBadgeView(city: city)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(city.name)
                                .font(.headline.weight(.bold))
                            Text(city.owner.displayName)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.68))
                        }
                        Spacer()
                    }

                    StatRow(label: "金币", value: "+\(city.production.gold)")
                    StatRow(label: "粮食", value: "+\(city.production.grain)")
                    StatRow(label: "铁", value: "+\(city.production.iron)")
                    StatRow(label: "科技", value: "+\(city.production.science)")
                    StatRow(label: "城防", value: "\(city.fortification)")
                }
            } else {
                Text("元老院令：夺取港口，切断敌军补给。")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct GeneralTraitCardView: View {
    var trait: GeneralTrait
    var preview: GeneralSkillPreview?
    var warMeritStatus: WarMeritStatus?

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Image(systemName: trait.systemImage)
                    .foregroundStyle(Color(red: 0.86, green: 0.68, blue: 0.34))
                Text(trait.displayName)
                    .font(.caption.weight(.heavy))
                Spacer(minLength: 0)
                Text(trait.skillName)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.75))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(Color(red: 0.86, green: 0.68, blue: 0.34))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            Text(trait.passiveDetail)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)

            Text(trait.skillDetail)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.56))
                .fixedSize(horizontal: false, vertical: true)

            if let warMeritStatus {
                WarMeritProgressView(status: warMeritStatus)
            }

            if let preview {
                HStack(spacing: 7) {
                    SkillPreviewPill(symbol: "scope", text: "范围 \(preview.range)")
                    SkillPreviewPill(
                        symbol: preview.trait == .siegeEngineer ? "building.columns.fill" : "cross.case.fill",
                        text: preview.trait == .siegeEngineer ?
                            "目标 \(preview.affectedCityIDs.count)" :
                            "友军 \(preview.affectedUnitIDs.count)"
                    )
                    SkillPreviewPill(
                        symbol: preview.cooldownRemaining > 0 ? "hourglass" : "checkmark.seal.fill",
                        text: preview.cooldownText
                    )
                }

                HStack(spacing: 7) {
                    Image(systemName: preview.isExecutable ? "sparkles" : "exclamationmark.triangle.fill")
                        .foregroundStyle(preview.isExecutable ? Color(red: 0.36, green: 0.86, blue: 0.92) : .orange)
                    Text(preview.blockedReason ?? preview.summary)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.66))
                        .lineLimit(2)
                        .minimumScaleFactor(0.74)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 7)
                .frame(minHeight: 28)
                .background(.black.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(9)
        .background(.black.opacity(0.20))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(red: 0.86, green: 0.68, blue: 0.34).opacity(0.22), lineWidth: 1)
        }
    }
}

struct WarMeritProgressView: View {
    var status: WarMeritStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 7) {
                Image(systemName: "chevron.up.circle.fill")
                    .foregroundStyle(Color(red: 0.98, green: 0.82, blue: 0.36))
                Text(status.rankName)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
                Text("伤害 +\(status.damageBonus)")
                    .font(.caption2.monospacedDigit().weight(.black))
                    .foregroundStyle(Color(red: 0.98, green: 0.82, blue: 0.36))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.black.opacity(0.34))
                    Capsule()
                        .fill(Color(red: 0.98, green: 0.82, blue: 0.36))
                        .frame(width: proxy.size.width * min(1, max(0, status.progressFraction)))
                }
            }
            .frame(height: 6)

            Text(status.nextRankName.map { "战功 \(status.experience)/\(status.nextRankExperience ?? status.experience) · 下一军阶 \($0)" } ?? "战功 \(status.experience) · 最高军阶")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .background(.black.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct SkillPreviewPill: View {
    var symbol: String
    var text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.caption2.weight(.heavy))
            Text(text)
                .font(.caption2.monospacedDigit().weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(Color(red: 0.36, green: 0.86, blue: 0.92))
        .padding(.horizontal, 7)
        .frame(height: 24)
        .background(.black.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct TacticalOrderControlView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    var unit: ArmyUnit
    var isCompact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if !isCompact {
                HStack(spacing: 7) {
                    Image(systemName: unit.resolvedTacticalOrder.systemImage)
                        .foregroundStyle(unit.resolvedTacticalOrder.tintColor)
                    Text("战术姿态")
                        .font(.caption.weight(.bold))
                    Spacer(minLength: 0)
                    Text(unit.resolvedTacticalOrder.displayName)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.black.opacity(0.75))
                        .padding(.horizontal, 6)
                        .frame(height: 20)
                        .background(unit.resolvedTacticalOrder.tintColor)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }

            HStack(spacing: 6) {
                ForEach(TacticalOrder.allCases) { order in
                    Button {
                        viewModel.setSelectedTacticalOrder(order)
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: order.systemImage)
                                .font(.caption.weight(.heavy))
                            Text(order.displayName)
                                .font(.caption2.weight(.black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .foregroundStyle(order == unit.resolvedTacticalOrder ? .black.opacity(0.80) : .white)
                        .frame(maxWidth: .infinity, minHeight: isCompact ? 38 : 44)
                        .background(order == unit.resolvedTacticalOrder ? order.tintColor : .black.opacity(0.20))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay {
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(order.tintColor.opacity(order == unit.resolvedTacticalOrder ? 0 : 0.32), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canSetSelectedTacticalOrder(order))
                }
            }

            if !isCompact {
                Text(unit.resolvedTacticalOrder.detail)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(isCompact ? 0 : 8)
        .background(isCompact ? Color.clear : .black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

struct ActionsPanelView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        PanelView(title: "军令", symbol: "flag.fill") {
            VStack(spacing: 8) {
                if !viewModel.attackTargets.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.red)
                        Text("点敌军头顶红色徽标可直接攻击。")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.68))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer()
                    }

                    ForEach(viewModel.attackTargets) { target in
                        let preview = viewModel.attackPreview(for: target.id)
                        Button {
                            viewModel.attack(target.id)
                        } label: {
                            CommandButtonLabel(
                                symbol: "bolt.fill",
                                text: preview.map { "攻击 \(target.faction.displayName)\(target.kind.displayName) · 伤害 \($0.damage)" } ?? "攻击 \(target.faction.displayName)\(target.kind.displayName)",
                                detail: preview?.commandModifierSummary
                            )
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(viewModel.isCampaignOver)
                    }
                }

                if let city = viewModel.commandCity, city.owner == .rome {
                    Button {
                        viewModel.developCommandCity()
                    } label: {
                        CommandButtonLabel(symbol: "building.2.crop.circle.fill", text: "扩建 \(city.name)")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(viewModel.isCampaignOver)

                    HStack(spacing: 8) {
                        ForEach(UnitKind.allCases.filter { kind in
                            kind != .navy || city.position.neighbors(width: viewModel.state.width, height: viewModel.state.height).contains { position in
                                viewModel.state.tile(at: position)?.terrain == .water
                            }
                        }) { kind in
                            Button {
                                viewModel.recruit(kind)
                            } label: {
                                VStack(spacing: 4) {
                                    Text(kind.shortLabel)
                                        .font(.caption.weight(.black))
                                    Text("\(kind.recruitmentCost.gold)")
                                        .font(.caption2.monospacedDigit().weight(.bold))
                                        .foregroundStyle(.white.opacity(0.72))
                                }
                                .frame(maxWidth: .infinity, minHeight: 48)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(viewModel.isCampaignOver)
                        }
                    }
                }

                if let unit = viewModel.selectedUnit, unit.faction == .rome {
                    TacticalOrderControlView(unit: unit)

                    if let trait = unit.resolvedGeneralTrait {
                        Button {
                            viewModel.useSelectedGeneralSkill()
                        } label: {
                            CommandButtonLabel(
                                symbol: trait.systemImage,
                                text: trait.skillName,
                                detail: viewModel.selectedGeneralSkillButtonDetail
                            )
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(!viewModel.canUseSelectedGeneralSkill)
                    }

                    HStack(spacing: 8) {
                        Button {
                            viewModel.trainSelectedUnit()
                        } label: {
                            CommandButtonLabel(symbol: "figure.walk", text: "训练")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(viewModel.isCampaignOver)

                        Button {
                            viewModel.appointGeneralToSelectedUnit()
                        } label: {
                            CommandButtonLabel(symbol: "person.crop.circle.badge.plus", text: "任命")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(unit.generalName != nil || viewModel.isCampaignOver)
                    }

                    HStack(spacing: 8) {
                        Button {
                            viewModel.restSelectedUnit()
                        } label: {
                            CommandButtonLabel(symbol: "cross.case.fill", text: "休整")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(unit.hasActed || viewModel.isCampaignOver)

                        Button {
                            viewModel.skipSelectedUnit()
                        } label: {
                            CommandButtonLabel(symbol: "forward.end.fill", text: "跳过")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(!viewModel.canSkipSelectedUnit)
                    }
                }

                if viewModel.attackTargets.isEmpty && viewModel.selectedUnit?.faction != .rome && (viewModel.commandCity?.owner != .rome) {
                    Text("等待可执行命令。")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct DiplomacyPanelView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        PanelView(title: "外交", symbol: "person.2.fill") {
            VStack(spacing: 8) {
                ForEach(Faction.turnOrder.filter { $0 != .rome }) { faction in
                    let status = viewModel.state.diplomaticStatus(between: .rome, and: faction)
                    Button {
                        viewModel.sendEnvoy(to: faction)
                    } label: {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(faction.factionColor)
                                .frame(width: 18, height: 18)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(faction.displayName)
                                    .font(.caption.weight(.bold))
                                Text(status.displayName)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.64))
                            }
                            Spacer()
                            Image(systemName: status == .alliance ? "checkmark.seal.fill" : "paperplane.fill")
                                .foregroundStyle(status == .alliance ? .green : .cyan)
                        }
                        .frame(minHeight: 36)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(status == .alliance || viewModel.isCampaignOver)
                }
            }
        }
    }
}

struct TechnologyPanelView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        PanelView(title: "科技", symbol: "hammer.fill") {
            VStack(spacing: 8) {
                ForEach(Technology.allCases) { technology in
                    let known = viewModel.state.researchedTechnologies[.rome, default: []].contains(technology)
                    Button {
                        viewModel.research(technology)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: known ? "checkmark.seal.fill" : "plus.circle.fill")
                                .foregroundStyle(known ? .green : .cyan)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(technology.displayName)
                                    .font(.caption.weight(.bold))
                                Text(technology.detail)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.64))
                            }
                            Spacer()
                            Text("\(technology.cost.science)")
                                .font(.caption.monospacedDigit().weight(.bold))
                        }
                        .frame(minHeight: 36)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(known || viewModel.isCampaignOver)
                }
            }
        }
    }
}

struct MissionPanelView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        PanelView(title: "元老院", symbol: "building.columns.fill") {
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.campaignStatus.kind.systemImage)
                        .foregroundStyle(viewModel.campaignStatus.kind.tintColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.campaignStatusTitle)
                            .font(.caption.weight(.bold))
                        Text(viewModel.campaignStatusDetail)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.62))
                            .lineLimit(2)
                    }
                    Spacer()
                }

                ForEach(viewModel.state.missions) { mission in
                    HStack(spacing: 8) {
                        Image(systemName: mission.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(mission.isCompleted ? .green : .white.opacity(0.5))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mission.title)
                                .font(.caption.weight(.bold))
                            Text(mission.objective)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.62))
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

struct LogPanelView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        PanelView(title: "战报", symbol: "scroll.fill") {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(Array(viewModel.state.eventLog.suffix(4).enumerated()), id: \.offset) { _, message in
                    Text(message)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.68))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct PanelView<Content: View>: View {
    var title: String
    var symbol: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(.white.opacity(0.9))

            content
        }
        .foregroundStyle(.white)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.18, green: 0.17, blue: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(red: 0.84, green: 0.66, blue: 0.32).opacity(0.65))
                .frame(height: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.07), lineWidth: 1)
        }
    }
}

struct StatRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.white.opacity(0.62))
            Spacer()
            Text(value)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .font(.caption)
    }
}

struct MiniLegendView: View {
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Faction.turnOrder) { faction in
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(faction.factionColor)
                        .frame(width: 12, height: 12)
                    Text(faction.displayName)
                        .font(.caption2.weight(.bold))
                }
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct CommandButtonLabel: View {
    var symbol: String
    var text: String
    var detail: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                if let detail {
                    Text(detail)
                        .font(.caption2.monospacedDigit().weight(.bold))
                        .foregroundStyle(.white.opacity(0.76))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: detail == nil ? 38 : 50)
        .padding(.horizontal, 10)
    }
}

struct CommandIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(configuration.isPressed ? .white.opacity(0.18) : .white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(configuration.isPressed ? Color.red.opacity(0.72) : Color(red: 0.60, green: 0.10, blue: 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(configuration.isPressed ? .white.opacity(0.18) : .black.opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
    }
}

struct HexMetrics {
    let tileWidth: CGFloat
    let tileHeight: CGFloat
    let origin: CGPoint
    let actionScale: CGFloat
    let tileScale: CGFloat

    init(mapWidth: Int, mapHeight: Int, container: CGSize) {
        let horizontalUnits = CGFloat(mapWidth) * 0.76 + 0.24
        let verticalUnits = CGFloat(mapHeight) + 0.5

        let horizontalInset = min(22, max(10, container.width * 0.035))
        let topInset = min(68, max(50, container.height * 0.16))
        let bottomInset = min(42, max(30, container.height * 0.10))
        let availableWidth = max(1, container.width - horizontalInset * 2)
        let availableHeight = max(1, container.height - topInset - bottomInset)
        let widthBased = availableWidth / horizontalUnits
        let heightBased = availableHeight / (verticalUnits * 0.88)
        let fittedTileWidth = min(widthBased, heightBased)

        tileWidth = max(18, min(76, fittedTileWidth))
        tileHeight = tileWidth * 0.88
        tileScale = min(1.05, max(0.74, tileWidth / 44))
        actionScale = min(1.15, max(0.72, tileWidth / 54))

        let totalWidth = tileWidth * (0.76 * CGFloat(mapWidth - 1) + 1)
        let totalHeight = tileHeight * (CGFloat(mapHeight) + 0.5)
        origin = CGPoint(
            x: horizontalInset + (availableWidth - totalWidth) / 2 + tileWidth / 2,
            y: topInset + (availableHeight - totalHeight) / 2 + tileHeight / 2
        )
    }

    func center(for position: Position) -> CGPoint {
        CGPoint(
            x: origin.x + CGFloat(position.x) * tileWidth * 0.76,
            y: origin.y + CGFloat(position.y) * tileHeight + (position.x.isMultiple(of: 2) ? 0 : tileHeight * 0.5)
        )
    }
}

struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let points = [
            CGPoint(x: rect.midX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.25),
            CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.25),
            CGPoint(x: rect.midX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.25),
            CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.25)
        ]

        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

struct TrianglePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

extension Faction {
    var factionColor: Color {
        switch self {
        case .rome: return Color(red: 0.72, green: 0.08, blue: 0.07)
        case .carthage: return Color(red: 0.50, green: 0.20, blue: 0.72)
        case .gaul: return Color(red: 0.08, green: 0.42, blue: 0.22)
        case .egypt: return Color(red: 0.86, green: 0.63, blue: 0.16)
        case .neutral: return Color(red: 0.52, green: 0.52, blue: 0.48)
        }
    }
}

extension DiplomaticStatus {
    var statusColor: Color {
        switch self {
        case .war: return Color(red: 0.86, green: 0.24, blue: 0.18)
        case .truce: return Color(red: 0.84, green: 0.66, blue: 0.32)
        case .alliance: return Color(red: 0.24, green: 0.66, blue: 0.34)
        }
    }
}

extension CampaignStatusKind {
    var systemImage: String {
        switch self {
        case .ongoing: return "flag.fill"
        case .romanVictory: return "checkmark.seal.fill"
        case .romanDefeat: return "exclamationmark.triangle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .ongoing: return Color(red: 0.84, green: 0.66, blue: 0.32)
        case .romanVictory: return Color(red: 0.24, green: 0.72, blue: 0.38)
        case .romanDefeat: return Color(red: 0.86, green: 0.24, blue: 0.18)
        }
    }
}

extension GeneralTrait {
    var systemImage: String {
        switch self {
        case .eagleStandard: return "flag.2.crossed.fill"
        case .siegeEngineer: return "hammer.fill"
        case .quartermaster: return "shippingbox.fill"
        case .shieldWall: return "shield.lefthalf.filled"
        }
    }
}

extension TacticalOrder {
    var systemImage: String {
        switch self {
        case .balanced: return "circle.grid.cross.fill"
        case .assault: return "bolt.fill"
        case .defensive: return "shield.fill"
        case .forcedMarch: return "figure.walk.motion"
        }
    }

    var tintColor: Color {
        switch self {
        case .balanced: return Color(red: 0.78, green: 0.72, blue: 0.62)
        case .assault: return Color(red: 0.92, green: 0.28, blue: 0.20)
        case .defensive: return Color(red: 0.30, green: 0.62, blue: 0.90)
        case .forcedMarch: return Color(red: 0.32, green: 0.74, blue: 0.42)
        }
    }
}

extension AIIntentKind {
    var systemImage: String {
        switch self {
        case .attack: return "bolt.fill"
        case .advanceAttack: return "arrow.up.right.circle.fill"
        case .captureCity: return "building.columns.fill"
        case .advance: return "arrow.up.forward.circle.fill"
        case .defend: return "shield.fill"
        case .regroup: return "cross.case.fill"
        case .useSkill: return "sparkles"
        }
    }

    var tintColor: Color {
        switch self {
        case .attack: return Color(red: 0.86, green: 0.18, blue: 0.12)
        case .advanceAttack: return Color(red: 0.92, green: 0.42, blue: 0.14)
        case .captureCity: return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .advance: return Color(red: 0.36, green: 0.70, blue: 0.88)
        case .defend: return Color(red: 0.30, green: 0.62, blue: 0.90)
        case .regroup: return Color(red: 0.36, green: 0.70, blue: 0.40)
        case .useSkill: return Color(red: 0.80, green: 0.50, blue: 0.92)
        }
    }
}

extension TerrainType {
    var systemImage: String {
        switch self {
        case .plains: return "leaf.fill"
        case .forest: return "tree.fill"
        case .hills: return "mountain.2.fill"
        case .water: return "water.waves"
        case .road: return "road.lanes"
        case .city: return "building.columns.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .plains: return Color(red: 0.68, green: 0.78, blue: 0.38)
        case .forest: return Color(red: 0.26, green: 0.64, blue: 0.34)
        case .hills: return Color(red: 0.72, green: 0.56, blue: 0.36)
        case .water: return Color(red: 0.36, green: 0.70, blue: 0.88)
        case .road: return Color(red: 0.80, green: 0.64, blue: 0.42)
        case .city: return Color(red: 0.86, green: 0.68, blue: 0.34)
        }
    }
}

extension UnitKind {
    var tokenSystemImage: String {
        switch self {
        case .legion: return "shield.fill"
        case .cavalry: return "bolt.fill"
        case .archer: return "target"
        case .navy: return "water.waves"
        }
    }

    var shortLabel: String {
        switch self {
        case .legion: return "步"
        case .cavalry: return "骑"
        case .archer: return "弓"
        case .navy: return "舰"
        }
    }
}
