# Registro de verificación · 0.5.0 · 4 de octubre de 2026

## Ejecutado

| Entorno | Resultado | Evidencia |
|---|---|---|
| Godot 4.7.2 headless, macOS | 30 comprobaciones de inventario, progreso y guardado; 0 fallos | `builds/test_core.log` |
| Godot 4.7.2 headless, escena real con física | 40 comprobaciones de controles, combate, IA y ciclo; 0 fallos | `builds/test_gameplay.log` |
| Mejoras 0.2: migración, sigilo, radio, diario y UX | 43 comprobaciones; 0 fallos | `builds/test_upgrade.log` |
| Contenido 0.3: recetas, escopeta, jefe, reserva, señuelos y evento | 42 comprobaciones; 0 fallos | `builds/test_content.log` |
| Movimiento 0.4: aceleración, resistencia, carrera, esquiva, ruido y guardado | 22 comprobaciones; 0 fallos | `builds/test_mobility.log` |
| Navegación 0.5: segmentos, recorrido y cruce de enemigos | 16 comprobaciones; 0 fallos | `builds/test_navigation.log` |
| Entrada 0.5: calibración, cancelación e histéresis | 18 comprobaciones; 0 fallos | `builds/test_touch.log` |
| Ejecutor que revisa errores de script y de limpieza | 211 comprobaciones, sin errores de ejecución en la corrida final | `builds/verification-v05.log` |
| Chromium / exportación WebGL2 | 28 comprobaciones; consola sin errores | `builds/browser-results.json` |
| Cliente de la habilidad de juegos web | Inicio, movimiento, captura y estado de juego inspeccionados | `builds/browser-v05/` |
| Godot nativo con ventana, Apple M5 / OpenGL 4.1 Metal | Refugio, incursión, almacén, rutas y diario renderizados; capturas inspeccionadas | `builds/refugio.png`, `incursion.png`, `almacen.png`, `rutas.png`, `diario.png` |
| Exportación Android | APK ARM64, API mínimo 24, objetivo 36; firma v2/v3 válida | `builds/export-android-v05.log`, `apk-signature-v05.txt` |
| Exportación macOS y web | Ambas generadas | `builds/export-macos-v05.log`, `export-web-v05.log` |
| iOS / Xcode 27 / iOS 27 SDK | Proyecto exportado, compilación y firma válidas, instalado en iPhone; plantilla nueva UIScene; arranque/render inicial confirmado en iPhone | `builds/xcode-build-v05.log`, `ios-signature-v05.json`, `ios-install-v05.log`, `ios-launch-v05.log` |

Las pruebas de navegador usan eventos táctiles CDP para ambos joysticks y eventos DOM TouchEvent para soltar solamente el tercer dedo. Son una simulación en Chromium, no una prueba en pantalla táctil física. Las pruebas nativas envían InputEventScreenTouch/Drag al viewport y pulsan el botón de recarga y el de saqueo, con la emulación de ratón desactivada.

## Recorridos comprobados

- Movimiento y disparo simultáneos; cada dedo conserva su dueño; el tercer dedo pulsa recargar sin perder movimiento/apuntado. Liberar un dedo no suelta el otro. Zona muerta y limpieza al pausar.
- Cargadores iniciales, duración de recarga, gasto/conservación de munición. Pared del almacén bloquea disparos, detección y asistencia. Impacto con línea libre hace daño; muerte por disparos crea un único botín y cuenta una sola baja.
- Detección, persecución, pérdida de visión, búsqueda, regreso e investigación de ruido.
- Límite por ranuras y pilas, transferencia parcial, recogida por botón táctil y pausa al abrir saqueo; cierre reanuda.
- Consumo y tiempo de curación. Cambio de foco pausa el reloj, impide daño y borra los dedos.
- Activación de extracción; salir o recibir daño cancela; completar conserva lo llevado. Repetir la señal no concede otra recompensa.
- Volver al refugio, entrar de nuevo con el botín y equipo conservados, recuperar una incursión interrumpida pausada y con el mismo ID/contenedores, morir, conservar almacén y volver a jugar.
- Entrega de materiales consume objetos; recompensas no repetibles; misión de bajas y equipo de emergencia sin recursos.
- Cierre y lectura desde otro objeto de guardado; botín activo permanece en riesgo. Archivo principal dañado recupera una copia validada; el archivo dañado no reemplaza la copia sana. Una transición de extracción pendiente se liquida una vez al reabrir.

El movimiento automatizado no reemplaza una partida humana completa. La extracción se acelera mediante llamadas de prueba para comprobar su transición sin esperar seis segundos en cada escenario. El mapa completo y el combate se han observado en la ejecución con ventana, pero no se ha realizado una sesión manual de 10 minutos en teléfono.

## Mejoras 0.2 comprobadas

- Lectura y conservación única de páginas; siguen en el diario después de morir.
- Agacharse reduce detección; disparar revela durante cuatro segundos; postura guardada.
- Torre sin batería rechaza extracción; activación consume una; cancelar y volver no repite consumo; energía guardada.
- Aviso de ataque antes del daño, pausa durante aviso, esquiva fuera de alcance y blanco guardado.
- Perfil v1 con incursión/botín migra a v2 y se vuelve a escribir.
- Incursión suspendida bloquea economía y preparación; cantidades negativas/objetos desconocidos rechazados.
- Escritura fallida revierte compra, equipo, descubrimiento y resultado.
- Botón de sigilo funciona al borde con joystick aumentado, sin capturar un dedo de movimiento. Ratón sobre el botón no dispara. Mapa abre/pausa/cierra; conserva sus dimensiones cuadradas. Cambiar selección reemplaza una sola ficha.
- Los puntos del diario quedan libres de árboles generados. Los sonidos se paran al destruir la escena; el ejecutor permite al servidor de audio terminar su limpieza antes de salir.

## Contenido 0.3 comprobado

- Recetas: ingredientes exactos, output, requisito de tres lotes, recompensa única, rechazo por falta de espacio y rollback al fallar guardado; bloqueo con incursión suspendida.
- Perfil v2 migra a v3 con contador por defecto y conserva radio/equipo activo. Con sólo Brezo y cero fichas sigue siendo posible iniciar una incursión.
- Llave garantizada, reserva rechaza sin llave y la consume una vez; desbloqueo y botín retirado permanecen al reanudar.
- Equipada Brezo desde botín, arma/cargador anterior se conservan; recarga seis cartuchos y dispara varios impactos gastando sólo uno.
- Señuelo lanzado con botón táctil real y tercer dedo sin perder movimiento/apuntado; atrae patrulla, consume uno, no repite durante cooldown, se congela en pausa, restaura una señal y expira; el muro detiene el lanzamiento.
- Capataz se activa por proximidad, absorbe daño y deja prueba de contrato; no duplica actor ni mochila.
- Anuncio, paracaídas, pausa, llegada, contenido y dos refuerzos; no se repite evento al guardar/reanudar.
- Navegador: caminar hacia caja real, abrir saqueo, recoger señuelo, cerrar con botón, lanzarlo con su botón sin disparar, pulsar G sin duplicarlo; cinco recetas presentes en refugio. Se usa el estado de posición para corregir el recorrido entre ráfagas de entrada.
- Se corrigió una carrera en el estado del control bajo el ratón: la exclusión de disparo usa la posición del evento contra los botones, además de la prueba de conservación total de munición mientras una recarga puede terminar.
- Capturas nativas controladas de fabricación, capataz, paracaídas y mapa inspeccionadas (`builds/v03-*.png`); capturas web de fabricación, saqueo y señuelo también inspeccionadas.

## Rendimiento y pendiente

En la captura de referencia 0.1, de Godot nativo en **Apple M5**, la lectura final dio **60 FPS**, con el límite fijado a 60 y aproximadamente 527 llamadas de dibujo en la escena de almacén. Es una observación corta en ordenador, no un benchmark sostenido, ni un resultado de móvil. Se ofrece límite 30/60, sombras desactivables, materiales compartidos, MultiMesh estático, ocho enemigos iniciales, IA a intervalos, HUD a 10 Hz y 40 trazadores reutilizados.

El arranque y renderizado inicial están confirmados en iPhone; no hay mediciones sostenidas de rendimiento en teléfonos. Pendiente:

- Instalar el APK y probar al menos dos teléfonos Android de gama media, con 30/60 FPS y sombras activadas/desactivadas.
- Probar los gestos físicos y una incursión completa en el iPhone con la app de desarrollo ya ejecutada.
- Verificar recortes/zona segura, suspensión real, audio y ergonomía de tres dedos en ambas plataformas.
- Afinar duración de 5–10 minutos, botín, dificultad y legibilidad con jugadores. La cuenta máxima actual es de 10 minutos.
- Sustituir o ampliar animaciones/modelos provisionales y añadir pruebas prolongadas de consumo de memoria, temperatura y batería.

## Versión 0.4

Se han añadido comprobaciones de carrera, frenado tras soltar el teclado, botón de esquiva y congelación de resistencia/cooldown en el navegador. Las comprobaciones nativas cubren además agotamiento, recuperación, movimiento al apuntar, ausencia de invulnerabilidad, ausencia de disparo durante esquiva, pared del almacén, interrupción y tercer dedo. Las seis misiones muestran consecuencias tras entrega.

Materiales y modelos se agrupan sin incluir articulaciones. Capturas de la escena nativa y web revisadas para textura, sombra, legibilidad, controles y archivo de lore. Sigue pendiente medir rendimiento y ergonomía en teléfonos reales.

La captura breve 0.4 registra 53 FPS y 387 llamadas al dibujo en Apple M5, límite de 60 y herramientas de verificación abiertas. Es sólo una observación del escritorio. Los fragmentos de efectos son 64 reutilizados; las partes estáticas de los personajes se agrupan con MultiMesh y los sonidos de pasos se limitan por cadencia.

## Versión 0.5

Rutas con volumen de cuerpo y segmentos suavizados contrastadas en almacén, cobertura y vehículo. Un actor realiza el desvío físicamente y dos actores con colisiones recorren direcciones opuestas sin bloquearse. Pausa congela timers; cadáver visible no bloquea ni duplica botín.

La calibración verifica tres contactos independientes, liberación individual, cancelación por OS, arrastre y redimensionado. Se conserva munición, salud y reloj de la incursión. En navegador se corrigió el test: CDP touchEnd termina el conjunto de contactos; para levantar sólo uno se envía changedTouches DOM. Se encontró y corrigió Volver fuera del scroll de Ajustes y tutorial sobrepuesto al mensaje de recarga.

Capturas de suelo, vehículo, personaje, HUD, calibración y viewport horizontal de teléfono inspeccionadas. La lectura de FPS durante una pantalla de calibración pausada no se usa como benchmark de juego. No se han medido temperatura ni autonomía. El iPhone recibió la revisión 4.7.2 con UIScene y renderizó el refugio; no se presenta la simulación como prueba táctil física. Recorrido y limitación exacta en PRUEBAS-TACTILES.md.

La plantilla 4.5.1 llegó a iniciar y abortó con SIGTRAP en UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption (informe sanitizado: `builds/ios-crash-summary-v05.json`). Se migró a 4.7.2 oficial, se fijó GodotPhysics3D y se repitieron las 211 comprobaciones. La nueva plantilla lleva UIApplicationSceneManifest; Xcode compila y codesign valida. La instalación está confirmada. Tras un bloqueo Locked, un nuevo intento abrió la revisión final y se recuperaron captura/estado del refugio del propio contenedor de la app. El usuario indicó que no puede probar dedos ahora. No se infiere ejecución estable del éxito de la orden de lanzamiento.

Ejecución física confirmada con captura `builds/iphone-native-v05.png`, estado `.json` (OS iOS / 0.5.0) y proceso activo. Imagen horizontal 2293 × 1290 inspeccionada; footer y texto inicial legibles. No se ha ejecutado una sesión de incursión ni gestos de dedos en esta prueba; el usuario no puede probarlos ahora. No hay medida de rendimiento sostenido ni benchmark de iPhone.

## Auditoría 0.5.1

235 comprobaciones nativas y 35 Chromium pasan sin errores. Cuatro fallos reproducidos/corregidos en resultados pendientes, validación de guardados, kit de emergencia y recorte táctil. La escena completa y migraciones anteriores se conservan; ajustes ausentes se completan. Informe y evidencias en AUDITORIA-0.5.1.md. Exportaciones 0.5.1/código6 regeneradas. iPhone actualizado, pero bloqueado: ejecución de esta revisión no confirmada; no se reutiliza la captura 0.5.0 como evidencia nueva.
