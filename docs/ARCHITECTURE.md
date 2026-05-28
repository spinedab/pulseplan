# PulsePlan — Arquitectura Técnica

**Versión:** 1.0.1+2

---

## Principios de Diseño

- **Simplicidad primero**: Una sola aplicación monolítica pero clara.
- **Persistencia local confiable**: SharedPreferences como única fuente de verdad.
- **Generación determinista**: El plan es 100% reproducible a partir de `LibrarySettings + seed`.
- **Seguridad por diseño**: La aplicación **nunca** almacena credenciales ni automatiza logins.
- **Edición controlada**: Solo Mes 1 es mutable. Mes 2 es un espejo inverso calculado.

---

## Estructura del Código

```
lib/
├── main.dart           # Toda la UI + estado + lógica de presentación (1600+ LOC)
└── plan_model.dart     # Modelos puros + generador de planes (PlanGenerator)
```

### plan_model.dart (Capa de Dominio)

Componentes clave:

- `LibrarySettings` — Configuración base (perfiles, duración, artistas, playlists, seed, ciclo)
- `ListeningProfile` — Un "dispositivo" con 30 días de planes
- `DayPlan` — Un día con lista de `ListeningSegment`
- `ListeningSegment` — Bloque individual (tipo, título, hora inicio, duración)
- `MusicAccount` — Cuenta manual con estado y asignación
- `PlanGenerator` — Motor determinista de generación de planes
  - `_variationBlocks()` decide los bloques creativos según modo diario
  - Soporta modo "beforeMain" y bloques intercalados
  - `generateSecondMonth()` invierte el orden de los días

**Garantía importante:**  
El tiempo total de la playlist principal **siempre** suma exactamente `targetMinutes` por día.

### main.dart (Capa de Presentación)

- Único `StatefulWidget` grande (`_PlannerHomePageState`)
- 5 pestañas implementadas como métodos privados
- Diálogos modales para edición de segmentos y cuentas
- Persistencia manual + carga en `initState`
- Estado de salud del dispositivo (ahora persistido)

**Decisiones técnicas aceptadas para v1:**
- No se usó Riverpod / Bloc / Provider (alcance actual no lo justificaba)
- Toda la regeneración de planes ocurre en memoria al aplicar cambios

---

## Flujo de Datos

```
Usuario edita Biblioteca
        ↓
_applyLibrarySettings()
        ↓
PlanGenerator.generate() → nuevos _profiles
        ↓
_reconcileAccounts()
        ↓
setState + _save() → SharedPreferences
```

Cierre de ciclo:

```
_closeTwoMonthCycle()
        ↓
Marcar cuentas activas → Resting + limpiar asignaciones
        ↓
Nuevo seed + generar siguiente mes
        ↓
Avanzar _monthStart + setState + _save()
```

---

## Persistencia

Claves utilizadas:

- `playlist_planner_snapshot_v1` → JSON completo (settings + profiles + accounts)
- `playlist_planner_health_v1` → Estado de checklist (desde v1.0.1)
- `playlist_planner_health_log_v1` → Historial de eventos (desde v1.0.1)

El snapshot incluye tanto la vista actual como la representación de los dos meses.

---

## Generación de Planes (Algoritmo)

1. Para cada perfil se calcula una `profileSeed`.
2. Para cada día se usa `Random(profileSeed + day * 1093)`.
3. Se determina un `startMinute` base + variación.
4. Se elige un `mode` (0-5) que define la estructura de bloques creativos.
5. Los bloques se insertan antes/después de porciones de la playlist principal.
6. Se garantiza que `mainMinutes == targetMinutes` todos los días.

Mes 2 = inversión temporal de Mes 1 (día 1 de Mes 2 = día 30 de Mes 1 invertido).

---

## Plataformas Soportadas

Todas las plataformas Flutter estándar están generadas:

- `android/`
- `ios/`
- `macos/`
- `web/`
- `linux/`
- `windows/`

Plugins utilizados:
- `shared_preferences`
- `url_launcher`

---

## Consideraciones de Seguridad

- No hay almacenamiento de credenciales.
- No hay llamadas de red automáticas (solo `launchUrl` iniciado por usuario).
- El alcance declarado ("personal authorized planning") está reforzado en código y documentación.
- No existe lógica de rotación automática de proxies o cuentas.

---

## Limitaciones Técnicas Actuales

- Meses fijos de 30 días (no usa `intl` ni calendario real)
- Sin internacionalización
- Sin tema oscuro completo
- Generación completa en cada "Aplicar" (aceptable hasta ~100 perfiles)
- Sin pruebas de golden ni integration tests avanzados

---

## Recomendaciones para Versiones Futuras (v2+)

1. Introducir un State Management real (Riverpod recomendado)
2. Añadir calendario real + manejo de meses de 28-31 días
3. Soporte de tema oscuro + Material You
4. Exportación a PDF / ICS
5. Pruebas de snapshot + golden tests de la UI de días
6. Soporte de backup/exportación cifrado local

---

**Documento mantenido por el equipo de arquitectura interna.**