# Changelog

All notable changes to PulsePlan will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.1+2] - 2026-05

### Added
- Full persistence of Device Health checklist and event log across restarts
- Confirmation dialogs for destructive actions ("Cerrar ciclo" and "Eliminar cuenta")
- Professional documentation package:
  - `PRODUCTION_CHECKLIST.md` (PhD-level internal review sign-off)
  - `RELEASE_NOTES.md`
  - `docs/USER_GUIDE.md` (Spanish)
  - `docs/ARCHITECTURE.md`
- `scripts/build_release.sh` — automated release build helper
- LICENSE, CHANGELOG.md, and SECURITY.md
- Proper PWA manifest and consistent branding ("PulsePlan") across all platforms
- All 6 Flutter platforms fully configured (Android, iOS, macOS, Web, Windows, Linux)

### Changed
- Health state and log now survive app restarts
- Improved error resilience in snapshot loading
- Android Gradle comments clarified for distribution
- Web PWA metadata updated with correct name, description and colors
- iOS and macOS display/product names unified to "PulsePlan"

### Fixed
- Removed unused `intl` dependency
- Potential data loss on "Cerrar ciclo" mitigated with confirmation
- Accidental deletion of assigned accounts now requires explicit confirmation

### Verified
- `flutter analyze` — clean (0 issues)
- All tests passing
- Release builds for Android and Web generated successfully

---

## [1.0.0+1] - Initial Development

- Initial implementation of PulsePlan
- 30-day planning engine with variable creative blocks
- Optional 60-day inverse cycle support
- Manual account management and assignment
- Library customization and plan regeneration
- JSON export functionality
- Basic device health monitoring panel (non-persistent at the time)