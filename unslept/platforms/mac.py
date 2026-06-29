# SPDX-License-Identifier: GPL-3.0-or-later
"""macOS backend.

Two independent mechanisms, mirroring the native Swift app:

* `caffeinate -i [-d]` — blocks idle system sleep (and display sleep). No root.
* `pmset disablesleep 1` — the ONLY thing that blocks lid-close (clamshell)
  sleep without an external display. Requires root, so we go through `sudo`.

Both are undone on `release()`.
"""
from __future__ import annotations

import os
import subprocess

from .base import Sleeper


class MacSleeper(Sleeper):
    name = "macOS"

    def __init__(self) -> None:
        self._caffeinate: subprocess.Popen | None = None
        self._disabled_sleep = False

    def preflight(self) -> list[str]:
        warnings: list[str] = []
        if os.geteuid() != 0:
            warnings.append(
                "pmset disablesleep требует root — будет вызван через sudo "
                "(терминал запросит пароль). Без него крышка усыпит Mac."
            )
        return warnings

    def engage(self, keep_display: bool = True) -> None:
        args = ["/usr/bin/caffeinate", "-i"]
        if keep_display:
            args.append("-d")
        self._caffeinate = subprocess.Popen(args)
        # lid-close protection
        self._set_disablesleep(True)

    def release(self) -> None:
        if self._caffeinate is not None and self._caffeinate.poll() is None:
            self._caffeinate.terminate()
        self._caffeinate = None
        if self._disabled_sleep:
            self._set_disablesleep(False)

    def _set_disablesleep(self, on: bool) -> None:
        cmd = ["pmset", "disablesleep", "1" if on else "0"]
        if os.geteuid() != 0:
            cmd = ["sudo"] + cmd
        result = subprocess.run(cmd)
        if result.returncode == 0:
            self._disabled_sleep = on
