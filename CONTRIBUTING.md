# Continuar el desarrollo

## Herramientas y primer arranque

Usa Godot **4.7.2 estándar**, GDScript y Compatibility, con GodotPhysics3D tal como indica project.godot. Abre/importa el proyecto en el editor y pulsa F5. La importación reconstruye .godot/ y los archivos .import; no deben subirse. Los archivos .gd.uid sí se versionan.

Para pruebas nativas necesitas Python 3, sin paquetes adicionales. El ejecutor admite Godot en PATH o una ruta explícita:

```sh
python3 tests/run_tests.py
```

En macOS, por ejemplo:

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot python3 tests/run_tests.py
```

En PowerShell, usando la ruta real de tu ejecutable:

```powershell
$env:GODOT_BIN = 'C:\Herramientas\Godot\Godot.exe'
python tests/run_tests.py
```

El ejecutor importa una copia limpia antes de las ocho suites. En la revisión 0.5.1 pasan 235 comprobaciones. Un proceso con código 0 no basta: también se revisan errores y el marcador final. Los registros se guardan en builds/. Los tests utilizan perfiles propios; no sustituyas esos nombres por el guardado del jugador.

## Prueba web

Sólo para exportación/verificación web: instala las plantillas oficiales **4.7.2** y Node.js 22 con npm. Desde la raíz, con el ejecutable godot en PATH:

```sh
mkdir -p builds/web
godot --headless --path . --export-debug Web builds/web/index.html
npm ci
npx playwright install chromium
npm run preview
```

En otra terminal:

```sh
npm run test:web
```

Si Godot no está en PATH, sustituye godot por su ruta al exportar. En Windows puedes crear builds/web desde el explorador o PowerShell. El servidor de pruebas escucha sólo en 127.0.0.1:8787. La suite usa contextos de navegador de prueba y no modifica el perfil de tu vista previa habitual. En 0.5.1 pasan 35 comprobaciones. Capturas, estado y errores se guardan en builds/; deben inspeccionarse al modificar controles o interfaz. El hook advanceTime espera tiempo real: estas pruebas no son una simulación determinista.

## Dónde trabajar

| Cambio | Archivos principales |
| --- | --- |
| Ciclo de incursión, pausa, extracción y resultados | scripts/main.gd |
| Movimiento, resistencia, disparo y curación | scripts/player.gd |
| IA, navegación y colisiones | scripts/enemy.gd, scripts/world.gd |
| Refugio, inventario y persistencia | scripts/progression.gd, scripts/inventory.gd, scripts/save_store.gd |
| Interfaz y entrada táctil | scripts/ui.gd, scripts/touch_*.gd |
| Modelos, materiales, animación y efectos | scripts/art.gd, scripts/effects.gd, assets/ |
| Lore, objetos, recetas, enemigos y contratos | data/ y authoring/create_data.py |
| Eventos, señuelos y entregas | scripts/raid_content.gd, data/expedition.json |
| Regresiones | tests/ |

Si modificas los JSON generados, actualiza también authoring/create_data.py para que ejecutar el generador no deshaga el cambio. Los WAV originales se generan con authoring/create_sound.py. La textura IA y su prompt están documentados en docs/ARTE-0.5.md; revisa docs/PROCEDENCIA.md antes de incorporar recursos nuevos.

## Criterios para una mejora

- Mantén el objetivo: extracción móvil, horizontal, PvE de un jugador y sin conexión. Ver docs/DISEÑO.md y docs/REQUISITOS.txt.
- Conserva inventario, cargadores y recompensas en cada transición; una incursión recuperada vuelve pausada. Añade migración y pruebas si cambias el guardado v3.
- Reproduce un fallo antes de corregirlo y añade una prueba cuando proteja una transición importante. Para cambios visuales sencillos, revisa capturas en lugar de crear tests que sólo repitan el código.
- Comprueba movimiento, apuntado y una tercera acción simultánea. Entradas sintéticas no acreditan ergonomía ni gestos físicos.
- Registra lo cambiado, pruebas y limitaciones en progress.md o en la descripción del cambio. No marques como realizadas las pruebas de teléfono que siguen pendientes.
- Publica compilaciones como GitHub Releases si las necesitas; mantén motor, SDK, node_modules, cachés y firmas fuera del código fuente.

Consulta docs/EXPORTACIONES.md para reconstruir Android/iOS/macOS. El Team ID portable está vacío: la firma se configura en cada entorno de desarrollo.
