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
  "README.md"
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
for (const token of ["moveUnit", "attack", "attackPreview", "CombatPreview", "recruit", "research", "performSimpleAI", "skipUnit", "performAIRecruitment", "bestAITarget", "developCity", "trainUnit", "appointGeneral", "sendEnvoy"]) {
  if (!core.includes(token)) {
    failures.push(`Core game state does not include ${token}`);
  }
}

const viewModel = readFileSync("RomeLegionsApp/App/GameViewModel.swift", "utf8");
for (const token of ["selectedPosition", "selectedTile", "func attackPreview", "primaryMission", "skipSelectedUnit", "--attack-demo", "restSelectedUnit"]) {
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

if (failures.length > 0) {
  console.error(failures.join("\n"));
  process.exit(1);
}

console.log("Project structure verification passed.");
