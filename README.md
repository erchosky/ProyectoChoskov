# Proyecto Choskov · La descarga

Juego de extracción 3D, PvE, de un jugador y sin conexión. Está preparado para Android e iPhone en horizontal y desarrollado con Godot 4.7.2, GDScript y el renderizador Compatibility.

La versión 0.5.1 incorpora correcciones de entrada táctil, equipamiento y guardado. Es un prototipo con identidad, personajes, escenarios y sonidos originales; la verificación en dispositivos y sus límites se detallan más abajo.

[Empezar desde GitHub o el ZIP](#empezar-desde-github-o-el-zip) · [Revisión de depuración 0.5.1](#revisión-de-depuración-051) · [Novedades 0.5](#novedades-05) · [Novedades 0.4](#novedades-04) · [Jugar ahora](#jugar-ahora) · [Primera incursión](#primera-incursión)

---

## Empezar desde GitHub o el ZIP

1. Instala **Godot 4.7.2 estándar**. El motor y los SDK no están incluidos.
2. Importa `project.godot` en el editor, espera la importación de recursos y pulsa **F5**. No necesitas Node, Android SDK ni Xcode para jugar y editar en Godot.
3. Para ejecutar las pruebas instala Python 3 y ejecuta `python3 tests/run_tests.py`. El ejecutor importa recursos y clases automáticamente. Busca `godot`/`godot4` en PATH; también admite `GODOT_BIN` con la ruta al ejecutable.

Las plantillas de exportación de Godot 4.7.2 sólo son necesarias al generar Android, iOS, web o macOS. La carpeta `builds/` se genera localmente y no forma parte del repositorio. Para exportar web, servirla y verificarla, consulta [la guía de desarrollo](CONTRIBUTING.md). Para subir el ZIP, consulta [GitHub](docs/GITHUB.md). Prioridades pendientes: [ROADMAP.md](ROADMAP.md).

## Revisión de depuración 0.5.1

Cuatro fallos reproducidos y corregidos: toques en botones recortados por el scroll; retorno al juego con un resultado pendiente de escritura; kit de emergencia con chaleco/mochila pero sin arma; aceptación de guardados con datos internos inválidos. 24 pruebas de regresión nuevas, 235 comprobaciones nativas en total. La validación preserva perfiles válidos v1/v2/v3 y completa ajustes ausentes. Informe: `docs/AUDITORIA-0.5.1.md`. La 0.5.1 está instalada en iPhone, pero el arranque de esta revisión no pudo comprobarse porque el dispositivo está bloqueado.

## Novedades 0.5

Modelos con bordes biselados, codos y rodillas articulados, animaciones de recarga, curación e impacto; suelo industrial texturizado y furgoneta abandonada con cobertura real. Navegación con espacio para el cuerpo, rutas suavizadas, separación y recuperación de bloqueos. Joystick izquierdo adaptable, histéresis al apuntar y una pantalla de prueba de tres dedos en **Ajustes → Probar controles táctiles**. Consulta `docs/MEJORAS-0.5.md`.

Motor y plantillas actualizados a **Godot 4.7.2** para incorporar UIScene, exigido por iOS 27. La app 0.5 está firmada e instalada en el iPhone emparejado; el arranque y renderizado del refugio se han confirmado mediante captura/estado recuperados del dispositivo. El usuario no puede realizar ahora la prueba física de dedos. Las 235 pruebas nativas y las 35 del navegador simulan entradas táctiles; véase `docs/PRUEBAS-TACTILES.md`.

## Novedades 0.4

Lore adulto sobre una evacuación manipulada, responsabilidades de Nilo y negocios de supervivencia. Cuatro testimonios reescritos y consecuencias permanentes al entregar los seis contratos.

Personajes articulados con equipo de campaña, materiales procedurales, asfalto, chapa, óxido, lámparas y vegetación. Cámara más cercana con anticipación e impulso opcional. Movimiento con aceleración y frenado, carrera con resistencia y esquiva con colisiones y coste. Consulta `docs/MEJORAS-0.4.md` para controles y parámetros.

Conserva el contenido de 0.3: 21 objetos, tres armas, tres enemigos, seis contratos, cinco recetas, reserva cerrada, señuelos y entrega con refuerzos. Los guardados existentes se conservan.

## Jugar ahora

- **En este Mac:** abre `Jugar.command` o ejecuta `./tools/Godot.app/Contents/MacOS/Godot --path .`.
- **En Godot:** importa `project.godot` con Godot 4.7.2 y pulsa F6/F5 (F5 ejecuta el juego completo).
- **Android:** copia `builds/ProyectoChoskov-debug.apk` al teléfono e instálalo. Es un APK de pruebas firmado, para **ARM64**, mínimo Android 7. Permite la instalación desde la aplicación que uses para abrirlo. No requiere conexión ni permisos de red. Consulta `docs/EXPORTACIONES.md`.
- **Versión macOS independiente:** descomprime `builds/ProyectoChoskov-macOS.zip`. No está firmada ni notarizada; para probar en este entorno usa preferentemente `Jugar.command`.
- **Prueba web adicional:** `npm run preview`, después abre http://127.0.0.1:8787. Es la exportación del mismo juego de Godot. El guardado web vive en el navegador y está separado del guardado nativo. No abras el HTML con file://.

El ZIP `builds/ProyectoChoskov-fuentes.zip` contiene el proyecto portable, los recursos y las pruebas. No incluye el motor, SDK, claves ni carpetas temporales.

## Primera incursión

1. En **Equipo**, pulsa **Preparar suministros del almacén**; puedes cambiar a rifle. Entra en la incursión.
2. Explora la zona de inicio. La caja dorada cercana contiene chatarra, cable y un vendaje. Acércate y pulsa **Buscar**.
3. Toca las pilas para recogerlas. La mochila y el saqueo **pausan toda la acción**. Cierra para continuar.
4. El almacén al nordeste tiene la caja negra, un rifle y mejor botín. Sus vigías son más peligrosos. Puedes rodear el edificio o evitarlo.
5. El sendero sur está disponible. La torre norte aparece en ámbar y requiere **una batería**; hay una en la caja al sur de la torre. Entra en la salida y pulsa **Extraer** (o **Radio** para activarla). Mantente dentro seis segundos. Salir, recibir daño o pausar cancela la cuenta.
6. La caja del campamento tiene un **señuelo**: úsalo con **G** o su botón. El puesto forestal guarda la llave de la reserva norte, donde encontrarás Brezo y el registro de Taro. El capataz es opcional. A los 90 s se anuncia una entrega que llega 15 s después.
7. Tras extraer, guarda el contenido de la mochila en **Almacén**, entrega misiones y prepara otra salida. Si mueres, pierdes mochila y equipo; el almacén y las mejoras permanecen.

Cada incursión admite hasta **10 minutos**; al agotarse el tiempo se pierde lo llevado. Puedes extraer antes. La duración real y la dificultad de 5–10 minutos están pendientes de ajuste con jugadores en teléfonos.

## Controles

En teléfono: joystick izquierdo para moverse y derecho para apuntar/disparar; recargar, curar, buscar y mochila son botones independientes. Se admite movimiento, disparo y un tercer dedo. CORRER alterna la carrera y ESQUIVAR da un impulso con coste de resistencia. La barra ámbar muestra la resistencia; correr hace más ruido y la esquiva no da invulnerabilidad. El botón Sigilo reduce velocidad, ruido y detección; los enemigos avisan antes de atacar. Mapa pausa la acción y muestra rutas y objetivos. La zona muerta del joystick derecho evita disparos accidentales. Los paneles se pueden desplazar con un dedo. En Ajustes puedes modificar asistencia, sensibilidad, tamaño de joysticks, sonido, sombras y límite de 30/60 FPS.

En ordenador: **Shift** correr, **Espacio** esquivar, **G** señuelo, **WASD/flechas** mover, **clic izquierdo mantenido** apuntar/disparar, **C** sigilo, **M** mapa, **R** recargar, **H** curar, **E** buscar/extraer, **Tab** mochila, **Esc** pausa, **F** pantalla completa. La pausa devuelve los controles a cero. La curación requiere tiempo y se interrumpe al recibir daño; el consumible se gasta al empezar.

## Contenido

- Nilo, un lirón explorador; refugio y mapa de Linde de Bruma.
- Pistola Junco, rifle Zarzal y escopeta Brezo; merodeadores, vigías y el capataz opcional.
- 21 objetos editables en JSON, mochila de 12 ranuras (16 con mochila Travesía), apilado y comparación de armas.
- Seis contratos con recompensa única; dos extracciones, una reserva cerrada y entregas con refuerzos.
- Cinco recetas de fabricación para curación, cartuchos, señuelos y baterías. Cuatro páginas de lore permanentes.
- Almacén ampliable, suministros comprables, venta de objetos y taller que reduce dispersión.
- Kit de emergencia gratuito cuando no quedan armas; munición de emergencia si no hay munición ni fichas suficientes. Permite seguir sin recursos.
- Tutorial integrado; techos ocultos al aproximarse; sonidos originales, trazadores reutilizados, minimapa y avisos.

## Guardado

El archivo nativo es `user://choskov.json`. En macOS corresponde normalmente a `~/Library/Application Support/Godot/app_userdata/Proyecto Choskov/choskov.json`.

Guarda el almacén, equipo preparado, ajustes, progreso y la incursión activa. La incursión se guarda cada cinco segundos, al saquear/equipar/curar/recargar, al pausar y al cambiar de aplicación. Un cierre abrupto puede retroceder hasta el último punto guardado. Al recuperar una incursión, queda **pausada**; el botín sigue en riesgo. La extracción en curso no se reanuda automáticamente.

El formato v3 migra los perfiles v1/v2, conserva sus incursiones y añade diario y objetivo seguido. Lleva suma de comprobación; se escribe a un archivo temporal y se reemplaza el principal, con copia `.bak` del último guardado válido. Si el principal está dañado, se recupera la copia. Si ambos están dañados o pertenecen a una versión desconocida, se comienza un perfil nuevo; no existe migración desde versiones futuras. Los resultados registran un identificador procesado para impedir recompensas repetidas.

## Verificación y límites

Ejecuta `python3 tests/run_tests.py` (Godot local en `tools`, o `godot` en PATH). Hay **235 comprobaciones automatizadas** de inventario, economía, guardado, combate, entrada táctil, saqueo, IA y ciclo completo. El ejecutor rechaza errores de script aunque Godot devuelva código 0. Las pruebas utilizan archivos separados del perfil del jugador.

Consulta `docs/VERIFICACION.md` para los resultados y su alcance, y `docs/EXPORTACIONES.md` para Android/iOS. La instalación de 0.5.1 en iPhone está confirmada, pero su ejecución queda pendiente por bloqueo del dispositivo. El arranque y la pantalla inicial sí se verificaron en 0.5.0. Gestos físicos, HUD durante partida, ergonomía y rendimiento sostenido **siguen pendientes**. Esta entrega sigue siendo un prototipo con arte procedural y animación propia.

## Organización

`data/`: objetos, armas, enemigos, misiones, páginas del diario, recetas y eventos. `scripts/`: entrada táctil, movimiento/combate, IA, inventario, guardado, progresión, mundo, efectos, sonido e interfaz separados. `scenes/main.tscn`: entrada del juego. `assets/`: icono, sonidos y textura industrial generada con IA. `authoring/`: generadores reproducibles de datos y audio. `tests/`: pruebas. `docs/`: diseño, exportación, procedencia y registro.
