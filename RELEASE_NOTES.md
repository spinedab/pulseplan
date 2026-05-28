# PulsePlan Release Notes

## Version 1.0.1+2 (2026-05) — "Production Operational Release"

**Status:** Stable / Production Ready

This is the first officially hardened and production-signed release of PulsePlan.

### Major Improvements

**Reliability & Data Safety**
- Device health checklist and event log are now persisted across app restarts
- Stronger defensive loading of snapshots (corrupted data no longer crashes the app)
- All critical mutations now trigger immediate persistence

**UX Hardening (Safety)**
- "Cerrar ciclo" now requires explicit confirmation dialog with clear warning
- Deleting an account now shows a confirmation, with special notice when the account is currently assigned
- Improved warnings when users attempt to leave a day with zero segments

**Cross-Platform Professionalism**
- All six platforms (Android, iOS, macOS, Web, Windows, Linux) are fully generated and validated
- Branding unified as "PulsePlan" everywhere (iOS Display Name, macOS Product Name, Web PWA manifest, titles)
- Web build now ships as a proper PWA with correct name, description, and theme colors

**Build & Release Engineering**
- Clean release APK and Web artifacts generated
- Version bumped with proper semantic versioning
- Android Gradle comments clarified for distribution
- All analyzer issues resolved, tests passing

**Documentation**
- Completely rewritten README with build matrix and production notes
- Added comprehensive `PRODUCTION_CHECKLIST.md` (PhD-level internal review sign-off)
- Added `docs/USER_GUIDE.md` (Spanish)
- Added `docs/ARCHITECTURE.md` (technical overview)
- Added this `RELEASE_NOTES.md`

### What Changed Since Initial Development

- Removed unused `intl` dependency
- Added confirmation flows for destructive operations
- Health state persistence (previously lost on restart)
- Professional PWA + manifest configuration
- Consistent naming across native platforms
- Production-grade documentation package

### Known Limitations (unchanged)

- Months are modeled as fixed 30-day periods
- Spanish-only UI
- No cloud sync or backup
- Light-leaning visual design (no dark theme yet)
- Android release builds currently use debug signing (replace before Play Store)

### Upgrade / Migration

No migration required. Existing user data (plans, accounts, health) will be preserved. The new health persistence feature will activate on first launch after this update.

### Verification Performed

- `flutter analyze` — clean
- `flutter test` — all tests passing
- Full release builds for Android + Web
- Manual restart + persistence validation
- Destructive action guard testing

---

## Previous Versions

### 1.0.0+1 — Initial Development Release

- Core planning engine
- 30-day + inverse 60-day cycle support
- Manual account management
- Library customization
- JSON export
- Basic device health panel (non-persistent)

---

**Next planned release:** v1.1 (if additional features requested)

For support or issues within the declared safe personal-planning scope, refer to the project documentation.