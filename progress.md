Original prompt: Implementar Proyecto Choskov según el documento adjunto: juego móvil nativo Godot 4, PvE sin conexión, 3D low poly, ciclo completo refugio/incursión/extracción/muerte, multitáctil, persistencia y exportaciones Android/iOS.

## Decisiones
- Proyecto vacío; sin AGENTS.md aplicable.
- Godot 4.5.1 stable (f62fdbde1), GDScript, Compatibility/OpenGL ES 3.
- La referencia es una wiki Next.js, no fuente del juego. No se reutilizan recursos ni código.
- Motor descargado localmente en tools; se prepara SDK Android y JDK local, sin instalaciones globales.
- Desarrollo nativo primero. La habilidad web se aplicará únicamente si se añade una exportación web para comprobarla.

## Entrega 0.1.0
- Ciclo completo Godot nativo implementado: refugio, mapa 3D, dos armas, dos enemigos, quince objetos, saqueo/mochila, dos extracciones, muerte, tres misiones, mejoras, compra/venta y kit de emergencia.
- Entrada propia por índice de dedo, botones con tercer dedo y desplazamiento de paneles. Emulación de ratón táctil desactivada.
- Guardado v1 con checksum, temporal y backup; ID de incursión/resultados únicos; recuperación pausada; copias no reciben botín activo automáticamente.
- Se corrigieron recuentos cero del inventario, conservación de cargadores al extraer/equipar, referencias de efectos al agrupar geometría, eliminación de paneles durante eventos de entrada y dependencia circular UI/minimapa al finalizar.
- Verificación final: 30 pruebas de sistemas + 40 de escena, sin errores de script; 8 en Chromium con multitáctil simulado. Capturas nativas y web inspeccionadas.
- APK Android debug ARM64 construido; firma v2/v3 verificada; Android API 24 mínimo, 35 objetivo; sin permisos de red. No hay dispositivo conectado, no se ha instalado.
- Exportaciones web y macOS adicionales. iOS intentado: falta App Store Team ID. Preset y documentación preparados; sin IPA firmado ni pruebas iPhone.
- Captura breve Apple M5: 60 FPS con límite 60 en almacén, aproximadamente 525 draw calls. No constituye medición móvil.
- README, diseño, verificación, exportación y procedencia documentados. Recursos originales; licencias Godot oficiales en data.

## Pendiente fuera de la verificación disponible
- Pruebas físicas Android/iPhone, firma Apple, ergonomía y safe areas reales.
- Balance de incursiones de 5–10 minutos, rendimiento sostenido/temperatura en gama media y pulido de modelos/animaciones.
- El avance temporal del harness web es tiempo real; no simula de forma determinista el motor de física de Godot. Las pruebas de escena nativas cubren las transiciones con pasos explícitos.

## Mejora 0.2 · petición de lógica, lore, UX/UI
- Tres páginas permanentes originales, Taro como hermano de Nilo, contratos contextualizados y pestaña Diario.
- Sigilo con velocidad/ruido/detección, exposición al disparar y sensibilidad aplicada al giro. Ataques de IA con aviso y punto fijado guardados.
- Torre norte consume una batería por incursión, caja norte garantizada y señales ámbar/verde; sur siempre disponible.
- Seguimiento de contratos, HUD con salud/progreso, mapa grande, refugio con narrativa, inventario ordenado y marcas de material, detalles reemplazables y pie fijo.
- Economía bloqueada durante incursión suspendida; rollback si falla la escritura; resultado pendiente con reintento; migración v1→v2.
- Se corrige sonido retenido al cerrar, disparo al pulsar UI con ratón y captura de botones por joysticks grandes.
- 113 comprobaciones nativas; 12 comprobaciones Chromium sin errores. APK 0.2 generado, firma v2/v3 verificada y datos contrastados con el proyecto; macOS y web exportados.
- La inspección visual encontró que _ready del minimapa reemplazaba el tamaño del mapa de rutas. Corregido y cubierto por una comprobación de dimensiones cuadradas.

- Capturas de refugio, HUD, rutas y diario inspeccionadas. Se sustituyen símbolos sin glifo en la fuente web por marcas ASCII legibles. Cliente original de la habilidad web ejecutado de nuevo sobre la entrega final.
- Pendiente: pruebas físicas móviles, balance con jugadores y firma Apple.

## Expansión 0.3 · más contenido
- 21 objetos, 3 armas, 3 enemigos, 6 contratos, 4 páginas y 5 recetas. Brezo dispara seis perdigones y consume un cartucho.
- Puesto norte con reserva cerrada: llave garantizada en puesto forestal, escopeta y registro cifrado dentro; capataz opcional con armadura y prueba de misión.
- Entrega a los 90/105 s, contenedor especial, dos refuerzos, evento guardado una vez. Señuelo con ocho segundos de ruido, cooldown, colisiones y restauración.
- Nuevo banco de fabricación, botón táctil de señuelo, mapa de evento y barra del jefe. Los materiales se consumen tras validar espacio; rollback al fallar guardado.
- Guardado v3 migra v1/v2. 42 pruebas nuevas en test_content.gd; total nativo 155. Chromium: 20 comprobaciones del recorrido y consola sin errores.

- Corregido disparo por carrera del control bajo el ratón: prueba el rectángulo del botón con la posición del propio evento. El test del navegador compara munición total para admitir completar una recarga durante el clic.
- El cliente web navega con pasos cortos corregidos por posición; el tiempo real de Godot puede avanzar durante capturas, por lo que no se supone una distancia fija tras mantener un dedo.
- Inspección de fabricación, puesto/jefe, paracaídas, mapa y señuelo nativo/web completada. Fuentes originales y exportaciones 0.3 actualizadas; pendiente dispositivo físico y balance con jugadores.

- Entrega final: APK 0.3.0/código 3 firmado v2/v3, sin permisos; siete JSON del APK contrastados con las fuentes; macOS 0.3 y web exportados. Cliente original web ejecutado e imagen/estado revisados. Código portable y SHA256 regenerados.

## Revisión 0.4 · lore adulto, gráficos y movilidad
- Cuatro testimonios y seis contratos reescritos: descarga industrial, evacuación manipulada, complicidad de Nilo y supervivencia de Vera. Epílogo permanente en cada contrato entregado. IDs y requisitos conservados. Generador JSON sincronizado.
- Aceleración/frenado, giro progresivo, piernas/brazos articulados, carrera con resistencia y ruido, esquiva con coste/cooldown y colisiones sin invulnerabilidad. Campos aditivos preservan incursiones v3 existentes. Pausa frena y suelta carrera.
- Personajes tácticos, superficies de ruido original, asfalto, chapa/óxido/respiraderos, bidones/lámparas/hierba, copas más detalladas, sombras oblicuas y ambiente frío. Cámara próxima, anticipación, apertura al correr e impacto opcional. Efectos reutilizados y sonido de pasos/esquiva propio.
- Interfaz acero/ámbar, resistencia visible y dos botones táctiles independientes. 22 pruebas nuevas; 177 nativas pasan. Primera revisión web: 20 anteriores pasan. Se amplía a 24 para movilidad nueva.
- La primera revisión visual detectó grano excesivo y manchas geométricas de suelo: se suaviza textura y elimina esa geometría. Se agrupan partes inmóviles del personaje, conservando articulaciones/arma. Pendiente verificación final, empaquetado y pruebas físicas de teléfonos.

- Verificación final 0.4: 177 pruebas nativas y 24 Chromium sin errores. Capturas de refugio, almacén, diario, HUD y viewport de teléfono revisadas. APK 0.4.0/código 4 firma v2/v3 válida, sin permisos; siete JSON del APK iguales a las fuentes. macOS 0.4.0 y web regenerados.
- Captura breve nativa Apple M5: lectura final 53 FPS / 387 llamadas, con límite de 60 y otras herramientas abiertas. No es medición sostenida ni de teléfono. El agrupado reduce llamadas respecto a la primera iteración visual.
- Fuente portable y huellas SHA256 se regeneran con esta entrega. Pendiente: pruebas físicas Android/iPhone, Team ID/firma Apple, sesiones de balance y rendimiento sostenido.

## Revisión 0.5 · arte, animación, navegación y pruebas táctiles
- Textura industrial generada mediante imagegen integrado, copiada en assets/concrete-v05.png; prompt y procedencia documentados. Malla de biseles compartida, rig con codos/rodillas y poses de recarga/curación/impacto. Vehículo con colisión real y área sin árboles. Cuerpos persistentes, sin colisión ni botín duplicado.
- AStar a 0,5 m, obstáculos inflados, barridos de volumen, proyección a celdas cercanas y simplificación acotada. Repath al moverse objetivo/intervalo, giro/velocidad suaves, separación y recuperación lateral de bloqueos. Configuración duplicada por enemigo.
- Stick adaptable configurable, histéresis de apuntado, cancelación OS de botones, protección de IDs repetidos y limpieza al redimensionar. Pantalla real de calibración de tres contactos usando el mismo TouchInput/TouchActionButton, incursión congelada. Volver de Ajustes pasa al pie fijo; tutorial cede ante recarga/curación/extracción/evento.
- 28 pruebas nativas añadidas: total 205 pasan; Chromium 28 pasan. La primera prueba nueva usaba game.loot inexistente y se corrigió a world.containers. El test web usaba CDP touchEnd con dedos restantes; se corrigió a changedTouches para levantar sólo uno.
- iPhone emparejado encontrado, modo desarrollador inicialmente desactivado. Se exporta Xcode con equipo de desarrollo local y preset portable restaurado a Team ID vacío; mínimo iOS 15 para Xcode 27. Firma verificada y perfil contiene el dispositivo. Construir dentro de Documents fallaba por FinderInfo/FileProvider: copia sin atributos a /tmp resuelve CodeSign. La app se instala, pero SpringBoard rechaza apertura por seguridad/perfil; falta paso manual de confianza/habilitación. No hay prueba física de tres dedos confirmada.
- Pendiente en esta revisión: empaquetado final y actualización de evidencias tras el último ajuste visual del HUD. Pruebas sostenidas de teléfono y balance con jugadores siguen pendientes.

- Revisión de compatibilidad: dos comprobaciones de recolocación inicial de guardados dentro de la nueva furgoneta; una posición libre no cambia. Informe local y captura para calibración móvil, con liberación independiente y recursos, sin red/identificadores.
- El usuario activó desarrollo/confianza. LaunchServices aceptó la orden, pero la app 4.5.1 se cerró: SIGTRAP en UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption. No se cuenta como ejecución estable. Apple exige UIScene al compilar con SDK27.
- Migración a Godot 4.7.2.stable.official.ed1daf0bf y plantillas oficiales; SHA256 descargados contrastados con GitHub. Backup de proyecto en builds/antes-migracion-0.5.zip; motor viejo conservado tools/Godot-4.5.1.app. GodotPhysics3D explícito. SDK/build-tools Android36 instalado.
- Pruebas detectaron doble procesamiento táctil del nuevo Button nativo: TouchActionButton ahora consume el toque propio y lo reenvía al TouchScroll padre. Dos pruebas de arrastre sobre botón aseguran scroll sin activación. Total actual 211 nativas / 28 navegador pasan.
- Xcode4.7.2 exportado/compilado/firmado, UIApplicationSceneManifest confirmado, app instalada. El nuevo arranque está pendiente porque el iPhone está bloqueado; petición de desbloqueo enviada. Usuario no puede realizar ahora la prueba de dedos. No se presentan contactos simulados como físicos.

- Comprobación física final: tras desbloqueo, 4.7.2 arranca y renderiza en iPhone 15 Pro Max/iOS27.0.1. Se recuperan Documents/native-validation-v05.png/json mediante devicectl; guardados en builds/iphone-native-v05.*, imagen 2293x1290 horizontal inspeccionada, pie fijo y texto legibles. Proceso activo confirma que no repite el crash UIScene. Sólo pantalla inicial: gestos físicos, incursión y rendimiento prolongado no verificados porque el usuario no puede probar ahora los dedos.
- Entregas finales: motor/plantillas4.7.2, APK0.5/código5/API24-36 con firma v2/v3 válida y siete JSON iguales a fuente; macOS universal0.5 y web. IPA desarrollo firmado para el perfil local, caduca el11/10/2026; no AppStore ni claves privadas. 211 pruebas nativas/28web, cliente original de habilidad ejecutado y captura/estado revisados sin errores. Pestaña del usuario actualizada a ?v=0.5 conservando su perfil web. Empaquetado portable con arte, documentación y pruebas; SHA256 de las cuatro entregas en builds/SHA256.json.

## Auditoría y debug 0.5.1
- Usuario solicita auditoría y depuración; alcance funcional: persistencia, economía, resultados, controles, UI, IA, pruebas nativas y navegador. Sin subagentes.
- Baseline: 211 pruebas pasan. Reproducción nueva: 14 comprobaciones fallan por cuatro causas; evidencia builds/audit-reproduction.log.
- Corregidos: botón táctil ignora recorte de ancestros; resultado pendiente accesible por Escape/Tab/foco y mutable en reintento; emergencia bloqueada por equipo sin arma; guardado con checksum acepta datos internos inválidos.
- Validación de perfiles/escenas anidados antes de restaurar, ajustes ausentes completados; migración del search_timer negativo que guardaba el motor de IA anterior. Temporizador actual saturado a cero.
- 24 comprobaciones nuevas de regresión: total 235. Runner requiere marcador de conclusión sin fallos, además de código/errores. Versionado 0.5.1/código 6; informes móviles leen versión del proyecto.
- Navegador ampliado con recorrido real hasta extracción, resultado, retorno, despliegue y suspensión/reanudación. Exportaciones y evidencias finales se actualizan en esta revisión. Pruebas de dedos físicos siguen aplazadas por el usuario.
- Verificación final: 235 nativas y 35 Chromium, sin errores. El primer intento de extracción tras señuelo terminó en muerte válida; nueva precondición usa incursión fresca sin teletransporte. Cliente original ejecutado; estado/capturas de combate, calibración, extracción y viewport revisados.
- APK0.5.1/código6 firmado v2/v3, siete JSON iguales a fuente; macOS universal0.5.1, web e IPA firmada regenerados. iPhone instalado, apertura rechazada por Locked; no se solicita más interacción porque el usuario aplazó pruebas físicas. No se afirma ejecución física de 0.5.1. Pestaña existente actualizada a ?v=0.5.1 con 136 fichas conservadas y captura inspeccionada.
- Informe en docs/AUDITORIA-0.5.1.md. Empaquetado portable y huellas de las cuatro entregas se regeneran con esta revisión. Pendiente: abrir 0.5.1 en iPhone desbloqueado, dedos/ergonomía/suspensión real, Android físico y sesiones prolongadas/balance.

## Paquete para GitHub
- Petición del usuario: ZIP para subir el proyecto y continuar mejorándolo. Se incluyen fuentes 0.5.1, recursos, pruebas, licencias, guías de arranque/contribución/subida y ROADMAP; se excluyen herramientas, builds, dependencias instaladas, cachés y firma.
- Copia limpia anterior reproduce Parse Error por clases globales ausentes: la caché .godot no estaba incluida. Runner actualizado para importar antes de probar y admitir GODOT_BIN; no se cambia la lógica ni la versión del juego.
- .gitignore ampliado para importaciones, Python y material de firma; .gitattributes fija texto/recursos binarios y se conservan los UID. ZIP con raíz ProyectoChoskov/, preparado para extraer y crear repositorio; sin publicación automática ni historial Git previo.
- Verificación del paquete extraído desde cero: 235 comprobaciones nativas pasan sin caché ni motor incluido, usando GODOT_BIN; evidencia local builds/github-clean-verification.log. Inventario: 103 archivos, 26 UID, CRC verificado, sin rutas personales/identificadores del equipo ni firma. ZIP final y SHA256 generados; el ZIP de fuentes también se actualiza con las guías.
