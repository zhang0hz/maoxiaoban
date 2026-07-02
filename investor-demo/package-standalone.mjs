import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const demoDir = fileURLToPath(new URL(".", import.meta.url));
const outputPath = path.join(demoDir, "maoxiaoban-demo.html");

const mimeTypes = {
  ".gif": "image/gif",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp"
};

function read(file) {
  return fs.readFileSync(path.join(demoDir, file), "utf8");
}

function assetDataUri(relativePath) {
  const fullPath = path.join(demoDir, relativePath);
  const ext = path.extname(fullPath).toLowerCase();
  const mime = mimeTypes[ext];

  if (!mime) {
    throw new Error(`Unsupported asset type: ${relativePath}`);
  }

  const data = fs.readFileSync(fullPath).toString("base64");
  return `data:${mime};base64,${data}`;
}

let html = read("index.html");
const css = read("styles.css");
const js = read("script.js");

html = html.replace(/<link rel="stylesheet" href="styles\.css">/, `<style>\n${css}\n</style>`);
html = html.replace(/<script src="script\.js"><\/script>/, `<script>\n${js}\n</script>`);

html = html.replace(/assets\/[A-Za-z0-9._-]+/g, (assetPath) => assetDataUri(assetPath));

html = html.replace(
  /<title>猫小伴投资方 Demo<\/title>/,
  "<title>猫小伴 Demo</title>"
);

fs.writeFileSync(outputPath, html, "utf8");

console.log(`Wrote ${outputPath}`);
console.log(`${Buffer.byteLength(html, "utf8")} bytes`);
