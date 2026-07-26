import SwiftUI

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
        #if os(macOS)
        CompactCommandContentView(includesLog: true)
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(red: 0.12, green: 0.12, blue: 0.11))
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 1)
            }
        #else
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                CompactCommandContentView(includesLog: true)
                .padding(8)
                .frame(width: proxy.size.width, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(red: 0.12, green: 0.12, blue: 0.11))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 1)
        }
        #endif
    }
}

struct CompactCommandContentView: View {
    var includesLog: Bool

    var body: some View {
        VStack(spacing: 8) {
            CompactActionsPanelView()
            CompactSelectionPanelView()
            BattlefieldFocusPanelView(isCompact: true)
            if includesLog {
                CompactLogPanelView()
            }
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

                    if let situation = viewModel.selectedUnitSituationReadout {
                        SelectedUnitSituationReadoutView(readout: situation, isCompact: true)
                    }

                    if let orderWindow = viewModel.selectedUnitOrderWindowReadout {
                        SelectedUnitOrderWindowReadoutView(readout: orderWindow, isCompact: true)
                    }

                    if let formation = viewModel.selectedLegionFormationSummary {
                        LegionFormationCardView(summary: formation, isCompact: true)
                    }

                    if let development = viewModel.selectedUnitDevelopmentDecisionSummary {
                        UnitDevelopmentDecisionCardView(summary: development, isCompact: true)
                    }

                    if let recommendation = viewModel.selectedTacticalRecommendationSummary {
                        TacticalRecommendationCardView(summary: recommendation, isCompact: true)
                    }

                    if let maneuver = viewModel.primaryManeuverOptionSummary {
                        ManeuverOptionCardView(summary: maneuver, isCompact: true)
                    }

                    if let synergy = viewModel.selectedCommanderSynergySummary {
                        CommanderSynergyCardView(summary: synergy, isCompact: true)
                    }

                    TacticalOrderPreviewStripView(
                        previews: viewModel.selectedTacticalOrderPreviews,
                        isCompact: true
                    )

                    if let trait = unit.resolvedGeneralTrait {
                        CompactGeneralTraitView(
                            trait: trait,
                            preview: viewModel.selectedGeneralSkillPreview,
                            warMeritStatus: viewModel.selectedWarMeritStatus,
                            commanderBrief: viewModel.selectedCommanderBrief,
                            commanderActionGuidance: viewModel.selectedCommanderActionGuidance,
                            commanderChainReadout: viewModel.selectedCommanderChainReadout,
                            commanderOpportunityBridgeReadout: viewModel.selectedCommanderOpportunityBridgeReadout,
                            skillTargetReadout: viewModel.selectedGeneralSkillTargetReadout
                        )
                    } else if let brief = viewModel.selectedCommanderBrief {
                        CompactNoGeneralView(brief: brief)
                    }
                }
            } else if let city = viewModel.selectedCity,
                      let brief = viewModel.selectedCityBrief {
                CompactCityReadoutView(city: city, brief: brief)
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
                    let countermeasurePreview = viewModel.selectedCountermeasureCommandPreview
                    let battleObjectivePreview = viewModel.selectedBattleObjectiveStageCommandPreview
                    let isCountermeasureTarget = countermeasurePreview?.isAttackTarget(target) == true
                    let isBattleObjectiveTarget = battleObjectivePreview?.isAttackTarget(target) == true
                    let attackActionLabel = isCountermeasureTarget ? "反制攻击" : (isBattleObjectiveTarget ? "目标线攻击" : "攻击")
                    let attackDetail = [
                        isCountermeasureTarget ? countermeasurePreview?.targetStageCueLabel : nil,
                        !isCountermeasureTarget && isBattleObjectiveTarget ? battleObjectivePreview?.attackStageCueLabel : nil,
                        preview?.commandModifierSummary
                    ].compactMap { $0 }.joined(separator: " · ")
                    let attackAccessibilityLead = isBattleObjectiveTarget ? battleObjectivePreview?.attackStageCueLabel : nil
                    Button {
                        viewModel.attack(target.id)
                    } label: {
                        CommandButtonLabel(
                            symbol: "bolt.fill",
                            text: preview.map { "\(attackActionLabel) \(target.faction.displayName)\(target.kind.displayName) · 伤\($0.damage)" } ?? "\(attackActionLabel) \(target.faction.displayName)\(target.kind.displayName)",
                            detail: attackDetail.isEmpty ? nil : attackDetail
                        )
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityLabel(isCountermeasureTarget ? "\(countermeasurePreview?.targetStageCueLabel ?? "3 目标，反制目标可攻击")，攻击\(target.faction.displayName)\(target.kind.displayName)" : "\(attackAccessibilityLead ?? "攻击")，攻击\(target.faction.displayName)\(target.kind.displayName)")
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
                    if let preview = viewModel.selectedCountermeasureCommandPreview {
                        CountermeasureCommandPreviewView(preview: preview, isCompact: true)
                    }

                    if let preview = viewModel.selectedBattleObjectiveStageCommandPreview {
                        BattleObjectiveStageCommandPreviewView(preview: preview, isCompact: true)
                    }

                    TacticalOrderControlView(unit: unit, isCompact: true)

                    if let trait = unit.resolvedGeneralTrait {
                        Button {
                            viewModel.useSelectedGeneralSkill()
                        } label: {
                            CommandButtonLabel(
                                symbol: trait.systemImage,
                                text: trait.skillName,
                                detail: viewModel.selectedGeneralSkillCommandButtonDetail
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

                if let city = viewModel.commandCity,
                   let brief = viewModel.commandCityBrief,
                   city.owner == .rome {
                    Button {
                        viewModel.developCommandCity()
                    } label: {
                        CommandButtonLabel(
                            symbol: "building.2.crop.circle.fill",
                            text: "扩建",
                            detail: brief.canDevelop ? brief.developmentGainLabel : brief.developmentStatusLabel
                        )
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(!brief.canDevelop || viewModel.isCampaignOver)

                    CityRecruitmentButtonsView(
                        options: brief.recruitmentOptions,
                        isCompact: true
                    )
                }
            }
        }
    }
}

struct CityRecruitmentButtonsView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    var options: [CityRecruitmentOptionPreview]
    var isCompact: Bool

    var body: some View {
        if isCompact {
            HStack(spacing: 7) {
                ForEach(options) { option in
                    Button {
                        viewModel.recruit(option.kind)
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: option.kind.tokenSystemImage)
                                .font(.caption.weight(.heavy))
                            Text(option.kind.shortLabel)
                                .font(.caption.weight(.black))
                            Text(option.canRecruit ? option.shortCostLabel : option.shortStatusLabel)
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(option.canRecruit ? .white.opacity(0.72) : .orange.opacity(0.86))
                                .lineLimit(1)
                                .minimumScaleFactor(0.58)
                        }
                        .frame(maxWidth: .infinity, minHeight: 54)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(!option.canRecruit || viewModel.isCampaignOver)
                    .accessibilityLabel(option.accessibilityLabel)
                }
            }
        } else {
            VStack(spacing: 7) {
                ForEach(options) { option in
                    Button {
                        viewModel.recruit(option.kind)
                    } label: {
                        CommandButtonLabel(
                            symbol: option.kind.tokenSystemImage,
                            text: "招募 \(option.kind.displayName) · \(option.costLabel)",
                            detail: option.canRecruit ? "\(option.statsLabel) · \(option.deploymentLabel)" : (option.blockedReason ?? option.deploymentLabel)
                        )
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(!option.canRecruit || viewModel.isCampaignOver)
                    .accessibilityLabel(option.accessibilityLabel)
                }
            }
        }
    }
}

struct CompactGeneralTraitView: View {
    var trait: GeneralTrait
    var preview: GeneralSkillPreview?
    var warMeritStatus: WarMeritStatus?
    var commanderBrief: SelectedCommanderBrief?
    var commanderActionGuidance: CommanderActionGuidance?
    var commanderChainReadout: SelectedCommanderChainReadout?
    var commanderOpportunityBridgeReadout: SelectedCommanderOpportunityBridgeReadout?
    var skillTargetReadout: SelectedGeneralSkillTargetReadout?

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
        if let commanderBrief, !commanderBrief.passiveContributions.isEmpty {
            GeneralPassiveContributionStrip(contributions: commanderBrief.passiveContributions, isCompact: true)
        }
        if let commanderChainReadout {
            CommanderChainReadoutView(readout: commanderChainReadout, isCompact: true)
        }
        if let commanderOpportunityBridgeReadout {
            CommanderOpportunityBridgeReadoutView(readout: commanderOpportunityBridgeReadout, isCompact: true)
        }
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
        if let commanderBrief {
            CommanderSkillStatusRow(
                brief: commanderBrief,
                guidance: commanderActionGuidance,
                isCompact: true
            )
        } else if let preview {
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
        if let skillTargetReadout {
            GeneralSkillTargetReadoutView(readout: skillTargetReadout, isCompact: true)
        }
    }
}

struct CompactNoGeneralView: View {
    var brief: SelectedCommanderBrief

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .foregroundStyle(.white.opacity(0.58))
            Text(brief.generalName ?? "无将领")
                .font(.caption.weight(.bold))
            Spacer(minLength: 0)
            Text("无被动贡献")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.56))
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 28)
        .background(.black.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityLabel(brief.accessibilityLabel)
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

struct TacticalOrderPreviewStripView: View {
    var previews: [SelectedTacticalOrderPreview]
    var isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if !isCompact {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(Color(red: 0.86, green: 0.68, blue: 0.34))
                    Text("姿态预览")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.62))
                    Spacer(minLength: 0)
                }
            }

            HStack(spacing: 5) {
                ForEach(previews) { preview in
                    TacticalOrderPreviewMiniCard(preview: preview, isCompact: isCompact)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, isCompact ? 6 : 7)
        .background(.black.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct TacticalOrderPreviewMiniCard: View {
    var preview: SelectedTacticalOrderPreview
    var isCompact: Bool

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: preview.order.systemImage)
                    .font(.caption2.weight(.heavy))
                Text(preview.order.displayName)
                    .font(.caption2.weight(.black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }

            Text("攻\(preview.attack) 防\(preview.defense)")
                .font(.caption2.monospacedDigit().weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.48)

            Text("移\(preview.movement) · \(preview.isCurrent ? "当前" : deltaSummary)")
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(preview.isCurrent ? .black.opacity(0.75) : .white.opacity(0.66))
                .lineLimit(1)
                .minimumScaleFactor(0.48)
        }
        .foregroundStyle(preview.isCurrent ? .black.opacity(0.82) : .white)
        .frame(maxWidth: .infinity, minHeight: isCompact ? 44 : 50)
        .padding(.horizontal, 3)
        .background(preview.isCurrent ? preview.order.tintColor : .black.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(preview.order.tintColor.opacity(preview.isCurrent ? 0 : 0.32), lineWidth: 1)
        }
        .accessibilityLabel(preview.accessibilityLabel)
    }

    private var deltaSummary: String {
        let deltas = [
            ("攻", preview.attackDelta),
            ("防", preview.defenseDelta),
            ("移", preview.movementDelta)
        ]
            .filter { $0.1 != 0 }
            .map { "\($0.0)\($0.1 > 0 ? "+" : "")\($0.1)" }

        if deltas.isEmpty {
            return preview.blockedReason ?? "±0"
        }

        return deltas.joined(separator: " ")
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
            let focus = viewModel.primaryBattlefieldFocusSummary
            let objectiveChain = viewModel.primaryBattleObjectiveChainSummary
            let convergence = viewModel.primaryBattlefieldConvergenceSummary
            let heat = viewModel.primaryThreatHeatZoneSummary
            let mapControl = viewModel.selectedMapControlSummary ?? viewModel.primaryMapControlSummary
            if let tile = viewModel.selectedTile {
                let city = viewModel.state.city(at: tile.position)
                let totalDefense = tile.terrain.defenseBonus + (city?.fortification ?? 0)

                if isCompact {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 7) {
                            CompactStat(label: "地形", value: tile.terrain.displayName)
                            CompactStat(label: "移", value: "\(tile.terrain.movementCost)")
                            CompactStat(label: "防", value: "+\(totalDefense)")
                            CompactStat(label: "补", value: viewModel.selectedSupplyLabel)
                        }

                        if let focus {
                            Label("\(focus.title) · \(focus.severityLabel)", systemImage: focus.kind.systemImage)
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(focus.severity.tintColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                                .accessibilityLabel(focus.accessibilityLabel)
                        }

                        if let convergence {
                            BattlefieldConvergenceCardView(summary: convergence, isCompact: true)
                        }

                        if let objectiveChain {
                            Label(objectiveChain.compactLabel, systemImage: "point.topleft.down.curvedto.point.bottomright.up.fill")
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(Color(red: 0.86, green: 0.68, blue: 0.34))
                                .lineLimit(1)
                                .minimumScaleFactor(0.68)
                                .accessibilityLabel(objectiveChain.accessibilityLabel)
                        }

                        if let heat {
                            Label("\(heat.title) · \(heat.impactLabel)", systemImage: heat.threatLevel.systemImage)
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(heat.threatLevel.tintColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                                .accessibilityLabel(heat.accessibilityLabel)
                        }

                        if let pressure = viewModel.primaryFrontlinePressureSummary {
                            Label("\(pressure.compactTitle) · \(pressure.impactLabel)", systemImage: pressure.level.systemImage)
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(pressure.level.tintColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                                .accessibilityLabel(pressure.accessibilityLabel)
                        }
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

                        if let focus {
                            BattlefieldFocusCardView(summary: focus, isCompact: false)
                        }

                        if let convergence {
                            BattlefieldConvergenceCardView(summary: convergence, isCompact: false)
                        }

                        if let objectiveChain {
                            BattleObjectiveChainCardView(
                                summary: objectiveChain,
                                isCompact: false,
                                focusedRole: viewModel.focusedBattleObjectiveRole,
                                stageCommandPreview: viewModel.focusedBattleObjectiveStageCommandPreview ?? viewModel.primaryBattleObjectiveStageCommandPreview,
                                focusStageAction: viewModel.focusPrimaryBattleObjectiveStage
                            )
                        }

                        if let heat {
                            ThreatHeatCardView(summary: heat, isCompact: false)
                        } else if let mapControl {
                            MapControlCardView(summary: mapControl, isCompact: false)
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
            } else if let convergence {
                BattlefieldConvergenceCardView(summary: convergence, isCompact: isCompact)
            } else if let heat {
                ThreatHeatCardView(summary: heat, isCompact: isCompact)
            } else if let objectiveChain {
                BattleObjectiveChainCardView(
                    summary: objectiveChain,
                    isCompact: isCompact,
                    focusedRole: viewModel.focusedBattleObjectiveRole,
                    stageCommandPreview: viewModel.focusedBattleObjectiveStageCommandPreview ?? viewModel.primaryBattleObjectiveStageCommandPreview,
                    focusStageAction: viewModel.focusPrimaryBattleObjectiveStage
                )
            } else if let focus {
                BattlefieldFocusCardView(summary: focus, isCompact: isCompact)
            } else if let mapControl {
                MapControlCardView(summary: mapControl, isCompact: isCompact)
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
            let maneuverSummaries = viewModel.selectedManeuverOptionSummaries
            let synergySummaries = viewModel.commanderSynergySummaries
            let planSummaries = viewModel.aiOperationalPlanSummaries
            let commanderThreatSummaries = viewModel.enemyCommanderThreatSummaries
            let countermeasureSummaries = viewModel.countermeasureSummaries
            let focusSummaries = viewModel.battlefieldFocusSummaries
            let heatSummaries = viewModel.threatHeatZoneSummaries
            let pressureSummaries = viewModel.frontlinePressureSummaries
            let formationSummaries = viewModel.legionFormationSummaries
            let developmentSummaries = viewModel.unitDevelopmentRecommendationSummaries
            let convergence = viewModel.primaryBattlefieldConvergenceSummary
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

                if let convergence {
                    BattlefieldConvergenceRowView(summary: convergence)
                }

                VStack(alignment: .leading, spacing: 6) {
                    if developmentSummaries.isEmpty {
                        Text("暂无成长推荐。")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(developmentSummaries.prefix(3)) { summary in
                            UnitDevelopmentRecommendationRowView(summary: summary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    if maneuverSummaries.isEmpty {
                        Text("选中单位后显示机动落点。")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(maneuverSummaries.prefix(2)) { summary in
                            ManeuverOptionRowView(summary: summary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    if synergySummaries.isEmpty {
                        Text("暂无本方将令协同。")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(synergySummaries.prefix(2)) { summary in
                            CommanderSynergyRowView(summary: summary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    if planSummaries.isEmpty {
                        Text("暂无敌军作战计划。")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(planSummaries.prefix(2)) { summary in
                            AIOperationalPlanRowView(summary: summary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    if commanderThreatSummaries.isEmpty {
                        Text("暂无敌方将领威胁。")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(commanderThreatSummaries.prefix(2)) { summary in
                            EnemyCommanderThreatRowView(summary: summary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    if countermeasureSummaries.isEmpty {
                        Text("暂无敌情反制建议。")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(countermeasureSummaries.prefix(2)) { summary in
                            CountermeasureRowView(
                                summary: summary,
                                preview: viewModel.countermeasureCommandPreview(for: summary),
                                focusAction: {
                                    viewModel.focusCountermeasure(summary.id)
                                }
                            )
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    if focusSummaries.isEmpty {
                        Text("暂无战场焦点。")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(focusSummaries.prefix(2)) { summary in
                            BattlefieldFocusRowView(summary: summary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    if heatSummaries.isEmpty {
                        Text("暂无威胁热区。")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(heatSummaries.prefix(2)) { summary in
                            ThreatHeatRowView(summary: summary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    if pressureSummaries.isEmpty {
                        Text("暂无集中战线压力。")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(pressureSummaries.prefix(3)) { summary in
                            FrontlinePressureRowView(summary: summary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    if formationSummaries.isEmpty {
                        Text("暂无可读军团编制。")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(formationSummaries.prefix(3)) { summary in
                            LegionFormationRowView(summary: summary)
                        }
                    }
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

struct UnitDevelopmentRecommendationRowView: View {
    var summary: UnitDevelopmentRecommendationSummary

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(summary.priority.tintColor.opacity(0.92))
                    .frame(width: 28, height: 28)
                Image(systemName: summary.kind.systemImage)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(summary.title)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(summary.reasonLabel.isEmpty ? summary.detail : summary.reasonLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Text(summary.impactLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 3) {
                Text(summary.priorityLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.priority.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                Text(summary.statusLabel)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(summary.scoreLabel)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white.opacity(0.44))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 54)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct BattlefieldFocusRowView: View {
    var summary: BattlefieldFocusSummary

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(summary.severity.tintColor.opacity(0.92))
                    .frame(width: 28, height: 28)
                Image(systemName: summary.kind.systemImage)
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

            VStack(alignment: .trailing, spacing: 3) {
                Text(summary.severityLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.severity.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                Text(summary.scoreLabel)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 46)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct AIOperationalPlanRowView: View {
    var summary: AIOperationalPlanSummary

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(summary.kind.tintColor.opacity(0.92))
                    .frame(width: 28, height: 28)
                Image(systemName: summary.kind.systemImage)
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
                Text(summary.timelineLabel.isEmpty ? summary.stepLabel : summary.timelineLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(summary.kind.tintColor.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.64)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 3) {
                Text(summary.kindLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.kind.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                Text(summary.impactLabel)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 46)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct EnemyCommanderThreatRowView: View {
    var summary: EnemyCommanderThreatSummary

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(summary.level.tintColor.opacity(0.92))
                    .frame(width: 28, height: 28)
                Image(systemName: summary.trait.systemImage)
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

            VStack(alignment: .trailing, spacing: 3) {
                Text(summary.levelLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.level.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                Text(summary.scoreLabel)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 46)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct CountermeasureRowView: View {
    var summary: CountermeasureSummary
    var preview: CountermeasureCommandPreview?
    var focusAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(summary.priority.tintColor.opacity(0.92))
                    .frame(width: 28, height: 28)
                Image(systemName: summary.kind.systemImage)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(summary.title)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(summary.commandLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
                    .minimumScaleFactor(0.70)
                if let preview {
                    Text(preview.nextStepLabel)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(summary.priority.tintColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 4) {
                Text(summary.priorityLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.priority.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                Text(summary.impactLabel)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                if let preview,
                   let focusAction {
                    Button("定位", systemImage: "scope") {
                        focusAction()
                    }
                    .font(.caption2.weight(.bold))
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(!preview.canFocus)
                    .accessibilityLabel("\(preview.buttonTitle)，\(preview.accessibilityLabel)")
                }
            }
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 50)
        .background(summary.priority.tintColor.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct CommanderSynergyRowView: View {
    var summary: CommanderSynergySummary

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(summary.kind.tintColor.opacity(0.92))
                    .frame(width: 28, height: 28)
                Image(systemName: summary.kind.systemImage)
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

            VStack(alignment: .trailing, spacing: 3) {
                Text(summary.kindLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.kind.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                Text(summary.impactLabel)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 46)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct ManeuverOptionRowView: View {
    var summary: ManeuverOptionSummary

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(summary.kind.tintColor.opacity(0.92))
                    .frame(width: 28, height: 28)
                Image(systemName: summary.kind.systemImage)
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

            VStack(alignment: .trailing, spacing: 3) {
                Text(summary.riskLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.risk.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                Text(summary.impactLabel)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 46)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct ThreatHeatRowView: View {
    var summary: ThreatHeatZoneSummary

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(summary.threatLevel.tintColor.opacity(0.92))
                    .frame(width: 28, height: 28)
                Image(systemName: summary.threatLevel.systemImage)
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

            VStack(alignment: .trailing, spacing: 3) {
                Text(summary.levelLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.threatLevel.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                Text(summary.impactLabel)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 46)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct BattlefieldFocusCardView: View {
    var summary: BattlefieldFocusSummary
    var isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 5 : 7) {
            HStack(spacing: 7) {
                Image(systemName: summary.kind.systemImage)
                    .foregroundStyle(summary.severity.tintColor)
                Text("焦点")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                Text(summary.title)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Spacer(minLength: 0)
                Text(summary.severityLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.severity.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            if !isCompact {
                Text(summary.report.summary)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }

            Text(summary.objectiveCueLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            HStack(spacing: 6) {
                Label(summary.targetLabel, systemImage: "scope")
                Spacer(minLength: 0)
                Label(summary.report.recommendedOrder.displayName, systemImage: summary.report.recommendedOrder.systemImage)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.66))
            .lineLimit(1)
            .minimumScaleFactor(0.70)

            Text(summary.detail)
                .font(.caption2.weight(.bold))
                .foregroundStyle(summary.severity.tintColor)
                .lineLimit(isCompact ? 1 : 2)
                .minimumScaleFactor(0.70)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(summary.severity.tintColor.opacity(0.12))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(summary.severity.tintColor.opacity(0.38), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct BattleObjectiveChainCardView: View {
    var summary: BattleObjectiveChainSummary
    var isCompact: Bool
    var focusedRole: BattleObjectiveMapRole?
    var stageCommandPreview: BattleObjectiveStageCommandPreview?
    var focusStageAction: ((BattleObjectiveMapRole) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 5 : 7) {
            HStack(spacing: 7) {
                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up.fill")
                    .foregroundStyle(Color(red: 0.86, green: 0.68, blue: 0.34))
                Text("目标线")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                Text(summary.title)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Spacer(minLength: 0)
                Text(summary.priorityLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(Color(red: 0.86, green: 0.68, blue: 0.34))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            Text(isCompact ? summary.compactLabel : summary.chainLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.66))
                .lineLimit(isCompact ? 2 : 3)
                .minimumScaleFactor(0.66)

            if focusStageAction != nil {
                HStack(spacing: 5) {
                    ForEach(stageRoles) { role in
                        let isStageActive = focusedRole == role || stageCommandPreview?.role == role
                        let stageCueLabel = stageCommandPreview?.role == role ? stageCommandPreview?.commandEntryCueLabel : nil
                        Button {
                            focusStageAction?(role)
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: role.symbol)
                                    .font(.system(size: 9, weight: .black))
                                Text(role.stageLabel)
                                    .font(.system(size: 10, weight: .black))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                            }
                            .foregroundStyle(isStageActive ? .black.opacity(0.82) : role.tintColor)
                            .padding(.horizontal, 5)
                            .frame(maxWidth: .infinity, minHeight: 22)
                            .background(isStageActive ? role.tintColor : role.tintColor.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel([stageAccessibilityLabel(for: role), stageCueLabel, "定位"].compactMap { $0 }.joined(separator: "，"))
                        .accessibilityAddTraits(isStageActive ? .isSelected : AccessibilityTraits())
                    }
                }
            }

            if let stageCommandPreview {
                BattleObjectiveStageCommandPreviewView(
                    preview: stageCommandPreview,
                    isCompact: isCompact
                )
            }

            if !isCompact {
                HStack(spacing: 6) {
                    Label(summary.focus.targetLabel, systemImage: summary.focus.kind.systemImage)
                    Spacer(minLength: 0)
                    Label(summary.recommendation?.targetLabel ?? summary.focus.targetLabel, systemImage: "scope")
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.86, green: 0.68, blue: 0.34).opacity(0.12))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(red: 0.86, green: 0.68, blue: 0.34).opacity(0.38), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }

    private var stageRoles: [BattleObjectiveMapRole] {
        var roles: [BattleObjectiveMapRole] = [.focus]

        if summary.synergy != nil {
            roles.append(.synergy)
        }

        if summary.maneuver != nil {
            roles.append(.maneuver)
        }

        if summary.recommendation != nil {
            roles.append(.recommendation)
        }

        return roles
    }

    private func stageAccessibilityLabel(for role: BattleObjectiveMapRole) -> String {
        switch role {
        case .focus:
            return summary.focusStageLabel
        case .synergy:
            return summary.synergyStageLabel
        case .maneuver:
            return summary.maneuverStageLabel
        case .recommendation:
            return summary.recommendationStageLabel
        }
    }
}

struct BattlefieldConvergenceCardView: View {
    var summary: BattlefieldConvergenceSummary
    var isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 5 : 7) {
            HStack(spacing: 7) {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .foregroundStyle(Color(red: 0.36, green: 0.86, blue: 0.92))
                Text("交汇")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                Text(isCompact ? summary.compactLabel : summary.title)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                Spacer(minLength: 0)
                Text(summary.priorityLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.64)
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(Color(red: 0.36, green: 0.86, blue: 0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            if isCompact {
                Text(summary.nextStepLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    BattlefieldConvergenceLabelRow(
                        symbol: "point.topleft.down.curvedto.point.bottomright.up.fill",
                        title: "主线",
                        value: summary.objectiveLabel,
                        tint: Color(red: 0.86, green: 0.68, blue: 0.34)
                    )
                    BattlefieldConvergenceLabelRow(
                        symbol: "shield.lefthalf.filled",
                        title: "回应",
                        value: summary.responseLabel,
                        tint: Color(red: 0.36, green: 0.86, blue: 0.92)
                    )
                    BattlefieldConvergenceLabelRow(
                        symbol: "map.fill",
                        title: "空间",
                        value: summary.spaceLabel,
                        tint: Color(red: 0.70, green: 0.76, blue: 0.32)
                    )
                    BattlefieldConvergenceLabelRow(
                        symbol: "arrow.forward.circle.fill",
                        title: "下一步",
                        value: summary.nextStepLabel,
                        tint: Color(red: 0.92, green: 0.46, blue: 0.20)
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(summary.signals.prefix(4)) { signal in
                        BattlefieldConvergenceSignalRow(signal: signal)
                    }
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: isCompact ? 48 : 132, alignment: .leading)
        .background(Color(red: 0.36, green: 0.86, blue: 0.92).opacity(0.10))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(red: 0.36, green: 0.86, blue: 0.92).opacity(0.34), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct BattlefieldConvergenceRowView: View {
    var summary: BattlefieldConvergenceSummary

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(red: 0.36, green: 0.86, blue: 0.92).opacity(0.92))
                    .frame(width: 28, height: 28)
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.76))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(summary.compactLabel.isEmpty ? summary.title : summary.compactLabel)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Text(summary.nextStepLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 3) {
                Text(summary.priorityLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(Color(red: 0.36, green: 0.86, blue: 0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                Text(summary.riskLabel)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
            }
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 48)
        .background(Color(red: 0.36, green: 0.86, blue: 0.92).opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct ReadoutLabelRow: View {
    var symbol: String
    var title: String
    var value: String
    var tint: Color
    var titleWidth: CGFloat = 38
    var titleOpacity: Double = 0.58
    var valueOpacity: Double = 0.72
    var minimumScaleFactor: CGFloat = 0.66

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.caption2.weight(.heavy))
                .foregroundStyle(tint)
                .frame(width: 14)
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(titleOpacity))
                .frame(width: titleWidth, alignment: .leading)
            Text(value)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(valueOpacity))
                .lineLimit(1)
                .minimumScaleFactor(minimumScaleFactor)
            Spacer(minLength: 0)
        }
    }
}

struct BattlefieldConvergenceLabelRow: View {
    var symbol: String
    var title: String
    var value: String
    var tint: Color

    var body: some View {
        ReadoutLabelRow(
            symbol: symbol,
            title: title,
            value: value,
            tint: tint,
            titleOpacity: 0.52
        )
    }
}

struct BattlefieldConvergenceSignalRow: View {
    var signal: BattlefieldConvergenceSignal

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: signal.role.systemImage)
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(signal.role.tintColor)
                .frame(width: 12)
            Text(signal.role.displayName)
                .font(.caption2.weight(.black))
                .foregroundStyle(signal.role.tintColor)
                .frame(width: 28, alignment: .leading)
            Text(signal.title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)
                .minimumScaleFactor(0.66)
            Text(signal.detail)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.54))
                .lineLimit(1)
                .minimumScaleFactor(0.64)
            Spacer(minLength: 0)
            if let position = signal.position {
                Text(position.description)
                    .font(.caption2.monospacedDigit().weight(.black))
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
        .padding(.horizontal, 6)
        .frame(minHeight: 22)
        .background(signal.role.tintColor.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .accessibilityLabel(signal.accessibilityLabel)
    }
}

struct ThreatHeatCardView: View {
    var summary: ThreatHeatZoneSummary
    var isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 5 : 7) {
            HStack(spacing: 7) {
                Image(systemName: summary.threatLevel.systemImage)
                    .foregroundStyle(summary.threatLevel.tintColor)
                Text("热区")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                Text(summary.title)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Spacer(minLength: 0)
                Text(summary.levelLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.threatLevel.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            if !isCompact {
                Text(summary.sourceLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }

            HStack(spacing: 6) {
                Label(summary.impactLabel, systemImage: "scope")
                Spacer(minLength: 0)
                Label(summary.controlLabel, systemImage: "flag.2.crossed.fill")
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.66))
            .lineLimit(1)
            .minimumScaleFactor(0.70)

            Text(summary.detail)
                .font(.caption2.weight(.bold))
                .foregroundStyle(summary.threatLevel.tintColor)
                .lineLimit(isCompact ? 1 : 2)
                .minimumScaleFactor(0.70)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(summary.threatLevel.tintColor.opacity(0.12))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(summary.threatLevel.tintColor.opacity(0.38), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct MapControlCardView: View {
    var summary: MapControlSummary
    var isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 5 : 7) {
            HStack(spacing: 7) {
                Image(systemName: "map.fill")
                    .foregroundStyle(summary.controlState.tintColor)
                Text("控区")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                Text(summary.title)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Spacer(minLength: 0)
                Text(summary.levelLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.threatLevel.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            if !isCompact {
                Text(summary.sourceLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }

            HStack(spacing: 6) {
                Label(summary.impactLabel, systemImage: "flag.2.crossed.fill")
                Spacer(minLength: 0)
                Label(summary.position.description, systemImage: "location.fill")
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.66))
            .lineLimit(1)
            .minimumScaleFactor(0.70)

            Text(summary.detail)
                .font(.caption2.weight(.bold))
                .foregroundStyle(summary.threatLevel.tintColor)
                .lineLimit(isCompact ? 1 : 2)
                .minimumScaleFactor(0.70)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(summary.controlState.tintColor.opacity(0.10))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(summary.controlState.tintColor.opacity(0.34), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct FrontlinePressureRowView: View {
    var summary: FrontlinePressureSummary

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(summary.level.tintColor.opacity(0.92))
                    .frame(width: 28, height: 28)
                Image(systemName: summary.level.systemImage)
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

            Text(summary.impactLabel)
                .font(.caption2.weight(.black))
                .foregroundStyle(.black.opacity(0.78))
                .padding(.horizontal, 6)
                .frame(height: 20)
                .background(.white.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 44)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct LegionFormationRowView: View {
    var summary: LegionFormationSummary

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(summary.report.readiness.tintColor.opacity(0.92))
                    .frame(width: 28, height: 28)
                Image(systemName: summary.report.role.systemImage)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(summary.title) · \(summary.roleLabel)")
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

            VStack(alignment: .trailing, spacing: 3) {
                Text(summary.readinessLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.report.readiness.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                Text(summary.integrityLabel)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 46)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct SelectedUnitSituationReadoutView: View {
    var readout: SelectedUnitSituationReadout
    var isCompact: Bool

    private var tint: Color {
        if readout.pressureLabel.contains("伤害") || readout.statusLabel.contains("高") {
            return Color(red: 0.92, green: 0.42, blue: 0.25)
        }

        if readout.spaceLabel.contains("争夺") || readout.riskLabel.contains("中") {
            return Color(red: 0.88, green: 0.68, blue: 0.26)
        }

        return Color(red: 0.40, green: 0.78, blue: 0.70)
    }

    private var commandEntrySymbol: String {
        switch readout.primaryCommandEntry?.kind {
        case .some(.countermeasure):
            return "shield.lefthalf.filled"
        case .some(.objectiveStage):
            return "point.topleft.down.curvedto.point.bottomright.up.fill"
        case .some(.commanderAction):
            return "sparkles"
        case .some(.maneuver):
            return "arrow.up.right.circle.fill"
        case .some(.recommendation):
            return "lightbulb.fill"
        case .some(.tacticalOrder):
            return "flag.checkered"
        case nil:
            return "rectangle.and.hand.point.up.left.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 5 : 7) {
            HStack(spacing: 7) {
                Image(systemName: "scope")
                    .foregroundStyle(tint)
                Text("处境")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                Text(readout.title)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Spacer(minLength: 0)
                Text(readout.statusLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.64)
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(tint)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            if isCompact {
                VStack(alignment: .leading, spacing: 3) {
                    Text(readout.nextStepLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(1)
                        .minimumScaleFactor(0.66)
                    HStack(spacing: 5) {
                        Image(systemName: commandEntrySymbol)
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(tint)
                            .frame(width: 13)
                        Text("入口")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white.opacity(0.58))
                        Text(readout.commandEntrySummaryLabel)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.72))
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                        Spacer(minLength: 0)
                    }
                }
            } else {
                SelectedUnitSituationLabelRow(
                    symbol: "flame.fill",
                    title: "压力",
                    value: "\(readout.pressureLabel) · \(readout.spaceLabel)",
                    tint: Color(red: 0.92, green: 0.42, blue: 0.25)
                )
                SelectedUnitSituationLabelRow(
                    symbol: "sparkles",
                    title: "机会",
                    value: "\(readout.opportunityLabel) · 风险 \(readout.riskLabel)",
                    tint: Color(red: 0.46, green: 0.72, blue: 0.96)
                )
                SelectedUnitSituationLabelRow(
                    symbol: commandEntrySymbol,
                    title: "入口",
                    value: readout.commandEntrySummaryLabel,
                    tint: Color(red: 0.88, green: 0.68, blue: 0.26)
                )
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: isCompact ? 60 : 104, alignment: .leading)
        .background(tint.opacity(0.11))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(tint.opacity(0.34), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(readout.accessibilityLabel)
    }
}

struct SelectedUnitSituationLabelRow: View {
    var symbol: String
    var title: String
    var value: String
    var tint: Color

    var body: some View {
        ReadoutLabelRow(symbol: symbol, title: title, value: value, tint: tint)
    }
}

struct SelectedUnitOrderWindowReadoutView: View {
    var readout: SelectedUnitOrderWindowReadout
    var isCompact: Bool

    private var tint: Color {
        if readout.riskLabel.contains("高") || readout.counterLabel.contains("威胁") {
            return Color(red: 0.96, green: 0.45, blue: 0.22)
        }

        if readout.statusLabel.contains("可") || readout.commanderLabel.contains("将") {
            return Color(red: 0.44, green: 0.74, blue: 0.96)
        }

        return Color(red: 0.85, green: 0.67, blue: 0.34)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 5 : 7) {
            HStack(spacing: 7) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundStyle(tint)
                Text("军令")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                Text(readout.title)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Spacer(minLength: 0)
                Text(readout.statusLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(tint)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            if isCompact {
                Text(readout.compactLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.60)
                HStack(spacing: 5) {
                    ForEach(Array(readout.steps.prefix(3))) { step in
                        SelectedUnitOrderWindowStepChip(step: step)
                    }
                    Spacer(minLength: 0)
                }
            } else {
                SelectedUnitOrderWindowLabelRow(
                    symbol: "flag.checkered",
                    title: "开局",
                    value: "\(readout.openingLabel) · \(readout.postureLabel)",
                    tint: tint
                )
                SelectedUnitOrderWindowLabelRow(
                    symbol: "arrow.up.right.circle.fill",
                    title: "机动",
                    value: "\(readout.movementLabel) · \(readout.strikeLabel)",
                    tint: Color(red: 0.45, green: 0.78, blue: 0.66)
                )
                SelectedUnitOrderWindowLabelRow(
                    symbol: "bolt.shield.fill",
                    title: "入口",
                    value: "\(readout.commanderLabel) · \(readout.counterLabel)",
                    tint: Color(red: 0.74, green: 0.58, blue: 0.96)
                )
                SelectedUnitOrderWindowLabelRow(
                    symbol: "arrow.right.circle.fill",
                    title: "下一步",
                    value: "\(readout.nextStepLabel) · 风险 \(readout.riskLabel)",
                    tint: Color(red: 0.96, green: 0.58, blue: 0.24)
                )
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: isCompact ? 58 : 124, alignment: .leading)
        .background(tint.opacity(0.11))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(tint.opacity(0.34), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(readout.accessibilityLabel)
    }
}

struct SelectedUnitOrderWindowStepChip: View {
    var step: SelectedUnitOrderWindowStep

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.caption2.weight(.heavy))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(step.kind.displayName)
                .font(.caption2.weight(.bold))
            Text(step.cueLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.70))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.56)
        .padding(.horizontal, 5)
        .frame(height: 20)
        .background(tint.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .accessibilityLabel(step.accessibilityLabel)
    }

    private var symbol: String {
        switch step.kind {
        case .countermeasure:
            return "shield.lefthalf.filled"
        case .objectiveStage:
            return "point.topleft.down.curvedto.point.bottomright.up.fill"
        case .commander:
            return "sparkles"
        case .maneuver:
            return "arrow.up.right.circle.fill"
        case .recommendation:
            return "lightbulb.fill"
        case .tacticalOrder:
            return "flag.checkered"
        case .engagement:
            return "arrow.triangle.2.circlepath"
        case .convergence:
            return "link.circle.fill"
        }
    }

    private var tint: Color {
        switch step.kind {
        case .countermeasure:
            return Color(red: 0.96, green: 0.45, blue: 0.22)
        case .objectiveStage:
            return Color(red: 0.92, green: 0.72, blue: 0.25)
        case .commander:
            return Color(red: 0.74, green: 0.58, blue: 0.96)
        case .maneuver:
            return Color(red: 0.45, green: 0.78, blue: 0.66)
        case .recommendation:
            return Color(red: 0.52, green: 0.78, blue: 0.96)
        case .tacticalOrder:
            return Color(red: 0.88, green: 0.68, blue: 0.34)
        case .engagement:
            return Color(red: 0.96, green: 0.30, blue: 0.30)
        case .convergence:
            return Color(red: 0.58, green: 0.82, blue: 0.76)
        }
    }
}

struct SelectedUnitOrderWindowLabelRow: View {
    var symbol: String
    var title: String
    var value: String
    var tint: Color

    var body: some View {
        ReadoutLabelRow(
            symbol: symbol,
            title: title,
            value: value,
            tint: tint,
            titleWidth: 42,
            minimumScaleFactor: 0.60
        )
    }
}

struct TacticalRecommendationCardView: View {
    var summary: TacticalRecommendationSummary
    var isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 5 : 7) {
            HStack(spacing: 7) {
                Image(systemName: summary.kind.systemImage)
                    .foregroundStyle(summary.kind.tintColor)
                Text("军议")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                Text("\(summary.kindLabel) · \(summary.targetLabel)")
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Spacer(minLength: 0)
                Text(summary.riskLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.risk.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            if !isCompact {
                Text(summary.report.reason)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }

            Text(summary.objectiveCueLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            HStack(spacing: 6) {
                Label(summary.pathLabel, systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                Spacer(minLength: 0)
                Label(summary.report.recommendedOrder.displayName, systemImage: summary.report.recommendedOrder.systemImage)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.66))
            .lineLimit(1)
            .minimumScaleFactor(0.70)

            Text(summary.report.command)
                .font(.caption2.weight(.bold))
                .foregroundStyle(summary.kind.tintColor)
                .lineLimit(isCompact ? 1 : 2)
                .minimumScaleFactor(0.70)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(summary.kind.tintColor.opacity(0.12))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(summary.kind.tintColor.opacity(0.38), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct ManeuverOptionCardView: View {
    var summary: ManeuverOptionSummary
    var isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 5 : 7) {
            HStack(spacing: 7) {
                Image(systemName: summary.kind.systemImage)
                    .foregroundStyle(summary.kind.tintColor)
                Text("机动")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                Text("\(summary.kindLabel) · \(summary.destinationLabel)")
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Spacer(minLength: 0)
                Text(summary.riskLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.risk.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            if !isCompact {
                Text(summary.detail)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }

            Text(summary.objectiveCueLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            HStack(spacing: 6) {
                Label(summary.impactLabel, systemImage: summary.kind.systemImage)
                Spacer(minLength: 0)
                Label(summary.report.recommendedOrder.displayName, systemImage: summary.report.recommendedOrder.systemImage)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.66))
            .lineLimit(1)
            .minimumScaleFactor(0.70)

            Text("\(summary.controlLabel) · \(summary.influenceLabel) · \(summary.modifierLabel)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(summary.kind.tintColor)
                .lineLimit(isCompact ? 1 : 2)
                .minimumScaleFactor(0.70)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(summary.kind.tintColor.opacity(0.12))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(summary.kind.tintColor.opacity(0.38), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct CommanderSynergyCardView: View {
    var summary: CommanderSynergySummary
    var isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 5 : 7) {
            HStack(spacing: 7) {
                Image(systemName: summary.kind.systemImage)
                    .foregroundStyle(summary.kind.tintColor)
                Text("将令")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                Text("\(summary.kindLabel) · \(summary.targetLabel)")
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Spacer(minLength: 0)
                Text(summary.statusLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.kind.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            if !isCompact {
                Text(summary.stepSequenceLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            } else {
                Text(summary.stepSequenceLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Text(summary.objectiveCueLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            HStack(spacing: 6) {
                Label(summary.impactLabel, systemImage: "scope")
                Spacer(minLength: 0)
                Label(summary.report.recommendedOrder.displayName, systemImage: summary.report.recommendedOrder.systemImage)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.66))
            .lineLimit(1)
            .minimumScaleFactor(0.70)

            Text(summary.modifierLabel == summary.statusLabel ? summary.detail : "\(summary.modifierLabel) · \(summary.detail)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(summary.kind.tintColor)
                .lineLimit(isCompact ? 1 : 2)
                .minimumScaleFactor(0.70)

            if !isCompact {
                VStack(spacing: 4) {
                    ForEach(summary.stepReadouts.prefix(3)) { step in
                        CommanderSynergyStepReadoutView(step: step, tint: summary.kind.tintColor)
                    }
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(summary.kind.tintColor.opacity(0.12))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(summary.kind.tintColor.opacity(0.38), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct CommanderSynergyStepReadoutView: View {
    var step: CommanderSynergyStepReadout
    var tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(step.roleLabel)
                .font(.caption2.weight(.black))
                .foregroundStyle(.black.opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.66)
                .padding(.horizontal, 5)
                .frame(height: 18)
                .background(tint)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 1) {
                Text("\(step.unitLabel) · \(step.orderLabel)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.76))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                Text("\(step.routeLabel) · \(step.detailLabel)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .accessibilityLabel(step.accessibilityLabel)
    }
}

struct LegionFormationCardView: View {
    var summary: LegionFormationSummary
    var isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 5 : 7) {
            HStack(spacing: 7) {
                Image(systemName: summary.report.role.systemImage)
                    .foregroundStyle(summary.report.readiness.tintColor)
                Text("编制")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                Text("\(summary.roleLabel) · \(summary.readinessLabel)")
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Spacer(minLength: 0)
                Text(summary.integrityLabel)
                    .font(.caption2.monospacedDigit().weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.report.readiness.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            if !isCompact {
                Text(summary.detail)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }

            HStack(spacing: 6) {
                Label(summary.supportLabel, systemImage: "person.3.fill")
                Spacer(minLength: 0)
                Label(summary.orderLabel, systemImage: summary.report.recommendedOrder.systemImage)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.66))
            .lineLimit(1)
            .minimumScaleFactor(0.70)

            HStack(spacing: 6) {
                Image(systemName: summary.report.skillReady ? "sparkles" : "scope")
                    .foregroundStyle(summary.report.skillReady ? Color(red: 0.36, green: 0.86, blue: 0.92) : .white.opacity(0.58))
                Text(summary.recommendationLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.66))
                    .lineLimit(isCompact ? 1 : 2)
                    .minimumScaleFactor(0.68)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, isCompact ? 7 : 8)
        .background(.black.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct UnitDevelopmentDecisionCardView: View {
    var summary: UnitDevelopmentDecisionSummary
    var isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 5 : 7) {
            HStack(spacing: 7) {
                Image(systemName: "chevron.up.forward.2")
                    .foregroundStyle(Color(red: 0.86, green: 0.68, blue: 0.34))
                Text("成长")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                Text(summary.title)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Spacer(minLength: 0)
            }

            ForEach(summary.options) { option in
                UnitDevelopmentDecisionOptionRowView(option: option, isCompact: isCompact)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, isCompact ? 7 : 8)
        .background(.black.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct UnitDevelopmentDecisionOptionRowView: View {
    var option: UnitDevelopmentDecisionOption
    var isCompact: Bool

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: option.symbol)
                .font(.caption.weight(.black))
                .foregroundStyle(option.kind.tintColor)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(option.title)
                        .font(.caption.weight(.heavy))
                    Text(option.shortCostLabel)
                        .font(.caption2.monospacedDigit().weight(.bold))
                        .foregroundStyle(.white.opacity(0.58))
                }
                Text(option.impactLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.64))
                    .lineLimit(isCompact ? 1 : 2)
                    .minimumScaleFactor(0.68)
            }

            Spacer(minLength: 0)

            Text(option.statusLabel)
                .font(.caption2.weight(.black))
                .foregroundStyle(option.canExecute ? .black.opacity(0.78) : .white.opacity(0.72))
                .padding(.horizontal, 6)
                .frame(height: 20)
                .frame(maxWidth: isCompact ? 82 : 118)
                .background(option.canExecute ? option.kind.tintColor : .white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(option.kind.tintColor.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityLabel(option.accessibilityLabel)
    }
}

struct EnemyIntentPanelView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        PanelView(title: "敌情", symbol: "eye.trianglebadge.exclamationmark.fill") {
            VStack(spacing: 7) {
                if let plan = viewModel.primaryAIOperationalPlanSummary {
                    AIOperationalPlanCardView(summary: plan)
                }

                if let commanderThreat = viewModel.primaryEnemyCommanderThreatSummary {
                    EnemyCommanderThreatCardView(summary: commanderThreat)
                }

                if let countermeasure = viewModel.primaryCountermeasureSummary {
                    CountermeasureCardView(
                        summary: countermeasure,
                        preview: viewModel.primaryCountermeasureCommandPreview,
                        focusAction: {
                            viewModel.focusCountermeasure(countermeasure.id)
                        }
                    )
                }

                if viewModel.enemyIntentSummaries.isEmpty {
                    Text("暂无明确敌军动向。")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(viewModel.enemyIntentSummaries.prefix(4)) { summary in
                        EnemyIntentRowView(summary: summary)
                    }
                }
            }
        }
    }
}

struct EnemyCommanderThreatCardView: View {
    var summary: EnemyCommanderThreatSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Image(systemName: summary.trait.systemImage)
                    .foregroundStyle(summary.level.tintColor)
                Text("敌将")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                Text(summary.title)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Spacer(minLength: 0)
                Text(summary.levelLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.level.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            Text(summary.impactLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            HStack(spacing: 6) {
                Label(summary.targetLabel, systemImage: "scope")
                Spacer(minLength: 0)
                Label(summary.intentLabel, systemImage: "bolt.shield.fill")
                Spacer(minLength: 0)
                Label(summary.statusLabel, systemImage: "timer")
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.66))
            .lineLimit(1)
            .minimumScaleFactor(0.70)

            Text(summary.detail)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.54))
                .lineLimit(2)
                .minimumScaleFactor(0.70)
        }
        .padding(8)
        .background(summary.level.tintColor.opacity(0.11))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct CountermeasureCardView: View {
    var summary: CountermeasureSummary
    var preview: CountermeasureCommandPreview?
    var focusAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Image(systemName: summary.kind.systemImage)
                    .foregroundStyle(summary.priority.tintColor)
                Text("反制")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                Text(summary.title)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Spacer(minLength: 0)
                Text(summary.priorityLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.priority.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            Text(summary.commandLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            HStack(spacing: 6) {
                Label(summary.threatLabel, systemImage: "eye.trianglebadge.exclamationmark.fill")
                Spacer(minLength: 0)
                Label(summary.responseLabel, systemImage: "shield.lefthalf.filled")
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.66))
            .lineLimit(1)
            .minimumScaleFactor(0.70)

            HStack(spacing: 6) {
                Label(summary.impactLabel, systemImage: "chart.line.uptrend.xyaxis")
                Spacer(minLength: 0)
                Label(summary.riskLabel, systemImage: "exclamationmark.triangle.fill")
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.60))
            .lineLimit(1)
            .minimumScaleFactor(0.70)

            Text(summary.reasonLabel.isEmpty ? summary.detail : summary.reasonLabel)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.54))
                .lineLimit(2)
                .minimumScaleFactor(0.70)

            if let preview {
                CountermeasureCommandPreviewView(preview: preview, isCompact: true)
            }

            if let preview,
               let focusAction {
                Button("定位回应", systemImage: "scope") {
                    focusAction()
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(!preview.canFocus)
                .accessibilityLabel("\(preview.buttonTitle)，\(preview.accessibilityLabel)")
            }
        }
        .padding(8)
        .background(summary.priority.tintColor.opacity(0.11))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct CountermeasureCommandPreviewView: View {
    var preview: CountermeasureCommandPreview
    var isCompact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                Image(systemName: preview.isExecutableNow ? "checkmark.shield.fill" : "shield.lefthalf.filled")
                    .foregroundStyle(preview.summary.priority.tintColor)
                Text(preview.statusLabel)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Spacer(minLength: 0)
                Text(preview.orderLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Text(preview.nextStepLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.70))
                .lineLimit(isCompact ? 2 : 1)
                .minimumScaleFactor(0.72)

            Text(preview.commandChainLabel)
                .font(.caption2.weight(.bold))
                .foregroundStyle(preview.summary.priority.tintColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(preview.chainSummaryLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(isCompact ? 2 : 1)
                .minimumScaleFactor(0.68)

            HStack(spacing: 6) {
                Label(preview.destinationLabel, systemImage: "arrow.up.right.circle.fill")
                Spacer(minLength: 0)
                Label(preview.targetLabel, systemImage: "scope")
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.58))
            .lineLimit(1)
            .minimumScaleFactor(0.70)

            if !isCompact {
                HStack(spacing: 6) {
                    Label(preview.recommendedOrderCueLabel, systemImage: "flag.checkered")
                    Spacer(minLength: 0)
                    Label(preview.targetStageCueLabel, systemImage: "bolt.fill")
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.70)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(preview.steps) { step in
                        HStack(spacing: 5) {
                            Image(systemName: step.isReady ? "checkmark.circle.fill" : step.symbol)
                                .foregroundStyle(step.isReady ? .green : .white.opacity(0.52))
                                .frame(width: 15)
                            Text(step.title)
                                .font(.caption2.weight(.bold))
                            Text(step.detail)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.58))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .padding(7)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(preview.accessibilityLabel)
    }
}

struct BattleObjectiveStageCommandPreviewView: View {
    var preview: BattleObjectiveStageCommandPreview
    var isCompact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                Image(systemName: preview.isExecutableNow ? "checkmark.circle.fill" : preview.role.symbol)
                    .foregroundStyle(preview.role.tintColor)
                Text(preview.statusLabel)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Spacer(minLength: 0)
                Text(preview.stageLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 18)
                    .background(preview.role.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            Text(preview.nextStepLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.70))
                .lineLimit(isCompact ? 2 : 1)
                .minimumScaleFactor(0.72)

            HStack(spacing: 6) {
                Label(preview.commandEntryLabel, systemImage: "rectangle.and.hand.point.up.left.fill")
                Spacer(minLength: 0)
                Label(preview.targetLabel, systemImage: "scope")
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.58))
            .lineLimit(1)
            .minimumScaleFactor(0.68)

            if !isCompact {
                HStack(spacing: 6) {
                    Label(preview.orderCueLabel, systemImage: "flag.checkered")
                    Spacer(minLength: 0)
                    Label(preview.attackCueLabel, systemImage: "bolt.fill")
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.68)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(preview.steps) { step in
                        HStack(spacing: 5) {
                            Image(systemName: step.isReady ? "checkmark.circle.fill" : step.symbol)
                                .foregroundStyle(step.isReady ? .green : .white.opacity(0.52))
                                .frame(width: 15)
                            Text(step.title)
                                .font(.caption2.weight(.bold))
                            Text(step.detail)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.58))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .padding(7)
        .background(.black.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(preview.accessibilityLabel)
    }
}

struct AIOperationalPlanCardView: View {
    var summary: AIOperationalPlanSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Image(systemName: summary.kind.systemImage)
                    .foregroundStyle(summary.kind.tintColor)
                Text("计划")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                Text(summary.title)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Spacer(minLength: 0)
                Text(summary.kindLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(summary.kind.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            Text(summary.sourceLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            HStack(spacing: 6) {
                Label(summary.impactLabel, systemImage: "scope")
                Spacer(minLength: 0)
                Label(summary.heatLabel, systemImage: "flame.fill")
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.66))
            .lineLimit(1)
            .minimumScaleFactor(0.70)

            VStack(alignment: .leading, spacing: 5) {
                Text(summary.timelineLabel.isEmpty ? summary.detail : summary.timelineLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(summary.kind.tintColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.68)

                ForEach(Array(summary.timelineSteps.prefix(3))) { step in
                    AIOperationalPlanTimelineStepView(step: step, tint: summary.kind.tintColor)
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(summary.kind.tintColor.opacity(0.12))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(summary.kind.tintColor.opacity(0.38), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(summary.accessibilityLabel)
    }
}

struct AIOperationalPlanTimelineStepView: View {
    var step: AIOperationalPlanTimelineStepReadout
    var tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("\(step.sequence)")
                .font(.caption2.monospacedDigit().weight(.black))
                .foregroundStyle(.black.opacity(0.78))
                .frame(width: 18, height: 18)
                .background(tint.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 5))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(step.roleLabel)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(tint)
                        .lineLimit(1)
                    Text(step.unitLabel)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                    Spacer(minLength: 0)
                    Text(step.impactLabel)
                        .font(.caption2.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                        .minimumScaleFactor(0.64)
                }

                Text("\(step.intentLabel) · \(step.orderLabel) · \(step.routeLabel)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(2)
                    .minimumScaleFactor(0.66)
            }
        }
        .padding(6)
        .background(.black.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(step.accessibilityLabel)
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

                    if let situation = viewModel.selectedUnitSituationReadout {
                        SelectedUnitSituationReadoutView(readout: situation, isCompact: false)
                    }

                    if let orderWindow = viewModel.selectedUnitOrderWindowReadout {
                        SelectedUnitOrderWindowReadoutView(readout: orderWindow, isCompact: false)
                    }

                    if let formation = viewModel.selectedLegionFormationSummary {
                        LegionFormationCardView(summary: formation, isCompact: false)
                    }

                    if let development = viewModel.selectedUnitDevelopmentDecisionSummary {
                        UnitDevelopmentDecisionCardView(summary: development, isCompact: false)
                    }

                    if let recommendation = viewModel.selectedTacticalRecommendationSummary {
                        TacticalRecommendationCardView(summary: recommendation, isCompact: false)
                    }

                    if let maneuver = viewModel.primaryManeuverOptionSummary {
                        ManeuverOptionCardView(summary: maneuver, isCompact: false)
                    }

                    if let synergy = viewModel.selectedCommanderSynergySummary {
                        CommanderSynergyCardView(summary: synergy, isCompact: false)
                    }

                    TacticalOrderPreviewStripView(
                        previews: viewModel.selectedTacticalOrderPreviews,
                        isCompact: false
                    )

                    if let trait = unit.resolvedGeneralTrait {
                        GeneralTraitCardView(
                            trait: trait,
                            preview: viewModel.selectedGeneralSkillPreview,
                            warMeritStatus: viewModel.selectedWarMeritStatus,
                            commanderBrief: viewModel.selectedCommanderBrief,
                            commanderActionGuidance: viewModel.selectedCommanderActionGuidance,
                            commanderChainReadout: viewModel.selectedCommanderChainReadout,
                            commanderOpportunityBridgeReadout: viewModel.selectedCommanderOpportunityBridgeReadout,
                            skillTargetReadout: viewModel.selectedGeneralSkillTargetReadout
                        )
                    } else if let brief = viewModel.selectedCommanderBrief {
                        NoGeneralCommandView(brief: brief)
                    }
                }
            } else if let city = viewModel.selectedCity,
                      let brief = viewModel.selectedCityBrief {
                CityReadoutView(city: city, brief: brief)
            } else {
                Text("元老院令：夺取港口，切断敌军补给。")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct CompactCityReadoutView: View {
    var city: City
    var brief: SelectedCityBrief

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                CityBadgeView(city: city, compact: true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(brief.title)
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text("\(brief.ownerLabel) · \(brief.positionLabel)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.64))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                CompactStat(label: "金", value: "+\(city.production.gold)")
                CompactStat(label: "粮", value: "+\(city.production.grain)")
                CompactStat(label: "防", value: "\(city.fortification)")
                CompactStat(label: "募", value: "\(brief.availableRecruitmentCount)")
            }

            Text(brief.deploymentSummary)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.66))
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            Text("扩建：\(brief.developmentGainLabel)")
                .font(.caption)
                .foregroundStyle(brief.canDevelop ? .white.opacity(0.68) : .orange.opacity(0.86))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .accessibilityLabel(brief.accessibilityLabel)
    }
}

struct CityReadoutView: View {
    var city: City
    var brief: SelectedCityBrief

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                CityBadgeView(city: city)
                VStack(alignment: .leading, spacing: 2) {
                    Text(brief.title)
                        .font(.headline.weight(.bold))
                    Text("\(brief.ownerLabel) · \(brief.positionLabel)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.68))
                }
                Spacer()
            }

            StatRow(label: "本城产出", value: brief.productionLabel)
            StatRow(label: "势力收入", value: brief.ownerIncomeLabel)
            StatRow(label: "罗马库存", value: brief.romanResourceLabel)
            StatRow(label: "城防", value: brief.fortificationLabel)
            StatRow(label: "部署", value: brief.deploymentSummary)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Image(systemName: "building.2.crop.circle.fill")
                        .foregroundStyle(Color(red: 0.86, green: 0.68, blue: 0.34))
                    Text("城市扩建")
                        .font(.caption.weight(.bold))
                    Spacer(minLength: 0)
                    Text(brief.canDevelop ? "可执行" : "受阻")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(brief.canDevelop ? .green : .orange)
                }
                Text("成本 \(brief.developmentCostLabel)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.64))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("收益 \(brief.developmentGainLabel) · \(brief.developmentStatusLabel)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.64))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }
            .padding(8)
            .background(.black.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 5) {
                Text("招募预览")
                    .font(.caption.weight(.bold))
                ForEach(brief.recruitmentOptions) { option in
                    HStack(spacing: 7) {
                        Image(systemName: option.kind.tokenSystemImage)
                            .foregroundStyle(option.canRecruit ? Color(red: 0.36, green: 0.86, blue: 0.92) : .white.opacity(0.45))
                            .frame(width: 16)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(option.kind.displayName) · \(option.costLabel)")
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text("\(option.statsLabel) · \(option.deploymentLabel)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.58))
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 5)
                    .background(option.canRecruit ? .white.opacity(0.06) : .black.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .accessibilityLabel(option.accessibilityLabel)
                }
            }
            .padding(8)
            .background(.black.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .accessibilityLabel(brief.accessibilityLabel)
    }
}

struct GeneralTraitCardView: View {
    var trait: GeneralTrait
    var preview: GeneralSkillPreview?
    var warMeritStatus: WarMeritStatus?
    var commanderBrief: SelectedCommanderBrief?
    var commanderActionGuidance: CommanderActionGuidance?
    var commanderChainReadout: SelectedCommanderChainReadout?
    var commanderOpportunityBridgeReadout: SelectedCommanderOpportunityBridgeReadout?
    var skillTargetReadout: SelectedGeneralSkillTargetReadout?

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

            if let commanderBrief, !commanderBrief.passiveContributions.isEmpty {
                GeneralPassiveContributionStrip(contributions: commanderBrief.passiveContributions, isCompact: false)
            }

            if let commanderChainReadout {
                CommanderChainReadoutView(readout: commanderChainReadout, isCompact: false)
            }

            if let commanderOpportunityBridgeReadout {
                CommanderOpportunityBridgeReadoutView(readout: commanderOpportunityBridgeReadout, isCompact: false)
            }

            Text(trait.skillDetail)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.56))
                .fixedSize(horizontal: false, vertical: true)

            if let commanderBrief {
                CommanderSkillStatusRow(
                    brief: commanderBrief,
                    guidance: commanderActionGuidance,
                    isCompact: false
                )
            }

            if let warMeritStatus {
                WarMeritProgressView(status: warMeritStatus)
            }

            if let preview {
                HStack(spacing: 7) {
                    SkillPreviewPill(symbol: "scope", text: "范围 \(preview.range)")
                    SkillPreviewPill(
                        symbol: preview.trait == .siegeEngineer ? "building.columns.fill" : "cross.case.fill",
                        text: commanderBrief?.skillEffectLabel ?? (
                            preview.trait == .siegeEngineer ?
                                "目标 \(preview.affectedCityIDs.count)" :
                                "友军 \(preview.affectedUnitIDs.count)"
                        )
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

            if let skillTargetReadout {
                GeneralSkillTargetReadoutView(readout: skillTargetReadout, isCompact: false)
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

struct NoGeneralCommandView: View {
    var brief: SelectedCommanderBrief

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .foregroundStyle(.white.opacity(0.58))
            VStack(alignment: .leading, spacing: 2) {
                Text("无将领")
                    .font(.caption.weight(.bold))
                Text("无被动贡献 · 可任命将领扩展战术能力")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityLabel(brief.accessibilityLabel)
    }
}

struct GeneralPassiveContributionStrip: View {
    var contributions: [GeneralPassiveContribution]
    var isCompact: Bool

    var body: some View {
        HStack(spacing: 6) {
            ForEach(contributions) { contribution in
                HStack(spacing: 4) {
                    Text(contribution.label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))
                    Text(contribution.value)
                        .font(.caption2.monospacedDigit().weight(.black))
                        .foregroundStyle(Color(red: 0.98, green: 0.82, blue: 0.36))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, 7)
                .frame(height: isCompact ? 22 : 24)
                .background(.black.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .accessibilityLabel("\(contribution.label)\(contribution.value)，\(contribution.detail)")
            }
            Spacer(minLength: 0)
        }
    }
}

struct CommanderChainReadoutView: View {
    var readout: SelectedCommanderChainReadout
    var isCompact: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "link.circle.fill")
                .foregroundStyle(Color(red: 0.86, green: 0.68, blue: 0.34))
                .frame(width: 14)
            Text("指挥链")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.58))
            if isCompact {
                Text(readout.compactLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.56)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(readout.summaryLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                        .minimumScaleFactor(0.60)
                    Text(readout.entryLabel)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color(red: 0.86, green: 0.68, blue: 0.34))
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)
                }
            }
            Spacer(minLength: 0)
            Text(readout.statusLabel)
                .font(.caption2.weight(.black))
                .foregroundStyle(.black.opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.58)
                .padding(.horizontal, 6)
                .frame(height: 20)
                .background(Color(red: 0.86, green: 0.68, blue: 0.34))
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, isCompact ? 3 : 5)
        .frame(maxWidth: .infinity, minHeight: isCompact ? 24 : 34, alignment: .leading)
        .background(.black.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityLabel(readout.accessibilityLabel)
    }
}

struct CommanderOpportunityBridgeReadoutView: View {
    var readout: SelectedCommanderOpportunityBridgeReadout
    var isCompact: Bool

    var body: some View {
        if isCompact {
            HStack(spacing: 6) {
                Image(systemName: "scope")
                    .foregroundStyle(Color(red: 0.36, green: 0.86, blue: 0.92))
                    .frame(width: 14)
                Text("战机")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                Text(readout.compactLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.54)
                Spacer(minLength: 0)
                Text(readout.entryLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(Color(red: 0.36, green: 0.86, blue: 0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.54)
            }
            .padding(.horizontal, 8)
            .frame(minHeight: 24)
            .background(.black.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .accessibilityLabel(readout.accessibilityLabel)
        } else {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Image(systemName: "scope")
                        .foregroundStyle(Color(red: 0.36, green: 0.86, blue: 0.92))
                    Text("战机桥接")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.white)
                    Spacer(minLength: 0)
                    Text(readout.statusLabel)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.black.opacity(0.78))
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)
                        .padding(.horizontal, 6)
                        .frame(height: 20)
                        .background(Color(red: 0.36, green: 0.86, blue: 0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                Text("\(readout.opportunityLabel) · \(readout.enemyThreatLabel)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
                Text("\(readout.entryLabel) · \(readout.nextStepLabel)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color(red: 0.86, green: 0.68, blue: 0.34))
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.black.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .accessibilityLabel(readout.accessibilityLabel)
        }
    }
}

struct CommanderSkillStatusRow: View {
    var brief: SelectedCommanderBrief
    var guidance: CommanderActionGuidance?
    var isCompact: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: brief.skillBlockedReason == nil && brief.skillStatusLabel == "可发动" ? "sparkles" : "exclamationmark.triangle.fill")
                .foregroundStyle(brief.skillBlockedReason == nil && brief.skillStatusLabel == "可发动" ? Color(red: 0.36, green: 0.86, blue: 0.92) : .orange)
            Text(brief.skillStatusLabel)
                .font(.caption2.weight(.black))
                .foregroundStyle(.white)
            if let guidance {
                Text(guidance.skillCueLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(guidance.isLinkedToBattleObjectiveStage ? Color(red: 0.86, green: 0.68, blue: 0.34) : .white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.60)
            } else if let effect = brief.skillEffectLabel {
                Text(effect)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(minHeight: isCompact ? 24 : 28)
        .background(.black.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityLabel(guidance?.accessibilityLabel ?? brief.accessibilityLabel)
    }
}

struct GeneralSkillTargetReadoutView: View {
    var readout: SelectedGeneralSkillTargetReadout
    var isCompact: Bool

    var body: some View {
        if isCompact {
            HStack(spacing: 6) {
                Image(systemName: "scope")
                    .foregroundStyle(Color(red: 0.72, green: 0.54, blue: 0.96))
                Text(readout.targetCountLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)
                Text(readout.effectLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color(red: 0.36, green: 0.86, blue: 0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                Spacer(minLength: 0)
                Text(readout.mapCueLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.56)
            }
            .padding(.horizontal, 8)
            .frame(minHeight: 24)
            .background(.black.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .accessibilityLabel(readout.accessibilityLabel)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    Image(systemName: "scope")
                        .foregroundStyle(Color(red: 0.72, green: 0.54, blue: 0.96))
                    Text(readout.title)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.white)
                    Spacer(minLength: 0)
                    Text(readout.statusLabel)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(readout.statusLabel == "可发动" ? Color(red: 0.36, green: 0.86, blue: 0.92) : .orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                }

                HStack(spacing: 6) {
                    Text(readout.targetCountLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                    Text(readout.effectLabel)
                        .font(.caption2.monospacedDigit().weight(.black))
                        .foregroundStyle(Color(red: 0.36, green: 0.86, blue: 0.92))
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                    Spacer(minLength: 0)
                    Text(readout.mapCueLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)
                }

                if !readout.targetLabels.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(readout.targetLabels.indices, id: \.self) { index in
                            Text(readout.targetLabels[index])
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.72))
                                .lineLimit(1)
                                .minimumScaleFactor(0.64)
                                .padding(.horizontal, 6)
                                .frame(height: 20)
                                .background(.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 6)
            .background(.black.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .accessibilityLabel(readout.accessibilityLabel)
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
            let countermeasurePreview = viewModel.selectedCountermeasureCommandPreview
            let battleObjectivePreview = viewModel.selectedBattleObjectiveStageCommandPreview

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
                    let preview = viewModel.selectedTacticalOrderPreview(for: order)
                    let isCountermeasureRecommendation = countermeasurePreview?.isRecommendedOrder(order) == true
                    let isBattleObjectiveRecommendation = !isCountermeasureRecommendation &&
                        battleObjectivePreview?.isRecommendedOrder(order) == true
                    Button {
                        viewModel.setSelectedTacticalOrder(order)
                    } label: {
                        TacticalOrderPreviewButtonContent(
                            order: order,
                            preview: preview,
                            isCompact: isCompact,
                            isCountermeasureRecommendation: isCountermeasureRecommendation,
                            isBattleObjectiveRecommendation: isBattleObjectiveRecommendation,
                            battleObjectiveCueLabel: isBattleObjectiveRecommendation ? battleObjectivePreview?.recommendedOrderStageCueLabel : nil
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!(preview?.canSwitch ?? viewModel.canSetSelectedTacticalOrder(order)))
                    .accessibilityLabel(isCountermeasureRecommendation ? "\(countermeasurePreview?.recommendedOrderCueLabel ?? "反制推荐姿态")，\(preview?.accessibilityLabel ?? order.detail)" : (isBattleObjectiveRecommendation ? "\(battleObjectivePreview?.recommendedOrderStageCueLabel ?? "目标线推荐姿态")，\(preview?.accessibilityLabel ?? order.detail)" : (preview?.accessibilityLabel ?? order.detail)))
                }
            }

            if !isCompact {
                if let currentPreview = viewModel.selectedTacticalOrderPreview(for: unit.resolvedTacticalOrder) {
                    Text("\(unit.resolvedTacticalOrder.detail) · 当前 \(currentPreview.detail)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                } else {
                    Text(unit.resolvedTacticalOrder.detail)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                }

                if let blockedReason = viewModel.selectedTacticalOrderPreviews.first(where: { !$0.isCurrent && !$0.canSwitch })?.blockedReason {
                    Text("切换限制：\(blockedReason)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange.opacity(0.86))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }
        }
        .padding(isCompact ? 0 : 8)
        .background(isCompact ? Color.clear : .black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

struct TacticalOrderPreviewButtonContent: View {
    var order: TacticalOrder
    var preview: SelectedTacticalOrderPreview?
    var isCompact: Bool
    var isCountermeasureRecommendation = false
    var isBattleObjectiveRecommendation = false
    var battleObjectiveCueLabel: String?

    var body: some View {
        VStack(spacing: isCompact ? 2 : 4) {
            HStack(spacing: 4) {
                Image(systemName: order.systemImage)
                    .font(.caption.weight(.heavy))
                Text(order.displayName)
                    .font(.caption2.weight(.black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            if let preview {
                Text("攻 \(preview.attack) 防 \(preview.defense) 移 \(preview.movement)")
                    .font(.caption2.monospacedDigit().weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.54)

                HStack(spacing: 3) {
                    TacticalDeltaText(prefix: "攻", value: preview.attackDelta)
                    TacticalDeltaText(prefix: "防", value: preview.defenseDelta)
                    TacticalDeltaText(prefix: "移", value: preview.movementDelta)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.52)

                Text(preview.isCurrent ? "当前" : (preview.blockedReason ?? "可切换"))
                    .font(.caption2.weight(.black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                if isCountermeasureRecommendation {
                    Text("反制")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(preview.isCurrent ? .black.opacity(0.76) : order.tintColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                } else if isBattleObjectiveRecommendation {
                    Text(battleObjectiveBadgeLabel)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(preview.isCurrent ? .black.opacity(0.76) : order.tintColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)
                }
            } else {
                Text(order.detail)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.54)
            }
        }
        .foregroundStyle(preview?.isCurrent == true ? .black.opacity(0.80) : .white)
        .frame(maxWidth: .infinity, minHeight: isCompact ? 54 : 66)
        .padding(.horizontal, 4)
        .background(preview?.isCurrent == true ? order.tintColor : .black.opacity(0.20))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(order.tintColor.opacity(recommendationStrokeOpacity(isCurrent: preview?.isCurrent == true)), lineWidth: recommendationStrokeWidth)
        }
        .opacity(preview?.canSwitch == false && preview?.isCurrent == false ? 0.76 : 1)
    }

    private var recommendationStrokeWidth: CGFloat {
        isCountermeasureRecommendation || isBattleObjectiveRecommendation ? 2 : 1
    }

    private var battleObjectiveBadgeLabel: String {
        battleObjectiveCueLabel?.split(separator: "·", maxSplits: 1).first.map(String.init) ?? "目标线"
    }

    private func recommendationStrokeOpacity(isCurrent: Bool) -> Double {
        if isCountermeasureRecommendation {
            return 0.90
        }

        if isBattleObjectiveRecommendation {
            return 0.74
        }

        return isCurrent ? 0 : 0.32
    }
}

struct TacticalDeltaText: View {
    var prefix: String
    var value: Int

    var body: some View {
        Text("\(prefix) \(formattedValue)")
            .font(.caption2.monospacedDigit().weight(.heavy))
            .foregroundStyle(color)
    }

    private var formattedValue: String {
        if value == 0 { return "±0" }
        return value > 0 ? "+\(value)" : "\(value)"
    }

    private var color: Color {
        if value > 0 { return Color(red: 0.58, green: 0.92, blue: 0.54) }
        if value < 0 { return Color(red: 1.0, green: 0.58, blue: 0.46) }
        return .white.opacity(0.62)
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
                        let countermeasurePreview = viewModel.selectedCountermeasureCommandPreview
                        let battleObjectivePreview = viewModel.selectedBattleObjectiveStageCommandPreview
                        let isCountermeasureTarget = countermeasurePreview?.isAttackTarget(target) == true
                        let isBattleObjectiveTarget = battleObjectivePreview?.isAttackTarget(target) == true
                        let attackActionLabel = isCountermeasureTarget ? "反制攻击" : (isBattleObjectiveTarget ? "目标线攻击" : "攻击")
                        let attackDetail = [
                            isCountermeasureTarget ? countermeasurePreview?.targetStageCueLabel : nil,
                            !isCountermeasureTarget && isBattleObjectiveTarget ? battleObjectivePreview?.attackStageCueLabel : nil,
                            preview?.commandModifierSummary
                        ].compactMap { $0 }.joined(separator: " · ")
                        let attackAccessibilityLead = isBattleObjectiveTarget ? battleObjectivePreview?.attackStageCueLabel : nil
                        Button {
                            viewModel.attack(target.id)
                        } label: {
                            CommandButtonLabel(
                                symbol: "bolt.fill",
                                text: preview.map { "\(attackActionLabel) \(target.faction.displayName)\(target.kind.displayName) · 伤害 \($0.damage)" } ?? "\(attackActionLabel) \(target.faction.displayName)\(target.kind.displayName)",
                                detail: attackDetail.isEmpty ? nil : attackDetail
                            )
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(viewModel.isCampaignOver)
                        .accessibilityLabel(isCountermeasureTarget ? "\(countermeasurePreview?.targetStageCueLabel ?? "3 目标，反制目标可攻击")，攻击\(target.faction.displayName)\(target.kind.displayName)" : "\(attackAccessibilityLead ?? "攻击")，攻击\(target.faction.displayName)\(target.kind.displayName)")
                    }
                }

                if let city = viewModel.commandCity,
                   let brief = viewModel.commandCityBrief,
                   city.owner == .rome {
                    Button {
                        viewModel.developCommandCity()
                    } label: {
                        CommandButtonLabel(
                            symbol: "building.2.crop.circle.fill",
                            text: "扩建 \(city.name)",
                            detail: brief.canDevelop ? "\(brief.developmentGainLabel) · 成本 \(brief.developmentCostLabel)" : brief.developmentStatusLabel
                        )
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(!brief.canDevelop || viewModel.isCampaignOver)

                    CityRecruitmentButtonsView(
                        options: brief.recruitmentOptions,
                        isCompact: false
                    )
                }

                if let unit = viewModel.selectedUnit, unit.faction == .rome {
                    if let preview = viewModel.selectedCountermeasureCommandPreview {
                        CountermeasureCommandPreviewView(preview: preview)
                    }

                    if let preview = viewModel.selectedBattleObjectiveStageCommandPreview {
                        BattleObjectiveStageCommandPreviewView(preview: preview)
                    }

                    TacticalOrderControlView(unit: unit)

                    if let trait = unit.resolvedGeneralTrait {
                        Button {
                            viewModel.useSelectedGeneralSkill()
                        } label: {
                            CommandButtonLabel(
                                symbol: trait.systemImage,
                                text: trait.skillName,
                                detail: viewModel.selectedGeneralSkillCommandButtonDetail
                            )
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(!viewModel.canUseSelectedGeneralSkill)
                    }

                    HStack(spacing: 8) {
                        Button {
                            viewModel.trainSelectedUnit()
                        } label: {
                            CommandButtonLabel(
                                symbol: "figure.walk",
                                text: "训练",
                                detail: viewModel.selectedTrainingButtonDetail
                            )
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(!viewModel.canTrainSelectedUnit)

                        Button {
                            viewModel.appointGeneralToSelectedUnit()
                        } label: {
                            CommandButtonLabel(
                                symbol: "person.crop.circle.badge.plus",
                                text: "任命",
                                detail: viewModel.selectedAppointmentButtonDetail
                            )
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(!viewModel.canAppointGeneralToSelectedUnit)
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

                if let advance = viewModel.primaryCampaignAdvanceReadout {
                    CampaignAdvanceReadoutView(readout: advance)
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

struct CampaignAdvanceReadoutView: View {
    var readout: CampaignAdvanceReadout

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "map.fill")
                    .foregroundStyle(Color(red: 0.84, green: 0.66, blue: 0.32))
                    .accessibilityHidden(true)
                Text(readout.title)
                    .font(.caption.weight(.heavy))
                Spacer(minLength: 0)
                Text(readout.statusLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.black.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                    .padding(.horizontal, 6)
                    .frame(height: 19)
                    .background(Color(red: 0.84, green: 0.66, blue: 0.32))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            Text(readout.compactLabel)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.76))
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 5) {
                    signalStrip(limit: 4)
                }

                HStack(spacing: 5) {
                    signalStrip(limit: 3)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                labelRow("目标", readout.missionObjectiveLabel)
                labelRow("路线", readout.objectiveLineLabel)
                labelRow("下一步", readout.nextStepLabel)
                labelRow("风险", readout.riskLabel)
            }
        }
        .padding(8)
        .background(Color(red: 0.12, green: 0.13, blue: 0.12).opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(red: 0.84, green: 0.66, blue: 0.32).opacity(0.24), lineWidth: 1)
        }
        .accessibilityLabel(readout.accessibilityLabel)
    }

    private func signalStrip(limit: Int) -> some View {
        ForEach(Array(readout.signals.prefix(limit))) { signal in
            ReadoutSignalPill(
                symbol: symbol(for: signal.kind),
                title: signal.title,
                tint: tint(for: signal.kind)
            )
        }
    }

    private func labelRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(label)
                .font(.caption2.weight(.heavy))
                .foregroundStyle(.white.opacity(0.46))
                .frame(width: 34, alignment: .leading)
            Text(value)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(2)
                .minimumScaleFactor(0.70)
            Spacer(minLength: 0)
        }
    }

    private func symbol(for kind: CampaignAdvanceSignalKind) -> String {
        switch kind {
        case .mission:
            return "building.columns.fill"
        case .progress:
            return "chart.bar.fill"
        case .frontline:
            return "shield.lefthalf.filled"
        case .objectiveChain:
            return "point.topleft.down.curvedto.point.bottomright.up.fill"
        case .objectiveStage:
            return "flag.checkered"
        case .recon:
            return "binoculars.fill"
        case .convergence:
            return "link.circle.fill"
        }
    }

    private func tint(for kind: CampaignAdvanceSignalKind) -> Color {
        switch kind {
        case .mission, .progress:
            return Color(red: 0.84, green: 0.66, blue: 0.32)
        case .frontline:
            return .red
        case .objectiveChain, .objectiveStage:
            return Color(red: 0.91, green: 0.74, blue: 0.38)
        case .recon:
            return .cyan
        case .convergence:
            return .mint
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

struct MapOverlayLegendView: View {
    var items: [MapOverlayLegendItem]
    var perspective: MapReconPerspectiveKind?
    var compact = false

    init(
        items: [MapOverlayLegendItem],
        perspective: MapReconPerspectiveKind? = nil,
        compact: Bool = false
    ) {
        self.items = items
        self.perspective = perspective
        self.compact = compact
    }

    var body: some View {
        Group {
            if compact {
                HStack(spacing: 5) {
                    ForEach(compactItems) { item in
                        MapOverlayLegendItemView(
                            item: item,
                            compact: true,
                            isFocused: isFocused(item.kind)
                        )
                    }

                    if hiddenCompactItemCount > 0 {
                        Text("+\(hiddenCompactItemCount)")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.68))
                            .frame(minWidth: 28, minHeight: 32)
                            .background(.white.opacity(0.06))
                            .clipShape(.rect(cornerRadius: 7))
                    }
                }
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(orderedItems) { item in
                            MapOverlayLegendItemView(
                                item: item,
                                compact: false,
                                isFocused: isFocused(item.kind)
                            )
                        }

                        if !items.isEmpty {
                            Divider()
                                .frame(height: 18)
                                .overlay {
                                    Color.white.opacity(0.18)
                                }
                        }

                        ForEach(Faction.turnOrder) { faction in
                            HStack(spacing: 5) {
                                Rectangle()
                                    .fill(faction.factionColor)
                                    .frame(width: 12, height: 12)
                                Text(faction.displayName)
                                    .font(.caption.bold())
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.74)
                            }
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }
                .scrollIndicators(.hidden)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: 520, minHeight: compact ? 36 : 52, alignment: .leading)
        .padding(.horizontal, compact ? 4 : 10)
        .padding(.vertical, compact ? 2 : 7)
        .background(.black.opacity(compact ? 0.18 : 0.35))
        .clipShape(.rect(cornerRadius: 8))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var compactItems: [MapOverlayLegendItem] {
        Array(orderedItems.prefix(3))
    }

    private var hiddenCompactItemCount: Int {
        max(0, orderedItems.count - compactItems.count)
    }

    private var orderedItems: [MapOverlayLegendItem] {
        guard let perspective else { return items }
        let presentation = MapOverlayPresentation(perspective: perspective)
        return items.enumerated()
            .sorted { lhs, rhs in
                let lhsPriority = presentation.legendPriority(lhs.element.kind)
                let rhsPriority = presentation.legendPriority(rhs.element.kind)
                return lhsPriority == rhsPriority ? lhs.offset < rhs.offset : lhsPriority < rhsPriority
            }
            .map(\.element)
    }

    private func isFocused(_ kind: MapOverlayLegendKind) -> Bool {
        guard let perspective else { return true }
        return MapOverlayPresentation(perspective: perspective).isFocusedLegend(kind)
    }

    private var accessibilityLabel: String {
        let overlayLabels = items.map(\.accessibilityLabel)
        let factionLabels = Faction.turnOrder.map { "\($0.displayName)阵营色" }
        return (overlayLabels + factionLabels).joined(separator: "，")
    }
}

struct MapOverlayLegendItemView: View {
    var item: MapOverlayLegendItem
    var compact = false
    var isFocused = true

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: item.symbol)
                .font(.caption.bold())
                .foregroundStyle(item.kind.legendTint)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.caption.bold())
                    .lineLimit(1)
                if !compact {
                    Text(item.detail)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }
        }
        .padding(.horizontal, compact ? 6 : 7)
        .frame(minHeight: compact ? 32 : 0)
        .padding(.vertical, compact ? 0 : 5)
        .background(item.kind.legendTint.opacity(isFocused ? 0.20 : 0.07))
        .clipShape(.rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(isFocused ? item.kind.legendTint.opacity(0.44) : .clear, lineWidth: 1)
        }
        .opacity(isFocused ? 1 : 0.52)
    }
}

struct BattleObjectiveTileOverlay: View {
    var overlays: [BattleObjectivePositionOverlay]
    var focusedRole: BattleObjectiveMapRole?
    var scale: CGFloat

    var body: some View {
        ZStack {
            Hexagon()
                .fill(Color(red: 0.86, green: 0.68, blue: 0.34).opacity(0.10))
            Hexagon()
                .stroke(
                    Color(red: 0.92, green: 0.70, blue: 0.28).opacity(0.76),
                    style: StrokeStyle(lineWidth: max(1.1, 1.5 * scale), lineCap: .round, dash: [4 * scale, 4 * scale])
                )
                .padding(7 * scale)

            ForEach(Array(overlays.prefix(4))) { overlay in
                BattleObjectiveStageBadge(
                    overlay: overlay,
                    index: overlay.role.stageNumber - 1,
                    count: 4,
                    isFocused: focusedRole == overlay.role,
                    scale: scale
                )
            }
        }
        .shadow(color: Color(red: 0.86, green: 0.68, blue: 0.34).opacity(0.24), radius: 4 * scale)
        .accessibilityLabel(overlays.map(\.accessibilityLabel).joined(separator: "，"))
    }
}

struct BattleObjectiveStageBadge: View {
    var overlay: BattleObjectivePositionOverlay
    var index: Int
    var count: Int
    var isFocused: Bool
    var scale: CGFloat

    var body: some View {
        ZStack {
            if isFocused {
                Circle()
                    .stroke(Color.white.opacity(0.92), lineWidth: max(1.2, 1.6 * scale))
                    .frame(width: 28 * scale, height: 28 * scale)
                    .shadow(color: overlay.role.tintColor.opacity(0.66), radius: 5 * scale)
            }
            Circle()
                .fill(overlay.role.tintColor.opacity(0.92))
            Image(systemName: overlay.role.symbol)
                .font(.system(size: 9 * scale, weight: .black))
                .foregroundStyle(.white)
                .offset(y: -2 * scale)
            Text("\(overlay.role.stageNumber)")
                .font(.system(size: max(7, 8 * scale), weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.78))
                .offset(y: 6 * scale)
        }
        .frame(width: 22 * scale, height: 22 * scale)
        .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
        .offset(offset)
        .accessibilityLabel(overlay.accessibilityLabel)
        .accessibilityAddTraits(isFocused ? .isSelected : AccessibilityTraits())
    }

    private var offset: CGSize {
        let spread = 14 * scale
        let x = (CGFloat(index) - CGFloat(count - 1) / 2) * spread
        return CGSize(width: x, height: -21 * scale)
    }
}

private extension BattleObjectiveMapRole {
    var tintColor: Color {
        switch self {
        case .focus:
            return Color(red: 0.96, green: 0.74, blue: 0.24)
        case .synergy:
            return Color(red: 0.90, green: 0.58, blue: 0.24)
        case .maneuver:
            return Color(red: 0.76, green: 0.72, blue: 0.28)
        case .recommendation:
            return Color(red: 0.98, green: 0.82, blue: 0.36)
        }
    }

    var symbol: String {
        switch self {
        case .focus:
            return "scope"
        case .synergy:
            return "person.crop.circle.badge.checkmark"
        case .maneuver:
            return "figure.run"
        case .recommendation:
            return "arrow.turn.up.right"
        }
    }
}

private extension MapOverlayLegendKind {
    var legendTint: Color {
        switch self {
        case .enemyRoute, .enemyTarget:
            return .red
        case .threatHeat:
            return .orange
        case .mapControl:
            return .cyan
        case .tacticalPath:
            return .blue
        case .maneuverOption:
            return .green
        case .battleObjective:
            return Color(red: 0.92, green: 0.70, blue: 0.28)
        case .countermeasure:
            return Color(red: 0.28, green: 0.78, blue: 0.76)
        case .reachable:
            return .yellow
        case .attackTarget:
            return .pink
        case .skillRange:
            return .purple
        }
    }
}
