# Procedencia y licencias

No se han descargado ni reutilizado modelos, texturas, audio, personajes, mapas ni código del juego de referencia.

| Recurso | Procedencia | Uso/licencia |
|---|---|---|
| Código GDScript, JSON, escenas y pruebas | Implementado para Proyecto Choskov | MIT del proyecto |
| Nilo, merodeadores, vigías, cajas, bosque, refugio y almacén | Mallas creadas por código en `scripts/art.gd` y `scripts/world.gd` | Recursos originales; CC0 |
| Icono SVG | Dibujo vectorial original del proyecto | CC0 |
| Sonidos WAV | Síntesis original y ruido con semilla fija; generador en `authoring/create_sound.py` | CC0 |
| Godot 4.7.2 y plantillas exportadas | Distribución oficial Godot | MIT y avisos de terceros incluidos en el motor |
| Fuente de interfaz y símbolos | Fuente de respaldo incluida en Godot; no se ha descargado una fuente adicional | Licencias de terceros de Godot |
| Temurin JDK 17 y Android SDK | Adoptium / Google; herramientas locales, no recursos del juego | Licencias de sus distribuciones; no se incluyen en el ZIP de fuentes |
| Playwright | Dependencia npm para comprobar la exportación web | Apache-2.0; herramienta de pruebas |

La referencia [a136332462/Escape-From-Duckov](https://github.com/a136332462/Escape-From-Duckov) se examinó como **wiki**, con secciones de objetos, operadores, mecánicas y mapas y una implementación web. Su README declara MIT para código y CC BY-SA 4.0 para contenido. No se utilizó nada que requiera atribución derivada: solamente se comprobó la naturaleza del repositorio y el concepto general del género. No es el código fuente del videojuego.

Godot y sus terceros: [licencia](https://godotengine.org/license/), [avisos de copyright de la versión](https://github.com/godotengine/godot/blob/4.7.2-stable/COPYRIGHT.txt). Los sonidos y modelos de esta entrega son provisionales originales, claramente identificados aquí, y se pueden sustituir sin cambiar los sistemas de juego.

## Recursos 0.4

Modelado articulado, detalles industriales, gradientes de ruido, materiales, fogonazos e impactos: originales generados en GDScript (`scripts/art.gd`, `world.gd`, `effects.gd`). Los sonidos de pasos y esquiva se sintetizan en `authoring/create_sound.py`. No se han incorporado modelos, texturas ni voces de terceros. Textos del encubrimiento, testimonios y epílogos originales en `data/notes.json` y `missions.json`, reproducibles con el generador.

## Recursos 0.5

`assets/concrete-v05.png`: textura generada con IA mediante imagegen integrado, sin referencias externas; prompt completo en `ARTE-0.5.md`. Incluida como recurso del proyecto y diferenciada de las mallas/sonidos procedurales CC0. Codos, rodillas, biseles, animaciones y furgoneta: código y geometría originales del proyecto. No se han usado paquetes de modelos comerciales ni sprites de la referencia.
