# SPDX-License-Identifier: GPL-3.0-or-later
"""Platform backend interface.

Every OS backend must guarantee one thing above all: after `release()` the
system is returned to *exactly* the behavior it had before `engage()` — idle
sleep AND lid-close behavior. `release()` must be idempotent and safe to call
from a signal handler, atexit, or a `finally` block.
"""
from __future__ import annotations

from abc import ABC, abstractmethod


class Sleeper(ABC):
    """A keep-awake backend for one operating system."""

    #: Human-readable OS name, shown in the CLI.
    name: str = "unknown"

    def preflight(self) -> list[str]:
        """Return human-readable warnings before engaging (e.g. missing
        privileges). An empty list means everything is ready."""
        return []

    @abstractmethod
    def engage(self, keep_display: bool = True) -> None:
        """Begin preventing sleep — both idle sleep and lid-close sleep.

        If `keep_display` is False, the screen is allowed to turn off while the
        system itself stays awake.
        """

    @abstractmethod
    def release(self) -> None:
        """Restore the system's original sleep / lid behavior.

        MUST be idempotent: calling it twice (or after a partial engage) must
        not raise and must leave the system in its original state.
        """
