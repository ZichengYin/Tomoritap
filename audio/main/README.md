# Main audio replacements

Put replacement audio files here, named by the sound slot:

```text
0.wav
1.wav
2.mp3
...
31.wav
```

Then run this from the project root:

```powershell
powershell -ExecutionPolicy Bypass -File tools/update-main-audio.ps1
```

The player still asks for keys named `0.mp3` through `31.mp3`, so the script keeps those JSON keys for compatibility. The embedded audio data can still be WAV, MP3, OGG, M4A, AAC, or FLAC.
