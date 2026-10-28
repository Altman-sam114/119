# 战场材质与地标

## 来源与接入

- 内置 image_gen 生成五类原创 PNG，无 CLI fallback、额外 key、模型下载或第三方框架。工具不返回可核验模型 ID，不虚构名称；全部原图保留在 Codex 生成目录，资源逐字节复制入项目。
- 参考来源为百度移动版“大征服者罗马 截图”结果中的 [麦松战役](https://www.bilibili.com/video/BV1xF1oBUEeQ) 与 [战斗实机图](https://www.bilibili.com/video/BV14o1dBDEYM)。仅参考连续地图、写实微缩实体和低饱和材质关系，未把商业截图输入生图工具，未复制或打包原游戏素材。
- `ground.png`、`water.png` 是不透明方形材质；`city.png`、`forest.png`、`hills.png` 是真实透明背景地标，均位于 `RomeLegionsApp/Resources/BattleUnitArt/`。复用已有 folder resource，不动人工工程配置。
- `BattleArtworkLoader` 共用资源查找/降采样，`BattleSceneryArtwork` 一次缓存；地表最长边 768px、地标 384px。iOS 只读 bundle，独立 macOS 云端 Render 才能使用显式 `ROMELEGIONS_ART_ROOT`。
- 材质只在真实陆地轮廓/水面内绘制，地形和道路仍由 Tile/HexMetrics 定义；地标不参与命中或改变状态。生成模型请求无缝，但不把请求视为已保证无缝，仍需用真实战斗图目检平铺接缝。
- 验证：云端检查五条独立路径、有界解码、表面不透明/地标透明、明暗层次，输出 `battle-scenery-art-preview.png` 并逐字节比对 App bundle；与原 15 战斗图和兵模检视图共同复判。不用 Canvas 降级冒充通过。

## 实际生成提示词

### ground.png（transparent_background: false）

```text
Use case: stylized-concept. Asset type: seamless tileable diffuse ground texture for an original premium ancient Mediterranean isometric strategy game. A square top-down orthographic landscape MATERIAL ONLY, delicate realistic hand-painted olive and sage grassland, irregular fine patches of faded straw grass, mottled ochre earth, tiny pale limestone grit and sparse very small low scrub. Natural multiscale painterly detail, coherent soft warm daylight, low contrast so game units remain readable. Colors: desaturated olive green, gray sage, dusty khaki, muted warm ochre; NO emerald green. Entire image filled edge to edge, seamless repeat in both directions, no vignette, no focal subject, no strong directional lighting or cast shadow. Terrain looks like a real aerial Mediterranean landscape at campaign map scale, not close-up lawn blades. NO hills or mountains, NO trees, NO buildings, NO roads, NO rivers, NO coast, NO hexagons, NO grid, NO UI, NO text, NO frame, NO logos. Premium subtle tactile ground suitable beneath small ancient armies. Opaque full square texture.
```

### water.png（transparent_background: false）

```text
Use case: stylized-concept. Asset type: seamless opaque WATER diffuse texture for premium ancient Mediterranean strategy-game map. Square image, top-down orthographic view, edge-to-edge calm deep sea water. Desaturated green-teal slate sea, subtle soft cloudy depth variation, many delicate tiny irregular ripples, natural fine painterly mineral texture. Historical painted atlas meets realistic strategy terrain, gently shaded, restrained low contrast so units and map routes remain visible. No bright sun glare, no dramatic surf, no distinct dominant waves. Seamlessly tileable in both directions with no visible seam, no dark vignette, flat even daylight across full image. Color range muted turquoise gray to dark teal blue, not saturated tropical cyan. NO land or coast, NO beach, NO island, NO ships, NO objects, NO foam rings, NO horizon, NO grid, NO hexagons, NO lettering or watermark. Full opaque square material sample.
```

### city.png（transparent_background: true）

```text
Use case: stylized-concept. Asset type: original premium ancient Roman strategy game CITY map sprite, transparent PNG cutout, not a UI icon or scenic painting. One compact believable Roman walled town miniature, viewed in elevated isometric orthographic projection looking down 40 degrees, warm upper-left sunlight. Dense cluster of about twenty ivory limestone buildings with realistic faded terracotta tile roofs, a small columned forum temple, a few cypress trees, encircling low stone defensive wall with square towers and a visible gate opening toward lower-right. Fine tactile limestone masonry, individual roofs and architectural detail, shaded courtyards, subtle depth and gentle contact shadows. High-end hand-painted realistic 3D historical strategy miniature, natural muted earth palette, NOT a toy or cartoon. Town occupies central 78 percent of square canvas, whole footprint completely in frame with at least 10 percent empty transparent air on all four sides. Soft irregular foundation edges only under buildings, NO massive flat tile base or island. True transparent alpha around town, including open spaces, no colored backdrop. NO lettering, NO city-name label, NO numeral, NO flag, NO UI, NO watermark, NO hexagon, NO soldiers, NO ocean. Premium original asset.
```

### forest.png（transparent_background: true）

```text
Use case: stylized-concept. Asset type: transparent forest terrain landmark sprite for a premium ancient Mediterranean strategy map. One irregular natural grove of roughly fourteen small varied Mediterranean trees: dark olive oak canopies, a few slim cypresses, occasional stone pines; visible tiny trunks and soft natural ground contact shadows. Elevated orthographic isometric camera looking down 40 degrees, wide low composition, warm upper-left daylight. Realistic high-end hand-painted 3D terrain miniature, richly sculpted foliage clumps with tiny sunlit leaves, deep but soft canopy shadow, muted gray olive / sage / dark pine palette, no saturated cartoon greens. The grove has an organic ragged outline and open gaps, not a perfect circle. Entire cluster centered in central 75 percent of square canvas with transparent margins. Genuine transparent alpha outside foliage and between trees, very faint ground shadows only; no opaque terrain base, no rectangular tile, no pedestal. NO river, NO mountains, NO buildings, NO people, NO text, NO UI, NO watermark. Make the silhouette and light direction read beautifully at 60px wide in a historical strategy game. Original artwork.
```

### hills.png（transparent_background: true）

```text
Use case: stylized-concept. Asset type: transparent rocky hills terrain landmark sprite for an original premium ancient Mediterranean strategy game. One small elongated range of three joined limestone ridges, realistic weathered pale gray ochre rock faces with fine stratification, soft sage scrub and sparse grass along lower slopes, clearly directional sunlit left faces and cool shaded right faces. Elevated isometric orthographic camera looking down 40 degrees, warm sunlight from upper-left. High-end realistic hand-painted 3D miniature terrain, convincing natural rock and smooth irregular transitions, NOT sharp low-poly triangles. Wide compact arrangement oriented upper-left to lower-right, all ridges fully visible, entire asset centered in central 75 percent of square canvas with empty transparent margins. Genuine transparent alpha outside the irregular landform, soft faint contact shadow only, no rectangular terrain tile, no pedestal or platform, no broad background ground plane. Muted limestone, slate, sage, dusty olive palette. NO snow, NO volcano, NO buildings, NO people, NO trees, NO water, NO text, NO UI, NO watermark. Original map asset readable at 70px wide.
```
