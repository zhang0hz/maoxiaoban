import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL(".", import.meta.url));

const requiredFiles = [
  "index.html",
  "styles.css",
  "script.js",
  "recording-script.md",
  "README.md",
  "assets/miu-loaf.gif",
  "assets/miu-peek.gif",
  "assets/miu-edge-walk.gif",
  "assets/miu-stretch.gif",
  "assets/miu-sleep.gif",
  "assets/miu-celebrate.gif",
  "assets/phase1-contact-sheet.png",
  "assets/app-icon-1024.png"
];

const requiredHtmlMarkers = [
  "viewport",
  "data-section=\"hero\"",
  "data-section=\"work\"",
  "data-section=\"leisure\"",
  "data-section=\"reminders\"",
  "data-section=\"signals\"",
  "data-section=\"privacy\"",
  "data-section=\"investor\"",
  "data-demo-step",
  "id=\"startDemo\"",
  "id=\"nextStep\"",
  "id=\"prevStep\"",
  "id=\"pauseDemo\"",
  "assets/miu-loaf.gif",
  "assets/miu-peek.gif",
  "assets/miu-edge-walk.gif",
  "assets/miu-stretch.gif",
  "assets/miu-sleep.gif",
  "assets/miu-celebrate.gif"
];

const requiredCssMarkers = [
  "@media (max-width: 720px)",
  "@keyframes",
  "prefers-reduced-motion",
  ".desktop-mock",
  ".pet-stage",
  ".recording-active",
  ".reminder-bubble"
];

const requiredJsMarkers = [
  "const demoSteps",
  "function startDemo",
  "function showStep",
  "function handleReminderAction",
  "function setFlowStep",
  "addEventListener"
];

function read(file) {
  return fs.readFileSync(path.join(root, file), "utf8");
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

for (const file of requiredFiles) {
  assert(fs.existsSync(path.join(root, file)), `Missing required file: ${file}`);
}

const html = read("index.html");
const css = read("styles.css");
const js = read("script.js");
const script = read("recording-script.md");
const readme = read("README.md");

for (const marker of requiredHtmlMarkers) {
  assert(html.includes(marker), `index.html missing marker: ${marker}`);
}

for (const marker of requiredCssMarkers) {
  assert(css.includes(marker), `styles.css missing marker: ${marker}`);
}

for (const marker of requiredJsMarkers) {
  assert(js.includes(marker), `script.js missing marker: ${marker}`);
}

assert((html.match(/data-section=/g) || []).length >= 7, "index.html must include at least seven demo sections");
assert((html.match(/<img /g) || []).length >= 6, "index.html must include at least six image or GIF visuals");
assert((html.match(/data-demo-step=/g) || []).length >= 6, "index.html must include at least six recording demo steps");
assert(script.includes("0:00-0:20"), "recording script missing opening timestamp");
assert(script.includes("2:35-3:00"), "recording script missing closing timestamp");
assert(readme.includes("open investor-demo/index.html"), "README missing direct-open instruction");

console.log("Investor demo validation passed.");
