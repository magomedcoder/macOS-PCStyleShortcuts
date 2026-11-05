# PC Style Shortcuts

Remaps keyboard shortcuts to PC-style defaults (Windows/Linux habits) and lets you change any binding.

## Features

- PC Style defaults out of the box (Ctrl+C/V, Home/End, word jumps, and more)
- One Settings window: remapping, Accessibility, startup, appearance, and all keys
- Per-action enable/disable and custom trigger chord
- Categories: Language, Editing, Navigation, Window, Browser
- Reset all bindings to PC Style with one button
- Smart terminal Ctrl+C/Z/X: in a terminal pane without selection they stay shell shortcuts; with selection or in an editor they remap (optional, on by default)
- Language switch: **⌥⇧** next layout, **⌥⌃** previous (no Space key)
- Launch at Login, optional Dock icon
- English and Russian UI

## Install

1. Open `PCStyleShortcuts.xcodeproj` in Xcode 27.2+
2. Run **PCStyleShortcuts**
3. System Settings -> Privacy & Security -> Accessibility -> enable the app  
   (or use **Open Accessibility Settings** in the app)
4. Customize keys from the menu bar -> **Settings...**

## Default highlights

| Action                       | Default                     |
| ---------------------------- | --------------------------- |
| Copy / Paste / Cut / Undo    | Ctrl+letter -> Cmd+letter   |
| Redo                         | Ctrl+Shift+Z -> Cmd+Shift+Z |
| Home / End                   | -> Cmd+<- / Cmd+->          |
| Word jump                    | Ctrl+<-/-> -> Option+<-/->  |
| Next / previous input source | ⌥⇧ / ⌥⌃                     |
| Browser zoom / refresh       | Off until enabled           |

## Develop

```bash
xcodebuild -scheme PCStyleShortcuts -destination 'platform=macOS' build
xcodebuild -scheme PCStyleShortcuts -destination 'platform=macOS' test
```

Russian README: [README-ru.md](README-ru.md)
