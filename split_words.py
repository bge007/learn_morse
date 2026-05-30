#!/usr/bin/env python3
"""
Split an audio file into individual word/segment files using audio energy level.

It measures loudness (dBFS) over time and treats stretches quieter than a
threshold, lasting at least `--min-silence` ms, as gaps between words. Each
remaining loud region is exported as its own file, named in time order:
a, b, c, d, ... (then seg27, seg28, ... beyond 26).

Examples:
    python split_words.py abcd.mp3
    python split_words.py abcd.mp3 --threshold -33 --min-silence 500 --pad 80
    python split_words.py voice.mp3 --format wav --outdir words
"""
import argparse
import os
import string
import sys

from pydub import AudioSegment
from pydub.silence import detect_nonsilent


def seg_name(i: int) -> str:
    """a, b, ... z, then seg27, seg28, ..."""
    return string.ascii_lowercase[i] if i < 26 else f"seg{i + 1}"


def fmt_ms(ms: float) -> str:
    return f"{ms / 1000:.2f}s"


def main() -> int:
    ap = argparse.ArgumentParser(description="Energy-based audio word splitter")
    ap.add_argument("input", nargs="?", default="abcd.mp3", help="input audio file (default: abcd.mp3)")
    ap.add_argument("--threshold", type=float, default=None,
                    help="silence threshold in dBFS (e.g. -33). Default: adaptive (avg loudness - 16 dB)")
    ap.add_argument("--min-silence", type=int, default=500,
                    help="minimum gap length in ms to count as a split (default: 500)")
    ap.add_argument("--pad", type=int, default=80,
                    help="ms of audio kept on each side of a segment so words aren't clipped (default: 80)")
    ap.add_argument("--format", default=None,
                    help="output format: wav, mp3, ... (default: same as input extension)")
    ap.add_argument("--bitrate", default="192k", help="bitrate for lossy output formats (default: 192k)")
    ap.add_argument("--outdir", default="words", help="output directory (default: words)")
    args = ap.parse_args()

    if not os.path.isfile(args.input):
        print(f"ERROR: file not found: {args.input}", file=sys.stderr)
        return 1

    out_fmt = (args.format or os.path.splitext(args.input)[1].lstrip(".") or "wav").lower()

    print(f"Loading {args.input} ...")
    audio = AudioSegment.from_file(args.input)
    dur = len(audio)
    avg = audio.dBFS
    thresh = args.threshold if args.threshold is not None else round(avg - 16, 1)
    print(f"  duration {fmt_ms(dur)}  avg {avg:.1f} dBFS  peak {audio.max_dBFS:.1f} dBFS")
    print(f"  using threshold {thresh} dBFS, min gap {args.min_silence} ms, pad {args.pad} ms\n")

    spans = detect_nonsilent(audio, min_silence_len=args.min_silence,
                             silence_thresh=thresh, seek_step=5)
    if not spans:
        print("No segments detected. Try a higher (less negative) --threshold or smaller --min-silence.",
              file=sys.stderr)
        return 2

    os.makedirs(args.outdir, exist_ok=True)
    print(f"Detected {len(spans)} segment(s) -> {args.outdir}/\n")
    print(f"  {'name':<6}{'start':>8}{'end':>9}{'length':>9}   file")

    results = []
    for i, (start, end) in enumerate(spans):
        s = max(0, start - args.pad)
        e = min(dur, end + args.pad)
        name = seg_name(i)
        out_path = os.path.join(args.outdir, f"{name}.{out_fmt}")
        chunk = audio[s:e]
        export_kwargs = {"format": out_fmt}
        if out_fmt in ("mp3", "m4a", "aac", "ogg", "opus"):
            export_kwargs["bitrate"] = args.bitrate
        chunk.export(out_path, **export_kwargs)
        results.append((name, start, end, len(chunk), out_path))
        print(f"  {name + '.' + out_fmt:<6}{fmt_ms(start):>8}{fmt_ms(end):>9}{fmt_ms(len(chunk)):>9}   {out_path}")

    print(f"\nDone. Wrote {len(results)} file(s) to {os.path.abspath(args.outdir)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
