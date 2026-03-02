# Migración SDL2 → SDL3 (Bloqueada - SDL3_mixer incompatible)

**Estado**: ⚠️ **Bloqueada** - SDL3_mixer requiere reescritura completa del sistema de audio
**Fecha inicio**: 2026-03-02
**Fecha pausa**: 2026-03-02
**SDL3 versión**: 3.4.0 (instalado en `/usr/local`)
**Progreso**: ~75% completado (sin audio)

## 🎯 Objetivo

Migrar el proyecto de SDL2 a SDL3 para aprovechar las nuevas características y mantener compatibilidad con versiones futuras.

---

## ✅ Completado (~75%)

### 1. Instalación de SDL3
- ✅ Script de instalación creado: `install_sdl3_3.4.0.sh`
- ✅ SDL3 3.4.0 instalado en `/usr/local/lib/`
- ✅ SDL3_image instalado en `/usr/local/lib/`
- ✅ SDL3_mixer instalado en `/usr/local/lib/` (pero API incompatible)

### 2. CMakeLists.txt
- ✅ Actualizado `find_package(SDL2)` → `find_package(SDL3 3.4.0)`
- ✅ Actualizado `find_package(SDL2_image)` → `find_package(SDL3_image)`
- ✅ Actualizado `find_package(SDL2_mixer)` → `find_package(SDL3_mixer)`
- ✅ Cambiadas variables de librería a targets modernos: `SDL3::SDL3`, `SDL3_image::SDL3_image`, `SDL3_mixer::SDL3_mixer`

### 3. Includes globales (140+ archivos)
- ✅ Reemplazados todos los `#include <SDL.h>` → `#include <SDL3/SDL.h>`
- ✅ Reemplazados `#include <SDL_*.h>` → `#include <SDL3/SDL_*.h>`
- ✅ Corregidos includes específicos:
  - `<SDL3/SDL_types.h>` → `<SDL3/SDL_stdinc.h>` (SDL_types.h ya no existe)
  - `<SDL3/SDL_image.h>` → `<SDL3_image/SDL_image.h>`
  - `<SDL3/SDL_mixer.h>` → `<SDL3_mixer/SDL_mixer.h>`

### 4. Constantes y tipos básicos
- ✅ Eventos renombrados (8 constantes):
  - `SDL_KEYDOWN` → `SDL_EVENT_KEY_DOWN`
  - `SDL_KEYUP` → `SDL_EVENT_KEY_UP`
  - `SDL_MOUSEBUTTONDOWN` → `SDL_EVENT_MOUSE_BUTTON_DOWN`
  - `SDL_MOUSEBUTTONUP` → `SDL_EVENT_MOUSE_BUTTON_UP`
  - `SDL_MOUSEMOTION` → `SDL_EVENT_MOUSE_MOTION`
  - `SDL_MOUSEWHEEL` → `SDL_EVENT_MOUSE_WHEEL`
  - `SDL_QUIT` → `SDL_EVENT_QUIT`

- ✅ Modificadores de teclado (10 constantes):
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

- ✅ Funciones de byte swapping (3 funciones):
  - `SDL_SwapLE16` → `SDL_Swap16LE`
  - `SDL_SwapLE32` → `SDL_Swap32LE`
  - `SDL_SwapLE64` → `SDL_Swap64LE`

- ✅ Constantes de teclas (26 letras):
  - `SDLK_a` → `SDLK_A` (y todas a-z)

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

### 6. Sistema de widgets (refactorización mayor)
- ✅ Creada estructura `widget::key_info` para reemplazar `SDL_Keysym`:
  ```cpp
  struct key_info {
      SDL_Keycode key;
      SDL_Scancode scancode;
      SDL_Keymod mod;
      key_info(const SDL_KeyboardEvent& ke); // Constructor desde SDL3
  };
  ```
- ✅ Actualizado `widget::key_event` para usar `key_info`
- ✅ Actualizado `widget::fire_key_event()` y `widget::on_char()`
- ✅ Actualizado `widget_edit::on_char()` y `widget_slider::on_char()`
- ✅ Todos los widgets ahora usan `key_info` en lugar de `SDL_Keysym`

### 7. Archivos modificados
**Total: 145+ archivos** en `src/` (*.cpp, *.h)

---

## 🚫 Bloqueante: SDL3_mixer

### Problema crítico

SDL3_mixer **cambió completamente su arquitectura**. No es una simple migración de API:

**SDL2_mixer (antiguo)**:
```cpp
Mix_Music *music = Mix_LoadMUS("song.ogg");
Mix_Chunk *sound = Mix_LoadWAV("effect.wav");
Mix_PlayMusic(music, -1);
Mix_PlayChannel(-1, sound, 0);
```

**SDL3_mixer (nuevo)**:
```cpp
// Arquitectura completamente diferente:
MIX_Mixer *mixer = MIX_CreateMixerDevice(...);
MIX_Audio *audio = MIX_LoadAudio("song.ogg");
MIX_Track *track = MIX_CreateTrack(...);
MIX_PlayAudio(track, audio, ...);
```

### Cambios en SDL3_mixer

1. **Tipos eliminados**:
   - ❌ `Mix_Music` → No existe
   - ❌ `Mix_Chunk` → No existe
   - ❌ `Mix_OpenAudio()` → No existe
   - ❌ `Mix_PlayMusic()` → No existe
   - ❌ `Mix_PlayChannel()` → No existe

2. **Nuevos tipos**:
   - ✅ `MIX_Mixer` - Dispositivo de mezcla
   - ✅ `MIX_Audio` - Datos de audio
   - ✅ `MIX_Track` - Canal de reproducción
   - ✅ `MIX_Group` - Grupo de tracks

3. **Nueva arquitectura**:
   - Sistema basado en tracks (similar a DAW)
   - Soporte para múltiples dispositivos
   - API orientada a propiedades
   - Mezcla en memoria o a dispositivo

### Impacto en el proyecto

El archivo `src/music.h` usa extensivamente la API antigua:
- `std::unique_ptr<Mix_Music>` (línea 158)
- `std::map<std::string, Mix_Chunk*>` (líneas 160-161)
- Cientos de llamadas a funciones `Mix_*` en `music.cpp`

**Estimación de trabajo**: Reescribir completamente `music.h/cpp` (~2000 líneas) + actualizar todos los usos en el juego (~50 archivos).

---

## 📋 Tareas Restantes (Estimación)

### Bloqueante mayor
1. ❌ **Reescribir sistema de audio completo** (~20-30 horas)
   - Diseñar nueva arquitectura con `MIX_Mixer`, `MIX_Audio`, `MIX_Track`
   - Migrar `music.h/cpp` (2000+ líneas)
   - Actualizar ~50 archivos que usan el sistema de audio
   - Testear todas las funciones de audio del juego

### Bloqueantes menores (pendientes sin audio)
2. ❌ **Errores de punteros** (~1-2 horas)
   - `src/coastmap.cpp` (línea 998)
   - `src/height_generator_map.cpp` (línea 73)
   - Investigar cambios en API de superficies SDL3

3. ❌ **Testing completo** (~2-3 horas)
   - Compilar sin errores
   - Ejecutar tests unitarios
   - Testear manualmente el juego
   - Verificar gráficos, input, eventos

---

## 🔍 Conclusión y Recomendación

### Estado actual
- ✅ **75% completado** (todo excepto audio)
- ✅ Sistema de eventos **completamente migrado**
- ✅ Sistema de widgets **refactorizado** para SDL3
- ✅ Includes y constantes **actualizados** globalmente
- ❌ Sistema de audio **bloqueado** por cambios incompatibles en SDL3_mixer

### Recomendación

**NO MIGRAR A SDL3 en este momento** por las siguientes razones:

1. **SDL3_mixer es incompatible**: Requiere reescritura completa del sistema de audio
2. **SDL3 aún en desarrollo**: API puede cambiar (actualmente en v3.4.0, no estable)
3. **Riesgo vs beneficio**: El esfuerzo de migración no justifica los beneficios actuales
4. **SDL2 es estable**: Funciona perfectamente y está ampliamente soportado

### Alternativa propuesta

**Mantener SDL2 y revisar SDL3 en el futuro**:
- Esperar a SDL3 v4.0 o superior (API estable)
- Esperar a que SDL3_mixer madure y tenga mejor compatibilidad
- Revisar la migración en 6-12 meses cuando el ecosistema SDL3 esté más maduro

### Valor del trabajo realizado

Aunque la migración no se completó, el trabajo tiene valor:

1. **Script de instalación** (`install_sdl3_3.4.0.sh`) - reutilizable
2. **Documentación detallada** - guía para futuras migraciones
3. **Refactorización de widgets** - estructura `key_info` es más limpia que `SDL_Keysym`
4. **Conocimiento adquirido** - cambios de SDL3 documentados

---

## 🚀 Si decides continuar en el futuro

### Paso 1: Verificar madurez de SDL3_mixer
```bash
# Verificar versión y compatibilidad
pkg-config --modversion SDL3_mixer
# Revisar changelog y breaking changes
```

### Paso 2: Diseñar nueva arquitectura de audio
- Estudiar ejemplos de SDL3_mixer
- Crear capa de abstracción para facilitar migración
- Testear con prototipo pequeño

### Paso 3: Migración incremental
- Migrar primero música de fondo
- Luego efectos de sonido
- Finalmente audio 3D y posicional

---

## 📚 Referencias

- [SDL3 Migration Guide](https://github.com/libsdl-org/SDL/blob/main/docs/README-migration.md)
- [SDL3 API Reference](https://wiki.libsdl.org/SDL3/)
- [SDL3_mixer Examples](https://github.com/libsdl-org/SDL_mixer/tree/main/examples)

---

**Branch**: `feature/sdl3-migration`
**Para continuar**: Ver pasos arriba
**Para volver a SDL2**: `git checkout master`
**Última actualización**: 2026-03-02

