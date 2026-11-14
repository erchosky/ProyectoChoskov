#!/bin/zsh
cd -- "$(dirname "$0")"
if [[ -x tools/Godot.app/Contents/MacOS/Godot ]]; then
  exec tools/Godot.app/Contents/MacOS/Godot --path .
elif command -v godot >/dev/null; then
  exec godot --path .
else
  open project.godot
fi
