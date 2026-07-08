// Copies the web app (index.html) into www/, which Capacitor bundles into the
// Android app and serves over an https origin. Speech is synthesized live via
// the Web Speech API, so no audio assets are needed.
import { cpSync, rmSync, mkdirSync, existsSync } from "node:fs";

if (existsSync("www")) rmSync("www", { recursive: true, force: true });
mkdirSync("www", { recursive: true });
cpSync("index.html", "www/index.html");
console.log("Copied index.html -> www/");
