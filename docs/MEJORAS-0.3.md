# Proyecto Choskov 0.3 · El puesto del norte

Esta expansión añade seis objetos, una tercera arma, un enemigo jefe, tres contratos, una página y cinco recetas. El total pasa a 21 objetos, tres armas, tres tipos de enemigos, seis contratos y cuatro páginas.

## Ir al norte

El puesto forestal contiene una **llave garantizada**. Llévala al puesto fortificado del noroeste y abre su reserva: consume la llave una sola vez y conserva el desbloqueo durante esa incursión. Dentro hay una **Escopeta Brezo**, 18 cartuchos, dos circuitos y un **registro cifrado de Taro**. Hay una nueva carta cerca de la entrada; leerla conserva la información aunque caigas.

El **capataz** aparece al acercarte al puesto. Tiene 210 de salud, absorbe un 30 % del daño y anuncia sus ataques durante 0,95 s. Su insignia sirve para un contrato de Vera. Puedes evitar al jefe, volver al sur y extraer sin completar esta ruta. Su activación, vida y muerte se guardan; reanudar no genera otro jefe ni otra mochila. Puede volver en una incursión nueva.

Brezo tiene seis cartuchos por cargador. Cada disparo consume un cartucho y traza seis perdigones de 12 de daño con abanico fijo; la mayoría fallan a distancias largas. Alcance 11 m, intervalo 0,8 s, recarga 2,4 s. Dispone de sonido original y silueta de arma distinta. El HUD muestra su nombre y la comparación de armas considera el daño total por cartucho; el daño real depende de los perdigones que impacten.

## El banco de Vera

En **Fabricar** puedes transformar materiales del almacén. Los resultados vuelven al almacén y se pueden llevar desde su pestaña:

| Receta | Materiales | Resultado |
|---|---|---|
| Vendajes de tela | 2 telas | 2 vendajes |
| Botiquín de campaña | 3 telas + 1 filtro | 1 botiquín |
| Cartuchos de Brezo | 2 chatarras | 12 cartuchos |
| Señuelo de cuerda | 1 cable + 1 chatarra | 1 señuelo |
| Celda recuperada | 2 cables + 1 circuito | 1 batería |

Tres lotes completados permiten entregar **Nada se desperdicia**. También se añaden contratos por el registro cifrado y la insignia del capataz. Las recetas son gratuitas en fichas, requieren materiales y espacio; si falta algo o falla el guardado, se conserva todo. Fabricar está bloqueado mientras haya una incursión suspendida.

## Distracción y entregas

El campamento tiene un **señuelo** para probarlo. Lánzalo con el botón, **G** o desde su ficha en la mochila. Sale siete metros hacia donde apuntas, se detiene ante paredes y hace ruido durante ocho segundos activos. Las patrullas cercanas investigan la señal; un enemigo que ya te persigue no se distrae. Consume uno, admite un lanzamiento cada tres segundos y conserva posición/duración al suspender. La pausa congela el tiempo. Movimiento, apuntado y lanzamiento pueden usar tres dedos independientes.

A los **90 segundos** Vera anuncia una entrega; llega a los **105 segundos** a una de tres zonas despejadas elegida por la semilla. El paracaídas y la señal azul del mapa indican su ubicación. Contiene 18 cartuchos, un botiquín, dos circuitos y un señuelo, y atrae dos merodeadores. Se puede recoger hasta que termine la incursión. Evento, contenedor y refuerzos se guardan juntos; no se repiten al reanudar. Se puede extraer antes de la entrega.

## Guardado y alcance

El formato v3 migra perfiles v1/v2, preserva el equipo y añade el contador de fabricación. Las incursiones anteriores conservan sus contenedores: para encontrar la nueva reserva, termina la incursión antigua y comienza otra. La nueva geometría del puesto y los eventos aparecen en el mapa actualizado. Los puntos interactivos y las zonas de entrega tienen espacio libre de árboles.

Las capturas de entrega y jefe usan una partida de prueba aislada con posiciones/tiempo controlados para inspeccionar la presentación. Los recorridos de consumo, daño, pausa, muerte y restauración se comprueban además en escenas reales. El balance sigue pendiente de sesiones con jugadores en móviles físicos.
