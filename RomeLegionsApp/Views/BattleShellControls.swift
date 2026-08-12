import SwiftUI

enum BattleDrawerCategory: String, CaseIterable, Identifiable {
    case orders
    case battlefield
    case enemy
    case senate
    case report

    var id: String { rawValue }

    var title: String {
        switch self {
        case .orders: return "情报军令"
        case .battlefield: return "战场"
        case .enemy: return "敌情"
        case .senate: return "元老院"
        case .report: return "战报"
        }
    }

    var symbol: String {
        switch self {
        case .orders: return "flag.fill"
        case .battlefield: return "map.fill"
        case .enemy: return "eye.fill"
        case .senate: return "building.columns.fill"
        case .report: return "scroll.fill"
        }
    }
}

struct MapOverlayPresentation {
    var perspective: MapReconPerspectiveKind

    var enemyRouteOpacity: Double {
        switch perspective {
        case .enemyIntent: return 1
        case .countermeasure: return 0.24
        case .objective: return 0.08
        case .terrainPressure: return 0.10
        }
    }

    /// Enemy commander threat remains visible in every perspective so a focused
    /// threat never loses its spatial context. The enemy route perspective gives
    /// it the strongest contrast; response and objective views keep it subdued.
    var enemyCommanderThreatOpacity: Double {
        switch perspective {
        case .enemyIntent: return 0.96
        case .countermeasure: return 0.38
        case .objective: return 0.24
        case .terrainPressure: return 0.30
        }
    }

    var tacticalRouteOpacity: Double {
        switch perspective {
        case .objective: return 0.95
        case .enemyIntent: return 0.30
        case .countermeasure: return 0.24
        case .terrainPressure: return 0.14
        }
    }

    var showsEnemyIntentDetails: Bool {
        perspective == .enemyIntent || perspective == .countermeasure
    }

    var showsEnemyCommanderThreatDetails: Bool {
        true
    }

    var showsBattleObjective: Bool {
        perspective == .objective
    }

    var showsCountermeasure: Bool {
        perspective == .countermeasure
    }

    var showsTerrainPressure: Bool {
        perspective == .terrainPressure
    }

    func isFocusedLegend(_ kind: MapOverlayLegendKind) -> Bool {
        switch kind {
        case .reachable, .attackTarget, .skillRange:
            return true
        case .enemyRoute, .enemyTarget:
            return perspective == .enemyIntent
        case .enemyCommanderThreat:
            return perspective == .enemyIntent
        case .countermeasure:
            return perspective == .countermeasure
        case .battleObjective, .tacticalPath, .maneuverOption:
            return perspective == .objective
        case .threatHeat, .mapControl:
            return perspective == .terrainPressure
        }
    }

    func legendPriority(_ kind: MapOverlayLegendKind) -> Int {
        if isFocusedLegend(kind) { return 0 }
        if perspective == .countermeasure && (kind == .enemyRoute || kind == .enemyTarget) {
            return 1
        }
        if perspective == .countermeasure && kind == .enemyCommanderThreat {
            return 1
        }
        return 2
    }
}

extension MapReconPerspectiveKind {
    var mapReconTint: Color {
        switch self {
        case .enemyIntent: return .red
        case .countermeasure: return .cyan
        case .objective: return Color(red: 0.86, green: 0.68, blue: 0.34)
        case .terrainPressure: return Color(red: 0.96, green: 0.58, blue: 0.24)
        }
    }
}

struct BattleEdgeToolsView: View {
    @Binding var activeDrawer: BattleDrawerCategory?
    var visualSize: CGFloat = 36
    var spacing: CGFloat = 2

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(BattleDrawerCategory.allCases) { category in
                Button(category.title, systemImage: category.symbol) {
                    activeDrawer = activeDrawer == category ? nil : category
                }
                .labelStyle(.iconOnly)
                .font(.caption.weight(.black))
                .foregroundStyle(activeDrawer == category ? .black : .white)
                .frame(width: visualSize, height: visualSize)
                .background(activeDrawer == category ? Color(red: 0.91, green: 0.74, blue: 0.38) : .black.opacity(0.62))
                .clipShape(.rect(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(activeDrawer == category ? .white.opacity(0.86) : .white.opacity(0.16), lineWidth: activeDrawer == category ? 1.5 : 1)
                }
                .overlay(alignment: .bottomTrailing) {
                    if activeDrawer == category {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.black, .white)
                            .offset(x: 3, y: 3)
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .accessibilityLabel(activeDrawer == category ? "关闭\(category.title)抽屉" : "打开\(category.title)抽屉")
            }
        }
        .padding(2)
        .background(.black.opacity(0.16))
        .clipShape(.rect(cornerRadius: 7))
    }
}

struct BattlefieldDrawerView: View {
    var category: BattleDrawerCategory
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Label(category.title, systemImage: category.symbol)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
                Button("关闭抽屉", systemImage: "xmark") {
                    onClose()
                }
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 44)
                .buttonStyle(CommandIconButtonStyle())
            }
            .padding(.horizontal, 10)
            .frame(minHeight: 48)
            .background(Color(red: 0.18, green: 0.16, blue: 0.13))

            ScrollView {
                LazyVStack(spacing: 10) {
                    drawerContent
                }
                .padding(10)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color(red: 0.11, green: 0.11, blue: 0.10).opacity(0.98))
        .clipShape(.rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.84, green: 0.66, blue: 0.32).opacity(0.42), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.48), radius: 16, x: -4, y: 6)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(category.title)战场抽屉")
    }

    @ViewBuilder
    private var drawerContent: some View {
        switch category {
        case .orders:
            SelectionPanelView()
            ActionsPanelView()
        case .battlefield:
            BattlefieldFocusPanelView()
            StrategicBalancePanelView()
        case .enemy:
            EnemyIntentPanelView()
        case .senate:
            TechnologyPanelView()
            DiplomacyPanelView()
            MissionPanelView()
        case .report:
            LogPanelView()
        }
    }
}

struct SelectionCommandDockView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    var isCompact: Bool
    var identityWidth: CGFloat
    var onShowMore: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            selectionIdentity
                .frame(width: identityWidth, alignment: .leading)

            Rectangle()
                .fill(.white.opacity(0.10))
                .frame(width: 1)
                .padding(.vertical, 8)

            SelectionDockCommandButtonsView(isCompact: isCompact, onShowMore: onShowMore)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(2)

            Button("更多情报", systemImage: "ellipsis.circle.fill") {
                onShowMore()
            }
            .labelStyle(.iconOnly)
            .font(.title3.weight(.bold))
            .frame(width: 44, height: 44)
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityHint("打开完整情报和军令")
        }
        .padding(.horizontal, 8)
        .foregroundStyle(.white)
        .background(Color(red: 0.105, green: 0.10, blue: 0.09).opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(red: 0.84, green: 0.66, blue: 0.32).opacity(0.68))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var selectionIdentity: some View {
        if let focusReadout = viewModel.activeEnemyCommanderThreatFocusReadout,
           viewModel.focusedEnemyCommanderThreatID != nil {
            EnemyCommanderThreatFocusIdentityView(readout: focusReadout)
        } else if let unit = viewModel.selectedUnit {
            HStack(spacing: 9) {
                UnitTokenView(unit: unit)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(unit.faction.displayName) \(unit.kind.displayName)")
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                    Text("\(unit.generalName ?? "无将领") · \(unit.resolvedTacticalOrder.displayName)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.70))
                        .lineLimit(1)
                    unitCommandCueView
                }
            }
            .accessibilityElement(children: .combine)
        } else if let city = viewModel.selectedCity,
                  let brief = viewModel.selectedCityBrief {
            HStack(spacing: 9) {
                CityBadgeView(city: city)
                VStack(alignment: .leading, spacing: 3) {
                    Text(city.name)
                        .font(.subheadline.weight(.bold))
                    Text("\(brief.ownerLabel) · \(brief.fortificationLabel)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.76))
                        .lineLimit(1)
                    Label(cityCommandCue(brief), systemImage: "flag.fill")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.91, green: 0.74, blue: 0.38))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                }
            }
            .accessibilityLabel(brief.accessibilityLabel)
        } else if let tile = viewModel.selectedTile {
            HStack(spacing: 9) {
                Image(systemName: tile.terrain.systemImage)
                    .font(.title3.weight(.black))
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.10))
                    .clipShape(.rect(cornerRadius: 7))
                VStack(alignment: .leading, spacing: 3) {
                    Text(tile.terrain.displayName)
                        .font(.subheadline.weight(.bold))
                    Text(tile.position.description)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.68))
                }
            }
        } else {
            Label("选择地图目标", systemImage: "scope")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white.opacity(0.74))
        }
    }

    private var unitCommandCue: String {
        if let forecast = viewModel.selectedCombatForecast {
            return forecast.compactLabel
        }
        if let situation = viewModel.selectedUnitSituationReadout {
            return situation.primaryCommandEntryLabel
        }
        if let recommendation = viewModel.selectedTacticalRecommendationSummary {
            return "目标 \(recommendation.targetLabel)"
        }
        return "等待军令"
    }

    @ViewBuilder
    private var unitCommandCueView: some View {
        if let forecast = viewModel.selectedCombatForecast {
            VStack(alignment: .leading, spacing: 1) {
                Label("\(forecast.attackerLabel) \(forecast.attackerPositionLabel) → \(forecast.defenderLabel) \(forecast.defenderPositionLabel)", systemImage: forecast.outcomeSymbol)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color(red: 0.91, green: 0.74, blue: 0.38))
                    .lineLimit(2)
                    .minimumScaleFactor(0.54)
                if forecast.attacker.generalName != nil || forecast.defender.generalName != nil {
                    Text("\(forecast.attackerGeneralLabel) → \(forecast.defenderGeneralLabel)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(1)
                        .minimumScaleFactor(0.56)
                }
                Text("\(forecast.damageLabel) · \(forecast.retaliationLabel) · \(forecast.outcomeLabel)")
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white.opacity(0.64))
                    .lineLimit(1)
                    .minimumScaleFactor(0.56)
            }
        } else {
            Label(unitCommandCue, systemImage: unitCommandCueSymbol)
                .font(.caption.monospacedDigit().weight(.bold))
                .foregroundStyle(Color(red: 0.91, green: 0.74, blue: 0.38))
                .lineLimit(2)
                .minimumScaleFactor(0.58)
        }
    }

    private var unitCommandCueSymbol: String {
        viewModel.selectedCombatForecast?.outcomeSymbol ?? "scope"
    }

    private func cityCommandCue(_ brief: SelectedCityBrief) -> String {
        if brief.canDevelop {
            return "经营目标 · \(brief.developmentGainLabel)"
        }
        return "部署目标 · \(brief.deploymentSummary)"
    }

}

struct SelectionDockCommandButtonsView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    var isCompact: Bool
    var onShowMore: () -> Void

    var body: some View {
        Group {
            if let focusReadout = viewModel.activeEnemyCommanderThreatFocusReadout,
               viewModel.focusedEnemyCommanderThreatID != nil {
                EnemyCommanderThreatFocusCommandStatusView(readout: focusReadout)
            } else if let unit = viewModel.selectedUnit, unit.faction == .rome {
                UnitDockCommandButtonsView(
                    unit: unit,
                    isCompact: isCompact,
                    onShowMore: onShowMore
                )
            } else if let city = viewModel.commandCity,
                      let brief = viewModel.commandCityBrief,
                      city.owner == .rome {
                CityDockCommandButtonsView(brief: brief, isCompact: isCompact)
            } else {
                DockCommandButton(
                    title: "情报",
                    symbol: "info.circle.fill",
                    tint: .cyan,
                    action: onShowMore
                )
            }
        }
        .frame(minHeight: 52)
    }
}

struct EnemyCommanderThreatFocusIdentityView: View {
    var readout: EnemyCommanderThreatFocusReadout

    var body: some View {
        HStack(spacing: 7) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(readout.isFocused ? readoutLevelTint.opacity(0.86) : .white.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: readout.skillSymbol)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("敌将 · \(readout.commanderLabel)")
                    .font(.caption.weight(.black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
                Text("\(readout.focusStateLabel) · \(readout.levelLabel) · \(readout.skillName)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(2)
                    .minimumScaleFactor(0.54)
                Text("\(readout.targetLabel) · \(readout.routeLabel)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
                    .minimumScaleFactor(0.50)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(readout.accessibilityLabel)
    }

    private var readoutLevelTint: Color {
        switch readout.levelLabel {
        case EnemyCommanderThreatLevel.critical.displayName:
            return .red
        case EnemyCommanderThreatLevel.severe.displayName:
            return .orange
        case EnemyCommanderThreatLevel.dangerous.displayName:
            return .yellow
        default:
            return .gray
        }
    }
}

struct EnemyCommanderThreatFocusCommandStatusView: View {
    var readout: EnemyCommanderThreatFocusReadout

    var body: some View {
        HStack(spacing: 7) {
            Label(readout.focusStateLabel, systemImage: readout.isFocused ? "scope" : "eye.trianglebadge.exclamationmark.fill")
                .font(.caption.weight(.black))
                .foregroundStyle(readout.isFocused ? .yellow : .white.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.64)

            VStack(alignment: .leading, spacing: 2) {
                Text(readout.commandAvailabilityLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.76))
                    .lineLimit(1)
                    .minimumScaleFactor(0.56)
                Text("\(readout.skillName) · 目标\(readout.targetLabel)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
                    .minimumScaleFactor(0.52)
                Text(readout.routeLabel)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.54))
                    .lineLimit(2)
                    .minimumScaleFactor(0.50)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(readout.accessibilityLabel)
        .accessibilityHint("使用右侧更多情报打开敌情抽屉；当前没有可执行的敌将命令")
    }
}

struct UnitDockCommandButtonsView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    var unit: ArmyUnit
    var isCompact: Bool
    var onShowMore: () -> Void

    var body: some View {
        if isCompact {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    primaryButtons
                }
                HStack(spacing: 6) {
                    cancelButton
                    recoveryButtons
                }
            }
        } else {
            HStack(spacing: 6) {
                primaryButtons
                cancelButton
                recoveryButtons
            }
        }
    }

    @ViewBuilder
    private var primaryButtons: some View {
        if let forecast = viewModel.selectedCombatForecast {
            DockCommandButton(
                title: forecast.confirmationTitle,
                symbol: forecast.outcomeSymbol,
                tint: forecast.isHighRisk ? .orange : .red,
                isDisabled: viewModel.isCampaignOver,
                accessibilityLabel: forecast.confirmationAccessibilityLabel,
                action: viewModel.confirmSelectedAttack
            )

        } else if !viewModel.attackTargets.isEmpty {
            AttackTargetMenuButton()
        }

        if let trait = unit.resolvedGeneralTrait {
            DockCommandButton(
                title: "技能",
                symbol: trait.systemImage,
                tint: .cyan,
                isDisabled: !viewModel.canUseSelectedGeneralSkill,
                accessibilityLabel: trait.skillName,
                action: viewModel.useSelectedGeneralSkill
            )
        }

        DockCommandButton(
            title: "姿态",
            symbol: unit.resolvedTacticalOrder.systemImage,
            tint: unit.resolvedTacticalOrder.tintColor,
            accessibilityLabel: "军令姿态，当前\(unit.resolvedTacticalOrder.displayName)",
            action: onShowMore
        )
    }

    @ViewBuilder
    private var cancelButton: some View {
        if let forecast = viewModel.selectedCombatForecast {
            DockCommandButton(
                title: "取消",
                symbol: "xmark.circle",
                tint: .gray,
                isSecondary: true,
                accessibilityLabel: forecast.cancelAccessibilityLabel,
                action: viewModel.cancelSelectedAttackTarget
            )
        }
    }

    @ViewBuilder
    private var recoveryButtons: some View {
        DockCommandButton(
            title: "休整",
            symbol: "cross.case.fill",
            tint: .green,
            isSecondary: true,
            isDisabled: unit.hasActed || viewModel.isCampaignOver,
            action: viewModel.restSelectedUnit
        )

        DockCommandButton(
            title: "跳过",
            symbol: "forward.end.fill",
            tint: .gray,
            isSecondary: true,
            isDisabled: !viewModel.canSkipSelectedUnit,
            action: viewModel.skipSelectedUnit
        )
    }
}

struct CityDockCommandButtonsView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    var brief: SelectedCityBrief
    var isCompact: Bool

    var body: some View {
        HStack(spacing: 6) {
            DockCommandButton(
                title: "扩建",
                symbol: "building.2.crop.circle.fill",
                tint: Color(red: 0.84, green: 0.66, blue: 0.32),
                isDisabled: !brief.canDevelop || viewModel.isCampaignOver,
                action: viewModel.developCommandCity
            )

            ForEach(Array(brief.recruitmentOptions.prefix(isCompact ? 2 : brief.recruitmentOptions.count))) { option in
                DockCommandButton(
                    title: option.kind.shortLabel,
                    symbol: option.kind.tokenSystemImage,
                    tint: option.kind == .navy ? .cyan : .orange,
                    isDisabled: !option.canRecruit || viewModel.isCampaignOver,
                    accessibilityLabel: option.accessibilityLabel,
                    action: { viewModel.recruit(option.kind) }
                )
            }
        }
    }
}

struct AttackTargetMenuButton: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        Menu {
            if let forecast = viewModel.selectedCombatForecast {
                Button {
                    viewModel.cancelSelectedAttackTarget()
                } label: {
                    Label("取消锁定", systemImage: "xmark.circle")
                }
                .accessibilityLabel(forecast.cancelAccessibilityLabel)
                .accessibilityHint("清除目标锁定，不会结算攻击")
            }

            ForEach(viewModel.attackTargets) { target in
                let preview = viewModel.attackPreview(for: target.id)
                Button {
                    viewModel.focusAttackTarget(target.id)
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("锁定\(SelectedCombatForecast.identityLabel(for: target))")
                            if let preview {
                                Text("伤害 \(preview.damage) · 反击 \(preview.retaliation)")
                            }
                        }
                    } icon: {
                        Image(systemName: viewModel.isSelectedAttackTarget(target.id) ? "checkmark.circle.fill" : "bolt.fill")
                    }
                }
                .accessibilityLabel(viewModel.attackTargetAccessibilityLabel(for: target))
            }
        } label: {
            DockCommandButtonContent(
                title: "选敌",
                symbol: "bolt.fill",
                tint: .red
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.selectedCombatForecast.map { "已锁定，\($0.accessibilityLabel)" } ?? "选择攻击目标")
        .accessibilityHint(viewModel.selectedCombatForecast == nil ? "打开目标列表，锁定后查看攻击预演" : "打开目标列表，或选择取消锁定")
    }
}

struct DockCommandButtonContent: View {
    var title: String
    var symbol: String
    var tint: Color
    var isSecondary = false

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
            Text(title)
                .font(.caption2.weight(.bold))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .frame(width: 44, height: 44)
        .background(isSecondary ? .black.opacity(0.20) : tint.opacity(0.30))
        .clipShape(.rect(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(tint.opacity(isSecondary ? 0.42 : 0.82), lineWidth: 1)
        }
    }
}

struct DockCommandButton: View {
    var title: String
    var symbol: String
    var tint: Color
    var isSecondary = false
    var isDisabled = false
    var accessibilityLabel: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            DockCommandButtonContent(
                title: title,
                symbol: symbol,
                tint: tint,
                isSecondary: isSecondary
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.42 : 1)
        .accessibilityLabel(accessibilityLabel ?? title)
    }
}

struct PhoneCommandDeckView: View {
    var body: some View {
        #if os(macOS)
        CompactCommandContentView(includesLog: false)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        #else
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                CompactCommandContentView(includesLog: false)
                .padding(.bottom, 10)
                .frame(width: proxy.size.width, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        #endif
    }
}

struct TopBarView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    var isCondensed = false
    var isNarrow = false
    var height: CGFloat = 44

    var body: some View {
        HStack(spacing: isCondensed ? 5 : 8) {
            Button {
                viewModel.openMenu()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title3.weight(.bold))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(CommandIconButtonStyle())
            .accessibilityLabel("打开主菜单")
            .accessibilityHint("返回模式选择和战役入口")

            VStack(alignment: .leading, spacing: 1) {
                Text(topBarTitle)
                    .font(.subheadline.weight(.black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                if !isCondensed {
                    Text(topBarSubtitle)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }
            .foregroundStyle(.white)

            Spacer(minLength: 4)

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
                    Text("结束")
                }
                .font(.caption.weight(.black))
                .frame(height: 32)
                .padding(.horizontal, isCondensed ? 8 : 10)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isCampaignOver)
        }
        .padding(.horizontal, 7)
        .frame(height: height)
        .background(Color(red: 0.14, green: 0.13, blue: 0.11))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1)
        }
    }

    private var topBarTitle: String {
        if isNarrow {
            return "罗马 · \(viewModel.state.turn) 回合"
        }
        return "罗马 · \(viewModel.state.mode.displayName) · \(viewModel.state.turn) 回合 · \(viewModel.campaignStatusTitle)"
    }

    private var topBarSubtitle: String {
        if isNarrow {
            return viewModel.campaignStatus.progressText ?? viewModel.campaignStatusDetail
        }
        return viewModel.bannerMessage
    }
}

struct CompactResourcePill: View {
    var resources: EmpireResources

    var body: some View {
        HStack(spacing: 4) {
            CompactResourceValue(symbol: "circle.stack.fill", value: resources.gold, tint: .yellow)
            CompactResourceValue(symbol: "leaf.fill", value: resources.grain, tint: .green)
            CompactResourceValue(symbol: "shield.fill", value: resources.iron, tint: .gray)
            CompactResourceValue(symbol: "sparkle.magnifyingglass", value: resources.science, tint: .cyan)
            CompactResourceValue(symbol: "star.fill", value: resources.prestige, tint: .orange)
        }
        .foregroundStyle(.white)
        .frame(minHeight: 30)
        .padding(.horizontal, 5)
        .background(.black.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("金币 \(resources.gold)，粮草 \(resources.grain)，铁 \(resources.iron)，科学 \(resources.science)，威望 \(resources.prestige)")
    }
}

struct CompactResourceValue: View {
    var symbol: String
    var value: Int
    var tint: Color

    var body: some View {
        VStack(spacing: 1) {
            Image(systemName: symbol)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint)
            Text(value, format: .number)
                .font(.caption2.monospacedDigit().weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .frame(minWidth: 20)
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
