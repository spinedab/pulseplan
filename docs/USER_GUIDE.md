# Guía de Usuario — PulsePlan

**Versión:** 1.0.1+2

PulsePlan es una herramienta profesional para planificar rutinas personales de escucha musical autorizada.

---

## Instalación

### Android
1. Instala el APK de release (`app-release.apk`)
2. Otorga permisos si se solicitan (solo para abrir enlaces externos)

### Web / PWA
1. Abre la versión web en un navegador moderno
2. Usa "Instalar" o "Añadir a pantalla de inicio" para usarla como aplicación

### Escritorio (macOS / Windows / Linux)
Compila desde el código fuente con Flutter o usa los binarios generados.

---

## Primer Uso

Al abrir la aplicación por primera vez verás:

- Un plan de **30 días** con **4 perfiles** por defecto
- Duración aproximada de **13 horas** diarias
- Ciclo de **60 días** activado (Mes 2 inverso)

Puedes empezar a usar el plan inmediatamente.

---

## Pestañas Principales

### 1. Plan (Calendario)

- **Selector de Mes**: Mes 1 (editable) / Mes 2 (solo lectura, espejo inverso)
- **Perfiles**: Selecciona entre los dispositivos/cuentas configuradas
- **Días del mes**: Navega por los 30 días
- **Bloques del día**: 
  - Playlist principal (obligatoria)
  - Bloques creativos (artista, playlist alterna, descubrimiento)

**Acciones disponibles en Mes 1:**
- Agregar nuevo bloque
- Editar hora de inicio y duración
- Eliminar bloques (mínimo 1 bloque por día)

### 2. Cuentas

Gestiona las cuentas/dispositivos manualmente:

- Crear nuevas cuentas con etiqueta y estado (Lista / Activa / Descanso)
- Asignar cuentas a perfiles específicos
- Ver inventario completo de cuentas
- **Cerrar ciclo**: Marca todas las cuentas activas como "Descanso" y avanza al siguiente período (requiere confirmación)

### 3. Biblioteca

Configura los parámetros base del plan:

- Playlist principal
- Prefijo y numeración de perfiles (ej: MUSIC-001)
- Artistas para bloques cortos
- Playlists alternas
- Activar/Desactivar ciclo de 60 días (Mes 2 inverso)
- Cantidad de perfiles (1-100)
- Duración diaria aproximada (10-14h)

Presiona **"Aplicar"** para regenerar todo el plan con los nuevos parámetros.

### 4. Exportar

Exporta un snapshot completo en formato JSON (indentado).  
Útil para:
- Respaldos manuales
- Análisis externo
- Integración con otras herramientas

### 5. Estado (Health)

Panel manual de "salud del dispositivo":

- Activa/desactiva indicadores (Proxy, Conexión, Música, Plan del día)
- Registra eventos rápidos ("Activa", "Pausa")
- Abre Tidal en el navegador
- Historial de los últimos eventos (persiste entre reinicios)

---

## Flujo de Trabajo Recomendado

1. Configura tu **Biblioteca** (artistas, playlists, duración)
2. Aplica los cambios
3. Ve a **Cuentas** y crea tus etiquetas de dispositivos
4. Asigna cuentas a los perfiles
5. Usa la pestaña **Plan** diariamente
6. Al terminar un ciclo de 60 días → usa "Cerrar ciclo" (con confirmación)
7. Exporta periódicamente desde la pestaña **Exportar** como respaldo

---

## Consejos Avanzados

- **Mes 2** es siempre la inversión exacta de Mes 1. No se puede editar directamente.
- Puedes tener hasta **100 perfiles** (útil para granjas pequeñas o múltiples dispositivos).
- Los bloques creativos se insertan alrededor de la playlist principal sin reducir su tiempo total.
- El JSON exportado contiene tanto el plan actual como la política de rotación.

---

## Limitaciones Conocidas

- Los meses siempre tienen 30 días (modelo simplificado)
- No hay respaldo en la nube (solo local)
- Interfaz solo en español
- Sin tema oscuro (diseño orientado a luz)

---

## Soporte

Este es un **planificador personal**. No automatiza cuentas, no almacena credenciales y no realiza acciones en plataformas de streaming.

Para cualquier duda, consulta el README y el archivo `PRODUCTION_CHECKLIST.md`.

---

*PulsePlan — Planificación seria para uso personal autorizado.*