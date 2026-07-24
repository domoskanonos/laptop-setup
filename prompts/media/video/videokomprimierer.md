# Videokomprimierer (CUDA + NVENC)

Lade ein Video runter und komprimiere es mit ffmpeg und NVIDIA-Hardwarecodierung.

## Befehl

```bash
# Download
wget -O "<dateiname_input>.mp4" "<url>"

# Komprimieren (HEVC / NVENC)
ffmpeg -hwaccel cuda -i "<dateiname_input>.mp4" \
  -c:v hevc_nvenc -preset p6 -cq 24 -rc constqp \
  -c:a aac -b:a 128k \
  "<dateiname_output>.mkv"
```

## Parameter

| Parameter | Bedeutung |
|---|---|
| `-hwaccel cuda` | GPU-Hardwarebeschleunigung |
| `-c:v hevc_nvenc` | HEVC (H.265) via NVIDIA NVENC |
| `-preset p6` | Qualitäts-Preset (p1 = schnell, p7 = beste Qualität) |
| `-cq 24` | Constrained Quality (niedriger = besser, ~24 ist guter Kompromiss) |
| `-rc constqp` | Constant Quantisierung (gleichbleibende Qualität) |
| `-c:a aac -b:a 128k` | AAC-Audio mit 128 kbit/s |
| Output `.mkv` | Matroska-Container für HEVC |

## Voraussetzung

```bash
ffmpeg -encoders 2>/dev/null | grep hevc_nvenc
# → muss etwas ausgeben
```
