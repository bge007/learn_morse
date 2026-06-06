# Morse Code Studio

Convert text to **Morse code**, hear it as a configurable tone (default **700 Hz**),
optionally **speak each letter or whole word** before its Morse, watch it on a **9:16
animated display**, and export it as an **audio (`.wav`)** or **video (`.mp4`)** file.

It runs as a single, dependency‑free web app (`index.html`) and is also packaged as an
**Android app** (a Capacitor WebView shell) with a tabbed, full‑screen mobile UI.

- **Web app:** open `index.html` over a local HTTP server.
- **Android app:** install the prebuilt APK from
  [**Releases**](https://github.com/0xab1e/learn_morse/releases), or build it yourself
  (see [Build the Android app](#build-the-android-app-apk-from-scratch)).

---

## Table of contents

- [Features](#features)
- [Repository layout](#repository-layout)
- [Quick start — run the web app](#quick-start--run-the-web-app)
- [Prerequisites (full toolchain)](#prerequisites-full-toolchain)
- [Build the Android app (APK) from scratch](#build-the-android-app-apk-from-scratch)
- [Install the APK on a phone](#install-the-apk-on-a-phone)
- [Generating / adding spoken audio](#generating--adding-spoken-audio)
- [`split_words.py` — energy-based audio splitter](#split_wordspy--energy-based-audio-splitter)
- [Configuration reference](#configuration-reference)
- [How it works](#how-it-works)
- [Troubleshooting](#troubleshooting)

---

## Features

- **Text → Morse → sound** via the Web Audio API; a clean sine tone with click‑free edges.
- **Adjustable timing & tone:** frequency (700 Hz), dot (92 ms) and dash (277 ms)
  durations, and the gaps between elements, letters, and words. Live WPM + total duration.
- **Speak‑before‑Morse** modes:
  - *Each letter (on change)* — speaks a letter when it differs from the previous one
    (`AAAA` → say "A" once, then key it four times).
  - *Whole word* — speaks the word, then keys its Morse (falls back to spelling letters
    for any word without a clip).
- **9:16 animated display** synced to the audio (blue while spoken, amber while keyed).
- **Loop** — repeat the whole message until stopped.
- **Export:** `.wav` (offline render) and a **1080×1920 `.mp4`** (H.264/AAC via
  MediaRecorder), both including the spoken clips.
- **Android app:** Create / Settings tabs, a full‑screen player, and a full‑screen video
  result screen; hardware‑back aware.

---

## Repository layout

```
index.html            The entire web app (HTML + CSS + JS, no build step)
spoken/               A–Z letter-name clips  (a.mp3 … z.mp3)
spoken/words/         Whole-word clips        (hello.mp3, world.mp3, …)
words/                Example output of split_words.py (a–d from abcd.mp3)
abcd.mp3              Example source audio

gen_letters.ps1       Windows-TTS generator for the A–Z letter clips
gen_words.ps1         Windows-TTS generator for whole-word clips
split_words.py        Energy-based audio splitter (pydub + ffmpeg)
copy-web.mjs          Mirrors index.html + spoken/ into www/ for the Android build

capacitor.config.json Capacitor app config (id com.morsestudio.app)
package.json          npm scripts + Capacitor deps
android/              Generated Capacitor Android (Gradle) project
.claude/launch.json   Dev preview server config (python http.server :8753)
```

---

## Quick start — run the web app

The app `fetch()`es the spoken clips, so serve it over HTTP (don't open `file://`):

```bash
git clone https://github.com/0xab1e/learn_morse.git
cd learn_morse

# any static server works — pick one:
python -m http.server 8753          # Python 3
#   npx serve -l 8753                # Node
```

Open **http://localhost:8753/**, type a message, and press **Play**. (Opened directly as
a `file://` page it still plays Morse, but browsers block the speech‑clip `fetch`, so
spelling/word audio is disabled — use the local server for the full experience.)

---

## Prerequisites (full toolchain)

You only need the full toolchain to **build the Android app** or **regenerate audio**.
Running the web app needs only a static file server.

| Tool | Version | Used for | Get it |
|------|---------|----------|--------|
| **Node.js** | ≥ 18 (tested 22) | Capacitor CLI, `copy-web.mjs` | https://nodejs.org |
| **JDK** | **17** (required by Capacitor 6) | Gradle / Android build | https://adoptium.net |
| **Android SDK** | platform **34**, build‑tools **34.x**, platform‑tools, cmdline‑tools | building/installing the APK | Android Studio, or `cmdline-tools` |
| **ffmpeg** | any recent | audio scripts + clip conversion | https://ffmpeg.org |
| **Python** | 3.9+ | `split_words.py` | https://python.org |
| **pydub** | latest | `split_words.py` | `pip install pydub` |

### Installing the Android SDK without Android Studio (command line)

1. Download the **Command‑line Tools** from <https://developer.android.com/studio#command-line-tools>
   and unzip to e.g. `C:\Android\cmdline-tools\latest\`.
2. Install the needed packages and accept licenses:
   ```bash
   sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
   sdkmanager --licenses
   ```
3. Point tools at the SDK with the **`ANDROID_HOME`** environment variable
   (e.g. `C:\Android`), or create `android/local.properties` (see below).

> JDK 17 must be the one Gradle uses. Set **`JAVA_HOME`** to your JDK 17 install.

---

## Build the Android app (APK) from scratch

From a fresh clone:

```bash
# 1. install the Capacitor toolchain
npm install

# 2. (only if android/ is missing for some reason) regenerate the native project
#    npx cap add android

# 3. tell Gradle where your Android SDK is — EITHER set ANDROID_HOME,
#    OR create android/local.properties with a single line:
#       sdk.dir=C:/Path/to/Android/Sdk          (Windows: use forward slashes)
#       sdk.dir=/Users/you/Library/Android/sdk  (macOS)

# 4. copy the web app into www/ and sync it into the native project
npm run build:web          # = node copy-web.mjs
npx cap sync android

# 5. build the debug APK
cd android
gradlew.bat assembleDebug    # Windows
./gradlew assembleDebug      # macOS / Linux
```

The APK is written to:

```
android/app/build/outputs/apk/debug/app-debug.apk
```

**Windows one‑liner** (steps 4–5): `npm run apk`

> First build downloads Gradle (~150 MB) and Android dependencies; later builds take
> ~30 s. App id `com.morsestudio.app`, minSdk 22, target/compileSdk 34.

### Release build (for distribution)

```bash
cd android && ./gradlew assembleRelease
```
…then sign the output with your keystore (`apksigner`) or wire `signingConfigs` into
`android/app/build.gradle`. The committed builds are **debug** (self‑signed, fine for
sideloading).

---

## Install the APK on a phone

- **Download:** grab `MorseCodeStudio-debug.apk` from the
  [Releases page](https://github.com/0xab1e/learn_morse/releases), copy it to your phone,
  tap it, and allow "install from unknown sources".
- **ADB (USB):** enable Developer Options → USB debugging, connect, then:
  ```bash
  adb install -r android/app/build/outputs/apk/debug/app-debug.apk
  ```

---

## Generating / adding spoken audio

The clips are already committed, so a fresh clone needs nothing. To regenerate or add
more (Windows, uses the built‑in SAPI voices + ffmpeg):

```powershell
# A–Z letter names -> spoken/a.mp3 … z.mp3
powershell -ExecutionPolicy Bypass -File gen_letters.ps1

# whole words -> spoken/words/<word>.mp3
powershell -ExecutionPolicy Bypass -File gen_words.ps1 hello world "good morning"
powershell -ExecutionPolicy Bypass -File gen_words.ps1 -ListVoices    # list installed voices
```

After adding clips, re‑sync the Android assets (`npm run build:web && npx cap sync android`)
and rebuild. In *Whole word* mode the app uses `spoken/words/<word>.mp3` when present and
otherwise spells the word letter by letter.

---

## `split_words.py` — energy-based audio splitter

Splits an audio file into individual segments using loudness (silence) detection and names
them in order `a, b, c, …`. Requires `pip install pydub` and `ffmpeg` on PATH.

```bash
python split_words.py abcd.mp3                          # -> words/a.mp3 … d.mp3
python split_words.py voice.mp3 --min-silence 500 --threshold -33 --pad 80
python split_words.py clip.mp3 --format wav --outdir parts
```

Key options: `--threshold` (dBFS, default adaptive ≈ avg − 16), `--min-silence` (ms,
default 500), `--pad` (ms kept around each segment, default 80), `--format`, `--outdir`.

---

## Configuration reference

Set in the app's **Settings** tab (persisted in `localStorage`):

| Setting | Default | Meaning |
|---|---|---|
| Tone frequency | 700 Hz | Pitch of the Morse tone |
| Dot duration | 92 ms | Length of a `·` (1 unit) |
| Dash duration | 277 ms | Length of a `−` (≈ 3 units) |
| Gap between sounds | 92 ms | Silence between elements within a letter |
| Gap between letters | 277 ms | Silence between letters |
| Gap between words | 645 ms | Silence between words |
| Volume | 70 % | Output level |

Defaults follow standard Morse ratios at a 92 ms dot (≈ 13 WPM).

---

## How it works

- **Timing model:** `buildPlan()` lays out every letter as optional spoken‑clip time +
  Morse elements, in offsets from zero. Renderers add a start time.
- **Audio:** one oscillator runs continuously and a gain node gates it per element
  (click‑free ramps); spoken clips are decoded `AudioBuffer`s scheduled on the same clock,
  so speech and Morse stay perfectly sequenced.
- **Display:** a `requestAnimationFrame` loop reads `AudioContext.currentTime` to drive the
  9:16 view; the same draw logic renders to a `<canvas>` for video.
- **Export:** WAV via `OfflineAudioContext`; MP4 via `canvas.captureStream()` + a
  `MediaStreamDestination` fed to `MediaRecorder` (real‑time capture).
- **Android:** Capacitor serves `www/` over an `https://localhost` origin inside a
  WebView, so all of the above (including the speech‑clip `fetch`) works unchanged.

---

## Troubleshooting

- **No speech / "fetch" errors** when opening `index.html` directly: serve over HTTP
  (`python -m http.server`). `file://` blocks the clip fetches.
- **Gradle can't find the SDK:** set `ANDROID_HOME` or create `android/local.properties`
  with `sdk.dir=…`. Ensure `platforms;android-34` and `build-tools;34.0.0` are installed.
- **Gradle/JDK error:** Capacitor 6 needs **JDK 17**. Point `JAVA_HOME` at a JDK 17.
- **`.wav` / `.mp4` won't save in the Android app:** the export buttons use browser
  blob‑download / Web Share, which a plain WebView may not fully honor. Native
  save/share (Capacitor Filesystem + Share) is a known follow‑up. Playback, the live
  player, and the full‑screen video preview all work.
- **MP4 vs WebM:** the recorder prefers MP4 (H.264/AAC) and falls back to WebM where MP4
  recording isn't supported.
