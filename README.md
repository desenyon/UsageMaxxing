# UsageMaxxing

UsageMaxxing is a local-first macOS menu bar app for exact AI subscription usage pulled from installed app integrations.

It reads **OpenUsage-compatible local plugins** (the same plugin format used by [OpenUsage](https://github.com/sunstory-dev/openusage)). You do **not** need the OpenUsage app running, but you do need:

1. **Node.js** on your PATH (`/opt/homebrew/bin/node`, `/usr/local/bin/node`, or `/usr/bin/node`)
2. **OpenUsage-compatible plugins** under Application Support (typically installed by OpenUsage or copied manually)
3. The **provider macOS app** installed (Cursor, Codex, Claude, etc.)

```text
~/Library/Application Support/com.sunstory.openusage/plugins
```

A provider appears as a usage card only when:

1. The provider app is installed.
2. A local exact usage plugin exists.
3. The plugin returns live usage lines.

Installed apps with expired auth or unavailable local state are shown separately as unavailable. UsageMaxxing does not fabricate, estimate, or hardcode quota data.

## Features

- Exact local usage via OpenUsage plugin bridge
- AI Capacity Pressure score (menu bar icon reflects load)
- Predictive hints: depletion estimate, burn notes, velocity vs last sync
- Collapsible multi-metric cards with provider identity rails
- Compact dashboard mode for continuous monitoring

## Supported plugin providers

- Claude
- Codex
- Cursor
- Gemini
- Antigravity
- Perplexity

## Build and run

```sh
Scripts/run-app.sh
```

Produces `dist/UsageMaxxing.app` with the Swift resource bundle embedded next to the executable.

## Test

```sh
swift test
Scripts/build-app.sh
# Verify bundle is packaged:
test -f dist/UsageMaxxing.app/Contents/MacOS/UsageMaxxing_UsageMaxxing.bundle/local_exact_usage_bridge.mjs
```

## Release package

```sh
VERSION=1.0.0 Scripts/package-release.sh
```

## Logo

- SVG: `docs/assets/usage-maxxing-logo.svg`
- App icon: `UsageMaxxing/Resources/AppIcon.icns`

## Privacy

All usage reads stay on your Mac. The bridge may access credentials already stored by provider apps when a plugin requires them; nothing is sent to a UsageMaxxing cloud backend.
