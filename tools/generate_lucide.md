# Generating the full Lucide pack

`src/Systems/IconData.lua` ships a curated starter set. To embed all ~1500
Lucide icons, generate a spritesheet + map offline and drop it in (the shape is
stable, so no other module changes).

## Steps

1. **Fetch Lucide SVGs** — `npm i lucide-static` (gives you `node_modules/lucide-static/icons/*.svg`).
2. **Rasterise to a grid** — render each SVG at 256×256 onto a 16-column sheet
   (4096px wide). Multiple pages once you exceed 256 icons per sheet. Use the
   provided `pack.js` sketch below (requires `sharp`).
3. **Upload each sheet** to Roblox and note the asset id(s).
4. **Emit `IconData.lua`** — write `Sheets` (sheetId → rbxassetid) and `Map`
   (name → { Sheet, Offset, Size }). The generator can print this Lua table
   directly so you paste it over the shipped `pack` table.

```js
// pack.js (sketch) — node pack.js
const fs = require("fs");
const sharp = require("sharp");
const path = require("path");

const DIR = "node_modules/lucide-static/icons";
const CELL = 256, COLS = 16;
const names = fs.readdirSync(DIR).filter(f => f.endsWith(".svg")).map(f => f.slice(0, -4)).sort();
const perSheet = COLS * COLS; // 256 per sheet

(async () => {
  const map = {};
  for (let s = 0; s * perSheet < names.length; s++) {
    const slice = names.slice(s * perSheet, (s + 1) * perSheet);
    const composites = await Promise.all(slice.map(async (name, i) => ({
      input: await sharp(path.join(DIR, name + ".svg"), { density: 300 })
        .resize(CELL, CELL).png().toBuffer(),
      left: (i % COLS) * CELL, top: Math.floor(i / COLS) * CELL,
    })));
    slice.forEach((name, i) => {
      map[name] = { Sheet: String(s + 1), col: i % COLS, row: Math.floor(i / COLS) };
    });
    await sharp({ create: { width: COLS * CELL, height: COLS * CELL, channels: 4,
      background: { r: 0, g: 0, b: 0, alpha: 0 } } })
      .composite(composites).png().toFile(`lucide_sheet_${s + 1}.png`);
  }
  // Emit Luau (fill in rbxassetid after uploading each sheet):
  let lua = "return {\n  Sheets = { },\n  Map = {\n";
  for (const [name, e] of Object.entries(map))
    lua += `    ["${name}"] = { Sheet = "${e.Sheet}", Offset = Vector2.new(${e.col*CELL}, ${e.row*CELL}), Size = Vector2.new(${CELL}, ${CELL}) },\n`;
  lua += "  },\n}\n";
  fs.writeFileSync("IconData.generated.lua", lua);
})();
```

White/monochrome icons recolor at runtime via `ImageColor3`, so render Lucide in
white (`stroke="#fff"`) for best theming.
