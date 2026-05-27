# Changelog

All notable changes to UsageMaxxing are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-05-27

### Added

- Full settings window: General, Sync, Display, Data sources, System status, and About
- Auto-refresh timer wired to configurable interval (5m–1h)
- Launch at login (SMAppService)
- System diagnostics: Node.js path, plugin directory, bridge script, readiness check
- Open plugin folder in Finder and copy path actions
- Display toggles: pressure strip, predictive insights, urgency sort, privacy masking
- Shared `UsageDashboardModel` for dashboard and settings refresh state
- `CHANGELOG.md` and root `VERSION` file for release tracking

### Changed

- Settings uses the same telemetry theme as the dashboard
- README logo displayed at the top

## [1.0.0] - 2026-05-27

### Added

- Initial public release
- Menu bar dashboard with exact OpenUsage-compatible local plugin usage
- AI Capacity Pressure score and menu bar color state
- Compressed cards, collapsible multi-metric providers, identity rails
- Predictive depletion and burn hints
- Compact dashboard mode
- Release build bundles `UsageMaxxing_UsageMaxxing.bundle` for installed apps

[1.1.0]: https://github.com/desenyon/UsageMaxxing/releases/tag/v1.1.0
[1.0.0]: https://github.com/desenyon/UsageMaxxing/releases/tag/v1.0.0
