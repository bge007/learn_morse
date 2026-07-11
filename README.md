# Morse Code Studio

Convert text to **Morse code**, hear it as a configurable tone (default **700 Hz**),
optionally **hear each letter or whole word spoken** by live **Text-to-Speech** —
before or after its Morse, in any voice your device offers — watch it on a
**9:16 animated display**, and export it as an **audio (`.wav`)** or
**video (`.mp4`)** file.

One codebase runs everywhere: a single-file web app (`index.html`, no build step)
for any browser on Windows / Linux / macOS, and the same file packaged as a native
**Android app** (Capacitor) with a tabbed, full-screen mobile UI. iOS needs only
`npx cap add ios` on a Mac.

**Current version: 1.7** (Android `versionCode 8`).

- **Web app:** open `index.html` over a local HTTP server.
- **Android app:** download the ready-made APK from the
  [Releases page](https://github.com/bge007/learn_morse/releases), or build it
  yourself (see [Build the Android app](#build-the-android-app-apk-from-scratch)).

---

## Table of contents

- [Features](#features)
- [Repository layout](#repository-layout)
- [Quick start — run the web app](#quick-start--run-the-web-app)
- [Prerequisites (full toolchain)](#prerequisites-full-toolchain)
- [Build the Android app (APK) from scratch](#build-the-android-app-apk-from-scratch)
- [Install the APK on a phone](#install-the-apk-on-a-phone)
- [Speech (Text-to-Speech)](#speech-text-to-speech)
- [Configuration reference](#configuration-reference)
- [How it works](#how-it-works)
- [Troubleshooting](#troubleshooting)

---

## Features

- **Text → Morse → sound** via the Web Audio API; a clean sine tone with click-free edges.
- **Adjustable timing & tone:** frequency (700 Hz), dot (92 ms) and dash (277 ms)
  durations, and the gaps between elements, letters, and words. Live WPM + total duration.
- **Practice presets** — one-tap fill buttons above the message box:
  **HW** (HELLO WORLD), **E–H** (E I S H — the dots drill), **E–J** (E A W J —
  dot-to-dash drill), **T–O** (T M O — the dashes drill), and **A–Z** (all 26
  letters, space-separated so each gets a word gap).
- **Spoken letters and words** via live Text-to-Speech — no audio files. Native OS
  speech engine inside the Android app, `speechSynthesis` in browsers:
  - *Each letter (on change)* — a letter's name is spoken alongside its Morse
    (`AAAA` → key it four times, say "A" once).
  - *Whole word* — the word is spoken alongside its Morse.
- **Voice picker** — choose any Text-to-Speech voice the device offers
  (male / female / regional variants such as English (India)); persisted.
- **Speak order (⇅ Order)** — choose whether each letter/word is spoken **after**
  its Morse (default — hear the code, then the answer) or **before** it
  (hear the name, then the code); persisted.
- **9:16 animated display** synced to the audio (amber while keyed, blue while spoken),
  with a height-capped scrolling Morse preview on the Practice screen.
- **Loop** — repeat the whole message until stopped.
- **Pause / Resume** — freeze playback mid-message (tones, animation, and pending
  speech all halt together) and continue exactly where it left off; Space bar
  toggles it on desktop.
- **Screen stays awake during playback** — the app holds a wake lock while playing
  or recording (native keep-awake plugin in the app, Screen Wake Lock API in
  browsers) so Android's screen timeout can't silence TTS mid-message; released
  as soon as playback stops.
- **Export:** `.wav` (offline render) and a **1080×1920 `.mp4`** (H.264/AAC via
  MediaRecorder). Exports contain the Morse tones (TTS speech is live-only; its
  timing windows are preserved as silence).
- **Android app:** Practice / Settings tabs (speech + timing options live under
  Settings), a full-screen player, and a full-screen video result screen;
  hardware-back aware.

---

## Repository layout

```
index.html            The entire web app (HTML + CSS + JS, ~1,400 lines, no build step)
copy-web.mjs          Mirrors index.html into www/ for the Android build
capacitor.config.json Capacitor app config (id com.morsestudio.app)
package.json          npm scripts + Capacitor deps (incl. the native TTS plugin)
android/              Generated Capacitor Android (Gradle) project
MASTER_PROMPT.md      Architecture guide + full development history (read before forking)
.claude/launch.json   Dev preview server config
```

---

## Quick start — run the web app

```bash
git clone https://github.com/bge007/learn_morse.git
cd learn_morse

# any static server works — pick one:
python -m http.server 8753          # Python 3
#   npx serve -l 8753                # Node
```

Open **http://localhost:8753/**, type a message (or press **A–Z**), and press **Play**.

Speech is synthesized live by the browser's Web Speech API — no audio files are
fetched, so the app also works opened directly as a `file://` page, though a local
HTTP server is still recommended.

---

## Prerequisites (full toolchain)

You only need the full toolchain to **build the Android app**. Running the web app
needs only a static file server (or just a browser).

| Tool | Version | Used for | Get it |
|------|---------|----------|--------|
| **Node.js** | ≥ 18 (tested 22/24) | Capacitor CLI, `copy-web.mjs` | https://nodejs.org |
| **JDK** | **17** (required by Capacitor 6) | Gradle / Android build | https://adoptium.net |
| **Android SDK** | platform **34**, build-tools **34.x**, platform-tools, cmdline-tools | building/installing the APK | Android Studio, or `cmdline-tools` |

### Installing the Android SDK without Android Studio (command line)

1. Download the **Command-line Tools** from <https://developer.android.com/studio#command-line-tools>
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
gradlew.bat assembleDebug    # Windows (run from android/, not via npm, in PowerShell)
./gradlew assembleDebug      # macOS / Linux
```

The APK is written to:

```
android/app/build/outputs/apk/debug/app-debug.apk
```

> First build downloads Gradle (~150 MB) and Android dependencies; later builds take
> ~30 s. App id `com.morsestudio.app`, minSdk 22, target/compileSdk 34.

### Release build (for distribution)

```bash
cd android && ./gradlew assembleRelease
```
…then sign the output with your keystore (`apksigner`) or wire `signingConfigs` into
`android/app/build.gradle`. Debug builds are self-signed and fine for sideloading.

---

## Install the APK on a phone

- **Copy & tap:** copy `app-debug.apk` to your phone, tap it, and allow
  "install from unknown sources".
- **ADB (USB):** enable Developer Options → USB debugging, connect, then:
  ```bash
  adb install -r android/app/build/outputs/apk/debug/app-debug.apk
  ```

---

## Speech (Text-to-Speech)

Speech is generated live — there are no audio files to generate or ship. One speech
abstraction picks the right backend per platform at runtime:

| Platform | Backend |
|---|---|
| Android / iOS app | `@capacitor-community/text-to-speech` → native OS speech engine |
| Windows / Linux / macOS browsers | Web Speech API (`speechSynthesis`) |

The native plugin is required on Android because the **Android System WebView does
not implement the Web Speech API** (Chrome does; a WebView shell doesn't).

- The **Voice** dropdown (Settings tab → Speech) lists every TTS voice the backend
  offers (e.g. male/female variants, English (India), other languages). The choice
  is persisted in `localStorage`.
- **Auto (English)** picks the default English voice.
- Utterance durations are estimated up front and refined with measured durations
  after the first playback, so the timeline stays accurate.
- On Android, voices come from the device's TTS engine (usually Google TTS) —
  install more voices via Settings → Accessibility → Text-to-speech output.

---

## Configuration reference

Set in the app's **Settings** tab (persisted in `localStorage`):

| Setting | Default | Meaning |
|---|---|---|
| Speak | Each letter | Off / Each letter / Whole word |
| Voice | Auto (English) | Any TTS voice the platform offers |
| Order | Morse first | Speech before or after each letter's Morse |
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

- **Timing model:** `buildPlan()` lays out every letter as Morse elements plus an
  optional spoken window (letter name or whole word) — before or after the Morse,
  per the ⇅ Order setting — in offsets from zero. Renderers add a start time.
- **Audio:** one oscillator runs continuously and a gain node gates it per element
  (click-free ramps).
- **Speech:** one abstraction, two backends — the Capacitor TTS plugin inside the
  app, `speechSynthesis` in browsers. Utterances can't be scheduled on an
  AudioContext, so they are queued with absolute audio-clock times and fired from
  the animation loop — keeping speech and Morse in sync. Durations start as
  estimates and are refined from measured playback.
- **Display:** a `requestAnimationFrame` loop reads `AudioContext.currentTime` to drive
  the 9:16 view; the same draw logic renders to a `<canvas>` for video.
- **Export:** WAV via `OfflineAudioContext`; MP4 via `canvas.captureStream()` + a
  `MediaStreamDestination` fed to `MediaRecorder` (real-time capture). TTS audio
  cannot be routed into either, so exports carry the tones with the speech windows
  left silent.
- **Android:** Capacitor serves `www/` over an `https://localhost` origin inside a
  WebView, so everything works unchanged.

---

## Troubleshooting

- **No speech (browser):** check that the browser supports the Web Speech API
  (all modern browsers do) and that the Speak mode isn't *Off*.
- **No speech (Android app):** make sure a TTS engine with English voices is
  installed (Settings → Accessibility → Text-to-speech output). Speech in the app
  uses the native engine via a Capacitor plugin — if you built the APK yourself,
  run `npm install` and `npx cap sync android` before `gradlew assembleDebug` so
  the plugin is bundled.
- **Voice list is empty at first:** voices load asynchronously; the list fills a
  moment after the page opens (the app re-populates on `voiceschanged`).
- **Gradle can't find the SDK:** set `ANDROID_HOME` or create `android/local.properties`
  with `sdk.dir=…`. Ensure `platforms;android-34` and `build-tools;34.0.0` are installed.
- **Gradle/JDK error:** Capacitor 6 needs **JDK 17**. Point `JAVA_HOME` at a JDK 17.
- **`npm run apk` fails in PowerShell:** run `.\gradlew.bat assembleDebug` directly
  from the `android/` directory instead.
- **`.wav` / `.mp4` won't save in the Android app:** the export buttons use browser
  blob-download / Web Share, which a plain WebView may not fully honor. Native
  save/share (Capacitor Filesystem + Share) is a known follow-up.
- **Exports have no speech:** expected — TTS is live-only; exports contain the Morse
  tones with the speech windows as silence.
- **MP4 vs WebM:** the recorder prefers MP4 (H.264/AAC) and falls back to WebM where
  MP4 recording isn't supported.
