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
  "md/prompt/v0（玩法推进）/v0.66（敌将焦点指挥卡与地图命令上下文）.md"
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
for (const token of ["moveUnit", "attack", "attackPreview", "CombatPreview", "recruit", "research", "performSimpleAI", "skipUnit", "performAIRecruitment", "bestAITarget", "hasKillableTarget", "bestAIDestination", "favoring engagedTargetIDs", "developCity", "trainUnit", "appointGeneral", "sendEnvoy", "CampaignStatus", "campaignStatus", "MissionRequirement", "campaignAlreadyEnded"]) {
  if (!core.includes(token)) {
    failures.push(`Core game state does not include ${token}`);
  }
}

const viewModel = [
  "RomeLegionsApp/App/GameViewModelMapReadouts.swift",
  "RomeLegionsApp/App/GameViewModelStrategyReadouts.swift",
  "RomeLegionsApp/App/GameViewModelSelectionReadouts.swift",
  "RomeLegionsApp/App/GameViewModel.swift"
].map((path) => readFileSync(path, "utf8")).join("\n");
for (const token of ["selectedPosition", "selectedTile", "selectedAttackTargetID", "selectedCombatForecast", "attackerIdentityLabel", "defenderIdentityLabel", "identityChainLabel", "func attackPreview", "focusAttackTarget", "cancelSelectedAttackTarget", "confirmSelectedAttack", "primaryMission", "skipSelectedUnit", "--attack-demo", "restSelectedUnit", "isCampaignOver", "campaignStatusTitle", "EnemyCommanderThreatMapOverlay", "primaryEnemyCommanderThreatMapOverlay", "activeEnemyCommanderThreatSummary", "activeEnemyCommanderThreatID", "activeEnemyCommanderThreatMapOverlay", "activeEnemyCommanderThreatFocusReadout", "EnemyCommanderThreatFocusReadout", "hasExecutableCommand", "commandAvailabilityLabel", "isPrimaryFallback", "enemyCommanderThreatOverlaysByPosition", "enemyCommanderThreatOverlayPositions", "focusedEnemyCommanderThreatID", "focusEnemyCommanderThreat", "enemyCommanderThreatID", "MapOverlayLegendKind.enemyCommanderThreat"]) {
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
for (const token of ["CompactCommandPanelView", "PhoneCommandDeckView", "TacticalStatusStripView", "BattlefieldFocusPanelView", "CityBadgeView", "TerrainGlyphView", "AttackTargetButton", "AttackTargetRing", "AttackTargetMenuButton", "AttackTargetSelectionMenuView", "AttackLockMapReadoutView", "EnemyCommanderThreatFocusIdentityView", "EnemyCommanderThreatFocusCommandStatusView", "EnemyCommanderThreatFocusMapReadoutView", "EnemyCommanderThreatCardView", "CombatForecastReadoutView", "cancelSelectedAttackTarget", "MapViewportState", "MagnificationGesture", "MapCameraControlsView", "focusViewport", "arrow.counterclockwise", "forward.end.fill", "CoastlineLayerView", "CoastlineBuilder", "isZoneCenter", "init(initialDrawer: BattleDrawerCategory? = nil)"]) {
  if (!battle.includes(token)) {
    failures.push(`Battle view does not include ${token}`);
  }
}

const renderPreview = readFileSync("Tools/RenderBattlePreview/main.swift", "utf8");
for (const token of ["commandDockSecondaryTarget", "selectedAttackTargetID", "selectedCombatForecast", "attackerIdentityLabel", "identityChainLabel", "cancelSelectedAttackTarget", "stateArchiveBeforeAttackForecast", "stateArchiveAfterCancel", "stateArchiveAfterRepeatedCancel", "aiIntentSnapshotBeforeAttackForecast", "missingAttackForecast", "stateBeforeAttackForecast", "EnemyCommanderThreatMapOverlay", "EnemyCommanderThreatFocusReadout", "activeEnemyCommanderThreatFocusReadout", "hasExecutableCommand", "commandAvailabilityLabel", "primaryEnemyCommanderThreatMapOverlay", "activeEnemyCommanderThreatSummary", "activeEnemyCommanderThreatID", "activeEnemyCommanderThreatMapOverlay", "enemyCommanderThreatOverlaysByPosition", "enemyCommanderThreatOverlayPositions", "focusedEnemyCommanderThreatID", "focusEnemyCommanderThreat", "missingEnemyCommanderThreatMapOverlay", "missingActiveEnemyCommanderThreatPrimary", "missingActiveEnemyCommanderThreatSecondary", "missingActiveEnemyCommanderThreatSummary", "missingActiveEnemyCommanderThreatOverlay", "missingActiveEnemyCommanderThreatSource", "missingActiveEnemyCommanderThreatReadout", "missingEnemyCommanderThreatFocusReadout", "missingEnemyCommanderThreatCommandCleanup", "missingFocusedEnemyCommanderThreatRender", "missingFocusedEnemyCommanderThreatCardRender", "focusedOutputPath", "focusedEnemyDrawerOutputPath", "hasVisibleFocusedEnemyCommanderThreatPreview", "hasVisibleFocusedEnemyCommanderThreatCard", "initialDrawer: .enemy", "enemyCommanderThreatID", "MapOverlayLegendKind.enemyCommanderThreat"]) {
  if (!renderPreview.includes(token)) {
    failures.push(`RenderBattlePreview does not include ${token}`);
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
if (!ciWorkflow.includes("CI_VERSION: v0.66")) {
  failures.push(".github/workflows/ci-results.yml does not include CI_VERSION v0.66");
}

if (failures.length > 0) {
  console.error(failures.join("\n"));
  process.exit(1);
}

console.log("Project structure verification passed.");
