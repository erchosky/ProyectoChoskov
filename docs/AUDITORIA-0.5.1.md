# Auditoría y depuración · 0.5.1

Realizada el 4 de octubre de 2026 sobre Godot 4.7.2. Revisión funcional de inventario/economía, guardado y migraciones, resultados, entrada táctil, paneles, combate, navegación y ciclo refugio/incursión. No se añaden bibliotecas ni se cambia el formato de guardado v3.

## Fallos reproducidos y corregidos

| Prioridad | Fallo y reproducción | Corrección |
| --- | --- | --- |
| Alta | Al fallar la escritura tras extraer o morir, Escape/Tab/foco permitían sustituir el panel de reintento y volver a jugar. Un reintento también podía cambiar éxito por muerte o viceversa. | El primer resultado conserva su intención; mochila, mapa, pausa y reanudación mantienen el panel de reintento. La recompensa y el ID se resuelven una sola vez. |
| Alta | Un archivo con checksum correcto pero objetos desconocidos, cantidades negativas, arma inválida o escena incompleta pasaba la lectura y fallaba al acceder al catálogo o restaurar actores. | Validación de tipos, IDs, cantidades, equipo, ajustes, coordenadas, enemigos, contenedores y señuelos antes de restaurar. Se recupera la copia validada; sólo si ambas fallan se usa perfil inicial, como en versiones previas. |
| Media | Sin armas ni fichas, llevar sólo chaleco/mochila bloqueaba el kit de emergencia y el despliegue. | El kit exige ausencia de arma equipada/almacenada, conserva protección y mochila y respeta su capacidad. La acción también aparece en el refugio. |
| Media | Un botón recortado por el scroll seguía recibiendo eventos táctiles globales fuera de la zona visible. También bloqueaba la entrada de los sticks en esa zona. | La detección táctil y la exclusión de sticks respetan todos los ancestros con recorte. Se conserva el scroll sobre botones y la cancelación por arrastre. |

La nueva reproducción inicial produjo 14 comprobaciones fallidas por estas cuatro causas: `builds/audit-reproduction.log`. Tras corregirlas, las 24 comprobaciones específicas pasan: `tests/test_audit.gd` / `builds/audit-fixed.log`.

## Compatibilidad y verificación

- **235 comprobaciones nativas** pasan en ocho suites: `builds/audit-native-final.log`. Incluyen las 211 previas de combate, movilidad, IA, contenidos y multitáctil.
- **35 comprobaciones Chromium** pasan: `builds/audit-browser-final.log` y `builds/browser-results.json`, sin errores de consola/script. Además de controles/saqueo/señuelos, se camina hasta la salida, se espera la extracción, se guarda botín, se despliega otra vez y se suspende/reanuda pausado. Cada escenario usa un perfil de prueba separado del jugador.
- El primer intento de ampliar el recorrido murió tras atraer patrullas con el señuelo. Se corrigió la precondición del test: extracción desde una incursión nueva. No se eliminan enemigos ni se simula una victoria. Evidencia del intento: `builds/browser-failure.*`.
- Cliente original develop-web-game ejecutado: `builds/browser-audit/shot-0.png`, `state-0.json`, sin errores. Captura/estado inspeccionados, además de calibración, extracción y viewport 844×390. El hook web advanceTime espera tiempo real; no se presenta como simulación determinista.
- Se conservan migraciones v1/v2/v3. Ajustes ausentes se completan con valores seguros. El pequeño search_timer negativo que guardaban versiones anteriores se normaliza a cero; la IA actual evita generarlo. Se comprueba roundtrip de una escena completa.
- El runner exige marcador final con cero fallos y rechaza FAIL/errores aunque el motor termine con código 0. El cliente web conserva estado/captura al fallar y cierra Chromium.
- APK **0.5.1/código 6**, ARM64/API 24–36, firma v2/v3 válida, sin permisos. Los siete catálogos del APK coinciden con la fuente. macOS universal, web e IPA de desarrollo regenerados. Fuentes y SHA256 actualizados.
- **iPhone:** 0.5.1 compila, codesign valida y se instala conservando el contenedor. El intento de abrir devuelve Locked: el teléfono está bloqueado. El renderizado inicial de 0.5.0 sí está documentado, pero no acredita ejecución de 0.5.1. Informe: `builds/ios-signature-audit.json`.

## Límites pendientes

El usuario aplazó la prueba con dedos físicos. Quedan gestos sobre cristal, suspensión real, audio/ergonomía de móvil, Android físico, rendimiento sostenido, temperatura/batería y balance con jugadores. No se pidió desbloquear ni repetir ahora esa prueba.

No se encontraron nuevas regresiones en las rutas, colisiones o combate cubiertos por las pruebas. Eso describe el alcance comprobado, no garantiza ausencia de cualquier fallo posible.
