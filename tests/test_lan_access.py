#!/usr/bin/env python3
"""CORS origin rules for local-only and same-host LAN UI access."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from engine import _origin_allowed  # noqa: E402

checks = []


def check(name, actual, expected):
    ok = actual is expected
    checks.append(ok)
    print(f"{'PASS' if ok else 'FAIL'}  {name}  got={actual!r} expected={expected!r}")


check("loopback UI stays allowed in local mode",
      _origin_allowed("http://127.0.0.1:8080", "127.0.0.1:5000", False), True)
check("LAN UI same host is allowed when enabled",
      _origin_allowed("http://192.168.1.20:8080", "192.168.1.20:5000", True), True)
check("LAN UI origin is denied when disabled",
      _origin_allowed("http://192.168.1.20:8080", "192.168.1.20:5000", False), False)
check("other host is denied",
      _origin_allowed("http://192.168.1.21:8080", "192.168.1.20:5000", True), False)
check("other web port is denied",
      _origin_allowed("http://192.168.1.20:8081", "192.168.1.20:5000", True), False)
check("HTTPS origin is denied",
      _origin_allowed("https://192.168.1.20:8080", "192.168.1.20:5000", True), False)
check("origin with path is denied",
      _origin_allowed("http://192.168.1.20:8080/path", "192.168.1.20:5000", True), False)
check("malformed origin is denied",
      _origin_allowed("http://192.168.1.20:bad", "192.168.1.20:5000", True), False)

print(f"{sum(checks)}/{len(checks)} LAN access checks passed")
sys.exit(0 if all(checks) else 1)
