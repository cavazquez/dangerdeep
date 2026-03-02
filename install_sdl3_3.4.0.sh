#!/bin/bash
set -e

# Script para instalar SDL3 3.4.0 + SDL3_mixer + SDL3_image desde el código fuente

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
SDL3_VERSION="3.4.0"
SDL3_MIXER_BRANCH="main"  # SDL3_mixer aún no tiene tags de versión estables
SDL3_IMAGE_BRANCH="main"  # SDL3_image aún no tiene tags de versión estables
BUILD_DIR="/tmp/sdl3_build_$$"
INSTALL_PREFIX="/usr/local"
JOBS=$(nproc)

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}  Instalación de SDL3 ${SDL3_VERSION} + SDL3_mixer + SDL3_image${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# Función para mostrar progreso
progress() {
    echo -e "${YELLOW}[$(date +%H:%M:%S)]${NC} $1"
}

# Función para errores
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# Verificar si se ejecuta como usuario normal
if [ "$EUID" -eq 0 ]; then 
    error_exit "No ejecutes este script como root. Usará sudo cuando sea necesario."
fi

# ===== PASO 1: Instalar dependencias =====
progress "Instalando dependencias del sistema..."
sudo apt-get update || error_exit "No se pudo actualizar repositorios"
sudo apt-get install -y \
    build-essential \
    cmake \
    git \
    pkg-config \
    ninja-build \
    libasound2-dev \
    libpulse-dev \
    libaudio-dev \
    libjack-dev \
    libsndio-dev \
    libsamplerate0-dev \
    libx11-dev \
    libxext-dev \
    libxrandr-dev \
    libxcursor-dev \
    libxfixes-dev \
    libxi-dev \
    libxss-dev \
    libxkbcommon-dev \
    libxtst-dev \
    libxv-dev \
    libxxf86vm-dev \
    libdrm-dev \
    libgbm-dev \
    libgl1-mesa-dev \
    libgles2-mesa-dev \
    libegl1-mesa-dev \
    libdbus-1-dev \
    libwayland-dev \
    libxinerama-dev \
    wayland-protocols \
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    libwebp-dev \
    libavif-dev \
    libjxl-dev \
    libflac-dev \
    libvorbis-dev \
    libopus-dev \
    libmpg123-dev \
    libmodplug-dev \
    libwavpack-dev \
    libudev-dev \
    libpipewire-0.3-dev \
    libdecor-0-dev \
    libusb-1.0-0-dev \
    || error_exit "No se pudieron instalar las dependencias"

echo -e "${GREEN}✓ Dependencias instaladas${NC}"

# ===== PASO 2: Crear directorio de trabajo =====
progress "Creando directorio temporal de compilación..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
echo -e "${GREEN}✓ Directorio creado: $BUILD_DIR${NC}"

# ===== PASO 3: Clonar y compilar SDL3 =====
progress "Clonando SDL3 v${SDL3_VERSION}..."
git clone --depth 1 --branch "release-${SDL3_VERSION}" https://github.com/libsdl-org/SDL.git SDL3 \
    || error_exit "No se pudo clonar SDL3"
cd SDL3

progress "Configurando SDL3 con CMake..."
mkdir build
cd build
cmake .. \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DSDL_SHARED=ON \
    -DSDL_STATIC=OFF \
    -DSDL_TEST=OFF \
    -DSDL_TESTS=OFF \
    || error_exit "Falló la configuración de SDL3"

progress "Compilando SDL3 (usando $JOBS cores)..."
ninja -j$JOBS || error_exit "Falló la compilación de SDL3"

progress "Instalando SDL3..."
sudo ninja install || error_exit "Falló la instalación de SDL3"
sudo ldconfig

echo -e "${GREEN}✓ SDL3 ${SDL3_VERSION} instalado correctamente${NC}"

# Verificar instalación de SDL3
SDL3_INSTALLED_VERSION=$(pkg-config --modversion sdl3 2>/dev/null || echo "ERROR")
if [ "$SDL3_INSTALLED_VERSION" = "ERROR" ]; then
    error_exit "SDL3 no se instaló correctamente"
fi
echo -e "${GREEN}  → Versión instalada: $SDL3_INSTALLED_VERSION${NC}"

# ===== PASO 4: Clonar y compilar SDL3_image =====
cd "$BUILD_DIR"
progress "Clonando SDL3_image..."
git clone --depth 1 --branch "$SDL3_IMAGE_BRANCH" https://github.com/libsdl-org/SDL_image.git SDL3_image \
    || error_exit "No se pudo clonar SDL3_image"
cd SDL3_image

progress "Configurando SDL3_image con CMake..."
mkdir build
cd build
cmake .. \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DSDL3IMAGE_SHARED=ON \
    -DSDL3IMAGE_STATIC=OFF \
    -DSDL3IMAGE_TESTS=OFF \
    -DSDL3IMAGE_PNG=ON \
    -DSDL3IMAGE_JPG=ON \
    -DSDL3IMAGE_TIF=ON \
    -DSDL3IMAGE_WEBP=ON \
    -DSDL3IMAGE_AVIF=ON \
    -DSDL3IMAGE_JXL=ON \
    || error_exit "Falló la configuración de SDL3_image"

progress "Compilando SDL3_image (usando $JOBS cores)..."
ninja -j$JOBS || error_exit "Falló la compilación de SDL3_image"

progress "Instalando SDL3_image..."
sudo ninja install || error_exit "Falló la instalación de SDL3_image"
sudo ldconfig

echo -e "${GREEN}✓ SDL3_image instalado correctamente${NC}"

# Verificar instalación de SDL3_image
SDL3_IMAGE_INSTALLED=$(pkg-config --exists SDL3_image && echo "OK" || echo "ERROR")
if [ "$SDL3_IMAGE_INSTALLED" = "ERROR" ]; then
    echo -e "${YELLOW}⚠ SDL3_image instalado pero no disponible en pkg-config${NC}"
else
    echo -e "${GREEN}  → SDL3_image detectado por pkg-config${NC}"
fi

# ===== PASO 5: Clonar y compilar SDL3_mixer =====
cd "$BUILD_DIR"
progress "Clonando SDL3_mixer..."
git clone --depth 1 --branch "$SDL3_MIXER_BRANCH" https://github.com/libsdl-org/SDL_mixer.git SDL3_mixer \
    || error_exit "No se pudo clonar SDL3_mixer"
cd SDL3_mixer

progress "Configurando SDL3_mixer con CMake..."
mkdir build
cd build
cmake .. \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DSDL3MIXER_SHARED=ON \
    -DSDL3MIXER_STATIC=OFF \
    -DSDL3MIXER_FLAC=ON \
    -DSDL3MIXER_OPUS=ON \
    -DSDL3MIXER_VORBIS=ON \
    -DSDL3MIXER_MP3_MPG123=ON \
    -DSDL3MIXER_MOD_MODPLUG=ON \
    -DSDL3MIXER_WAVPACK=ON \
    || error_exit "Falló la configuración de SDL3_mixer"

progress "Compilando SDL3_mixer (usando $JOBS cores)..."
ninja -j$JOBS || error_exit "Falló la compilación de SDL3_mixer"

progress "Instalando SDL3_mixer..."
sudo ninja install || error_exit "Falló la instalación de SDL3_mixer"
sudo ldconfig

echo -e "${GREEN}✓ SDL3_mixer instalado correctamente${NC}"

# Verificar instalación de SDL3_mixer
SDL3_MIXER_INSTALLED=$(pkg-config --exists SDL3_mixer && echo "OK" || echo "ERROR")
if [ "$SDL3_MIXER_INSTALLED" = "ERROR" ]; then
    echo -e "${YELLOW}⚠ SDL3_mixer instalado pero no disponible en pkg-config${NC}"
else
    echo -e "${GREEN}  → SDL3_mixer detectado por pkg-config${NC}"
fi

# ===== PASO 6: Verificación final =====
echo ""
echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}  Verificación de instalación${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

echo -e "${GREEN}Librerías instaladas:${NC}"
echo "  • SDL3: $(pkg-config --modversion sdl3 2>/dev/null || echo 'instalado en /usr/local')"
echo "  • SDL3_image: $(pkg-config --modversion SDL3_image 2>/dev/null || echo 'instalado en /usr/local')"
echo "  • SDL3_mixer: $(pkg-config --modversion SDL3_mixer 2>/dev/null || echo 'instalado en /usr/local')"
echo ""

echo -e "${GREEN}Ubicación de archivos:${NC}"
echo "  Headers:   $INSTALL_PREFIX/include/SDL3/"
echo "  Libraries: $INSTALL_PREFIX/lib/"
echo "  pkg-config: $INSTALL_PREFIX/lib/pkgconfig/"
echo ""

# Verificar que las librerías existen
if [ -f "$INSTALL_PREFIX/lib/libSDL3.so" ]; then
    echo -e "${GREEN}✓ libSDL3.so encontrado${NC}"
else
    echo -e "${RED}✗ libSDL3.so NO encontrado${NC}"
fi

if [ -f "$INSTALL_PREFIX/lib/libSDL3_image.so" ]; then
    echo -e "${GREEN}✓ libSDL3_image.so encontrado${NC}"
else
    echo -e "${RED}✗ libSDL3_image.so NO encontrado${NC}"
fi

if [ -f "$INSTALL_PREFIX/lib/libSDL3_mixer.so" ]; then
    echo -e "${GREEN}✓ libSDL3_mixer.so encontrado${NC}"
else
    echo -e "${RED}✗ libSDL3_mixer.so NO encontrado${NC}"
fi

# ===== PASO 7: Limpieza =====
echo ""
progress "Limpiando archivos temporales..."
cd /
rm -rf "$BUILD_DIR"
echo -e "${GREEN}✓ Archivos temporales eliminados${NC}"

# ===== PASO 8: Configuración adicional =====
echo ""
echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}  Configuración adicional${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

echo "Para usar SDL3 en tus proyectos, asegúrate de que CMake pueda encontrarlo:"
echo ""
echo -e "${YELLOW}# Agrega a tu CMakeLists.txt:${NC}"
echo "  find_package(SDL3 3.4.0 REQUIRED)"
echo "  find_package(SDL3_image REQUIRED)"
echo "  find_package(SDL3_mixer REQUIRED)"
echo ""
echo "O usa pkg-config:"
echo "  pkg-config --cflags --libs sdl3"
echo "  pkg-config --cflags --libs SDL3_image"
echo "  pkg-config --cflags --libs SDL3_mixer"
echo ""

echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}  ✓ Instalación completada exitosamente${NC}"
echo -e "${GREEN}================================================================${NC}"
echo ""
echo "Tiempo total: $SECONDS segundos"
