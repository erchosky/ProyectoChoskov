# Linde de Bruma

Nilo, un lirón que trazó rutas para una evacuación manipulada, busca a su hermano Taro en un sector industrial contaminado. Taro reunió pruebas de las órdenes que abandonaron al turno de noche. Vera mantiene el refugio mediante triaje y tratos con quienes venden los suministros. Los merodeadores explotan las rutas; los vigías protegen el encubrimiento. El tono es adulto, seco y moralmente incómodo. La presentación usa acero, vegetación apagada y luces ámbar, con equipo de campaña y animación articulada.

## Decisiones de la incursión

Salir con una pistola conserva el rifle para otra ocasión. Los caminos permiten orientarse, pero acercan al jugador a patrullas. La ruta exterior da acceso a contenedores sin cruzar el almacén. Los materiales comunes llenan la mochila; el almacén contiene equipo, circuitos y la caja negra. Volver por el sur es más cercano; la torre de radio permite extraer después de atravesar la zona norte. El mapa está hecho a mano; el contenido de cajas y pequeñas variaciones de patrullas dependen de una semilla guardada.

La pistola hace 27 de daño, tiene 12 balas, recarga en 1,5 s y dispara cada 0,34 s; el rifle hace 23, carga 24, recarga en 2,2 s y dispara cada 0,13 s. La cadencia y el sonido los distinguen. La curación reduce velocidad y bloquea disparos; el chaleco reduce daño un 25 %. No hay penalización por abrir la mochila: toda la acción se pausa, una decisión deliberada para el móvil y juego individual.

## Arquitectura

- TouchInput administra índices de dedos, zonas muertas y vectores; TouchActionButton administra un tercer dedo y cancela pulsaciones al arrastrar; TouchScroll permite desplazarse sin emular ratón.
- Explorer usa CharacterBody3D y rayos físicos para combatir. Raider separa patrulla, investigación, persecución, búsqueda y regreso; repiensa cada 0,35 segundos y usa AStarGrid2D para rodear el mapa estático.
- RaidWorld produce el mapa y sus colisiones; los techos se ocultan al aproximarse al edificio. Art crea mallas originales y agrupa la geometría estática con MultiMesh, conservando colisiones independientes.
- Inventory tiene capacidad por pilas y transferencias parciales; no hay objetos de formas especiales. Progression administra preparación, compras, equipo, mejoras, misiones y resultados.
- SaveStore escribe un perfil completo con checksum y copia válida; la incursión tiene ID y un resultado pendiente durable antes de liquidar su botín. Las operaciones de economía guardan objetos y recompensas en el mismo perfil.
- Effects reutiliza 40 trazadores. Un sol, materiales compartidos, sin texturas complejas, IA limitada a ocho enemigos iniciales y HUD a 10 Hz. Los datos editables son JSON.

## Límites de la primera entrega

Animaciones procedurales sencillas; sin animador esquelético ni navegación dinámica. Los techos se ocultan por proximidad, en lugar de aplicar una transparencia costosa. No hay multijugador, cuentas, red, compras ni anuncios. El equilibrio, accesibilidad para manos/dispositivos distintos y lectura del combate necesitan pruebas humanas en móviles. Los objetivos 30/60 FPS son opciones y metas; no resultados móviles.

## Voces de la Linde · 0.2

Las páginas descubiertas se guardan aunque Nilo caiga. El sigilo permite acercarse a patrullas y escoger cuándo iniciar el combate; disparar revela su posición cuatro segundos. Los ataques tienen una fase visible de preparación. La torre exige una batería, mientras el sendero sur garantiza una retirada sin consumibles. El objetivo seguido y el mapa dan contexto a las rutas. Los parámetros y detalles están en `MEJORAS-0.2.md`.

## El puesto del norte · 0.3

La ruta del puesto forestal al norte conecta llave, reserva, carta de Taro, escopeta y un jefe opcional. Las entregas crean una decisión temporal: retirarse antes o buscar mejores suministros con refuerzos. Los señuelos permiten dirigir patrullas sin iniciar un combate. Tela, chatarra, cable, filtro y circuitos tienen usos de fabricación además de entrega/venta. RaidContent coordina eventos y señuelos sobre el estado serializable de la incursión. Detalles y valores en `MEJORAS-0.3.md`.

## Revisión 0.4

Los contratos tienen testimonios tras entrega. La movilidad combina aceleración y frenado, apuntado independiente, carrera con resistencia y ruido, y esquiva con coste/cooldown sin invulnerabilidad. La cámara anticipa desplazamiento y apunta con un encuadre más próximo; el impulso al disparar es opcional. El detalle industrial no altera la huella de las coberturas principales. Parámetros y continuidad en `MEJORAS-0.4.md`.
