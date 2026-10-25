#!/usr/bin/env bash
# Bean Sorter launcher: engine + PHP, optionally with a kiosk browser.
# Backends stay alive if Chromium exits or the display is unavailable.
set -u
APP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$APP"

SIM=""
NO_KIOSK=0
for a in "$@"; do
  [ "$a" = "--simulate" ] && SIM="--simulate"
  [ "$a" = "--no-kiosk" ] && NO_KIOSK=1
done
ENGINE_ARGS=(--camera pi --valve real)
[ -n "$SIM" ] && ENGINE_ARGS=(--simulate)

mkdir -p logs var/sessions var/chromium
LOCK="$APP/var/bean_sorter.lock"

BIND="127.0.0.1"
[ "${BEAN_LAN:-0}" = "1" ] && BIND="0.0.0.0"
ENGINE_ARGS+=(--host "$BIND")

CHROME="$(command -v chromium || command -v chromium-browser || true)"

open_kiosk() {
  [ -z "$CHROME" ] && return 1
  "$CHROME" --kiosk --noerrdialogs --disable-infobars \
    --disable-session-crashed-bubble --incognito --password-store=basic \
    --user-data-dir="$APP/var/chromium" http://127.0.0.1:8080/ &
  CHROME_PID=$!
  return 0
}

if [ -f "$LOCK" ]; then
  OWNER="$(cat "$LOCK" 2>/dev/null || true)"
  if [ -n "$OWNER" ] && kill -0 "$OWNER" 2>/dev/null; then
    # Existing launcher owns the backends; a second click only opens the UI.
    if [ "$NO_KIOSK" = "0" ]; then open_kiosk || true; fi
    exit 0
  fi
  # Recover from a stale lock left by power loss or SIGKILL.
  rm -f "$LOCK"
fi
echo $$ > "$LOCK"

ENGINE_PID=""; PHP_PID=""; CHROME_PID=""
STOPPING=0
cleanup() {
  [ "$STOPPING" = "1" ] && return
  STOPPING=1
  [ -n "$ENGINE_PID" ] && kill "$ENGINE_PID" 2>/dev/null   # engine's finally{} turns the valve OFF
  [ -n "$PHP_PID" ] && kill "$PHP_PID" 2>/dev/null
  [ -n "$CHROME_PID" ] && kill "$CHROME_PID" 2>/dev/null
  [ -n "$ENGINE_PID" ] && wait "$ENGINE_PID" 2>/dev/null
  [ -n "$PHP_PID" ] && wait "$PHP_PID" 2>/dev/null
  rm -f "$LOCK"
}
trap cleanup EXIT
trap 'exit 0' INT TERM

python3 engine.py "${ENGINE_ARGS[@]}" >> logs/engine.log 2>&1 &
ENGINE_PID=$!
PHP_CLI_SERVER_WORKERS=4 php -S "$BIND:8080" -t web >> logs/php.log 2>&1 &
PHP_PID=$!

ok=0
for _ in $(seq 1 50); do
  if curl -sf http://127.0.0.1:5000/api/status >/dev/null 2>&1 && \
     curl -sf "http://127.0.0.1:8080/" >/dev/null 2>&1; then
    ok=1; break
  fi
  sleep 0.5
done
if [ "$ok" != 1 ]; then
  MSG="Bean Sorter failed to start - see logs/engine.log and logs/php.log"
  if command -v zenity >/dev/null 2>&1; then zenity --error --text "$MSG" || true
  elif command -v notify-send >/dev/null 2>&1; then notify-send "Bean Sorter" "$MSG" || true
  else echo "$MSG" >&2; fi
  exit 1
fi

if [ "$NO_KIOSK" = "0" ]; then open_kiosk || true; fi

# Supervise the backends, not Chromium. A failed display/browser must not stop
# sorting or prevent access through another trusted LAN device.
while kill -0 "$ENGINE_PID" 2>/dev/null && kill -0 "$PHP_PID" 2>/dev/null; do
  sleep 2
done
echo "Bean Sorter backend exited - see logs/engine.log and logs/php.log" >&2
exit 1
