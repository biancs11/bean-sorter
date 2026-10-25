#!/usr/bin/env bash
# Installs dependencies (needs internet ONCE), makes scripts executable and
# drops the launcher on the desktop.  --autostart also starts it on boot.
set -u
APP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_PACKAGES=1
INSTALL_DESKTOP=1
AUTOSTART=0
for arg in "$@"; do
  [ "$arg" = "--service-only" ] && { INSTALL_PACKAGES=0; INSTALL_DESKTOP=0; }
  [ "$arg" = "--autostart" ] && AUTOSTART=1
done

if [ "$INSTALL_PACKAGES" = "1" ]; then
  sudo apt update
  sudo apt install -y python3-flask python3-picamera2 python3-opencv python3-numpy \
    python3-gpiozero python3-lgpio php-cli php-sqlite3 php-zip php-gd php-mbstring \
    php-xml chromium || \
  sudo apt install -y python3-flask python3-picamera2 python3-opencv python3-numpy \
    python3-gpiozero python3-lgpio php-cli php-sqlite3 php-zip php-gd php-mbstring \
    php-xml chromium-browser
fi

chmod +x "$APP/start_bean_sorter.sh" "$APP/install.sh"

# The engine and PHP can run without X11/Chromium. Install a system service so
# --autostart works even when no Waveshare/display session is available.
SERVICE_USER="${SUDO_USER:-$(id -un)}"
UNIT_TMP="$(mktemp)"
cat > "$UNIT_TMP" <<EOF
[Unit]
Description=Bean Sorter camera and web services
After=local-fs.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory="$APP"
EnvironmentFile=-/etc/bean-sorter.env
ExecStart=/bin/bash "$APP/start_bean_sorter.sh" --no-kiosk
Restart=on-failure
RestartSec=3
KillMode=control-group
TimeoutStopSec=15

[Install]
WantedBy=multi-user.target
EOF
sudo install -m 0644 "$UNIT_TMP" /etc/systemd/system/bean-sorter.service
rm -f "$UNIT_TMP"
sudo systemctl daemon-reload

DESK_OUT=""
if [ "$INSTALL_DESKTOP" = "1" ]; then
  DESK_SRC="$APP/BeanSorter.desktop"
  DESK_OUT="$(mktemp)"
  sed "s|__APP__|$APP|g" "$DESK_SRC" > "$DESK_OUT"

  for d in "$HOME/Desktop" "$HOME/.local/share/applications"; do
    mkdir -p "$d"
    cp "$DESK_OUT" "$d/BeanSorter.desktop"
    chmod +x "$d/BeanSorter.desktop"
    gio set "$d/BeanSorter.desktop" metadata::trusted true 2>/dev/null || true
  done
fi

if [ "$AUTOSTART" = "1" ]; then
  sudo systemctl enable --now bean-sorter.service
  echo "Bean Sorter service enabled at boot (works without a display session)."
fi
if [ -n "$DESK_OUT" ]; then rm -f "$DESK_OUT"; fi
echo "Done."
if [ "$INSTALL_DESKTOP" = "1" ]; then
  echo "Double-click 'Bean Sorter' on the desktop to start the services and kiosk."
fi
echo "For display-independent boot, run: sudo systemctl enable --now bean-sorter.service"
