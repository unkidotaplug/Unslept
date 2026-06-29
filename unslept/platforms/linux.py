# SPDX-License-Identifier: GPL-3.0-or-later
"""Linux backend (systemd / logind).

We take a systemd inhibitor lock that blocks the lid-switch handling plus
suspend and idle:

    systemd-inhibit --what=handle-lid-switch:sleep:idle --mode=block \\
        sleep infinity

The lock is held by the child `sleep infinity` process and is released
*automatically* by logind the moment that process dies — on clean exit, on
Ctrl+C, or even if Unslept itself crashes. That auto-release is exactly why we
prefer an inhibitor over editing /etc/systemd/logind.conf (which would require
restarting logind and risk killing the user session).

No root required: taking a delay/block inhibitor is a normal user operation.
"""
from __future__ import annotations

import shutil
import subprocess

from .base import Sleeper


class LinuxSleeper(Sleeper):
    name = "Linux"

    def __init__(self) -> None:
        self._proc: subprocess.Popen | None = None

    def preflight(self) -> list[str]:
        if shutil.which("systemd-inhibit") is None:
            return [
                "Не найден systemd-inhibit. Нужен systemd (в Arch и большинстве "
                "современных дистрибутивов он есть из коробки)."
            ]
        return []

    def engage(self, keep_display: bool = True) -> None:
        # `idle` covers idle-sleep; display blanking stays with the DE/compositor.
        self._proc = subprocess.Popen(
            [
                "systemd-inhibit",
                "--what=handle-lid-switch:sleep:idle",
                "--who=Unslept",
                "--why=Keep awake while AI codes",
                "--mode=block",
                "sleep",
                "infinity",
            ]
        )

    def release(self) -> None:
        if self._proc is not None and self._proc.poll() is None:
            self._proc.terminate()
            try:
                self._proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self._proc.kill()
        self._proc = None
