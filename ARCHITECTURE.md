# First Maps Project – Updated Architecture (June 2025)

## 1 · Servicios

### 1.1 Firebase (`/services/firebase/`)

| Dominio | Archivo / Clase | Responsabilidad |
|---------|-----------------|------------------|
| **Maps → Markers** | `maps/firebase_markers_service.dart` | CRUD de marcadores en Firestore.<br>Consulta por `mapId`.<br>Relación marcador ⇄ grupo. |
| **Maps → Groups** | `groups/firebase_groups_service.dart` | CRUD de grupos.<br>Consulta por `mapId`.<br>Mantiene metadata (`emoji`, `name`, …).<br>**No** persiste el flag `active`. |
| **Places** | `places/firebase_places_details_service.dart` | CRUD en colección *place_details*.<br>Cache de lugares frecuentes.<br>Persistencia de detalles de Google Places. |

### 1.2 Maps (`/services/maps/`)

| Archivo | Responsabilidad |
|---------|-----------------|
| `emoji_marker_converter.dart` | Validar/convertir emojis a `BitmapDescriptor`.<br>Manejar cache de íconos y *pre‑load* de emojis. |
| `google_maps_pins_service.dart` | **Única fuente** de lógica de iconos y estética de pins.<br>Reutiliza `googleMarker` existente si lo trae el modelo.<br>Genera borde azul/tamaño 120 px cuando `isSelected == true`. |

---

## 2 · Providers (`/providers/maps/`)

> Implementados con **Riverpod 3** y generación de código (`@riverpod`).

| Provider | Tipo | Descripción |
|----------|------|-------------|
| `activeMapProvider` | `AsyncValue<MapInfo?>` | Mapa seleccionado. Dispara recálculo de grupos, marcadores y pins. |
| `groupsProvider` | `AsyncNotifier<List<Group>>` | Lista de grupos del mapa activo.<br>Detecta cambio de emoji y delega a `markersProvider.groupEmojiUpdate()`. |
| `markersProvider` | `AsyncNotifier<List<MapMarker>>` | CRUD + enriquecimiento (`googleMarker`, `visible`).<br>Expone métodos imperativos: `addMarker`, `updateMarker`, `removeMarker`, `refresh`, `applyGroupVisibility`, `applyMarkerVisibility`, `groupEmojiUpdate`. |
| `selectedPlaceProvider` | `StateProvider<PlaceInformation?>` | Lugar seleccionado.<br>Al cambiar, llama a `googleMapMarkersProvider.notifier.applySelection(prev, next)`. |
| `selectedMarkerProvider` | `Provider<MapMarker?>` | Derivado: busca el `MapMarker` correspondiente al `PlaceInformation` seleccionado. |
| `googleMapMarkersProvider` | `AsyncNotifier<Set<Marker>>` | Conjunto de `Marker` visibles en `GoogleMap`.<br>Recalcula cuando cambia de mapa o se llama a `refresh()`.<br>Métodos: `addMarker`, `updateMarker`, `removeMarker`, `refresh`, `applySelection`. |
| `mapReadyProvider` | `Provider<bool>` | Devuelve `true` cuando `activeMap`, `groupsProvider` y `markersProvider` están en `AsyncData`. |
| `activeMapResetProvider` | `Provider<void>` | Listener global: al cambiar de mapa limpia `groupsProvider`, `markersProvider` y `googleMapMarkersProvider`. |

---

## 3 · Modelos (`/widgets/models/`)

| Modelo | Claves |
|--------|--------|
| `map_info.dart` | id, name, owner … |
| `group.dart` | Campos persistentes: `id`, `mapId`, `name`, `description`, `emoji`.<br>Campos runtime: `active`, **`_markerIcon`** (cache).<br>Método: `getMarkerIcon()` – convierte emoji a ícono y cachea. |
| `map_marker.dart` | Persistentes: `markerId`, `detailsId`, `mapId`, `groupId`, `information`.<br>Runtime: `googleMarker`, `visible` (por defecto `true`). |
| `place_information.dart` | placeId, name, location, photos, … |

---

## 4 · Flujo de Datos

1. **Carga Inicial**
   1.1 `activeMapProvider` obtiene el mapa por defecto.
   1.2 `groupsProvider` carga grupos.
   1.3 `markersProvider` extrae marcadores, enriquece cada uno con su `googleMarker` mediante `GoogleMapsPinsService`.
   1.4 `mapReadyProvider` → `true` → `GoogleMapMarkersProvider.build()` genera `Marker`s y la UI inicializa el mapa.

2. **Interacción**
   - CRUD de marcadores → `markersProvider` actualiza lista y notifica a `googleMapMarkersProvider` (add/update/remove).
   - Selección de lugar → `selectedPlaceProvider` → `googleMapMarkersProvider.applySelection(prev,next)` → sólo cambia `zIndex` de los dos pins implicados.
   - Filtros visuales → llamados a `applyGroupVisibility` o `applyMarkerVisibility` cambian el flag `visible` y luego `googleMapMarkersProvider.refresh()` actúa.

3. **Gestión de grupos**
   - Cambio de emoji → `groupsProvider` detecta y llama a `markersProvider.groupEmojiUpdate(group)` → cada pin del grupo se re‑genera con nuevo icono.

4. **Cambio de mapa**
   - `activeMapProvider` emite nuevo mapa.
   - `activeMapResetProvider` limpia estados para evitar fugas.
   - Providers se recargan con nuevos datos.

---

## 5 · Convenciones

### Providers
- `@riverpod` + generación automática.
- Dependencias declaradas con `watch`; lecturas puntuales mediante `read(...future)` para evitar rebuilds innecesarios.
- Enriquecimiento de `MapMarker` siempre dentro de `markersProvider` (nunca en servicios ni UI).

### Services
- Sin estado runtime.
- Toda estética de pins en `EmojiMarkerConverter` / `GoogleMapsPinsService`.
- Manejo de errores con `try/catch`, log y `rethrow` si procede.

### Models
- Inmutables con `copyWith`.
- Campos runtime separados y documentados.
- Métodos `fromFirestore` / `toFirestore` para integración backend.

---

> **Nota:** Este documento refleja la arquitectura tras la migración a
> Riverpod 3 (jun 2025) y la introducción de métodos de filtrado y
> actualización reactiva de pins. Cualquier cambio adicional en nombres
> de providers o servicios debe reflejarse aquí para mantener la
> documentación en sincronía con el código.

