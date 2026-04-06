// node tool/gen_icon.js
// Generates Ishbor briefcase launcher icons for all Android mipmap densities.
// Requires: npm install sharp (already done)

const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const sizes = {
  'mipmap-mdpi':    48,
  'mipmap-hdpi':    72,
  'mipmap-xhdpi':   96,
  'mipmap-xxhdpi':  144,
  'mipmap-xxxhdpi': 192,
};

function makeSvg(s) {
  const r = Math.round(s * 0.22); // corner radius
  // proportions (relative to icon size)
  const bx = s * 0.14, by = s * 0.40, bw = s * 0.72, bh = s * 0.40;
  const br = s * 0.07;
  const sw = Math.max(2, s * 0.042); // stroke width
  const hx = s * 0.33, hBot = by + sw / 2, hTop = s * 0.22, hw = s * 0.34;
  const hr = s * 0.07;
  const midY = by + bh * 0.5;
  const midX = bx + bw * 0.5;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${s}" height="${s}" viewBox="0 0 ${s} ${s}">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="${s}" y2="${s}" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#1B4FD8"/>
      <stop offset="100%" stop-color="#0EA5E9"/>
    </linearGradient>
  </defs>

  <!-- Background -->
  <rect width="${s}" height="${s}" rx="${r}" ry="${r}" fill="url(#bg)"/>

  <!-- Briefcase body -->
  <rect x="${bx}" y="${by}" width="${bw}" height="${bh}" rx="${br}" ry="${br}"
        fill="none" stroke="white" stroke-width="${sw}" stroke-linejoin="round"/>

  <!-- Center vertical divider -->
  <line x1="${midX}" y1="${by}" x2="${midX}" y2="${by + bh}"
        stroke="white" stroke-width="${sw}" stroke-linecap="round"/>

  <!-- Horizontal clasp band -->
  <line x1="${bx}" y1="${midY}" x2="${bx + bw}" y2="${midY}"
        stroke="white" stroke-width="${sw}" stroke-linecap="round"/>

  <!-- Handle (arch) -->
  <path d="M ${hx},${hBot}
           L ${hx},${hTop + hr}
           A ${hr},${hr} 0 0,1 ${hx + hr},${hTop}
           L ${hx + hw - hr},${hTop}
           A ${hr},${hr} 0 0,1 ${hx + hw},${hTop + hr}
           L ${hx + hw},${hBot}"
        fill="none" stroke="white" stroke-width="${sw}"
        stroke-linecap="round" stroke-linejoin="round"/>
</svg>`;
}

async function generate() {
  const baseDir = path.join(__dirname, '..', 'android', 'app', 'src', 'main', 'res');
  for (const [folder, size] of Object.entries(sizes)) {
    const svg = Buffer.from(makeSvg(size));
    const outPath = path.join(baseDir, folder, 'ic_launcher.png');
    await sharp(svg)
      .resize(size, size)
      .png()
      .toFile(outPath);
    console.log(`✅  ${outPath}  (${size}x${size})`);
  }

  // Also update web icons
  const webIconDir = path.join(__dirname, '..', 'web', 'icons');
  for (const [webSize, size] of [[192, 192], [512, 512]]) {
    const svg = Buffer.from(makeSvg(size));
    const outPath = path.join(webIconDir, `Icon-${webSize}.png`);
    await sharp(svg).resize(size, size).png().toFile(outPath);
    console.log(`✅  ${outPath}  (${size}x${size})`);
    // Maskable too
    const maskPath = path.join(webIconDir, `Icon-maskable-${webSize}.png`);
    await sharp(svg).resize(size, size).png().toFile(maskPath);
    console.log(`✅  ${maskPath}`);
  }
  // favicon
  const favicon = Buffer.from(makeSvg(64));
  const faviconPath = path.join(__dirname, '..', 'web', 'favicon.png');
  await sharp(favicon).resize(64, 64).png().toFile(faviconPath);
  console.log(`✅  ${faviconPath}`);

  console.log('\nDone! All icons generated.');
}

generate().catch(e => { console.error(e); process.exit(1); });
