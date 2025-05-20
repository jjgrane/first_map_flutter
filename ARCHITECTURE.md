# Arquitectura de First Maps Project

## Servicios

### Firebase Services (`/services/firebase/`)

#### Maps
- `firebase_markers_service.dart`: Gestiona los marcadores en Firestore
  - Operaciones CRUD para marcadores
  - Obtiene marcadores por mapId
  - Maneja la relación entre marcadores y grupos

#### Groups
- `firebase_groups_service.dart`: Gestiona los grupos en Firestore
  - Operaciones CRUD para grupos
  - Obtiene grupos por mapId
  - Maneja la metadata de grupos (emoji, nombre, etc.)
  - No persiste estado runtime (active)

#### Places
- `firebase_places_details_service.dart`: Gestiona los detalles de lugares en Firestore
  - Almacena y recupera información detallada de lugares
  - Operaciones CRUD en colección 'place_details'
  - Maneja la persistencia de datos de Google Places
  - Cache local de detalles de lugares frecuentes

### Maps Services (`/services/maps/`)
- `emoji_marker_converter.dart`: Convierte emojis a íconos de marcadores
  - Valida y formatea emojis
  - Convierte emojis a BitmapDescriptor
  - Maneja caché de íconos
  - Preload de emojis para grupos
- `google_maps_pins_service.dart`: Lógica centralizada de conversión y gestión de pins de Google Maps
  - Crea y actualiza pins de Google Maps a partir de modelos de dominio
  - Toda la estética y lógica de íconos pasa por aquí

## Providers

### Maps (`/providers/maps/`)
- `map_providers.dart`: Estado central de la aplicación
  - `activeMapProvider`: Mapa actualmente seleccionado
  - `markersStateProvider`: Estado de marcadores del mapa (CRUD y sincronización con Firestore)
  - `selectedPlaceProvider`: Lugar seleccionado actualmente
  - `selectedMarkerProvider`: Marcador seleccionado actualmente
  - `googleMapMarkersProvider`: Set reactivo de marcadores de Google Maps (lo que se ve en el mapa)
  - `groupsStateProvider`: Estado y gestión de grupos
    - Maneja lista de grupos del mapa actual
    - Controla estado activo/inactivo de grupos (runtime)
    - Sincroniza con Firebase (excepto estado runtime)
  - `mapReadyProvider`: Provider combinado que expone `markers`, `groups` y `map` solo cuando todos están listos (no nulos). Permite inicializar los pins de Google Maps de forma robusta y eficiente.
  - `activeMapResetProvider`: Provider global que resetea el estado de markers y grupos al cambiar el mapa activo, asegurando limpieza de estado.

## Modelos (`/widgets/models/`)

- `map_info.dart`: Información básica del mapa
- `map_marker.dart`: Modelo de marcador con metadata
- `place_information.dart`: Información detallada de lugares
- `group.dart`: Modelo de grupo con metadata
  - Campos persistentes: id, mapId, name, description, emoji
  - Campos runtime: active (no persistido)
  - Caché local de íconos de marcadores

## Flujo de Datos

1. **Carga Inicial**:
   - Se selecciona un mapa (`activeMapProvider`)
   - Se cargan sus marcadores (`markersStateProvider`)
   - Se cargan sus grupos (`groupsStateProvider`)
   - Los grupos se inicializan como activos por defecto
   - Cuando tanto el mapa, los markers y los grupos están listos, `mapReadyProvider` expone los datos y se inicializan los pins de Google Maps.

2. **Interacción con Marcadores**:
   - Usuario selecciona lugar → `selectedPlaceProvider`
   - Se crea/actualiza/elimina marcador → `markersStateProvider`
   - Cada operación de CRUD en `markersStateProvider` actualiza automáticamente el set de Google Maps llamando a `googleMapMarkersProvider` (a través de los notifiers)
   - El set de pins de Google Maps (`googleMapMarkersProvider`) es reactivo y refleja siempre el estado actual
   - El widget `MapView` (StatefulWidget) solo escucha cambios de pins y actualiza el mapa visualmente, pero **no recalcula ni gestiona los pins base**
   - Al actualizar el marcador seleccionado, se usa el operador `?? []` para asegurar que nunca se pasen listas nulas a los métodos que esperan listas no nulas, evitando errores de tipo.

3. **Gestión de Grupos**:
   - Usuario crea/edita grupo → `groupsStateProvider`
   - Se actualiza emoji del grupo → `emoji_marker_converter`
   - Se actualizan marcadores del grupo → `markersStateProvider`
   - Usuario activa/desactiva grupo → Solo afecta estado runtime

4. **Gestión de Places**:
   - Usuario busca/selecciona lugar → Se obtienen detalles del lugar
   - Se almacenan detalles en Firestore → `firebase_places_details_service`
   - Se asocia lugar con marcador → `markersStateProvider`

5. **Limpieza de Estado y Robustez**:
   - Al cambiar el mapa activo, `activeMapResetProvider` limpia el estado de markers y grupos para evitar inconsistencias.
   - Se eliminan logs de debug y se asegura que la UI y el estado sean consistentes y robustos ante datos nulos.

## Convenciones de Código

### Providers
- Usar `StateNotifierProvider` para estado mutable
- Usar `Provider` para servicios singleton
- Usar `FutureProvider` para datos asíncronos
- Mantener estado runtime separado del persistente
- **No actualizar el set de pins de Google Maps desde los widgets, solo desde los notifiers**

### Services
- Implementar manejo de errores con try/catch
- Loggear errores antes de relanzarlos
- Usar tipos fuertemente tipados
- Documentar métodos públicos
- No persistir estado runtime
- **Toda la lógica de conversión y estética de pins debe estar en EmojiMarkerConverter y GoogleMapsPinsService**

### Models
- Implementar `copyWith` para inmutabilidad
- Implementar `fromFirestore` y `toFirestore`
- Documentar campos complejos
- Separar claramente campos persistentes de runtime