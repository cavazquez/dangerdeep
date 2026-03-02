# Migración SDL2 → SDL3 (En Progreso)

**Estado**: Trabajo en progreso (branch: `feature/sdl3-migration`)
**Fecha inicio**: 2026-03-02
**SDL3 versión**: 3.4.0 (instalado en `/usr/local`)

## 🎯 Objetivo

Migrar el proyecto de SDL2 a SDL3 para aprovechar las nuevas características y mantener compatibilidad con versiones futuras.

---

## ✅ Completado

### 1. Instalación de SDL3
- ✅ Script de instalación creado: `install_sdl3_3.4.0.sh`
- ✅ SDL3 3.4.0 instalado en `/usr/local/lib/`
- ✅ SDL3_image instalado en `/usr/local/lib/`
- ✅ SDL3_mixer instalado en `/usr/local/lib/`

### 2. CMakeLists.txt
- ✅ Actualizado `find_package(SDL2)` → `find_package(SDL3 3.4.0)`
- ✅ Actualizado `find_package(SDL2_image)` → `find_package(SDL3_image)`
- ✅ Actualizado `find_package(SDL2_mixer)` → `find_package(SDL3_mixer)`
- ✅ Cambiadas variables de librería a targets modernos: `SDL3::SDL3`, `SDL3_image::SDL3_image`, `SDL3_mixer::SDL3_mixer`

### 3. Includes globales
- ✅ Reemplazados todos los `#include <SDL.h>` → `#include <SDL3/SDL.h>`
- ✅ Reemplazados `#include <SDL_*.h>` → `#include <SDL3/SDL_*.h>`
- ✅ Corregidos includes específicos:
  - `<SDL3/SDL_types.h>` → `<SDL3/SDL_stdinc.h>` (SDL_types.h ya no existe)
  - `<SDL3/SDL_image.h>` → `<SDL3_image/SDL_image.h>`
  - `<SDL3/SDL_mixer.h>` → `<SDL3_mixer/SDL_mixer.h>`

### 4. Constantes y tipos básicos
- ✅ Eventos renombrados:
  - `SDL_KEYDOWN` → `SDL_EVENT_KEY_DOWN`
  - `SDL_KEYUP` → `SDL_EVENT_KEY_UP`
  - `SDL_MOUSEBUTTONDOWN` → `SDL_EVENT_MOUSE_BUTTON_DOWN`
  - `SDL_MOUSEBUTTONUP` → `SDL_EVENT_MOUSE_BUTTON_UP`
  - `SDL_MOUSEMOTION` → `SDL_EVENT_MOUSE_MOTION`
  - `SDL_MOUSEWHEEL` → `SDL_EVENT_MOUSE_WHEEL`
  - `SDL_QUIT` → `SDL_EVENT_QUIT`

- ✅ Modificadores de teclado:
  - `KMOD_LCTRL` → `SDL_KMOD_LCTRL`
  - `KMOD_RCTRL` → `SDL_KMOD_RCTRL`
  - `KMOD_LALT` → `SDL_KMOD_LALT`
  - `KMOD_RALT` → `SDL_KMOD_RALT`
  - `KMOD_LSHIFT` → `SDL_KMOD_LSHIFT`
  - `KMOD_RSHIFT` → `SDL_KMOD_RSHIFT`
  - `KMOD_MODE` → `SDL_KMOD_MODE`
  - `KMOD_CTRL` → `SDL_KMOD_CTRL`
  - `KMOD_SHIFT` → `SDL_KMOD_SHIFT`
  - `KMOD_ALT` → `SDL_KMOD_ALT`

- ✅ Funciones de byte swapping:
  - `SDL_SwapLE16` → `SDL_Swap16LE`
  - `SDL_SwapLE32` → `SDL_Swap32LE`
  - `SDL_SwapLE64` → `SDL_Swap64LE`

### 5. Estructura de eventos de teclado
- ✅ `SDL_Keysym` eliminado en SDL3
- ✅ Actualizado `cfg.h` y `cfg.cpp`:
  - `cfg::key::equal(const SDL_Keysym&)` → `cfg::key::equal(const SDL_KeyboardEvent&)`
  - `ks.sym` → `ke.key`
  - `ks.mod` → `ke.mod`
  
- ✅ Eventos de teclado actualizados globalmente:
  - `event.key.keysym.sym` → `event.key.key`
  - `event.key.keysym.mod` → `event.key.mod`
  - `event.key.keysym.scancode` → `event.key.scancode`
  - `event.key.keysym` → `event.key`

- ✅ Eliminado campo obsoleto `event.key.unicode` (SDL3 usa SDL_EVENT_TEXT_INPUT)

### 6. Archivos modificados
**Total: 140+ archivos** en `src/` (*.cpp, *.h)

---

## 🚧 Pendiente (Bloqueantes para compilación)

### 1. widget.h/widget.cpp - Sistema de UI
**Problema**: `widget.h` usa `SDL_Keysym` extensivamente en su API pública.

**Archivos afectados**:
- `src/widget.h` (líneas 115, 116, 160, 224, 518, 599)
- `src/widget.cpp`

**Solución requerida**:
```cpp
// Antes (SDL2)
struct key_event {
    const widget *source;
    const SDL_Keysym ks;
};
void on_char(const SDL_Keysym &ks);

// Después (SDL3) - Opción 1: Usar SDL_KeyboardEvent
struct key_event {
    const widget *source;
    const SDL_KeyboardEvent ke;
};
void on_char(const SDL_KeyboardEvent &ke);

// Opción 2: Crear estructura de compatibilidad
struct KeyInfo {
    SDL_Keycode key;
    SDL_Scancode scancode;
    SDL_Keymod mod;
};
```

**Impacto**: Requiere actualizar todos los widgets que manejan eventos de teclado.

---

### 2. music.h/music.cpp - Sistema de audio
**Problema**: No encuentra tipos `Mix_Music` y `Mix_Chunk` de SDL3_mixer.

**Archivos afectados**:
- `src/music.h` (líneas 158, 160, 161, 162)
- `src/music.cpp`

**Diagnóstico**:
```bash
# Verificar si SDL3_mixer está correctamente instalado
ls -la /usr/local/include/SDL3_mixer/
ls -la /usr/local/lib/libSDL3_mixer*
pkg-config --cflags --libs SDL3_mixer
```

**Posibles causas**:
1. Include path incorrecto
2. SDL3_mixer no se compiló correctamente
3. Falta agregar include directories en CMakeLists.txt

**Solución temporal**: Agregar a CMakeLists.txt:
```cmake
include_directories(/usr/local/include/SDL3_mixer)
```

---

### 3. Constantes de teclas con minúsculas
**Problema**: SDL3 cambió todas las constantes de teclas a mayúsculas.

**Errores**:
- `SDLK_w_renamed_SDLK_W` was not declared
- `SDLK_m_renamed_SDLK_M` was not declared

**Archivos afectados**:
- `src/freeview_display.cpp` (línea 178)
- `src/map_display.cpp` (línea 1037, 1043)
- Potencialmente otros archivos

**Solución**: Reemplazo global de constantes minúsculas:
```bash
sed -i 's/\bSDLK_a\b/SDLK_A/g' # y así para todas las letras a-z
```

---

### 4. Errores de punteros en coastmap.cpp y height_generator_map.cpp
**Problema**: "base operand of '->' is not a pointer"

**Archivos**:
- `src/coastmap.cpp` (línea 998)
- `src/height_generator_map.cpp` (línea 73)

**Análisis requerido**: Verificar si hay cambios en la API de SDL3 relacionados con superficies o texturas.

---

## 📋 Tareas Restantes (Por prioridad)

### Alta prioridad (bloqueantes)
1. [ ] Arreglar `music.h` - resolver includes de SDL3_mixer
2. [ ] Refactorizar `widget.h` - eliminar dependencia de SDL_Keysym
3. [ ] Reemplazar todas las constantes de teclas minúsculas (SDLK_a → SDLK_A)
4. [ ] Investigar errores de punteros en coastmap y height_generator_map

### Media prioridad (API changes)
5. [ ] Actualizar inicialización SDL (SDL_Init flags pueden haber cambiado)
6. [ ] Verificar cambios en window creation (SDL_CreateWindow)
7. [ ] Verificar cambios en renderer (SDL_CreateRenderer)
8. [ ] Actualizar manejo de eventos de texto (SDL_EVENT_TEXT_INPUT)
9. [ ] Verificar cambios en SDL_image (IMG_Load, etc.)
10. [ ] Verificar cambios en SDL_mixer (Mix_OpenAudio, Mix_PlayMusic, etc.)

### Baja prioridad (optimizaciones)
11. [ ] Aprovechar nuevas características de SDL3
12. [ ] Optimizar manejo de eventos con nueva API
13. [ ] Documentar cambios de API para futuros desarrolladores

---

## 🔍 Guía de referencia SDL3

**Documentación oficial**:
- [SDL3 Migration Guide](https://github.com/libsdl-org/SDL/blob/main/docs/README-migration.md)
- [SDL3 API Reference](https://wiki.libsdl.org/SDL3/)

**Cambios principales SDL2 → SDL3**:
- Eventos: Cambio de nombres (SDL_EVENTNAME → SDL_EVENT_NAME)
- Teclado: SDL_Keysym eliminado, campos movidos a SDL_KeyboardEvent
- Audio: Reescritura completa del subsistema
- Ventanas: Nuevos flags y opciones
- Renderer: API modernizada
- Tipos: Limpieza de tipos obsoletos

---

## 🚀 Próximos pasos

Para continuar la migración:

1. **Resolver SDL3_mixer**:
   ```bash
   # Verificar instalación
   pkg-config --modversion SDL3_mixer
   # Reinstalar si es necesario
   ./install_sdl3_3.4.0.sh
   ```

2. **Refactorizar widget.h**:
   - Crear abstracción para eventos de teclado
   - Actualizar todos los widgets heredados
   - Probar sistema de UI

3. **Actualizar constantes de teclas**:
   - Script de reemplazo global
   - Verificar todas las referencias

4. **Compilar y testear**:
   - Resolver errores de compilación restantes
   - Ejecutar tests unitarios
   - Testear juego manualmente

---

## 📝 Notas

- SDL3 aún está en desarrollo activo (v3.4.0)
- Algunos cambios de API pueden requerir ajustes en lógica de juego
- Considerar mantener compatibilidad con SDL2 en branch separado
- Los cambios son extensivos pero sistemáticos

---

**Branch**: `feature/sdl3-migration`
**Para volver a SDL2**: `git checkout master`
