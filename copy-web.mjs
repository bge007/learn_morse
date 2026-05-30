// Copies the web app (index.html + spoken/ clips) into www/, which Capacitor
// bundles into the Android app and serves over an https origin (so fetch works).
import { cpSync, rmSync, mkdirSync, existsSync } from "node:fs";

if (existsSync("www")) rmSync("www", { recursive: true, force: true });
mkdirSync("www", { recursive: true });
cpSync("index.html", "www/index.html");
cpSync("spoken", "www/spoken", { recursive: true });
console.log("Copied index.html + spoken/ -> www/");
