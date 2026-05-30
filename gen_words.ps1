<#
  Generate spoken-WORD audio clips with Windows TTS, for the Morse app's "Word mode".
  Each word becomes spoken/words/<sanitized-word>.mp3 (lowercase, alphanumerics only).

  Usage:
    powershell -ExecutionPolicy Bypass -File gen_words.ps1 hello world "good morning"
    powershell -ExecutionPolicy Bypass -File gen_words.ps1 -Voice "Microsoft David Desktop" cat dog
    powershell -ExecutionPolicy Bypass -File gen_words.ps1 -ListVoices
#>
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Words,
  [string]$OutDir = "spoken\words",
  [string]$Voice = "",
  [int]$Rate = -1,
  [switch]$ListVoices
)

Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer

if ($ListVoices) {
  $synth.GetInstalledVoices() | ForEach-Object { Write-Output $_.VoiceInfo.Name }
  $synth.Dispose(); exit 0
}
if (-not $Words -or $Words.Count -eq 0) {
  Write-Output 'Usage: gen_words.ps1 hello world "good morning"'
  $synth.Dispose(); exit 1
}

$synth.Rate = $Rate
$synth.Volume = 100
if ($Voice -ne "") { try { $synth.SelectVoice($Voice) } catch { Write-Output "Voice '$Voice' not found; using $($synth.Voice.Name)" } }
Write-Output "Voice: $($synth.Voice.Name)"

$out = Join-Path (Get-Location) $OutDir
New-Item -ItemType Directory -Force -Path $out | Out-Null
$ff = Get-Command ffmpeg -ErrorAction SilentlyContinue

foreach ($w in $Words) {
  $key = ($w.ToLower() -replace '[^a-z0-9]+', '')
  if (-not $key) { Write-Output "skip '$w' (no alphanumerics)"; continue }
  $wav = Join-Path $out "$key.wav"
  $synth.SetOutputToWaveFile($wav)
  $synth.Speak($w)
  $synth.SetOutputToNull()
  if ($ff) {
    $mp3 = Join-Path $out "$key.mp3"
    & ffmpeg -y -hide_banner -loglevel error -i $wav -codec:a libmp3lame -b:a 192k $mp3
    Remove-Item $wav -Force
    Write-Output "  '$w' -> $OutDir\$key.mp3"
  } else {
    Write-Output "  '$w' -> $OutDir\$key.wav  (install ffmpeg to get .mp3)"
  }
}
$synth.Dispose()
Write-Output "Done."
