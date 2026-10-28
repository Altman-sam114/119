import { execFileSync } from "node:child_process";
import { appendFileSync, writeFileSync } from "node:fs";
import { pathToFileURL } from "node:url";

export const checks = [
  { id: "static-checks", step: "static_checks", env: "STATIC_OUTCOME", outcome: "staticChecksOutcome", log: "ci-results/static-checks.log" },
  { id: "swift-tests", step: "swift_tests", env: "SWIFT_TESTS_OUTCOME", outcome: "swiftTestsOutcome", log: "ci-results/swift-test.log" },
  { id: "gameplay-smoke", step: "gameplay_smoke", env: "GAMEPLAY_SMOKE_OUTCOME", outcome: "gameplaySmokeOutcome", log: "ci-results/gameplay-smoke.log" },
  { id: "render-battle-preview", step: "render_preview", env: "RENDER_PREVIEW_OUTCOME", outcome: "renderPreviewOutcome", log: "ci-results/render-battle-preview.log" },
  { id: "xcode-build", step: "xcode_build", env: "XCODE_BUILD_OUTCOME", outcome: "buildOutcome", log: "ci-results/xcodebuild.log" }
];

export function selectScope(changedFiles, options = {}) {
  const { profile = "auto", reason = "", baselineAvailable = true, baseSha = "", headSha = "" } = options;
  if (!["auto", "full"].includes(profile)) throw new Error(`Unknown validation profile: ${profile}`);
  if (profile === "full" && !reason.trim()) throw new Error("Full validation requires a reason");

  const selected = new Set(["static-checks"]);
  const reasons = { "static-checks": ["Baseline diff, structure and documentation contracts"] };
  const add = (ids, why) => {
    for (const id of ids) {
      selected.add(id);
      (reasons[id] ??= []).push(why);
    }
  };
  let ciContracts = false;
  for (const file of changedFiles) {
    if (file.endsWith(".md") || [".gitignore", ".gitattributes"].includes(file)) continue;
    if (file.startsWith(".github/") || /^Tools\/(ci_scope(?:\.test)?|verify_project)\.mjs$/.test(file)) {
      ciContracts = true;
    } else if (file === "Package.swift" || file === "Package.resolved" || file.startsWith("Sources/")) {
      add(checks.map(({ id }) => id), `Shared core/build input: ${file}`);
    } else if (file.startsWith("Tests/RomeLegionsCoreTests/")) {
      add(["swift-tests"], `Core test input: ${file}`);
    } else if (file.startsWith("Tools/GameplaySmoke/")) {
      add(["gameplay-smoke"], `Smoke input: ${file}`);
    } else if (file.startsWith("Tools/RenderBattlePreview/")) {
      add(["render-battle-preview"], `Render input: ${file}`);
    } else if (/^RomeLegionsApp\/(App\/GameViewModel[^/]*\.swift|Views\/Battle[^/]*\.swift|Resources\/BattleUnitArt\/)/.test(file)) {
      add(["render-battle-preview", "xcode-build"], `Shared battle presentation input: ${file}`);
    } else if (file.startsWith("RomeLegionsApp/") || file.startsWith("RomeLegionsApp.xcodeproj/")) {
      add(["xcode-build"], `App/bundle/project input: ${file}`);
    } else {
      add(checks.map(({ id }) => id), `Unclassified path; conservative full validation: ${file}`);
    }
  }
  const direct = [...selected].filter((id) => id !== "static-checks");
  if (!baselineAvailable) add(checks.map(({ id }) => id), "No reliable comparison base; conservative full validation");
  if (profile === "full") add(checks.map(({ id }) => id), `Explicit full validation: ${reason.trim()}`);
  const selectedChecks = checks.map(({ id }) => id).filter((id) => selected.has(id));
  return {
    validationProfile: profile === "full" || !baselineAvailable || selectedChecks.length === checks.length ? "full" : "task-scoped",
    requestedProfile: profile,
    reason,
    baseSha,
    headSha,
    baselineAvailable,
    changedFiles,
    baseline: ["static-checks"],
    direct,
    optional: profile === "full" ? selectedChecks.filter((id) => id !== "static-checks" && !direct.includes(id)) : [],
    selectedChecks,
    selectionReasons: reasons,
    skippedChecks: checks.filter(({ id }) => !selected.has(id)).map(({ id }) => ({ id, reason: "Not affected by the changed inputs; not requested as optional validation" })),
    ciContracts
  };
}

export function evaluateChecks(scope, outcomes) {
  // An unselected check is an intentional skip; a selected skip is a failure.
  return checks.map((check) => {
    const selected = scope.selectedChecks.includes(check.id);
    const outcome = outcomes[check.outcome] || "skipped";
    const skippedReason = scope.skippedChecks.find(({ id }) => id === check.id)?.reason;
    return {
      ...check,
      selected,
      outcome,
      status: !selected ? (outcome === "skipped" ? "skipped" : "failure") : (outcome === "success" ? "success" : "failure"),
      reason: selected ? "Required by validation scope" : skippedReason
    };
  });
}

function main() {
  const git = (...args) => execFileSync("git", args, { encoding: "utf8" });
  const headSha = process.env.GITHUB_SHA || git("rev-parse", "HEAD").trim();
  let baseSha = process.env.CI_DIFF_BASE || "";
  if (process.env.GITHUB_EVENT_NAME === "workflow_dispatch") {
    try { baseSha = git("rev-parse", `${headSha}^`).trim(); } catch { baseSha = ""; }
  }
  let baselineAvailable = false;
  if (baseSha && !/^0+$/.test(baseSha)) {
    try { git("rev-parse", "--verify", `${baseSha}^{commit}`); baselineAvailable = true; } catch { /* Full fallback below. */ }
  }
  const changedFiles = (baselineAvailable
    ? git("diff", "--name-only", "--no-renames", "-z", baseSha, headSha)
    : git("ls-tree", "-r", "--name-only", "-z", headSha)).split("\0").filter(Boolean);
  const scope = selectScope(changedFiles, {
    profile: process.env.CI_PROFILE || "auto",
    reason: process.env.CI_REASON || "",
    baseSha: baselineAvailable ? baseSha : "",
    headSha,
    baselineAvailable
  });
  writeFileSync("ci-results/validation-scope.json", JSON.stringify(scope, null, 2) + "\n");
  const outputs = checks.map(({ id, step }) => `${step}=${scope.selectedChecks.includes(id)}`);
  outputs.push(`ci_contracts=${scope.ciContracts}`, `base_sha=${scope.baseSha}`);
  appendFileSync(process.env.GITHUB_OUTPUT, outputs.join("\n") + "\n");
  console.log(JSON.stringify(scope, null, 2));
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) main();
