# Gradient Studio

A premium, iPad-first gradient wallpaper generator built with SwiftUI. Design
custom gradients (linear, radial, angular, diamond, reflected, mesh), layer
shapes and effects (blobs, glow, grain, vignette, glass, liquid, aurora, and
more), pick from 25+ presets, and export at up to 8K resolution as PNG or
JPEG — straight to Photos, Files, or AirDrop via the native share sheet.

Every pixel you see in the live preview comes from the same Core
Graphics/Core Image rendering pipeline used for export, so what you design is
exactly what you get.

---

## Features

- **Gradients:** linear, radial, angular (conic), diamond, reflected, and
  mesh gradients with full geometry control (angle, spread, center,
  radius, aspect ratio, rotation).
- **Colors:** unlimited draggable/reorderable color stops, full color
  picker, HEX/RGB/HSB input, opacity, recent colors, 14 built-in palettes,
  and your own saved custom palettes.
- **Shapes & effects:** circles, blobs, waves, rings, squares, rounded
  rects, organic shapes, lines, curves, noise, grain, glow, blur, soft
  light, vignette, radial glow, color bloom, glass, liquid, and aurora —
  each with position, size, rotation, color, opacity, blur, feather, and
  blend mode.
- **25+ wallpaper presets** across Minimal, Abstract, AMOLED, Neon, Pastel,
  Luxury, Nature, Aurora, Sunset, Space, Glass, Liquid, Mesh, Dark, and
  Light categories — every preset stays fully editable after loading.
- **Resolution control:** iPad portrait/landscape, iPad mini, 4K, square,
  16:9, 4:3, 3:2, 9:16, or any custom resolution up to 8192×8192.
- **Real-time editing** with debounced live preview, undo/redo, duplicate
  and delete layers, and direct on-canvas dragging to reposition shapes or
  gradient centers.
- **Projects persist automatically** to disk (JSON in the app's Documents
  directory) — save, rename, duplicate, and reopen past designs.
- Native iPad layout with sidebar navigation, dark/light mode, and support
  for portrait, landscape, and multitasking.

---

## Local Development

### Requirements

- macOS 14 (Sonoma) or later
- Xcode 16.0 or later
- An iPad running iPadOS 17 or later (device or simulator)

### Opening the project

1. Clone or download this repository.
2. Open `GradientWallpaper.xcodeproj` in Xcode.
3. Select the **GradientWallpaper** scheme.
4. Choose an iPad simulator (or a connected iPad) as the run destination.
5. Press **⌘R** to build and run.

### Running on a physical iPad

To run on your own iPad from Xcode, you'll need a free or paid Apple
Developer account attached to your Xcode login:

1. Select the `GradientWallpaper` project in the navigator, then the
   `GradientWallpaper` target → **Signing & Capabilities**.
2. Enable **Automatically manage signing** and select your personal team.
3. Xcode will generate a development certificate and provisioning profile
   for you automatically the first time you build to a device.
4. Connect your iPad, select it as the run destination, and press **⌘R**.
   The first launch on-device may require trusting your developer
   certificate under **Settings → General → VPN & Device Management**.

This local signing step is completely separate from the GitHub Actions
workflow described below, which intentionally produces an **unsigned**
build that requires no Apple Developer account at all.

### Running the tests

Press **⌘U** in Xcode, or from the command line:

```bash
xcodebuild test \
  -project GradientWallpaper.xcodeproj \
  -scheme GradientWallpaper \
  -destination "platform=iOS Simulator,name=iPad Pro 13-inch (M4)"
```

---

## GitHub Actions: Building an Unsigned IPA

This repository includes a workflow at `.github/workflows/build.yml` that
builds the app on a GitHub-hosted macOS runner and packages an **unsigned**
`.ipa` — no Apple Developer account, distribution certificate, provisioning
profile, or App Store Connect API key required.

### How it works

Because there's no signing identity, the workflow can't use Xcode's normal
`-exportArchive` step (which requires a provisioning profile). Instead it:

1. Checks out the repository.
2. Selects Xcode 16.1 on the runner.
3. Resolves any Swift package dependencies.
4. Runs `xcodebuild archive` with code signing explicitly disabled
   (`CODE_SIGNING_ALLOWED=NO`, `CODE_SIGNING_REQUIRED=NO`).
5. Copies the resulting unsigned `.app` bundle into a `Payload/` folder.
6. Zips `Payload/` and renames it to `GradientWallpaper-unsigned.ipa` — this
   is the standard IPA container format, just without a code signature
   inside it.
7. Uploads the `.ipa` (and the raw `.app` bundle, for convenience) as
   workflow artifacts.

The resulting `.ipa` is genuinely unsigned. It cannot be installed on a
physical iPad as-is — you'll need to sign it yourself afterward (for
example with a tool like AltStore, Sideloadly, or your own Apple Developer
signing certificate) before installing it on a device.

### Steps to run it

1. Create a new GitHub repository.
2. Upload this entire project (including `.github/workflows/build.yml`) to
   the repository.
3. On GitHub, open the **Actions** tab for your repository.
4. Select the **Build Unsigned IPA** workflow in the left sidebar.
5. Click **Run workflow** (or push to `main` — the workflow also triggers
   automatically on pushes to that branch).
6. Wait for the run to finish — it typically takes 5–10 minutes on a
   GitHub-hosted macOS runner.
7. Open the completed workflow run.
8. Scroll to the **Artifacts** section at the bottom of the run summary and
   download **GradientWallpaper-unsigned-ipa**.

The downloaded file is a `.zip` containing `GradientWallpaper-unsigned.ipa`.

---

## Project Structure

```
GradientWallpaper/
├── GradientWallpaper.xcodeproj
├── GradientWallpaper/
│   ├── App/            Entry point, Info.plist, editor view model
│   ├── Models/          Gradient, effect, canvas, palette, project models
│   ├── Views/            Sidebar panels: create, presets, colors, gradients,
│   │                      shapes, effects, saved projects, settings, export
│   ├── Components/     Reusable controls: sliders, swatches, stop bar,
│   │                      hex/RGB editor, layer stack, thumbnails
│   ├── Rendering/       Core Graphics gradient + mesh + top-level compositor
│   ├── Effects/            Shape and post-process effect renderers
│   ├── Presets/            Built-in wallpaper preset library
│   ├── Services/          Persistence, export, Photos saving, undo/redo
│   ├── Utilities/         CodableColor (hex/RGB/HSB conversions)
│   └── Assets.xcassets
├── Tests/                     XCTest unit tests for models, rendering, persistence
├── .github/workflows/build.yml
├── README.md
└── LICENSE
```

---

## Limitations & Notes

- The unsigned `.ipa` from GitHub Actions **cannot be installed directly**
  on an iPad — iOS requires every app to be signed before installation.
  Sign it yourself locally, with a signing service, or with your own
  Apple Developer certificate before sideloading.
- Mesh gradients use inverse-distance-weighted color blending sampled on a
  grid rather than a hardware mesh shader, which keeps them fast and
  portable across OS versions at the cost of very slightly softer
  transitions on extreme point counts.
- Angular (conic) gradients are drawn as many thin wedges rather than via a
  native conic gradient API, since Core Graphics has no public one; at
  360 segments this is visually indistinguishable from a true conic
  gradient.
- Exports above roughly 6000×6000 can use significant memory on-device;
  the app validates and reports a clear error rather than crashing if a
  requested resolution is unreasonable for the current device.
- Deployment target is iPadOS 17.0, chosen to support recent iPads while
  avoiding APIs only available on the very latest OS versions.

## License

MIT — see `LICENSE`.
