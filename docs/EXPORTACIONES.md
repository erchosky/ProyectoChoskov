# Exportaciones · Godot 4.7.2

Versión exacta usada: `4.7.2.stable.official.ed1daf0bf`. Plantillas oficiales **4.7.2.stable**. Renderizador Compatibility/OpenGL ES 3, sin C#, plugins nativos ni servicios de red. Una sola base GDScript para las tres plataformas.

## Android

Se ha generado `builds/ProyectoChoskov-debug.apk`, firmado con una clave de depuración. No sirve para publicación en Google Play. ARM64, mínimo API 24 (Android 7), objetivo API 36, paisaje, modo inmersivo; permisos de internet desactivados. Godot utiliza el manifest de su plantilla estándar. El API objetivo y mínimo se pueden consultar con `aapt dump badging`.

Herramientas disponibles en este entorno:

- Godot local: `tools/Godot.app/Contents/MacOS/Godot`.
- JDK 17 Temurin: `tools/jdk/Contents/Home`.
- SDK: `tools/android-sdk`; command-line tools, platform-tools, plataforma Android 36 y build-tools 36.0.0.
- Plantillas Android oficiales; exportación estándar sin Gradle. No se ha necesitado NDK ni CMake porque no se compila el motor ni un plugin desde fuentes.

Para reconstruir aquí:

```sh
./tools/Godot.app/Contents/MacOS/Godot --headless --path . --export-debug Android builds/ProyectoChoskov-debug.apk
JAVA_HOME="$PWD/tools/jdk/Contents/Home" ./tools/android-sdk/build-tools/36.0.0/apksigner verify --verbose builds/ProyectoChoskov-debug.apk
./tools/android-sdk/platform-tools/adb install -r builds/ProyectoChoskov-debug.apk
```

No había dispositivos conectados a adb, por lo que **no se ha instalado ni ejecutado el APK en Android**. La firma se ha comprobado; eso no verifica la ejecución del juego en el sistema.

En otro ordenador instala Godot 4.7.2 y sus plantillas, JDK 17 y Android SDK 36, configura las rutas en Ajustes del editor → Exportación → Android. `export_presets.cfg` incluye el preset portable; las rutas locales y la clave debug pertenecen a los ajustes del editor, no al proyecto.

Para publicar: crear y custodiar una clave de release propia, rellenar la firma release, exportar AAB con la cadena de herramientas requerida por la tienda y probar teléfonos reales. No se ha generado ni solicitado una clave comercial.

## iOS

El preset **iOS** usa `com.choskov.proyecto`, ARM64, versión 0.5.1/código 6 y mínimo iOS 15.0, con exportación de proyecto Xcode. El Team ID permanece vacío en el proyecto portable; para la prueba local se usó temporalmente el equipo de desarrollo ya configurado en este Mac y se restauró el preset después.

Se ha exportado `builds/ios-v05/Choskov.xcodeproj`, compilado con Xcode 27/SDK iOS 27 y firmado para desarrollo. La firma local se verifica con `codesign --verify --deep --strict`. El perfil generado incluye el iPhone emparejado. La revisión 0.5.1 se ha instalado mediante `devicectl`; el intento de apertura devuelve Locked y su ejecución sigue pendiente. La revisión anterior 0.5.0 arrancó después de desbloquear el teléfono y generó captura/estado del refugio. Desarrollo/confianza ya se habilitaron. El intento previo con plantilla 4.5.1 produjo un crash UIScene, por lo que se migró a 4.7.2. La ejecución inicial de 0.5.0 está confirmada; la ejecución de 0.5.1 y la prueba física de dedos siguen pendientes; detalles en `PRUEBAS-TACTILES.md`.

La carpeta Documents sincronizada añade metadatos Finder/FileProvider al bundle que impiden firmar. La construcción válida se hizo desde una copia sin atributos en `/tmp/choskov-ios-472`, con DerivedData fuera de Documents. El proyecto portable especifica mínimo 15.0; en esa construcción también se pasó `IPHONEOS_DEPLOYMENT_TARGET=15.0` porque Xcode 27 rechaza el mínimo 14.0 de la plantilla original.

Para reproducir en otro Mac:

1. En Godot 4.7.2 → Proyecto → Exportar → iOS, introducir el Team ID propio de 10 caracteres y verificar el Bundle Identifier.
2. Exportar proyecto a carpeta vacía local, con nombre Choskov y mínimo iOS 15.0.
3. Abrir `Choskov.xcodeproj`, seleccionar el equipo en Signing & Capabilities y firma automática de desarrollo; elegir el iPhone propio.
4. Compilar y ejecutar. Si se construye desde consola: `xcodebuild -project Choskov.xcodeproj -scheme Choskov -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /ruta/local/DerivedData -allowProvisioningUpdates IPHONEOS_DEPLOYMENT_TARGET=15.0 build`.
5. Ejecutar el recorrido de `PRUEBAS-TACTILES.md` antes de publicar. Para distribución se necesitan certificados/perfiles apropiados; no se ha publicado nada en App Store.

El IPA de esta entrega en `builds/ProyectoChoskov-iOS-desarrollo.ipa` es una compilación de desarrollo para los dispositivos del perfil, no distribución App Store. No contiene claves privadas. [El exportador oficial de Godot 4.7.2](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/ios/export/export_plugin.cpp) define la opción `application/min_ios_version` usada en el preset.

## Web y macOS

Se incluyen exportaciones adicionales, del mismo proyecto. Web usa WebGL2 y plantilla sin hilos; es una ayuda de prueba y no sustituye la entrega móvil. `builds/web` se debe servir por HTTP. macOS se exporta universal, sin firma ni notarización.

```sh
./tools/Godot.app/Contents/MacOS/Godot --headless --path . --export-debug Web builds/web/index.html
./tools/Godot.app/Contents/MacOS/Godot --headless --path . --export-debug macOS builds/ProyectoChoskov-macOS.zip
```

Fuentes oficiales: [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), [Android](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html), [iOS](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html).

La plantilla anterior se cerraba en iOS 27 por no adoptar UIScene. [Apple documenta este requisito para aplicaciones compiladas con el SDK nuevo](https://developer.apple.com/documentation/uikit/transitioning-to-the-uikit-scene-based-life-cycle). La revisión 4.7.2 incluye el manifiesto y delegado correspondientes. El certificado/perfil es de desarrollo y tiene caducidad registrada en `builds/ios-signature-v05.json`; se debe renovar o usar distribución apropiada para una entrega permanente.
