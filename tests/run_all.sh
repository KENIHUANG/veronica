#!/usr/bin/env bash
# 一键回归:导入检查 + 全部逻辑测试。用法:GODOT=/path/to/godot tests/run_all.sh
# 可选:SHOTS=1 时额外跑截图脚本(需要 xvfb-run;输出到 $SHOT_DIR,默认 ./_shots)
set -u
cd "$(dirname "$0")/.."
G="${GODOT:-godot}"
fail=0
filter() { grep -vE 'mesh_get_surface_count|Parameter "m" is null|ObjectDB instances leaked|^\s+at: |ALSA lib'; }

echo "== import"
out=$("$G" --headless --path . --import 2>&1)
if echo "$out" | grep -qE "SCRIPT ERROR|Parse Error"; then echo "$out" | grep -E "SCRIPT ERROR|Parse Error"; fail=1; else echo "ok"; fi

check() {  # name, regex that must appear, [regex that must NOT appear]
	local name=$1 must=$2 mustnot=${3:-}
	echo "== $name"
	local o
	o=$(timeout 600 "$G" --headless --fixed-fps 60 --path . -s "tests/$name.gd" 2>&1 | filter)
	if echo "$o" | grep -qE "SCRIPT ERROR"; then echo "$o" | grep -A3 "SCRIPT ERROR"; fail=1; return; fi
	if ! echo "$o" | grep -qE "$must"; then echo "$o" | tail -8; echo "FAIL ($name): missing /$must/"; fail=1; return; fi
	if [ -n "$mustnot" ] && echo "$o" | grep -qE "$mustnot"; then echo "$o" | grep -E "$mustnot" | head -5; echo "FAIL ($name)"; fail=1; return; fi
	echo "ok"
}
check play      "ending flag=true end-screen=end"
check head      "keycard: true"
check scream    "chased to restroom and hit"
check note      "note fails: 0"
check loc_touch "restroom door opened by touch: true"
check letters   "letters fails: 0"
check valve     "valve fails: 0"
check hide      "hide fails: 0"
check labdoor   "labdoor fails: 0"

if [ "${SHOTS:-0}" = "1" ]; then
	export SHOT_DIR="${SHOT_DIR:-$PWD/_shots}"; mkdir -p "$SHOT_DIR"
	for s in pic_sheet shot_frames shot_statue shots2 shot_lab shot_writing shot_letters shot_signs; do
		[ -f "tests/$s.gd" ] || continue
		echo "== shots: $s"
		xvfb-run -a -s "-screen 0 1280x720x24" "$G" --rendering-driver "${SHOT_DRIVER:-opengl3}" --path . -s "tests/$s.gd" -- all 2>&1 | grep -E "saved|SCRIPT ERROR" | head -20
	done
	echo "screenshots in $SHOT_DIR"
fi

[ $fail = 0 ] && echo "ALL PASSED" || { echo "SOME TESTS FAILED"; exit 1; }
