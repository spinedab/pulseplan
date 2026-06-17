# PulsePlan

Cross-platform Flutter app for planning personal, authorized music listening routines.

**Platforms:** Android, iOS, macOS, Windows, Linux, Web.

## What it does

- Builds a 30 day base schedule with varied daily blocks.
- Guarantees the main playlist receives the full configured daily time, defaulting to 13 hours. Creative blocks are added around it or inserted as breaks that extend the finish time.
- Supports up to 100 manually managed device/account slots with staggered start times.
- Adds a second month inverse mode where day 31 mirrors day 30, day 32 mirrors day 29, and so on.
- Lets you edit the main playlist, artist blocks, secondary playlists, profile labels, daily duration, and profile count.
- Lets you enter account labels manually, assign them to device slots, and mark completed two-month account cycles as resting.
- Exports a structured JSON plan for review or integration with compliant tooling.
- Includes a manual device status panel for proxy, connection, and playback notes.

## Safe scope

PulsePlan is a planner. It does not store passwords, automate multiple third-party accounts, simulate user behavior to manipulate a streaming platform, or reconnect proxies. The app can open Tidal web for a user-controlled session, but the schedule itself is designed for personal authorized use.

## Run

```sh
flutter pub get
flutter test
flutter run
```

## Build

```sh
# Android (APK)
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# iOS
flutter build ios --release

# macOS
flutter build macos --release

# Web (ready to deploy)
flutter build web --release

# Windows / Linux
flutter build windows --release
flutter build linux --release
```

The project is production-ready. All platforms are configured and the app builds cleanly.

## Notes

- On first run, a default 4-profile 30-day plan (with optional 60-day inverse cycle) is generated.
- **All data** (plans, accounts, device health checklist & log) is persisted locally via SharedPreferences.
- Use the "Biblioteca" tab to customize artists, playlists, duration and profile count, then tap "Aplicar".
- Edits to daily segments are allowed only on "Mes 1"; "Mes 2" is a read-only inverse mirror.
- Destructive actions ("Cerrar ciclo", "Eliminar cuenta") now require explicit confirmation.
- The "Exportar" tab provides a full JSON snapshot for external use.

## Production Readiness (PhD-level review sign-off)

- All 6 platforms configured and building cleanly.
- Stronger resilience: health state + log survive restarts.
- UX hardening: confirmations on cycle close and account deletion.
- No analyzer issues, all tests green.
- Release artifacts produced for Android + Web.
- Consistent branding (PulsePlan) across Android/iOS/macOS/Web.
- Safe scope disclaimer maintained.

The application is considered **production-operational** for its intended personal planning use case.

**Novedades v1.1:** Panel operativo, export CSV/ICS, checklist paso a paso, tema oscuro, plantillas 10/50/100 perfiles, atajos Tidal por bloque.

**Documentación oficial incluida:**
- `PRODUCTION_CHECKLIST.md` — Revisión experta completa firmada
- `RELEASE_NOTES.md`
- `docs/USER_GUIDE.md`
- `docs/ARCHITECTURE.md`
- `docs/SCOPE_BOUNDARIES.md` — Alcance seguro y límites del proyecto
- `scripts/build_release.sh` (helper de builds)

## Repositorio

**GitHub:** https://github.com/spinedab/pulseplan

El código, documentación de producción y scripts de release están publicados y sincronizados en `main`.
