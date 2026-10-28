# Battle Unit Art / v0.81

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
