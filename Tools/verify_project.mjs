import { existsSync, readFileSync } from "node:fs";

const requiredFiles = [
  "Package.swift",
  "Sources/RomeLegionsCore/GameState.swift",
  "Tests/RomeLegionsCoreTests/GameStateTests.swift",
  "RomeLegionsApp.xcodeproj/project.pbxproj",
  "RomeLegionsApp/App/RomeLegionsApp.swift",
  "RomeLegionsApp/App/GameViewModel.swift",
  "RomeLegionsApp/App/GameViewModelMapReadouts.swift",
  "RomeLegionsApp/App/GameViewModelStrategyReadouts.swift",
  "RomeLegionsApp/App/GameViewModelSelectionReadouts.swift",
  "RomeLegionsApp/Views/RootView.swift",
  "RomeLegionsApp/Views/MainMenuView.swift",
  "RomeLegionsApp/Views/BattleView.swift",
  "RomeLegionsApp/Views/BattleShellControls.swift",
  "RomeLegionsApp/Views/BattleMapView.swift",
  "RomeLegionsApp/Views/BattlePanels.swift",
  "RomeLegionsApp/Views/BattleViewStyles.swift",
  "Tools/RenderBattlePreview/main.swift",
  "RomeLegionsApp/Resources/Info.plist",
  "RomeLegionsApp/Assets.xcassets/Contents.json",
  "RomeLegionsApp/Assets.xcassets/AccentColor.colorset/Contents.json",
  "RomeLegionsApp/Assets.xcassets/AppIcon.appiconset/Contents.json",
  "RomeLegionsApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png",
  "README.md",
  "AGENTS.md",
  "update_log.md",
  "md/test/test.md",
  "md/flow/flow.md",
  "md/flow/flowchart.md",
  "md/prompt/README.md",
  ".github/workflows/ci-results.yml",
  "md/prompt/v0（协作系统）/v0.1（建立多Agent协作文档）.md",
  "md/prompt/v0（玩法推进）/v0.4（战役目标与胜负结算）.md",
  "md/prompt/v0（玩法推进）/v0.63（战斗目标锁定身份与取消入口）.md",
  "md/prompt/v0（玩法推进）/v0.64（敌将技能威胁地图焦点与空间叠层）.md",
  "md/prompt/v0（玩法推进）/v0.65（敌将威胁聚焦同源读板）.md",
  "md/prompt/v0（玩法推进）/v0.66（敌将焦点指挥卡与地图命令上下文）.md",
  "md/prompt/v0（玩法推进）/v0.67（反制决策确认闭环）.md"
  ,"md/prompt/v0（玩法推进）/v0.68（地图视觉层级与上下文命令坞）.md"
  ,"md/prompt/v0（玩法推进）/v0.69（AI将领机动施令与同源预演）.md"
  ,"md/prompt/v0（玩法推进）/v0.70（AI战术姿态同源预演与计划威胁桥接）.md"
];

const failures = [];

for (const path of requiredFiles) {
  if (!existsSync(path)) {
    failures.push(`Missing ${path}`);
  }
}

for (const path of requiredFiles.filter((file) => file.endsWith(".json"))) {
  try {
    JSON.parse(readFileSync(path, "utf8"));
  } catch (error) {
    failures.push(`Invalid JSON ${path}: ${error.message}`);
  }
}

if (failures.length > 0) {
  console.error(failures.join("\n"));
  process.exit(1);
}

const pbx = readFileSync("RomeLegionsApp.xcodeproj/project.pbxproj", "utf8");
for (const token of [
  "RomeLegionsApp.swift",
  "GameViewModel.swift",
  "GameViewModelMapReadouts.swift",
  "GameViewModelStrategyReadouts.swift",
  "GameViewModelSelectionReadouts.swift",
  "RootView.swift",
  "MainMenuView.swift",
  "BattleView.swift",
  "BattleShellControls.swift",
  "BattleMapView.swift",
  "BattlePanels.swift",
  "BattleViewStyles.swift",
  "Sources/RomeLegionsCore/GameState.swift",
  "Assets.xcassets"
]) {
  if (!pbx.includes(token)) {
    failures.push(`project.pbxproj does not reference ${token}`);
  }
}

const core = readFileSync("Sources/RomeLegionsCore/GameState.swift", "utf8");
for (const token of ["moveUnit", "attack", "attackPreview", "CombatPreview", "recruit", "research", "performSimpleAI", "skipUnit", "performAIRecruitment", "bestAITarget", "hasKillableTarget", "bestAIDestination", "favoring engagedTargetIDs", "AIGeneralSkillCandidate", "bestAIGeneralSkillCandidate", "aiGeneralSkillCandidate", "aiGeneralSkillProjection", "skillCandidate.destination", "projected.evaluateCampaignProgress()", "developCity", "trainUnit", "appointGeneral", "sendEnvoy", "CampaignStatus", "campaignStatus", "MissionRequirement", "campaignAlreadyEnded"]) {
  if (!core.includes(token)) {
    failures.push(`Core game state does not include ${token}`);
  }
}
for (const [label, pattern] of [
  ["capture-aware skill projection", /private func aiGeneralSkillProjection\([\s\S]*?aiActionProjection\(for: unit, destination: destination\)[\s\S]*?projection\.state\.generalSkillPreview\(for: projection\.unit\)/],
  ["capture-aware shared action projection", /private func aiActionProjection\([\s\S]*?projected\.captureCityIfPossible\([\s\S]*?projected\.evaluateCampaignProgress\(\)/],
  ["plan landing-preview reuse", /private func aiPlanStepReport\([\s\S]*?aiGeneralSkillProjection\(for: skillPlanningUnit, destination: destination\)\.preview/],
  ["threat landing-preview reuse", /private func enemyCommanderThreatReport\([\s\S]*?if intent\?\.kind == \.useSkill[\s\S]*?aiGeneralSkillProjection\(/],
  ["real move then skill re-preview", /performSimpleAI\(for faction:[\s\S]*?case \.moveSkill, \.movement:[\s\S]*?candidate\.intent\.destination[\s\S]*?moveUnit\(id: unitID, to: destination\)[\s\S]*?guard !campaignStatus\.isGameOver[\s\S]*?candidate\.tier == \.moveSkill[\s\S]*?generalSkillPreview\(for: movedUnit\)[\s\S]*?shouldAIUseGeneralSkill\(movedUnit, preview: preview\)[\s\S]*?useGeneralSkill\(unitID: unitID\)/]
]) {
  if (!pattern.test(core)) {
    failures.push(`Core game state does not include ${label}`);
  }
}

// Scope data-flow assertions to actual function bodies so an unrelated helper
// or a later declaration cannot satisfy a missing caller edge.
function coreFunction(name) {
  return core.match(new RegExp(`^    (?:public|private) (?:mutating )?func ${name}\\([\\s\\S]*?^    \\}`, "m"))?.[0] ?? "";
}
for (const [name, tokens] of [
  ["aiIntent", ["bestAITacticalAction(for: unit, favoring: [])?.intent"]],
  ["performSimpleAI", ["bestAITacticalAction(for: actingUnit, favoring: engagedTargetIDs)", "order: candidate.intent.tacticalOrder", "switch candidate.tier", "candidate.intent.targetUnitID", "engagedTargetIDs.insert(targetID)"]],
  ["bestAITacticalAction", [
    "unit.faction == activeFaction", "!unit.hasActed",
    "unit.hasMoved ? [unit.resolvedTacticalOrder] : TacticalOrder.allCases",
    "if shouldAIRest(unit)", "shouldAIUseGeneralSkill(unit, preview: preview)",
    "bestAITarget(for: $0, origin: unit.position, favoring: engagedTargetIDs, targets: directTargets)",
    "if reachableByBudget[budget] == nil", "reachableByBudget[budget] = reachablePositions(for: ordered)",
    "reachableByBudget: reachableByBudget, enemies: enemies", "objectives: objectives, enemies: enemies, favoring: engagedTargetIDs"
  ]],
  ["aiAttackEvaluations", ["aiCombatPreview(attacker: unit, defender: defender)", "defender: defender, preview: preview", "engagedTargetIDs: engagedTargetIDs"]],
  ["bestAITarget", ["hasKillableTarget", "!hasKillableTarget || $0.preview.defeatsDefender", "projectedDamage: attack.preview.damage", "combatPreview: attack.preview", "attack.preview.retaliation * aiRetaliationWeight(for: unit)"]],
  ["bestAIDestination", ["let candidates = reachable.map", "aiActionProjection(for: unit, destination: destination)", "projection.state.campaignStatus.isGameOver", "for: movedUnit, targets: targets, favoring: engagedTargetIDs", "attacks: attacks, objectives: objectives, enemies: enemies", "targets: targets, evaluations: attacks", "preferredAICandidate(candidates, currentOrder: unit.resolvedTacticalOrder)"]],
  ["bestAIGeneralSkillCandidate", ["unit.generalSkillCooldownRemaining == 0", "reachableByBudget.values.reduce", "aiGeneralSkillCandidate(for: unit, destination: $0, reachable: reachable)", "legalDestinations.contains(skillCandidate.destination)", "skillPreview: skillCandidate.preview"]],
  ["aiPlanningUnit", ["hasMoved: hasMoved ?? unit.hasMoved", "hasActed: hasActed ?? unit.hasActed"]],
  ["aiActionProjection", ["hasMoved: isMovement || unit.hasMoved", "projected.captureCityIfPossible", "projected.evaluateCampaignProgress()"]],
  ["aiPlanStepDetail", ["aiTacticalActionExplanation(for: intent, unit: unit, skillPreview: skillPreview)"]],
  ["enemyCommanderThreatReport", ["aiTacticalActionExplanation(for: $0, unit: unit, skillPreview: skillPreview)", "reasons.append(tacticalExplanation)", "待命技能："]],
  ["aiTacticalActionExplanation", ["aiPlanningUnit(from: unit, order: intent.tacticalOrder)", "let targetID = intent.targetUnitID", "aiActionProjection(for: planningUnit, destination: destination)", "projection.state.attackPreview(attackerID: unit.id, defenderID: targetID)", "preview.defeatsDefender", "!preview.attackerFalls", "preview.retaliation", "skillPreview?.summary"]]
]) {
  const body = coreFunction(name);
  for (const token of tokens) {
    if (!body.includes(token)) failures.push(`Core ${name} data flow does not include ${token}`);
  }
}
for (const name of ["bestAIDestination", "bestAIGeneralSkillCandidate", "aiPositionScore", "aiTacticalActionPrecedes", "aiAttackScore"]) {
  const body = coreFunction(name);
  if (/reachablePositions\(|aiIntents\(|aiOperationalPlanReports\(/.test(body) ||
      (["aiPositionScore", "aiTacticalActionPrecedes", "aiAttackScore"].includes(name) && /aiCombatPreview\(|attackPreview\(/.test(body))) {
    failures.push(`Core ${name} must reuse local reachability/previews without reentering search or reports`);
  }
}
if (core.includes("preferredAITacticalOrder") || /hasActed:\s*false/.test(coreFunction("aiActionProjection"))) {
  failures.push("Core must not retain the old posture selector or revive spent actions in projection");
}
const tacticalRanking = coreFunction("aiTacticalActionPrecedes");
if (!/left\.tier\.rawValue < right\.tier\.rawValue[\s\S]*?if leftKills != rightKills[\s\S]*?if leftFalls != rightFalls[\s\S]*?if left\.score != right\.score/.test(tacticalRanking)) {
  failures.push("Tactical ranking must compare hard tier, kill, survival, then score in that order");
}
if (!/private enum AITacticalActionTier: Int\s*\{\s*case rest, originalSkill, directAttack, moveSkill, movement, hold\s*\}/.test(core) ||
    !/private struct AITacticalActionCandidate\s*\{[\s\S]*?var combatPreview: CombatPreview\?[\s\S]*?var skillPreview: GeneralSkillPreview\?/.test(core)) {
  failures.push("Core must preserve the private tactical candidate previews and hard action-tier order");
}
for (const name of ["aiPlanStepReport", "aiPlanStepDetail", "enemyCommanderThreatReport", "aiTacticalActionExplanation"]) {
  if (/bestAITacticalAction\(|bestAITarget\(|aiIntents\(|aiIntentReports\(|aiOperationalPlanReports\(|enemyCommanderThreatReports\(/.test(coreFunction(name))) {
    failures.push(`Core ${name} must explain the selected intent without reentering decision/report selection`);
  }
}

const viewModel = [
  "RomeLegionsApp/App/GameViewModelMapReadouts.swift",
  "RomeLegionsApp/App/GameViewModelStrategyReadouts.swift",
  "RomeLegionsApp/App/GameViewModelSelectionReadouts.swift",
  "RomeLegionsApp/App/GameViewModel.swift"
].map((path) => readFileSync(path, "utf8")).join("\n");
for (const token of ["selectedPosition", "selectedTile", "selectedAttackTargetID", "selectedCombatForecast", "attackerIdentityLabel", "defenderIdentityLabel", "identityChainLabel", "func attackPreview", "focusAttackTarget", "cancelSelectedAttackTarget", "confirmSelectedAttack", "primaryMission", "skipSelectedUnit", "--attack-demo", "restSelectedUnit", "isCampaignOver", "campaignStatusTitle", "EnemyCommanderThreatMapOverlay", "primaryEnemyCommanderThreatMapOverlay", "activeEnemyCommanderThreatSummary", "activeEnemyCommanderThreatID", "activeEnemyCommanderThreatMapOverlay", "activeEnemyCommanderThreatFocusReadout", "EnemyCommanderThreatFocusReadout", "hasExecutableCommand", "commandAvailabilityLabel", "mapHeadlineLabel", "mapSpatialLabel", "mapStatusLabel", "isPrimaryFallback", "enemyCommanderThreatOverlaysByPosition", "enemyCommanderThreatOverlayPositions", "focusedEnemyCommanderThreatID", "focusEnemyCommanderThreat", "enemyCommanderThreatID", "MapOverlayLegendKind.enemyCommanderThreat", "CountermeasureCommandContextReadout", "activeCountermeasureCommandPreview", "activeCountermeasureMapOverlay", "activeCountermeasureCommandContextReadout", "confirmCountermeasureOrder", "confirmCountermeasureMovement", "lockCountermeasureTarget", "BattleDisplayContextMode", "BattleDisplayContextReadout", "battleDisplayContextReadout", "automationIdentifier", "primaryLegendKinds", "secondaryLegendKinds"]) {
  if (!viewModel.includes(token)) {
    failures.push(`Game view model does not include ${token}`);
  }
}

const battle = [
  "RomeLegionsApp/Views/BattleView.swift",
  "RomeLegionsApp/Views/BattleShellControls.swift",
  "RomeLegionsApp/Views/BattleMapView.swift",
  "RomeLegionsApp/Views/BattlePanels.swift",
  "RomeLegionsApp/Views/BattleViewStyles.swift"
].map((path) => readFileSync(path, "utf8")).join("\n");
for (const token of ["CompactCommandPanelView", "PhoneCommandDeckView", "TacticalStatusStripView", "BattlefieldFocusPanelView", "CityBadgeView", "TerrainGlyphView", "AttackTargetButton", "AttackTargetRing", "AttackTargetMenuButton", "AttackTargetSelectionMenuView", "AttackLockMapReadoutView", "EnemyCommanderThreatFocusIdentityView", "EnemyCommanderThreatFocusCommandStatusView", "EnemyCommanderThreatFocusMapReadoutView", "EnemyCommanderThreatCardView", "CombatForecastReadoutView", "cancelSelectedAttackTarget", "MapViewportState", "MagnificationGesture", "MapCameraControlsView", "focusViewport", "arrow.counterclockwise", "forward.end.fill", "CoastlineLayerView", "CoastlineBuilder", "isZoneCenter", "drawerUsesScrollView", "drawerContentStack", "layoutSize: CGSize", "CountermeasureCommandContextIdentityView", "CountermeasureCommandContextButtonsView", "CountermeasureCommandContextMapReadoutView", "CountermeasureContextConfirmationButtonsView", "BattleDisplayContextReadout", "displayContext", "isAttackOrigin: isMapAttackOrigin", "isPortrait"]) {
  if (!battle.includes(token)) {
    failures.push(`Battle view does not include ${token}`);
  }
}

const renderPreview = readFileSync("Tools/RenderBattlePreview/main.swift", "utf8");
for (const token of ["commandDockSecondaryTarget", "selectedAttackTargetID", "selectedCombatForecast", "attackerIdentityLabel", "identityChainLabel", "cancelSelectedAttackTarget", "stateArchiveBeforeAttackForecast", "stateArchiveAfterCancel", "stateArchiveAfterRepeatedCancel", "aiIntentSnapshotBeforeAttackForecast", "missingAttackForecast", "stateBeforeAttackForecast", "EnemyCommanderThreatMapOverlay", "EnemyCommanderThreatFocusReadout", "activeEnemyCommanderThreatFocusReadout", "hasExecutableCommand", "commandAvailabilityLabel", "mapHeadlineLabel", "mapSpatialLabel", "mapStatusLabel", "compactStatusColumns", "primaryEnemyCommanderThreatMapOverlay", "activeEnemyCommanderThreatSummary", "activeEnemyCommanderThreatID", "activeEnemyCommanderThreatMapOverlay", "enemyCommanderThreatOverlaysByPosition", "enemyCommanderThreatOverlayPositions", "focusedEnemyCommanderThreatID", "focusEnemyCommanderThreat", "missingEnemyCommanderThreatMapOverlay", "missingActiveEnemyCommanderThreatPrimary", "missingActiveEnemyCommanderThreatSecondary", "missingActiveEnemyCommanderThreatSummary", "missingActiveEnemyCommanderThreatOverlay", "missingActiveEnemyCommanderThreatSource", "missingActiveEnemyCommanderThreatReadout", "missingEnemyCommanderThreatFocusReadout", "missingEnemyCommanderThreatCommandCleanup", "missingFocusedEnemyCommanderThreatRender", "missingFocusedEnemyCommanderThreatCardRender", "focusedOutputPath", "focusedEnemyDrawerOutputPath", "hasVisibleFocusedEnemyCommanderThreatPreview", "hasVisibleFocusedEnemyCommanderThreatCard", "initialDrawer: .enemy", "enemyCommanderThreatID", "MapOverlayLegendKind.enemyCommanderThreat", "missingAIMoveSkillPreviewChain", "moveSkillIntent", "moveSkillIntent.tacticalOrder == .forcedMarch", "moveSkillPreview", "moveSkillOverlay", "moveSkillResolution", "campaignEndSkillOverlay", "campaignEndSkillProjection", "missingCountermeasureCommandContext", "missingCountermeasureCommandSource", "missingCountermeasureCommandConfirmation", "assertCountermeasureSingleStepCommands", "CountermeasureCommandRuntimeSnapshot", "confirmCountermeasureOrder()", "confirmCountermeasureMovement()", "lockCountermeasureTarget()", "missingCountermeasureOrderRuntimeConfirmation", "missingCountermeasureMovementRuntimeConfirmation", "missingCountermeasureTargetRuntimeConfirmation", "missingCountermeasureCommandCleanup", "missingCountermeasureCommandRender", "focusedCountermeasureOutputPath", "focused-countermeasure", "BattleDisplayContextReadout", "isMapAttackOrigin", "selectedAttackSourceIDBeforeForecast", "attackOriginIDsBeforeForecast", "attackOriginIDsAfterForecast", "missingBattleDisplayContext", "missingMapOverlayHierarchy", "visibleRawSourceIdentifier", "missingContextualCommandDock", "missingMapVisualPriority"]) {
  if (!renderPreview.includes(token)) {
    failures.push(`RenderBattlePreview does not include ${token}`);
  }
}

const gameplaySmoke = readFileSync("Tools/GameplaySmoke/main.swift", "utf8");
if (!/try verifyAITacticalActionPreviewChain\(\)[\s\S]*?let viewModel = GameViewModel\(\)/.test(renderPreview)) {
  failures.push("RenderBattlePreview must run isolated tactical data checks before creating screenshot state");
}
const tacticalRender = renderPreview.match(/^    private static func verifyAITacticalActionPreviewChain\([\s\S]*?^    \}/m)?.[0] ?? "";
for (const token of [
  "[TacticalOrder.assault, .defensive, .forcedMarch]",
  "missingAITacticalActionPreviewChain",
  "intent.projectedDamage == preview.damage",
  "step.projectedDamage == preview.damage",
  "threat.projectedDamage == preview.damage",
  "intentOverlay.summary.intent == intent",
  "threatOverlay.summary.report == threat",
  'step.detail.contains("击杀")',
  'step.detail.contains("反击")',
  "step.detail.contains(destination.description)",
  "movementSegments.count == 5",
  "movementSegments.first?.from == source.position",
  "movementSegments.last?.to == destination",
  "$0.from.hexDistance(to: $0.to) == 1",
  "zip(movementSegments, movementSegments.dropFirst()).allSatisfy({ $0.0.to == $0.1.from })",
  "threatOverlay.routeSegments.contains(where: { !$0.isTargetLeg && $0.from == source.position && $0.to == destination })",
  "model.state == before",
  "try encoder.encode(model.state) == archiveBefore"
]) {
  if (!tacticalRender.includes(token)) {
    failures.push(`RenderBattlePreview tactical intent/plan/threat/map chain does not include ${token}`);
  }
}
for (const token of ["moveSkillIntent", "moveSkillPreview", "moveSkillPlan", "moveSkillThreat", "killPriorityIntent", "campaignEndMoveSkillState"]) {
  if (!gameplaySmoke.includes(token)) {
    failures.push(`Gameplay smoke does not include ${token}`);
  }
}
for (const order of ["assault", "defensive", "forcedMarch"]) {
  if (!gameplaySmoke.includes(`try verifyAITacticalActionSmoke(order: .${order})`)) {
    failures.push(`Gameplay smoke must invoke the isolated ${order} tactical action fixture`);
  }
}
const tacticalSmoke = gameplaySmoke.match(/^func verifyAITacticalActionSmoke\([\s\S]*?^\}/m)?.[0] ?? "";
for (const token of [
  "previews[.assault]?.defeatsDefender == true",
  "previews.values.allSatisfy { !$0.defeatsDefender }",
  "previews[.assault]?.attackerFalls == true",
  "previews[.defensive]?.attackerFalls == false",
  "!alternativeState.reachablePositions(for: commanderID).contains(destination)",
  "intent.projectedDamage == preview.damage",
  "step?.projectedDamage == preview.damage && threat?.projectedDamage == preview.damage",
  "state.enemyCommanderThreatReports(against: .rome, limit: 5) == threats && state == before",
  "resolution.performSimpleAI(for: .carthage)",
  "resolution.unit(withID: commanderID)?.health == preview.attackerRemainingHealth",
  "resolution.unit(withID: targetID)?.health == preview.defenderRemainingHealth"
]) {
  if (!tacticalSmoke.includes(token)) {
    failures.push(`Gameplay smoke tactical action chain does not include ${token}`);
  }
}

const coreTests = readFileSync("Tests/RomeLegionsCoreTests/GameStateTests.swift", "utf8");
const requiredTacticalTests = [
  "aiTacticalAssaultJointKillMatchesPreviewAndResolution",
  "aiTacticalDefensiveSurvivalMatchesReportsAndResolution",
  "aiTacticalForcedMarchUsesOnlyLegalLanding",
  "aiTacticalDirectKillKeepsMovementSkillBelowAttackTier",
  "aiTacticalRestKeepsPriorityOverSkillAndAttack",
  "aiTacticalMovedUnitCannotAdoptBetterIllegalOrder",
  "aiTacticalActedUnitNeverRefreshesDuringExecution",
  "aiTacticalReportsRemainStableAcrossTiesAndStorageOrder",
  "aiTacticalMovementKillOutranksEngagedNonLethalTarget",
  "aiTacticalTerminalAndWrongFactionStayInert"
];
for (const name of requiredTacticalTests) {
  // Require an independent test declaration and expectations, not a helper,
  // comment, or disabled test annotation containing the same name.
  const testBody = coreTests.match(new RegExp(`^@Test func ${name}\\(\\)(?: throws)? \\{[\\s\\S]*?^\\}`, "m"))?.[0] ?? "";
  if (!testBody.includes("#expect(")) {
    failures.push(`Core tests must declare and assert the independent v0.70 test ${name}`);
  }
}
for (const token of ["aiMoveThenGeneralSkillIntentMatchesPostMovePreviewAndResolution", "aiMoveThenGeneralSkillFeedsPlanAndThreatFromSamePreview", "aiImmediateKillOutranksProfitableMoveSkill", "aiReadyOriginalSkillKeepsExistingPriority", "aiMoveSkillRespectsCooldownAndNoDestinationFallback", "aiMoveSkillProjectionStopsAtCampaignEndingCapture"]) {
  if (!coreTests.includes(token)) {
    failures.push(`Core tests do not include ${token}`);
  }
}

const agentGuide = readFileSync("AGENTS.md", "utf8");
for (const token of ["Agent A", "Agent B", "Agent C", "核心架构边界", "测试规则", "禁止项", "git push origin main", "GitHub Actions"]) {
  if (!agentGuide.includes(token)) {
    failures.push(`AGENTS.md does not include ${token}`);
  }
}

const testGuide = readFileSync("md/test/test.md", "utf8");
for (const token of ["Probe / Fast", "Smoke", "Stage Regression", "Full", "node Tools/verify_project.mjs", "swift test", "GitHub Actions", "ci-artifact-manifest.json"]) {
  if (!testGuide.includes(token)) {
    failures.push(`md/test/test.md does not include ${token}`);
  }
}

const flowGuide = readFileSync("md/flow/flow.md", "utf8");
for (const token of ["当前核心数据流", "当前核心执行流", "云端协作执行流", "核心状态对象", "关键边界", "不允许破坏的行为"]) {
  if (!flowGuide.includes(token)) {
    failures.push(`md/flow/flow.md does not include ${token}`);
  }
}

const flowchartGuide = readFileSync("md/flow/flowchart.md", "utf8");
for (const token of ["```mermaid", "核心数据流", "回合执行流", "多 Agent 云端迭代流", "测试选择流", "GitHub Actions"]) {
  if (!flowchartGuide.includes(token)) {
    failures.push(`md/flow/flowchart.md does not include ${token}`);
  }
}

const promptReadme = readFileSync("md/prompt/README.md", "utf8");
for (const token of ["角色召唤", "Agent A 提示词必含内容", "CI / main push", "gh auth login"]) {
  if (!promptReadme.includes(token)) {
    failures.push(`md/prompt/README.md does not include ${token}`);
  }
}

const ciWorkflow = readFileSync(".github/workflows/ci-results.yml", "utf8");
for (const token of ["RomeLegions CI Results", "branches:", "main", "ci-artifact-manifest.json", "actions/upload-artifact", "xcodebuild"]) {
  if (!ciWorkflow.includes(token)) {
    failures.push(`.github/workflows/ci-results.yml does not include ${token}`);
  }
}
if (!ciWorkflow.includes("CI_VERSION: v0.70")) {
  failures.push(".github/workflows/ci-results.yml does not include CI_VERSION v0.70");
}
if (!/^\s+timeout-minutes: 75\s*$/m.test(ciWorkflow)) {
  failures.push(".github/workflows/ci-results.yml must preserve the 75-minute job budget");
}
const requiredCIChecks = [
  '["static-checks", outcomes.staticChecksOutcome, "ci-results/static-checks.log"]',
  '["swift-tests", outcomes.swiftTestsOutcome, "ci-results/swift-test.log"]',
  '["gameplay-smoke", outcomes.gameplaySmokeOutcome, "ci-results/gameplay-smoke.log"]',
  '["render-battle-preview", outcomes.renderPreviewOutcome, "ci-results/render-battle-preview.log"]',
  '["xcode-build", outcomes.buildOutcome, "ci-results/xcodebuild.log"]'
];
const declaredCIChecks = ciWorkflow.match(/const checks = \[([\s\S]*?)\n\s*\];/)?.[1]
  .split("\n").map((line) => line.trim().replace(/,$/, "")).filter(Boolean) ?? [];
if (JSON.stringify(declaredCIChecks) !== JSON.stringify(requiredCIChecks)) {
  failures.push("CI JUnit metadata must preserve exactly the five configured checks and their outcome/log mappings");
}
for (const [stepID, outcomeVariable] of [
  ["static_checks", "STATIC_OUTCOME"],
  ["swift_tests", "SWIFT_TESTS_OUTCOME"],
  ["gameplay_smoke", "GAMEPLAY_SMOKE_OUTCOME"],
  ["render_preview", "RENDER_PREVIEW_OUTCOME"],
  ["xcode_build", "XCODE_BUILD_OUTCOME"]
]) {
  if (!ciWorkflow.includes(`id: ${stepID}`) ||
      !ciWorkflow.includes(`${outcomeVariable}: \${{ steps.${stepID}.outcome }}`) ||
      !ciWorkflow.includes(`[ "$${outcomeVariable}" != "success" ]`)) {
    failures.push(`CI must run ${stepID}, propagate its actual outcome and fail on non-success`);
  }
}
const requiredRenderPreviewPaths = [
  "ci-results/render-previews/battle-landscape-preview.png",
  "ci-results/render-previews/battle-landscape-preview-unit.png",
  "ci-results/render-previews/battle-landscape-preview-focused.png",
  "ci-results/render-previews/battle-landscape-preview-focused-enemy.png",
  "ci-results/render-previews/battle-landscape-preview-focused-countermeasure.png",
  "ci-results/render-previews/battle-portrait-preview.png",
  "ci-results/render-previews/battle-portrait-preview-unit.png",
  "ci-results/render-previews/battle-portrait-preview-focused.png",
  "ci-results/render-previews/battle-portrait-preview-focused-enemy.png",
  "ci-results/render-previews/battle-portrait-preview-focused-countermeasure.png",
  "ci-results/render-previews/battle-wide-preview.png",
  "ci-results/render-previews/battle-wide-preview-unit.png",
  "ci-results/render-previews/battle-wide-preview-focused.png",
  "ci-results/render-previews/battle-wide-preview-focused-enemy.png",
  "ci-results/render-previews/battle-wide-preview-focused-countermeasure.png"
];
const declaredRenderPreviewPaths = [...ciWorkflow.matchAll(
  /^\s+"(ci-results\/render-previews\/battle-[^"]+\.png)"[,]?$/gm
)].map((match) => match[1]);
if (JSON.stringify(declaredRenderPreviewPaths) !== JSON.stringify(requiredRenderPreviewPaths)) {
  failures.push(".github/workflows/ci-results.yml must preserve exactly the 15 render preview paths in v0.70");
}

if (failures.length > 0) {
  console.error(failures.join("\n"));
  process.exit(1);
}

console.log("Project structure verification passed.");
