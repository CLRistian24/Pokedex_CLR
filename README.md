# 🐉 PokéDex Nacional — Flutter App

Aplicación móvil y de escritorio desarrollada en Flutter para la gestión de datos Pokémon, equipos tácticos y visualización detallada utilizando la PokéAPI.

---

## 🚀 Características Principales (¿Qué hace y qué tiene?)

* **PokéDex CLR**: Paginación mediante *Scroll Infinito* no bloqueante con búsqueda local e integración directa por ID/Nombre a la PokéAPI.
* **Filtros Avanzados**: Filtrado interactivo por Generación (Gen 1 a Gen 6), Tipo base y Relaciones de Tipo (Fortalezas y Debilidades de daño 2x).
* **Gestión de Equipos**:
  * Creación, edición de nombre y eliminación de equipos (límite de 6 integrantes por equipo).
  * Reglas de validación: Impide registrar Pokémon repetidos o pertenecientes a la misma línea evolutiva.
  * Generador de Equipos Aleatorios con filtros personalizables.
* **Sets de Movimientos**: Asignación automática y manual de un set de 4 movimientos por Pokémon con vista detallada de sus especificaciones (Poder, Precisión, Tipo y Descripción).
* **Línea Evolutiva Interactiva**: Navegación y posibilidad de evolucionar o involucionar Pokémon directamente dentro de los equipos.
* **Audio y Multimedia**: Reproducción de gritos (*cries*) de Pokémon y visualización de versiones Shiny en alta resolución.
* **Personalización y Persistencia**: Preferencias de tema visual (colores de carcasa estilo PokéDex) y favoritos guardados localmente.

---

## 🔒 Permisos del Sistema

### 📱 Android (`android/app/src/main/AndroidManifest.xml`)
* `android.permission.INTERNET`: Requerido para consultar la PokéAPI, cargar imágenes de sprites y reproducir los gritos de audio en tiempo real.

### 🌐 Linux / Desktop (`linux/main.cc`)
* **Acceso a Red (Network Access)**: Requerido para peticiones HTTP salientes y almacenamiento en caché de imágenes/audio.

---

## 🛠️ Tecnologías Utilizadas

* **Flutter & Dart** (Compatible con Linux Desktop & Android)
* **Provider / ChangeNotifier** (Gestión de estado global)
* **HTTP & CachedNetworkImage** (Consumo de APIs e imágenes en caché)
* **AudioPlayers** (Reproducción de archivos de audio)
* **SharedPreferences** (Almacenamiento local persistente)