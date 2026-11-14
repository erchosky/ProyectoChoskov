from pathlib import Path
import os, re, shutil, subprocess, sys
root=Path(__file__).resolve().parents[1]
configured=os.environ.get('GODOT_BIN')
if configured:
 godot=shutil.which(configured) or Path(configured).expanduser()
 if not Path(godot).is_file(): sys.exit('GODOT_BIN no apunta a un ejecutable de Godot válido')
else:
 godot=root/'tools/Godot.app/Contents/MacOS/Godot'
 if not godot.exists(): godot=shutil.which('godot') or shutil.which('godot4')
 if not godot: sys.exit('Instala Godot 4.7.2 y configura GODOT_BIN o añade godot al PATH')
# Fresh GitHub checkouts do not include imported assets or the class-name cache.
(root/'builds').mkdir(exist_ok=True)
imported=subprocess.run([str(godot),'--headless','--path',str(root),'--editor','--quit'],cwd=root,text=True,capture_output=True,timeout=120)
output=imported.stdout+imported.stderr
(root/'builds'/'test_import.log').write_text(output)
if imported.returncode or 'SCRIPT ERROR' in output or 'ERROR:' in output:
 print(output)
 sys.exit(1)
for name in ['test_core','test_gameplay','test_upgrade','test_content','test_mobility','test_navigation','test_touch','test_audit']:
 result=subprocess.run([str(godot),'--headless','--path',str(root),'--script',f'tests/{name}.gd'],cwd=root,text=True,capture_output=True,timeout=45)
 output=result.stdout+result.stderr
 print(output)
 (root/'builds').mkdir(exist_ok=True)
 (root/'builds'/f'{name}.log').write_text(output)
 if result.returncode or 'SCRIPT ERROR' in output or 'ERROR:' in output or 'FAIL:' in output or not re.search(r'(?m)^\w+_RESULT \d+ checks, 0 failures$',output):
  sys.exit(1)
print('ALL_CHECKS_PASS: todas las verificaciones sin errores de ejecución')
