# Versión 0.5 · arte, animación, navegación y controles

## Arte y movimiento visual

Las piezas del personaje usan una malla biselada compartida, con brazos y piernas separados en codos y rodillas. Las articulaciones acompañan avance, marcha lateral y agachado; el torso respira en reposo, se inclina en carrera/esquiva y reacciona al impacto. Recargar mueve la mano al arma y curarse recoge los brazos. Son animaciones procedurales, no clips de captura de movimiento. El arma conserva su raíz independiente para las tres clases existentes.

El almacén usa `assets/concrete-v05.png`, generado con la herramienta integrada de imagen y aplicado con proyección triplanar. Prompt y procedencia en `ARTE-0.5.md`. Las cajas industriales adoptan una paleta fría. La nueva furgoneta incluye ventanas, parrilla, ruedas y desgaste, con un obstáculo sólido y espacio reservado sin árboles. Los cuerpos abatidos permanecen visibles, no bloquean y no generan botín extra al recibir otro impacto. Se conservan al restaurar la incursión.

## Navegación

La rejilla AStar pasa a celdas de 0,5 metros. Las paredes/coberturas se expanden 0,46 metros antes de calcular rutas. Un barrido de esfera de radio 0,44 verifica espacio al suavizar segmentos y al elegir puntos cercanos si el redondeo cae en una celda prohibida. Cada ruta mantiene un tramo inicial desde la posición real. Los atajos tienen una búsqueda acotada de 12 puntos.

Los enemigos conservan detección por rayos físicos, memoria, investigación de ruido, búsqueda y regreso. Recalculan a intervalos y al desplazarse el objetivo; giran gradualmente y aceleran/frenan. Se separan de vecinos en un radio de 1,5 metros. Si no progresan durante 0,65 segundos, buscan un paso lateral comprobado de 1,1 metros o cambian el destino de patrulla. Las configuraciones son copias por actor para evitar modificar el catálogo compartido.

Las pruebas recorren físicamente un desvío, verifican cada segmento en almacén/cobertura/furgoneta y hacen cruzarse dos enemigos con colisiones activas. No garantizan todas las combinaciones de una multitud; el siguiente paso es observar sesiones largas.

## Controles y UX

El stick izquierdo admite un inicio adaptable en la parte inferior izquierda fuera del pad habitual; se puede fijar en Ajustes. Conserva un único propietario por dedo. El apuntado arranca al superar el 29 % del radio y vuelve al reposo por debajo del 21 %, reduciendo cortes por pequeñas oscilaciones. No se concede disparo durante esquiva ni invulnerabilidad.

Cambio de tamaño, pausa y cierre limpian entradas. Un toque cancelado por el sistema o arrastrado no activa botones. El botón Volver de Ajustes permanece en el pie fijo. Los mensajes de recarga/curación/extracción y entrega tienen prioridad sobre el tutorial, evitando texto superpuesto.

**Ajustes → Probar controles táctiles** usa el mismo código de sticks y botones del juego. Cuenta acciones de un tercer dedo con ambos sticks activos, muestra cuándo se suelta cada control y mantiene la incursión pausada. El resultado sirve al jugador para comprobar el teléfono, no certifica automáticamente que se haya realizado una prueba física.

## Compatibilidad

Versión 0.5.0 / código 5, Godot 4.7.2. El guardado sigue en v3 con campos opcionales y configuración adaptable por defecto; no se borra el perfil. Android ARM64, mínimo API 24 y objetivo 36; iOS ARM64 con mínimo 15.0 para Xcode 27. Ninguna dependencia Phaser ni servicio de red. La escena y lógica son comunes a las exportaciones nativa y web.

## Compatibilidad con iOS 27

La prueba de arranque en el iPhone reveló un cierre de la plantilla 4.5.1 en UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption. Se actualizó a motor/plantillas 4.7.2 oficiales, verificando sus SHA256; la exportación incluye UIApplicationSceneManifest. GodotPhysics3D queda seleccionado explícitamente para conservar las colisiones de la base anterior. Los botones táctiles consumen sus eventos y los reenvían al scroll padre, evitando doble acción del nuevo Button nativo.

En builds de depuración móviles se guarda una captura inicial y estado local (`native-validation-v05.*`). La calibración nativa registra contactos, liberación independiente y recursos conservados en `touch-validation-v05.json`, y captura cuando se confirma el tercer dedo. No envía nada por red. Estos archivos sirven para verificar una sesión real posteriormente; su mera implementación no se considera una prueba física realizada.

Si una partida anterior coloca al personaje dentro de nueva cobertura, su primer tick activo busca una posición libre cercana. Una posición válida permanece intacta. La recolocación sólo se aplica al aparecer/reanudar, nunca al caminar contra una pared.
