import { writeFileSync } from "node:fs";
import { deflateSync } from "node:zlib";

const width = 1024;
const height = 1024;
const output = "RomeLegionsApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png";

function crc32(bytes) {
  let crc = 0xffffffff;
  for (const byte of bytes) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit += 1) {
      crc = (crc >>> 1) ^ (0xedb88320 & -(crc & 1));
    }
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const typeBytes = Buffer.from(type, "ascii");
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(Buffer.concat([typeBytes, data])));
  return Buffer.concat([length, typeBytes, data, crc]);
}

function pixelFor(x, y) {
  const dx = x - width / 2;
  const dy = y - height / 2;
  const radius = Math.sqrt(dx * dx + dy * dy);

  let color = [220, 205, 168, 255];
  if (radius > 460) color = [196, 181, 145, 255];
  if (x > 170 && x < 850 && y > 210 && y < 280) color = [144, 20, 16, 255];
  if (x > 260 && x < 730 && y > 330 && y < 650) color = [24, 24, 23, 255];
  if (x > 510 && x < 680 && y > 270 && y < 720) color = [144, 20, 16, 255];
  if (Math.abs((x - 235) * 0.22 + (y - 520)) < 16 && y > 260 && y < 790) color = [235, 226, 190, 255];
  if (Math.abs((x - 790) * -0.22 + (y - 520)) < 16 && y > 260 && y < 790) color = [235, 226, 190, 255];
  return color;
}

const raw = Buffer.alloc((width * 4 + 1) * height);
let offset = 0;
for (let y = 0; y < height; y += 1) {
  raw[offset] = 0;
  offset += 1;
  for (let x = 0; x < width; x += 1) {
    const [r, g, b, a] = pixelFor(x, y);
    raw[offset] = r;
    raw[offset + 1] = g;
    raw[offset + 2] = b;
    raw[offset + 3] = a;
    offset += 4;
  }
}

const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(width, 0);
ihdr.writeUInt32BE(height, 4);
ihdr[8] = 8;
ihdr[9] = 6;
ihdr[10] = 0;
ihdr[11] = 0;
ihdr[12] = 0;

const png = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  chunk("IHDR", ihdr),
  chunk("IDAT", deflateSync(raw, { level: 9 })),
  chunk("IEND", Buffer.alloc(0))
]);

writeFileSync(output, png);
console.log(`Wrote ${output}`);
