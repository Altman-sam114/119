# Battle Unit Art

## 当前兵模

- 内置 image_gen 生成的原创透明 PNG，工具未返回可核验底层模型名称；未使用 CLI fallback 或额外 API key。四兵种全部替换，旧稿与首次接入说明留作来源追溯，不代表当前文件。
- 当前盾兵为六人两列、弓兵为六人两列、骑兵为三骑、海军为单艘战舰；同向镜头、左上光源、灰铁/青铜/深红/象牙材质。当前是静态 2D 预渲染兵模，不冒充可旋转 3D 或完整商业成品。
- 逐字节复制至 `RomeLegionsApp/Resources/BattleUnitArt/{legion,archer,cavalry,navy}.png`；原图保留在 Codex 生成目录。军旗/地环仍读取真实阵营，不靠贴图颜色判断归属。
- 百度移动版搜索“大征服者罗马 截图”后查看 [麦松战役](https://www.bilibili.com/video/BV1xF1oBUEeQ) 和 [另一战斗实机图](https://www.bilibili.com/video/BV14o1dBDEYM)；只参考微缩实体比例和材质，不复制或打包原作截图。
- 关联地表资源及提示词见 [战场材质](battle-scenery-art.md)。所有资源的 alpha、受限解码、实际 bundle 与真实战斗图由云端检查。

### 当前 legion.png 提示词

```text
Use case: stylized-concept. Asset type: premium original Roman strategy game battle unit sprite, transparent PNG cutout, NOT a UI mockup. Create a high-end miniature formation of SIX ancient Roman legionaries, full body, two disciplined ranks of three soldiers, all facing toward the lower-right, consistent elevated three-quarter isometric camera looking down at 35 degrees. Realistic hand-painted 3D strategy miniature quality, sculpted bronze helmets with small red crests, segmented steel armor, deep oxblood tunics, large curved red rectangular scutum shields with restrained gold lightning emblems, short swords. Readable strong silhouettes at small game-map scale; compact formation, fine material shading, slight natural pose variation, physically coherent feet. Warm upper-left sunlight, subtle soft contact shadow but no terrain, no base platform, no backdrop. Composition: square 1024x1024, entire six-person formation centered with generous transparent margins, no cropping, camera sees helmets, shoulders, shields and feet clearly. Palette: muted crimson, aged bronze, ivory and cool worn steel. Constraints: genuinely transparent alpha background, one cohesive original formation, no text, no numerals, no watermark, no UI, no hexagon, no toy plastic look, no chibi proportions, no giant single hero.
```

### 当前 archer.png 首稿与构图修订

```text
Use case: stylized-concept. Asset type: premium original ancient Roman strategy game ARCHER formation sprite, transparent PNG cutout. Create SIX realistic Roman auxiliary archers, full body, in two staggered ranks of three, all facing lower-right at an elevated three-quarter isometric camera about 35 degrees above horizon. Each holds a clearly curved wooden bow at the ready, with quiver, worn leather armor over ivory tunic, restrained crimson cloaks, bronze helmets, sandals. High-end hand-painted 3D strategy miniature rendering, detailed leather, linen, bronze and wood; adult natural proportions, distinct readable silhouette at small battle-map size. All archers and their equipment entirely in frame, no cropped limbs, centered compact formation with transparent margins, square composition. Match warm upper-left sunlight and grounded soft contact shadows, no physical base and no terrain. Palette muted red, ivory, bronze, dark natural wood. Constraints: genuinely transparent alpha background, original artwork, no text or numbers, no logos, no UI or icons, no hexagon base, no giant hero, no toy plastic, no chibi.
```

首稿右侧弓箭触及画框，使用该首稿为唯一编辑目标，保持透明背景，实际修订请求：

```text
Edit target image 1: the six Roman archer formation on transparent background. Preserve exactly the premium painted realistic material style, the SIX adult archers, ivory tunics, crimson cloaks, bronze helmets, bows and same elevated isometric camera. Correct ONLY the framing: shrink/reframe the ENTIRE formation to occupy at most 76 percent of the square canvas, center it, complete the clipped rightmost bow and arrow so ALL equipment and all feet are visible. There must be at least 10 percent completely empty transparent margin beyond every bow tip and arrow tip on ALL four sides. Preserve genuine alpha transparency, no backdrop, no terrain, no new people or other objects, no text or watermark. Keep the compact two ranks of three archers facing lower-right, warm upper-left lighting and detailed tactile armor.
```

### 当前 cavalry.png 提示词

```text
Use case: stylized-concept. Asset type: original premium Roman strategy game CAVALRY squad sprite, transparent PNG cutout. Subject: THREE ancient Roman cavalry soldiers mounted on three muscular chestnut and dark bay horses, compact staggered triangular formation, all facing lower-right, elevated isometric orthographic camera looking down 35 degrees. All THREE horses complete with correct legs, heads, tails and hooves, riders in bronze helmets, iron chainmail, deep crimson cloaks, short upright lances and small round bronze shields. High-end realistic hand-painted 3D miniature quality, sculpted anatomy, tactile worn leather tack, finely shaded metal, layered red saddle blankets. Warm upper-left daylight and soft ambient occlusion, consistent historical game asset lighting. Composition: a square canvas, entire formation must fit within central 78 percent of canvas including lance tips, hooves and tails; empty transparent border of at least 10 percent on all four sides. Clearly readable formation at small map scale, not a cinematic portrait. Constraints: genuine transparent alpha, no floor plane or terrain, no circular base, no watermark, no text, no UI, no flag, no chibi, no toy plastic. Premium original game miniature, not a reproduction of a commercial asset.
```

### 当前 navy.png 提示词

```text
Use case: stylized-concept. Asset type: premium original Roman naval strategy-game miniature sprite, transparent PNG cutout. ONE ancient Roman quinquereme war galley, complete ship seen from elevated isometric orthographic camera 35 degrees looking down, bow pointing lower-right. Long dark walnut hull with bronze ram, elegant upward curved stern, twin steering oars, orderly banks of narrow oars on both sides, one central mast with a large ivory square sail carrying a broad simple muted crimson stripe, detailed rigging, small crenellated foredeck, believable tiny deck details. High-end hand-painted realistic 3D miniature game rendering, finely carved wood grain, sail cloth folds, warm upper-left sunlight with subtle shaded interior. Clear silhouette at small map size. Square canvas, whole ship centered in central 78 percent, all oars, ropes, mast, prow and stern fully inside, transparent air of at least 10 percent on every edge. True transparent alpha background even between rigging and oars. NO water, NO ocean, NO splash, NO base or tile, NO flag, NO human portrait, NO text or letters, NO watermark, NO UI. Original historical strategy-game asset, not copied from a commercial game.
```

## 首次接入记录（历史资源，已替换）

## 来源与交付

- 日期：2026-10-28。由内置生图工具生成，明确请求 `transparent_background: true`，没有使用 CLI fallback、外部模型下载、额外 API key 或原游戏素材。工具不返回可核验的底层模型版本，因此不虚构模型名称。
- 百度搜索“大征服者罗马 游戏截图”，实际查看“麦松战役”实机图（`https://www.bilibili.com/video/BV1xF1oBUEeQ`）；参考微缩军队的地面关系和材质，不复制、裁切或打包截图。
- 最终资源：`RomeLegionsApp/Resources/BattleUnitArt/legion.png`、`cavalry.png`、`archer.png`、`navy.png`。生成原图保留在 Codex 生成目录，项目资源为逐字节副本，不做本地图片处理或验证。
- 四类 PNG 随 `BattleUnitArt` folder resource 打入 App。`BattleUnitArtwork` 以 ImageIO 统一降采样到最长边 384px 并缓存，避免地图更新时反复解码高分辨率原图。
- 独立 macOS Render 通过显式 `ROMELEGIONS_ART_ROOT` 读取同一文件；iOS 不使用此环境变量、不从仓库路径或网络读取。云端检查 alpha、材质轮廓和打包内容，检视图为 `battle-unit-art-preview.png`。
- 兵模属于 2D 预渲染贴图，尚非可旋转的 3D 模型。四兵种共享古地中海装备美术，阵营军旗与地面环仍由真实 `Faction` 绘制；民族专属服装、独立将领肖像和动作帧是后续升级，不把当前版本称为完整商业美术。

## 最终生成提示词

下面保存实际请求的提示词。第一张为全新生成；其余三张引用第一张作为美术/材质/镜头参考，不把商业截图输入模型。

### legion.png

```text
Use case: stylized-concept. Asset type: production transparent PNG sprite for an original premium ancient-Mediterranean turn-based strategy iOS game, not a concept sheet. Primary request: ONE beautifully crafted miniature Roman heavy-infantry cohort, 3 full-body legionaries in a tight triangular formation, leader in front and two slightly behind. Isometric orthographic camera, viewed from about 35 degrees above, facing down-right; all feet on the same shallow isometric ground plane. Realistic high-end hand-painted 3D strategy-game rendering, convincing sculpted anatomy and fine but clean materials, not cartoon and not flat vector. Brushed iron helmets with restrained bronze trim, chainmail and segmented armor, oxblood cloth and leather, three curved rectangular red-brown scutum shields with subtle embossed bronze ornament, one short sword and two upright spears. Strong readable silhouette, distinct tiny helmet glints, layered armor, weighted stance. Soft warm light from upper-left, ambient occlusion between bodies, subtle contact shadow only under feet. Entire group centered with 12 percent transparent padding on all sides; ALL spear tips and feet inside frame. The formation occupies 76 percent of canvas width and 80 percent of canvas height. Truly transparent background/alpha, no colored backdrop, no floor tile, no circular base, no border, no flags, no UI, no letters, no numbers, no text, no watermark. Must remain legible as a 65-pixel-tall in-game army miniature. Original design, do not copy commercial game assets.
```

### archer.png

```text
Use case: stylized-concept. Asset type: a NEW production transparent PNG strategy-game sprite. Input image 1 is ONLY a visual style/material/camera reference, NOT an edit target and not a character identity requirement. Create ONE original ancient Mediterranean ARCHER COHORT of three full-body archers in a compact triangular formation, front archer drawing a recurved wooden bow aimed down-right, rear two holding recurved bows ready, leather quivers and a few visible arrows. Match the reference's premium realistic hand-painted 3D miniature quality, brushed iron and restrained bronze, aged leather, muted oxblood tunics, soft warm upper-left light and precise occlusion. Isometric orthographic view from about 35 degrees above, face down-right, all feet on same plane. Make bows and quivers instantly distinguishable from heavy infantry at 65 pixels high, no shields or spears. Strong clear silhouette; three complete bodies; all bow tips and feet fully inside the frame. Group centered with at least 10 percent EMPTY transparent padding around the entire silhouette, including arrows, at every edge. Truly transparent alpha background, subtle contact shadow under feet only, no floor/base, no flag, no UI, no letters, no captions, no border, no watermark. Original game asset, not a screenshot and not a character portrait.
```

### cavalry.png

```text
Use case: stylized-concept. Asset type: NEW production transparent PNG cavalry sprite for an original premium ancient-Mediterranean isometric strategy game. Input image 1 is ONLY the visual style, material and camera reference. Draw ONE compact squad of TWO fully visible armored ancient Roman cavalry riders on muscular chestnut horses, staggered in depth, front horse at lower-right and second behind at upper-left, both facing down-right. Riders have iron helmets with modest bronze accents, muted oxblood cloaks, leather tack, round cavalry shields and SHORT diagonal lances; keep the complete lance tips in frame. Isometric orthographic camera looking 35 degrees down, like a miniature on the game's terrain, NOT a cinematic low-angle poster. Exquisite realistic hand-painted 3D game rendering, sculpted horses, polished helmet highlights, layered saddle blankets, restrained bronze and deep reddish-brown leather; same warm upper-left light and shadow richness as the reference infantry. Two recognizable horse silhouettes, eight anatomically sound legs, no overlap hiding the front horse head. All hooves, tails, heads and lances completely visible. Entire squad occupies only central 76 percent of image with at least 10 percent transparent air around all sides. True transparent alpha background, very subtle contact shadows only, no ground tile, no circular base, no flag, no UI, no text or watermark. Must read clearly when reduced to a 70-pixel in-game cavalry miniature. Original design, not commercial game asset reproduction.
```

### navy.png

```text
Use case: stylized-concept. Asset type: NEW transparent production naval-unit sprite in the SAME premium realistic hand-painted 3D ancient-strategy art family as reference image 1. Reference image 1 is for brushwork, material realism, soft upper-left lighting, subdued bronze/oxblood/ivory palette and orthographic miniature camera ONLY. Subject: ONE beautifully crafted ancient Mediterranean war galley / Roman trireme seen in a high three-quarter isometric view from about 35 degrees above, bow pointing down-right. Long dark walnut hull, subtle bronze ram on the prow, orderly oars on both sides, tiny raised foredeck, believable ropes and ONE mast with a full warm-ivory square sail with a restrained oxblood stripe. Distinct shallow hull and broad sail silhouette; all oars, mast tip, stern and bow inside the canvas. Exquisite model-like craftsmanship, shaded sail folds, realistic wood grain, bronze glints and readable details for a 75-pixel-wide strategy miniature. Center the entire ship in the central 76 percent of image, leave generous EMPTY transparent padding. Truly transparent alpha everywhere outside the ship, including spaces between oars and rigging. NO sea, NO water plane, NO white rectangle, NO ground base, NO decorative frame, NO UI, NO labels, NO watermark, NO extra ships. Original game asset, not a screenshot.
```
