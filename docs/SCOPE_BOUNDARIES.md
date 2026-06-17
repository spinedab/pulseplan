# PulsePlan — Límites de Alcance

Este documento define qué hace PulsePlan, qué queda explícitamente fuera del proyecto, y cómo conectar herramientas externas de forma legítima.

## Alcance seguro (implementado)

PulsePlan es un **planificador local** para rutinas de escucha personal y autorizada:

- Generación de planes de 30/60 días con hasta 100 perfiles
- Gestión manual de cuentas por etiqueta (sin credenciales)
- Asignación cuenta ↔ perfil/dispositivo
- Exportación JSON, CSV y calendario ICS
- Dashboard con slots activos y próximos según la hora actual
- Checklist operativo paso a paso
- Atajos para abrir Tidal web con búsqueda del bloque actual (login manual)
- Plantillas de configuración importables
- Tema claro/oscuro, persistencia local

## Fuera de alcance (no se implementará en este repositorio)

Las siguientes capacidades **no forman parte** de PulsePlan por diseño:

| Capacidad | Motivo |
|-----------|--------|
| Almacenar contraseñas o tokens | Riesgo de seguridad y responsabilidad legal |
| Login automático en Tidal u otras plataformas | Viola términos de servicio típicos |
| Reproducción automatizada | Manipulación de métricas / abuso de plataforma |
| Rotación automática de proxies | Evasión de controles anti-abuso |
| Simulación de comportamiento humano | Fraude / farming de streams |
| Eludir límites de cuentas o dispositivos | Fuera del uso autorizado |

Estas exclusiones están documentadas en `README.md`, `SECURITY.md` y en el campo `rotationPolicy` del JSON exportado.

## Integración legítima vía exportación

Si necesitas conectar PulsePlan con otras herramientas **compatibles con tu uso autorizado**, el punto de extensión oficial es la exportación estructurada:

```json
{
  "app": "PulsePlan",
  "scope": "personal_authorized_planning",
  "rotationPolicy": {
    "manualLogin": true,
    "credentialStorage": false
  },
  "accounts": [...],
  "months": [...]
}
```

Formatos disponibles desde la pestaña **Exportar**:

- **JSON** — snapshot completo para integraciones
- **CSV** — hojas de cálculo y reporting
- **ICS** — importar en Google Calendar, Apple Calendar, etc.
- **Plantillas** — presets de 10/50/100 perfiles

Cualquier herramienta externa que consuma estos datos debe operar bajo responsabilidad del usuario y cumplir los términos de servicio de las plataformas involucradas.

## Responsabilidad del usuario

El usuario es responsable de:

1. Usar PulsePlan solo para actividades personales autorizadas
2. Cumplir los ToS de Tidal y cualquier otro servicio
3. No usar la exportación para automatizar abuso de plataformas

---

*Última actualización: 2026-06-17 (v1.1.0)*