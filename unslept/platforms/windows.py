# SPDX-License-Identifier: GPL-3.0-or-later
"""Windows 10/11 backend.

IMPORTANT — closing the lid is handled SEPARATELY from idle sleep on Windows:

1. `SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED [| ES_DISPLAY_REQUIRED])`
   blocks *idle* sleep while this process lives. It does NOT stop the explicit
   "lid close action" — Windows would still sleep when the lid shuts.

2. To stop the lid putting the machine to sleep we must change the power
   scheme's LIDACTION to "Do nothing" via `powercfg`. We back up the original
   AC/DC values first and restore them on exit. Requires administrator rights.

Crash safety: the original lid values are written to a backup file on disk
*before* we change them. If the process is hard-killed without cleaning up, the
next launch detects the leftover backup and restores it first.
"""
from __future__ import annotations

import ctypes
import json
import os
import re
import subprocess
from pathlib import Path

from .base import Sleeper

# SetThreadExecutionState flags
ES_CONTINUOUS = 0x80000000
ES_SYSTEM_REQUIRED = 0x00000001
ES_DISPLAY_REQUIRED = 0x00000002

# LIDACTION values
LID_DO_NOTHING = 0  # 0=nothing 1=sleep 2=hibernate 3=shutdown

_CURRENT_AC = re.compile(r"Current AC Power Setting Index:\s*(0x[0-9a-fA-F]+)")
_CURRENT_DC = re.compile(r"Current DC Power Setting Index:\s*(0x[0-9a-fA-F]+)")


class WindowsSleeper(Sleeper):
    name = "Windows"

    def __init__(self) -> None:
        base = os.environ.get("LOCALAPPDATA") or str(Path.home())
        self._backup = Path(base) / "Unslept" / "lid_backup.json"
        self._es_set = False

    # ── privilege check ─────────────────────────────────────────────────────
    def _is_admin(self) -> bool:
        try:
            return bool(ctypes.windll.shell32.IsUserAnAdmin())
        except Exception:
            return False

    def preflight(self) -> list[str]:
        warnings: list[str] = []
        if not self._is_admin():
            warnings.append(
                "Изменение действия крышки (powercfg) требует прав администратора. "
                "Запусти терминал «от имени администратора» — иначе закрытие крышки "
                "усыпит ПК, несмотря на блокировку idle-сна."
            )
        return warnings

    # ── engage / release ────────────────────────────────────────────────────
    def engage(self, keep_display: bool = True) -> None:
        # recover from a previous crash before touching anything
        self._recover_if_needed()

        flags = ES_CONTINUOUS | ES_SYSTEM_REQUIRED
        if keep_display:
            flags |= ES_DISPLAY_REQUIRED
        ctypes.windll.kernel32.SetThreadExecutionState(flags)
        self._es_set = True

        self._backup_lid()
        self._set_lid(LID_DO_NOTHING)

    def release(self) -> None:
        if self._es_set:
            # clearing to ES_CONTINUOUS alone removes our keep-awake request
            ctypes.windll.kernel32.SetThreadExecutionState(ES_CONTINUOUS)
            self._es_set = False
        self._restore_lid()

    # ── lid action via powercfg ─────────────────────────────────────────────
    @staticmethod
    def _powercfg(*args: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["powercfg", *args], capture_output=True, text=True
        )

    def _query_lid(self) -> tuple[int | None, int | None]:
        out = self._powercfg(
            "/query", "SCHEME_CURRENT", "SUB_BUTTONS", "LIDACTION"
        ).stdout
        ac = _CURRENT_AC.search(out)
        dc = _CURRENT_DC.search(out)
        return (
            int(ac.group(1), 16) if ac else None,
            int(dc.group(1), 16) if dc else None,
        )

    def _backup_lid(self) -> None:
        ac, dc = self._query_lid()
        self._backup.parent.mkdir(parents=True, exist_ok=True)
        self._backup.write_text(json.dumps({"ac": ac, "dc": dc}))

    def _set_lid(self, value: int) -> None:
        self._powercfg(
            "/setacvalueindex", "SCHEME_CURRENT", "SUB_BUTTONS", "LIDACTION", str(value)
        )
        self._powercfg(
            "/setdcvalueindex", "SCHEME_CURRENT", "SUB_BUTTONS", "LIDACTION", str(value)
        )
        self._powercfg("/setactive", "SCHEME_CURRENT")

    def _restore_lid(self) -> None:
        if not self._backup.exists():
            return
        try:
            data = json.loads(self._backup.read_text())
        except (OSError, ValueError):
            data = {}
        ac, dc = data.get("ac"), data.get("dc")
        if ac is not None:
            self._powercfg(
                "/setacvalueindex", "SCHEME_CURRENT", "SUB_BUTTONS", "LIDACTION", str(ac)
            )
        if dc is not None:
            self._powercfg(
                "/setdcvalueindex", "SCHEME_CURRENT", "SUB_BUTTONS", "LIDACTION", str(dc)
            )
        self._powercfg("/setactive", "SCHEME_CURRENT")
        try:
            self._backup.unlink()
        except OSError:
            pass

    def _recover_if_needed(self) -> None:
        # A leftover backup at startup means a prior run was killed mid-flight.
        if self._backup.exists():
            self._restore_lid()
