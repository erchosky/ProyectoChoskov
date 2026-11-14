# Subir y retomar el proyecto en GitHub

El paquete ProyectoChoskov-GitHub-0.5.1.zip contiene una carpeta raíz ProyectoChoskov/. Dentro están project.godot, código, recursos, pruebas, documentación, licencias y configuración portable. No contiene el motor, SDK, compilaciones, node_modules, cachés ni material de firma.

## Crear el repositorio

Descomprime el ZIP primero. GitHub no convierte un ZIP subido en archivos de código: si subes el ZIP como archivo, sólo se almacena el paquete.

La opción más cómoda es GitHub Desktop: añade la carpeta ProyectoChoskov como repositorio local; si todavía no es un repositorio Git, créalo ahí. Revisa los archivos, crea el commit inicial y publica en tu cuenta con la visibilidad que prefieras. El ZIP no incluye historial Git anterior; es una instantánea del proyecto 0.5.1.

También puedes crear en GitHub un repositorio vacío y ejecutar dentro de ProyectoChoskov, sustituyendo la URL por la de tu repositorio:

```sh
git init
git add .
git commit -m "Importa Proyecto Choskov 0.5.1"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/TU_REPOSITORIO.git
git push -u origin main
```

Si utilizas Upload files en la web, sube el contenido descomprimido, manteniendo las subcarpetas. Incluye también .gitignore y .gitattributes, que algunos exploradores ocultan. GitHub Desktop o Git conservan mejor esa estructura.

## Retomar en otro ordenador

Clona/descarga el repositorio, instala Godot 4.7.2 estándar, importa project.godot y pulsa F5. Las instrucciones de pruebas y exportación están en CONTRIBUTING.md y EXPORTACIONES.md. El juego no necesita motor/SDK guardados en GitHub ni servicios remotos para funcionar.

La carpeta builds/ se reconstruye y está excluida por .gitignore. Las referencias históricas a capturas y logs de builds/ en los informes describen la sesión de desarrollo; esos archivos no están en el ZIP de código. No indican recursos necesarios para abrir el juego. Los resultados de referencia se resumen en AUDITORIA-0.5.1.md; puedes regenerar las pruebas localmente.

Para continuar el trabajo, comparte la URL del repositorio y el objetivo concreto de la siguiente mejora. ROADMAP.md contiene las prioridades pendientes y progress.md conserva el historial de decisiones técnicas.
