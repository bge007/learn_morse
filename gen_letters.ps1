<#
  Generate spoken LETTER-NAME clips (A-Z) into spoken/ using Windows TTS.
  Produces spoken/a.mp3 ... spoken/z.mp3 (pronounced as letter names: "ay","bee",...).
  Requires ffmpeg on PATH for .mp3 output (otherwise writes .wav).

  Usage:
    powershell -ExecutionPolicy Bypass -File gen_letters.ps1
    powershell -ExecutionPolicy Bypass -File gen_letters.ps1 -Voice "Microsoft Zira Desktop"
#>
param(
  [string]$OutDir = "spoken",
  [string]$Voice = "",
  [int]$Rate = -1
)

Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synth.Rate = $Rate
$synth.Volume = 100
if ($Voice -ne "") { try { $synth.SelectVoice($Voice) } catch { Write-Output "Voice '$Voice' not found; using $($synth.Voice.Name)" } }
Write-Output "Voice: $($synth.Voice.Name)"

$out = Join-Path (Get-Location) $OutDir
New-Item -ItemType Directory -Force -Path $out | Out-Null
$ff = Get-Command ffmpeg -ErrorAction SilentlyContinue

foreach ($i in 65..90) {
  $L = [char]$i
  $key = ([string]$L).ToLower()
  $wav = Join-Path $out "$key.wav"
  $synth.SetOutputToWaveFile($wav)
  $ssml = "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'><say-as interpret-as='characters'>$L</say-as></speak>"
  try { $synth.SpeakSsml($ssml) } catch { $synth.Speak([string]$L) }
  $synth.SetOutputToNull()
  if ($ff) {
    $mp3 = Join-Path $out "$key.mp3"
    & ffmpeg -y -hide_banner -loglevel error -i $wav -codec:a libmp3lame -b:a 192k $mp3
    Remove-Item $wav -Force
  }
}
$synth.Dispose()
Write-Output "Done -> $OutDir\a.mp3 .. z.mp3"
