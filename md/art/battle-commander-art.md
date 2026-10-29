# 将领肖像

## 来源与约束

- 四幅原稿由本任务此前的内置 `image_gen` 调用生成，本轮目检后逐字节复制接入，未使用 CLI fallback、额外 key、外部模型或商业游戏肖像。工具不提供可核验底层模型 ID，不虚构模型名称。
- 原创历史人物艺术演绎，不宣称真实容貌考证；没有采用现代演员身份。凯撒的桂冠/红披风、汉尼拔的短卷发/紫披风、维钦托利的长发/绿披风、拉比埃努斯的短发/链甲分别独立，不能按阵营或技能混用。
- 四幅不透明方形画作位于 `RomeLegionsApp/Resources/BattleUnitArt/commander-<id>.png`；同一 folder resource 打包，未改人工工程配置。
- `BattleCommanderPortrait` 仅精确匹配 `凯撒`、`汉尼拔`、`维钦托利`、`拉比埃努斯`；`马戈`、`凯撒军团`、空姓名等使用中性图标/姓名盾徽，不猜测别名或错误套图。
- `BattleCommanderArtwork` 复用 ImageIO 加载器，最长边256px并一次缓存；iOS只读bundle，独立macOS云端Render才读取显式资源根目录。`CommanderPortraitView` 在地图、底栏身份和敌将卡共享同一资源与圆形裁剪，不拥有玩法状态。
- 云端检查四条独立资源、原图互不重复、256px解码、明暗与精确姓名映射，输出 `battle-commander-art-preview.png`；Xcode 后逐字节比较包内文件。中性图标降级不算正式资源验收。

## 实际生成提示词

均使用内置工具，`transparent_background: false`。原请求在本任务生成记录中可核对；本轮只接入这些已生成原稿，没有编造新生成成功。

### commander-caesar.png

```text
Use case: historical-scene. Asset type: original high-end strategy-game COMMANDER PORTRAIT of Julius Caesar, square image for a small circular in-game medallion. A historically inspired middle-aged Roman statesman-general with a lean angular clean-shaven face, short receding gray-brown hair, intelligent stern eyes, restrained laurel wreath, worn bronze decorated cuirass and deep crimson cloak at shoulders. Tight head-and-upper-shoulders composition, face centered, three-quarter view turned slightly right, both eyes visible; head occupies about 65 percent of canvas height, generous space around laurel tips. Realistic premium hand-painted classical oil / 3D game portrait, subtle brushwork, exquisitely detailed skin, bronze and fabric, natural adult proportions. Warm upper-left key light, soft cool shadow, very dark muted olive-brown plain textured background with no scene. Palette aged bronze, ivory skin tones, crimson and slate. Original visual interpretation of historical Caesar, do not resemble any modern actor or copy a commercial game's portrait. NO text, NO letters, NO UI frame, NO border, NO numeral, NO watermark, NO glowing fantasy effects, NO helmet covering the face. Opaque full square background.
```

### commander-hannibal.png

```text
Use case: historical-scene. Asset type: original premium historical strategy-game COMMANDER PORTRAIT of Hannibal Barca, square image for a circular in-game medallion. A historically inspired Carthaginian general in his forties with a strong sun-weathered North African Mediterranean face, olive-brown complexion, short dark curly hair, neatly trimmed dark beard, intense intelligent eyes and one subtle old cheek scar. Ancient bronze scale cuirass with restrained Punic geometric ornament, warm ivory tunic and muted indigo-purple military cloak, no helmet hiding his face. Tight head-and-upper-shoulders composition, face centered, three-quarter turned slightly left, both eyes visible, head occupies 65 percent of square. Premium realistic hand-painted classical oil / 3D strategy game portrait, exquisitely rendered skin, aged bronze, natural woven cloth, restrained brushwork. Warm upper-left daylight, soft cool shadow, very dark desaturated olive-brown textured background. Match the visual family of a grounded Roman strategy game, no fantasy armor. Original visual interpretation of the historical commander, not a modern actor and not a copy of a commercial game portrait. NO text, NO lettering, NO frame or border, NO insignia labels, NO watermark, NO UI, NO glowing effects. Opaque full square background.
```

### commander-vercingetorix.png

```text
Use case: historical-scene. Asset type: original premium ancient strategy-game COMMANDER PORTRAIT, square painted bust, for an iOS Roman-era tactics game, not a UI mockup. Subject: a historically inspired Vercingetorix, adult Gallic war leader about 38, powerful angular face, clear alert blue-gray eyes, thick long tawny blond hair swept back, full short blond mustache and beard, solemn determined expression, facing slightly right of viewer. Upper chest visible, worn iron chainmail, dark forest-green wool cloak clasped with a restrained Celtic bronze brooch, simple bronze neck torc; no fantasy horns, no crown. Style: exceptionally refined realistic hand-painted historical game portrait, convincing sculpted anatomy, skin pores and natural fine facial detail, tactile wool, aged iron and bronze, rich but restrained brushwork, softly lit with warm upper-left daylight. Composition: centered head and shoulders on a plain subtly painted dark umber and olive background, entire head and hair inside canvas with generous top and side margins, eyes about 40 percent down from top, face occupies central 50 percent width and remains recognizable as a 24px circular map medallion. Palette earthy warm browns, dark green, worn bronze, natural hair and skin, no saturated neon. Exactly one person, original character interpretation of the historical figure; do not copy actors or commercial game artwork. NO text, no name, no lettering, no border, no frame, no badge, no watermark, no logos, no UI, no weapons crossing face. Opaque square background.
```

### commander-labienus.png

```text
Use case: historical-scene. Asset type: original premium ancient Roman strategy-game COMMANDER PORTRAIT, square painted head-and-shoulders bust for a round map medallion and character card, NOT a UI mockup. Subject: a historically inspired Titus Labienus, Roman cavalry commander about 48 years old, lean angular weathered face, strong aquiline nose, deep-set hazel eyes, clean-shaven, short dark brown hair lightly graying at temples, focused intelligent calm expression, turned three-quarter slightly left. Upper chest in fine worn iron chainmail with restrained bronze shoulder fittings, dark oxblood cavalry cloak held by a simple circular bronze brooch, ivory linen collar; NO laurel crown and NO helmet so his short hair and face distinguish him from Caesar. Style: exceptionally refined realistic hand-painted historical game portrait with convincing adult anatomy, natural skin detail, tactile iron, wool and bronze, rich restrained brushwork. Warm upper-left daylight, gentle shadow, dark umber and muted olive painted background without objects. Composition centered, complete head with generous top and side margins, eyes about 40 percent down from top, face occupies the middle 50 percent of width, face must read at a tiny 24px circular size. Palette natural warm skin, dark brown hair, muted deep red and cool chainmail, weathered bronze. Exactly one person, original artistic interpretation, not an actor and not copied from commercial game artwork. NO text, no letters, no name, no border, no frame, no badge, no watermark, no logos, no UI, no weapon across face. Opaque square canvas.
```
