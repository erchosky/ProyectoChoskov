# Pruebas táctiles · 0.5

## Estado observado

- 235 comprobaciones nativas pasan; 18 nuevas cubren calibración, tres dedos, propietario independiente, cancelación, arrastre, cambio de tamaño, origen adaptable e histéresis. Se inyectan eventos en el viewport real de Godot, sin emular ratón.
- Chromium: 35 comprobaciones pasan. Dos contactos CDP y eventos DOM con `changedTouches` verifican la liberación individual del tercer dedo; cancelar los contactos elimina el propietario restante. Son entradas simuladas, no dedos sobre cristal.
- No había dispositivos Android conectados a adb.
- iPhone 15 Pro Max con iOS 27.0.1: se verificó firma y perfil, se instaló la app y el usuario activó desarrollo/confianza. La plantilla 4.5.1 llegó a iniciar pero se cerró por falta de ciclo UIScene, confirmado en el informe de crash del propio juego. Se migró a **Godot 4.7.2**, con UIApplicationSceneManifest y firma válida; la app nueva está instalada. Tras quedar desbloqueado, la revisión arrancó y renderizó el refugio: captura y estado recuperados del contenedor del juego (`builds/iphone-native-v05.png` y `.json`). El proceso también aparece activo en devicectl. **Se ha confirmado ejecución y renderizado inicial; no contactos físicos**. El usuario indicó que no puede probar ahora los dedos.

## Recorrido pendiente en el iPhone

1. Abrir Proyecto Choskov ya instalado. Modo de desarrollador, confianza del perfil y renderizado inicial están confirmados en este iPhone.
2. En Ajustes del juego elegir Probar controles táctiles. Mantener ambos sticks desplazados y pulsar ACCIÓN con un tercer dedo: debe contar una acción y mostrar OK. Soltar el izquierdo mientras el derecho sigue ACTIVO; repetir al revés. Probar con tres dedos de ambas manos.
3. Probar inicio adaptable y fijo con joystick pequeño/grande; tocar botones próximos sin mover el stick ni disparar por accidente. Comprobar bordes y recortes junto al notch/isla dinámica en horizontal.
4. Entrar en incursión: moverse/apuntar/recargar, esquivar y curarse; abrir mochila/mapa con dedos aún apoyados y comprobar que se limpian al cerrar. Suspender/bloquear el teléfono y reabrir: debe volver pausado sin daño ni gasto.
5. Observar navegación junto a las tres entradas del almacén, cajas, árboles y furgoneta. Hacer una sesión de diez minutos a 30/60 FPS y sombras activadas/desactivadas; registrar temperatura, estabilidad, consumo y claridad del HUD.

Para Android se necesita conectar un ARM64 con depuración autorizada o instalar el APK de pruebas. Repetir el recorrido al menos en dos gamas. Instalar o firmar una app no acredita estos pasos.

## Evidencia local al realizar la prueba

La versión debug móvil escribe `user://native-validation-v05.png` y `.json` al arrancar y renderizar. La calibración guarda `touch-validation-v05.json`: OS, viewport, acciones, combos, liberación independiente de cada stick, muestras acotadas y conservación de recursos. El combo válido también produce `touch-validation-v05.png`. Sólo se escribe en el contenedor del juego, sin red ni identificadores personales.

En iPhone se puede recuperar un archivo mediante `xcrun devicectl device copy from --device <iPhone> --domain-type appDataContainer --domain-identifier com.choskov.proyecto --source <ruta-del-archivo> --destination <ruta-local>`. Para localizarlo: `device info files` con ese mismo dominio y `--search validation`. Se debe inspeccionar el informe y la imagen antes de declarar que los contactos físicos se han verificado.

Captura real del iPhone: viewport 2293 × 1290, orientación horizontal; estado OS iOS / versión 0.5.0 y zona segura física [177, 0, 2442, 1230]. La imagen inicial se ha inspeccionado: pie de Ajustes/Entrar visible y texto legible. El contenido largo usa scroll. Esto no verifica aún HUD en incursión, rotación, suspensión ni la prueba de tres dedos.

Revisión 0.5.1: añadidas tres comprobaciones de toques en botones recortados, dentro de las 24 nuevas de auditoría. IPA actualizado e instalado; el teléfono está bloqueado y devuelve Locked al abrir, por lo que la captura física anterior corresponde sólo a 0.5.0. Gestos físicos siguen aplazados. Ver AUDITORIA-0.5.1.md.
