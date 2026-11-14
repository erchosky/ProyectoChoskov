# Proyecto Choskov 0.2 · Voces de la Linde

Nilo busca a su hermano Taro después de la desaparición de la cuadrilla forestal. Vera mantiene encendida la última luz del refugio. Tres páginas originales, repartidas entre el campamento, el puesto forestal y la torre, reconstruyen los primeros siete días de la Bruma. La caja negra del almacén forma parte de esa historia. Las páginas leídas se conservan en el Diario incluso al morir; no conceden fichas ni ocupan la mochila.

## Nuevas decisiones

- **Sigilo (C o botón):** velocidad 2,2 m/s frente a 4,3; detección visual al 55 % de la distancia normal. Los pasos alertan a 1,5 m frente a 4,5. Disparar revela la presencia durante cuatro segundos, aunque se siga agachado. Los muros siguen bloqueando visión y disparos.
- **Ataques anunciados:** merodeador 0,45 s; vigía 0,65 s. La señal naranja y «¡ATAQUE!» permiten reaccionar. Salir del alcance evita el golpe; el vigía dispara hacia la posición que fijó al empezar el aviso. La pausa y el guardado conservan el aviso y ese punto.
- **Radio:** la salida norte consume una batería al activarse, una sola vez por incursión. Cancelar, volver o suspender no consume otra. El contenedor al sur de la torre garantiza una batería. La salida sur está siempre disponible. Ambas conservan la espera de seis segundos y sus cancelaciones.
- **Objetivo elegido:** los contratos se pueden seguir desde Misiones. El HUD muestra cantidades y distingue material transportado en riesgo; el mapa señala la zona del contrato. Sólo el almacén permite entregar materiales.

## Lectura y uso

El refugio presenta la historia, número de regresos y páginas descubiertas. Cinco pestañas separan equipo, almacén, misiones, mejoras y diario. La interfaz incluye barra de salud, botón de sigilo, mapa grande con leyenda y colores de salida, dirección de apuntado e inventario ordenado con marcas de materiales para contratos.

Seleccionar un objeto reemplaza su ficha anterior y muestra las acciones en el mismo lugar, sin acumular paneles. Los controles de continuar/cerrar quedan en el pie de los paneles. Tras extraer se puede guardar todo directamente; si el almacén se llena, lo restante permanece en la mochila y se indica. Las acciones imposibles de recarga/curación quedan desactivadas.

## Lógica y persistencia

Una incursión suspendida bloquea preparación, equipo, compra, venta, entregas, mejoras y transferencias del refugio; los ajustes y la consulta del diario siguen disponibles. Esto impide crear un segundo equipo que después sobrescriba el primero. Las operaciones económicas revierten sus cambios si no se puede escribir el archivo. Un resultado que falla al guardar queda pausado con opción de reintentar.

El formato v2 migra de forma aditiva los perfiles v1, conservando equipo, materiales e incursiones activas. Añade diario y contrato seguido. El checksum, archivo temporal, respaldo y prevención de recompensas repetidas siguen vigentes. Los eventos táctiles sobre botones quedan excluidos de los joysticks, incluso con el tamaño aumentado; pulsar un botón con ratón evita disparar al mismo tiempo. El sonido libera sus reproducciones al cerrar la escena.

## Alcance

Se conserva el juego nativo en Godot, sin red ni servicios. El navegador es una exportación adicional del mismo proyecto. Los nuevos parámetros de combate y sigilo son un punto inicial de balance; necesitan sesiones con jugadores y pruebas en teléfonos físicos.
