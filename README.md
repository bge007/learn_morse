# Morse Code Studio

A self-contained, local web app that converts text to Morse code and plays it as a
configurable tone (default **700 Hz**) — with optional spoken letters/words, a 9:16
visual display, audio (`.wav`) and video (`.mp4`) export, and looping.

Everything runs in the browser with no build step or dependencies. The only external
files are the spoken-audio clips in `spoken/`.

## Run it

The app fetches the spoken clips, so serve it over HTTP (don't just open `file://`):

```bash
python -m http.server 8753
# then open http://localhost:8753/
```

(With no spelling/word audio it also works opened directly as a file; speech needs HTTP.)

## Features

- **Text → Morse → sound** using the Web Audio API; clean sine tone with click-free edges.
- **Config:** tone frequency (700 Hz), dot (92 ms) and dash (277 ms) durations, and the
  gaps between elements, letters, and words — all adjustable. Effective WPM and total
  duration are shown live.
- **Speak before Morse** (mode selector):
  - *Each letter (on change)* — speaks a letter when it differs from the previous one
    (e.g. `AAAA` says "A" once, then keys it four times).
  - *Whole word* — speaks the word, then keys its Morse (falls back to spelling letters
    for any word without a clip).
- **9:16 display** — the current letter/word animates in sync (blue while spoken, amber
  while keyed), with the dot/dash pattern and a caption.
- **Export:** `Download .wav` (offline render) and `Generate video (9:16)` → `.mp4`
  (H.264/AAC via MediaRecorder), both including the spoken clips.
- **Loop** — repeat the whole message until Stop.

## Spoken audio

- `spoken/a.mp3 … z.mp3` — letter-name clips (A–Z).
- `spoken/words/<word>.mp3` — whole-word clips.

Clips are generated with Windows TTS and trimmed/normalized at load time.

## Scripts

- **`gen_words.ps1`** — synthesize whole-word clips into `spoken/words/`:
  ```powershell
  powershell -ExecutionPolicy Bypass -File gen_words.ps1 hello world "good morning"
  powershell -ExecutionPolicy Bypass -File gen_words.ps1 -ListVoices
  ```
- **`split_words.py`** — split an audio file into individual segments by energy level
  (silence detection), named in order `a, b, c, …` (requires `pydub` + `ffmpeg`):
  ```bash
  python split_words.py abcd.mp3 --min-silence 500 --threshold -33
  ```

## Layout

```
index.html         the app (single file: HTML + CSS + JS)
spoken/            A–Z letter-name clips
spoken/words/      whole-word clips
words/             example output of split_words.py (a–d from abcd.mp3)
abcd.mp3           example source audio
gen_words.ps1      whole-word TTS generator
split_words.py     energy-based audio splitter
.claude/launch.json  preview-server config (python http.server on :8753)
```
