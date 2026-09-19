# Bundled typefaces

The app sets type in the same two faces the web registry loads from Google Fonts,
so both versions look alike. Both are under the SIL Open Font License 1.1.

- `InstrumentSerif-Regular.ttf`, `InstrumentSerif-Italic.ttf` — Instrument Serif
  by Rodrigo Fuenzalida and Jordan Egstad.
- `JetBrainsMono.ttf`, `JetBrainsMono-Italic.ttf` — JetBrains Mono by JetBrains
  (variable weight axis).

They are registered at launch by `AppFonts` in `Theme/Theme.swift`. If
registration ever fails the app falls back to New York and SF Mono.
