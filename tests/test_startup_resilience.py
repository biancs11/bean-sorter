#!/usr/bin/env python3
"""Guard the offline/headless service and display-independent launcher contract."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent.parent
launcher = (ROOT / "start_bean_sorter.sh").read_text(encoding="utf-8")
installer = (ROOT / "install.sh").read_text(encoding="utf-8")
checks = []


def check(name, ok):
    checks.append(bool(ok))
    print(f"{'PASS' if ok else 'FAIL'}  {name}")


check("launcher does not wait for Chromium to keep services alive",
      'wait "$CHROME_PID"' not in launcher)
check("launcher supervises both backend processes",
      'kill -0 "$ENGINE_PID"' in launcher and 'kill -0 "$PHP_PID"' in launcher)
check("headless service mode skips Chromium", '--no-kiosk' in launcher
      and 'if [ "$NO_KIOSK" = "0" ]; then open_kiosk' in launcher)
check("installer creates a display-independent system service",
      'ExecStart=/bin/bash' in installer and '--no-kiosk' in installer)
check("service startup does not wait for internet", 'network-online.target' not in installer)
check("boot autostart is managed by systemd", 'systemctl enable --now bean-sorter.service' in installer)
check("service-only setup avoids package downloads", '--service-only' in installer
      and 'if [ "$INSTALL_PACKAGES" = "1" ]; then' in installer)

print(f"{sum(checks)}/{len(checks)} startup resilience checks passed")
sys.exit(0 if all(checks) else 1)
