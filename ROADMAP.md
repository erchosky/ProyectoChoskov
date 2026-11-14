# Próximos pasos

Base actual: **0.5.1**, ciclo completo jugable, 235 comprobaciones nativas y 35 Chromium. Auditoría: docs/AUDITORIA-0.5.1.md.

## 1. Validación en teléfonos

- Abrir 0.5.1 en el iPhone desbloqueado. La instalación está confirmada; su arranque sigue pendiente. La captura física existente corresponde a 0.5.0.
- Completar el recorrido de docs/PRUEBAS-TACTILES.md: tres dedos, liberación independiente, arrastre, zona segura, suspensión y recuperación.
- Repetir en dos Android ARM64 de distinta gama. Aún no hay ejecución física Android verificada.
- Medir sesiones de diez minutos con 30/60 FPS y sombras activadas/desactivadas: tiempo de frame, memoria, temperatura y batería.

Criterio de cierre: informes y capturas de dispositivos reales, incidencias reproducidas/corregidas y ausencia de pérdidas de progreso en suspensión.

## 2. Sensación de combate y legibilidad

- Ajustar aceleración, esquiva, apuntado y alcance con jugadores, conservando costes y colisiones.
- Mejorar siluetas, lectura de amenazas, transiciones de animación y reacción al daño.
- Revisar HUD y botones en las relaciones de aspecto reales; medir toques accidentales y fatiga.

Criterio de cierre: sesiones documentadas y parámetros contrastados con experiencia de juego, además de las regresiones automatizadas.

## 3. Arte y contenido

- Ampliar animaciones y sustituir modelos provisionales con recursos originales de procedencia documentada.
- Añadir lugares, amenazas y consecuencias al lore adulto sin perder coherencia con los contratos existentes.
- Ajustar botín, recetas, recompensas y rutas para incursiones de 5–10 minutos; mantener IDs o migrarlos al cambiar catálogos.

## 4. Entrega reproducible

- Añadir integración continua para importar el proyecto y ejecutar las suites nativas en un entorno limpio.
- Preparar capturas y compilaciones por versión en GitHub Releases.
- Configurar firma propia de distribución cuando se decida publicar, después de las pruebas físicas y de rendimiento.

Estos puntos son trabajo pendiente; no describen funciones ya implementadas.
