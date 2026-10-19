#!/usr/bin/env bash
# Esegue tutti i test del prototipo. Uso:
#   GODOT=/percorso/Godot_v4.7.2-stable_linux.x86_64 ./run_tests.sh
set -u
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")"
"$GODOT" --headless --path . --import >/dev/null 2>&1
status=0
for t in tests/test_*.gd; do
	echo "== $t"
	out="$("$GODOT" --headless --path . -s "res://$t" 2>&1)"
	code=$?
	echo "$out" | grep -E "^(FAIL|PASS: [0-9]+$|TUTTI|CI SONO)|SCRIPT ERROR|Parse Error"
	if [ $code -ne 0 ] || ! echo "$out" | grep -q "TUTTI I TEST SUPERATI"; then
		status=1
	fi
done
exit $status
