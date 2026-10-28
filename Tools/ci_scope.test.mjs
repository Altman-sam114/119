import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { checks, evaluateChecks, selectScope } from "./ci_scope.mjs";

const ids = (...paths) => selectScope(paths).selectedChecks;
const all = checks.map(({ id }) => id);

test("documentation and plan-only changes do not compile or render the game", () => {
  assert.deepEqual(ids("AGENTS.md", "README.md", "work.md", "md/flow/flow.md", "md/test/test.md", "update_log.md"), ["static-checks"]);
  assert.equal(selectScope(["README.md"]).ciContracts, false);
});

test("CI routing changes only add their direct Node contracts", () => {
  for (const file of [".github/workflows/ci-results.yml", "Tools/ci_scope.mjs", "Tools/ci_scope.test.mjs", "Tools/verify_project.mjs"]) {
    const scope = selectScope([file]);
    assert.deepEqual(scope.selectedChecks, ["static-checks"]);
    assert.equal(scope.ciContracts, true);
  }
});

test("shared core and package inputs cover their real consumers", () => {
  for (const file of ["Sources/RomeLegionsCore/GameState.swift", "Package.swift", "Package.resolved"]) assert.deepEqual(ids(file), all);
});

test("test and tool changes select their own execution entry", () => {
  assert.deepEqual(ids("Tests/RomeLegionsCoreTests/GameStateTests.swift"), ["static-checks", "swift-tests"]);
  assert.deepEqual(ids("Tools/GameplaySmoke/main.swift"), ["static-checks", "gameplay-smoke"]);
  assert.deepEqual(ids("Tools/RenderBattlePreview/main.swift"), ["static-checks", "render-battle-preview"]);
});

test("battle presentation and artwork select Render and App build without core execution", () => {
  for (const file of ["RomeLegionsApp/App/GameViewModel.swift", "RomeLegionsApp/App/GameViewModelMapReadouts.swift", "RomeLegionsApp/Views/BattlePanels.swift", "RomeLegionsApp/Resources/BattleUnitArt/legion.png", "RomeLegionsApp/Resources/BattleUnitArt/ground.png", "RomeLegionsApp/Resources/BattleUnitArt/city.png"]) {
    assert.deepEqual(ids(file), ["static-checks", "render-battle-preview", "xcode-build"]);
  }
});

test("other App and project inputs require build, not unrelated battle screenshots", () => {
  for (const file of ["RomeLegionsApp/Views/MainMenuView.swift", "RomeLegionsApp/Resources/Info.plist", "RomeLegionsApp.xcodeproj/project.pbxproj"]) {
    assert.deepEqual(ids(file), ["static-checks", "xcode-build"]);
  }
});

test("mixed changes union dependencies, including both rename endpoints", () => {
  assert.deepEqual(ids("README.md", "Tools/GameplaySmoke/main.swift", "RomeLegionsApp/Views/BattleMapView.swift"), ["static-checks", "gameplay-smoke", "render-battle-preview", "xcode-build"]);
  assert.deepEqual(ids("Sources/RomeLegionsCore/Old.swift", "md/moved.md"), all);
});

test("unknown paths or unavailable baselines fail safe to full validation", () => {
  assert.deepEqual(ids("new-build-input.conf"), all);
  assert.deepEqual(selectScope(["README.md"], { baselineAvailable: false }).selectedChecks, all);
});

test("manual full requires a reason and only expands the auto scope", () => {
  assert.throws(() => selectScope([], { profile: "full" }), /requires a reason/);
  assert.throws(() => selectScope([], { profile: "docs-only" }), /Unknown/);
  const scope = selectScope(["README.md"], { profile: "full", reason: "release regression" });
  assert.deepEqual(scope.selectedChecks, all);
  assert.equal(scope.optional.length, 4);
});

test("intentional skips are distinct from missing or cancelled required checks", () => {
  const scope = selectScope(["README.md"]);
  const results = evaluateChecks(scope, { staticChecksOutcome: "success" });
  assert.equal(results.filter(({ status }) => status === "failure").length, 0);
  assert.equal(results.filter(({ status }) => status === "skipped").length, 4);
  for (const outcome of [undefined, "skipped", "cancelled", "failure"]) {
    assert.equal(evaluateChecks(scope, { staticChecksOutcome: outcome })[0].status, "failure");
  }
  assert.equal(evaluateChecks(scope, { staticChecksOutcome: "success", buildOutcome: "success" }).at(-1).status, "failure");
});

test("workflow wires every selected check to its real outcome and final metadata gate", () => {
  const workflow = readFileSync(".github/workflows/ci-results.yml", "utf8");
  for (const check of checks) {
    assert.ok(workflow.includes(`id: ${check.step}`), check.id);
    if (check.id !== "static-checks") assert.ok(workflow.includes(`if: steps.scope.outputs.${check.step} == 'true'`), check.id);
    assert.ok(workflow.includes(`${check.env}: \${{ steps.${check.step}.outcome }}`), check.id);
  }
  for (const contract of ["fetch-depth: 0", "github.event.before", "evaluateChecks(scope, outcomes)", "<skipped message=", "failed_checks=", "steps.metadata.outputs.failed_checks", "validation-scope.json"]) assert.ok(workflow.includes(contract), contract);
});

function runMetadata(scope, outcomeOverrides = {}) {
  const root = mkdtempSync(join(tmpdir(), "romelegions-ci-contract-"));
  mkdirSync(join(root, "Tools"));
  mkdirSync(join(root, "ci-results"));
  copyFileSync("Tools/ci_scope.mjs", join(root, "Tools/ci_scope.mjs"));
  writeFileSync(join(root, "ci-results/validation-scope.json"), JSON.stringify(scope));
  writeFileSync(join(root, "ci-results/static-checks.log"), "fixture structural check passed\n");
  const workflow = readFileSync(".github/workflows/ci-results.yml", "utf8");
  const script = workflow.match(/node --input-type=module <<'NODE'\n([\s\S]*?)^\s*NODE$/m)?.[1];
  assert.ok(script, "metadata script must be executable independently of game build steps");
  const output = join(root, "github-output");
  execFileSync(process.execPath, ["--input-type=module", "-e", script], {
    cwd: root,
    env: {
      ...process.env,
      ...Object.fromEntries(checks.map(({ env }) => [env, "skipped"])),
      STATIC_OUTCOME: "success", SCOPE_OUTCOME: "success",
      GITHUB_REF_NAME: "main", GITHUB_SHA: "fixture-sha", GITHUB_RUN_ID: "123", GITHUB_RUN_ATTEMPT: "2",
      GITHUB_OUTPUT: output, PROJECT_NAME: "RomeLegions", CI_VERSION: "fixture",
      RESULT_BUNDLE_PATH: "ci-results/RomeLegions.xcresult",
      ...outcomeOverrides
    }
  });
  return {
    manifest: JSON.parse(readFileSync(join(root, "ci-results/ci-artifact-manifest.json"), "utf8")),
    junit: readFileSync(join(root, "ci-results/junit.xml"), "utf8"),
    output: readFileSync(output, "utf8")
  };
}

test("actual metadata emits four explicit skips and no fictitious game evidence for docs", () => {
  const { manifest, junit, output } = runMetadata(selectScope(["work.md"]));
  assert.equal(manifest.branch, "main");
  assert.equal(manifest.runAttempt, "2");
  assert.equal(manifest.testOutcome, "skipped");
  assert.deepEqual(manifest.renderPreviewPaths, []);
  assert.deepEqual(manifest.projectSpecificReports, ["ci-results/static-checks.log"]);
  assert.equal(manifest.resultBundlePath, null);
  assert.match(junit, /failures="0" skipped="4"/);
  assert.equal((junit.match(/<skipped /g) || []).length, 4);
  assert.match(output, /failed_checks=0/);
});

test("actual metadata fails a selected skipped check and a scope setup failure", () => {
  const { manifest, junit, output } = runMetadata(selectScope(["Tests/RomeLegionsCoreTests/GameStateTests.swift"]));
  assert.equal(manifest.testOutcome, "failure");
  assert.match(junit, /failures="1" skipped="3"/);
  assert.match(output, /failed_checks=1/);
  const failedSetup = runMetadata(selectScope(["README.md"]), { SCOPE_OUTCOME: "failure" });
  assert.match(failedSetup.output, /failed_checks=1/);
});

test("actual metadata rejects a successful Render outcome with missing required PNGs", () => {
  const { manifest, output } = runMetadata(selectScope(["Tools/RenderBattlePreview/main.swift"]), { RENDER_PREVIEW_OUTCOME: "success" });
  const render = manifest.checkResults.find(({ id }) => id === "render-battle-preview");
  assert.equal(render.outcome, "success");
  assert.equal(render.status, "failure");
  assert.equal(manifest.renderPreviewPaths.length, 16);
  assert.ok(render.missingPaths.includes("ci-results/render-previews/battle-unit-art-preview.png"));
  assert.match(output, /failed_checks=1/);
});
