import { existsSync, readFileSync } from "node:fs";

const requiredFiles = [
  "Package.swift",
  "Sources/RomeLegionsCore/GameState.swift",
  "Tests/RomeLegionsCoreTests/GameStateTests.swift",
  "RomeLegionsApp.xcodeproj/project.pbxproj",
  "RomeLegionsApp/App/RomeLegionsApp.swift",
  "RomeLegionsApp/App/GameViewModel.swift",
  "RomeLegionsApp/Views/RootView.swift",
  "RomeLegionsApp/Views/MainMenuView.swift",
  "RomeLegionsApp/Views/BattleView.swift",
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
  "md/prompt/v0（玩法推进）/v0.4（战役目标与胜负结算）.md"
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
  "RootView.swift",
  "MainMenuView.swift",
  "BattleView.swift",
  "Sources/RomeLegionsCore/GameState.swift",
  "Assets.xcassets"
]) {
  if (!pbx.includes(token)) {
    failures.push(`project.pbxproj does not reference ${token}`);
  }
}

const core = readFileSync("Sources/RomeLegionsCore/GameState.swift", "utf8");
for (const token of ["moveUnit", "attack", "attackPreview", "CombatPreview", "recruit", "research", "performSimpleAI", "skipUnit", "performAIRecruitment", "bestAITarget", "developCity", "trainUnit", "appointGeneral", "sendEnvoy", "CampaignStatus", "campaignStatus", "MissionRequirement", "campaignAlreadyEnded"]) {
  if (!core.includes(token)) {
    failures.push(`Core game state does not include ${token}`);
  }
}

const viewModel = readFileSync("RomeLegionsApp/App/GameViewModel.swift", "utf8");
for (const token of ["selectedPosition", "selectedTile", "func attackPreview", "primaryMission", "skipSelectedUnit", "--attack-demo", "restSelectedUnit", "isCampaignOver", "campaignStatusTitle"]) {
  if (!viewModel.includes(token)) {
    failures.push(`Game view model does not include ${token}`);
  }
}

const battle = readFileSync("RomeLegionsApp/Views/BattleView.swift", "utf8");
for (const token of ["CompactCommandPanelView", "PhoneCommandDeckView", "TacticalStatusStripView", "BattlefieldFocusPanelView", "CityBadgeView", "TerrainGlyphView", "AttackTargetButton", "AttackTargetRing", "forward.end.fill"]) {
  if (!battle.includes(token)) {
    failures.push(`Battle view does not include ${token}`);
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

if (failures.length > 0) {
  console.error(failures.join("\n"));
  process.exit(1);
}

console.log("Project structure verification passed.");
