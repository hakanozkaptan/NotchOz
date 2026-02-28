# NotchOz

A macOS menu bar app that shows widgets in the **notch area** (or handler area on notchless displays). Inspired by the NotchNook concept.

## Screenshots

<img width="702" height="561" alt="Screenshot 2026-02-28 at 19 50 57" src="https://github.com/user-attachments/assets/3c6dea29-9ece-4338-ade3-165cbc4fd4c1" />
<img width="696" height="563" alt="Screenshot 2026-02-28 at 19 51 04" src="https://github.com/user-attachments/assets/64267b71-65be-48cc-b622-fc31d750c1aa" />
<img width="693" height="564" alt="Screenshot 2026-02-28 at 19 51 19" src="https://github.com/user-attachments/assets/b99fe47b-fa41-4787-ba14-f4c09c6cd575" />
<img width="695" height="566" alt="Screenshot 2026-02-28 at 19 51 35" src="https://github.com/user-attachments/assets/c63720b0-52e4-429d-ab7f-d3f90017c22a" />
<img width="313" height="263" alt="Screenshot 2026-02-28 at 19 52 36" src="https://github.com/user-attachments/assets/d14500dd-ca53-4fae-92d1-a3c3ed7d7501" />


## Requirements

- **macOS 14.0** or later
- Xcode 15+ (for development)

## Installation

1. Open the project in Xcode: `NotchWidgets.xcodeproj`
2. Swift Package dependencies will resolve automatically (DynamicNotchKit).
3. Build and run with **Product → Run** (⌘R).

The app does not appear in the Dock; it only shows an icon in the **menu bar** (next to the clock).

## Usage

- **Hover** the pointer over the top-center of the screen (Dynamic Island area) → the widget strip opens.
- **Click** the NotchOz icon in the menu bar → **Settings** or **Quit**.
- In **Settings** you can:
  - Choose which widgets are visible (toggle list, no reorder).
  - Set **weather** city (searchable list of 81 Turkish provinces).
  - Edit the **quick info** note shown in the notch.
- **Quit** closes the app.

## Language

The app supports **English** and **Turkish**. In Settings (sidebar footer), language is selected with **flag-only** buttons (🇬🇧 / 🇹🇷); no “System” option.

## Widgets

- **Clock** — Date and time (compact or expanded).
- **Weather** — Current conditions via Open-Meteo (no API key). City is chosen from a searchable list of **81 Turkish provinces** (e.g. İstanbul, Ankara, İzmir).
- **Music** — **Spotify** now playing: track name, artist, artwork, play/pause, previous/next, and a small bar visualizer. Requires Spotify to be installed and running.
- **Quick info** — Short note text configured in Settings, shown in the notch with a simple “NOT” style block.

## Weather API

Weather data is provided by [Open-Meteo](https://open-meteo.com/); no sign-up or API key is required. In Settings → Weather, pick a **city** from the list (or search); the list includes all 81 Turkish provinces with case-insensitive search (e.g. “istanbul” matches “İstanbul”).

## Permissions

The app does not request special permissions by default. Network access is used only for weather data and for loading Spotify artwork (asynchronously).

## Project structure

```
NotchWidgets/                     # Xcode project (app name: NotchOz)
├── NotchWidgetsApp.swift         # App entry point
├── Core/
│   ├── AppDelegate.swift         # Menu bar, logo, lifecycle
│   ├── NotchPresenter.swift      # Notch show/hide (DynamicNotchKit)
│   ├── WidgetRegistry.swift      # Widget list and order
│   ├── SettingsManager.swift     # UserDefaults (language, weather city, note, etc.)
│   ├── TurkishProvinces.swift    # 81 provinces for weather picker
│   ├── L10n.swift                # Localization (en/tr)
│   └── HoverTrackingView.swift   # Hover detection for notch
├── Widgets/
│   ├── WidgetProtocol.swift      # Widget contract
│   ├── ClockWidget.swift
│   ├── WeatherWidget.swift
│   ├── MusicWidget.swift         # Spotify now playing + controls
│   └── QuickInfoWidget.swift
├── UI/
│   ├── NotchContentView.swift    # Notch strip (music, clock, weather, note)
│   ├── MenuBarContentView.swift # Menu bar menu UI
│   ├── SettingsView.swift        # Tabs: Widgets, Weather, Quick info; language flags
│   └── WidgetPickerView.swift    # Widget toggles (checkboxes)
└── Resources/
    └── Assets.xcassets
```

## Releases

A **GitHub Action** (`.github/workflows/release.yml`) builds a DMG on `macos-14` with Xcode 16.2. The app is not signed/notarized on CI; users may need to allow it in **System Settings → Privacy & Security** the first time.

**Option A — Release from a tag**  
Push a version tag; the workflow creates a GitHub Release and attaches `NotchOz.dmg`:

```bash
git tag v1.0.0
git push origin v1.0.0
```

**Option B — Manual run (no tag)**  
Go to **Actions → Release DMG → Run workflow**. When the run finishes, download the DMG from the run’s **Artifacts** (no release is created).

## License

This project is for educational and personal use. DynamicNotchKit is subject to its own license.