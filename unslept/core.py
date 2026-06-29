# SPDX-License-Identifier: GPL-3.0-or-later
"""Unified, OS-detecting CLI for Unslept.

Picks the right platform backend automatically and guarantees the system is
restored on exit via three overlapping safety nets: a signal handler
(SIGINT/SIGTERM), `atexit`, and a `finally` block. `release()` is idempotent,
so running through several of them is harmless.
"""
from __future__ import annotations

import argparse
import atexit
import platform
import signal
import sys
import time

from . import __version__
from .platforms.base import Sleeper


def _make_sleeper() -> Sleeper:
    system = platform.system()
    if system == "Darwin":
        from .platforms.mac import MacSleeper

        return MacSleeper()
    if system == "Windows":
        from .platforms.windows import WindowsSleeper

        return WindowsSleeper()
    if system == "Linux":
        from .platforms.linux import LinuxSleeper

        return LinuxSleeper()
    raise SystemExit(f"Unslept: неподдерживаемая ОС '{system}'.")


def _fmt(total: int) -> str:
    h, m, s = total // 3600, (total % 3600) // 60, total % 60
    if h:
        return f"{h}h {m:02d}m {s:02d}s"
    if m:
        return f"{m}m {s:02d}s"
    return f"{s}s"


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(
        prog="unslept",
        description="Keep your computer awake — even with the lid closed.",
    )
    parser.add_argument(
        "--timer", type=int, metavar="MIN",
        help="автоматически выключиться через MIN минут",
    )
    parser.add_argument(
        "--allow-display-sleep", action="store_true",
        help="разрешить экрану гаснуть (система всё равно не уснёт)",
    )
    parser.add_argument(
        "--version", action="version", version=f"Unslept {__version__}",
    )
    args = parser.parse_args(argv)

    sleeper = _make_sleeper()

    for warning in sleeper.preflight():
        print(f"⚠️  {warning}", file=sys.stderr)

    state = {"released": False}

    def cleanup(*_args: object) -> None:
        if state["released"]:
            return
        state["released"] = True
        try:
            sleeper.release()
        finally:
            print("\n✓ Штатное поведение сна восстановлено.")

    atexit.register(cleanup)

    def _on_signal(_signum: int, _frame: object) -> None:
        cleanup()
        sys.exit(0)

    signal.signal(signal.SIGINT, _on_signal)
    if hasattr(signal, "SIGTERM"):
        try:
            signal.signal(signal.SIGTERM, _on_signal)
        except (ValueError, OSError):
            pass  # not available in some embedded contexts

    sleeper.engage(keep_display=not args.allow_display_sleep)
    print(f"● Unslept активен на {sleeper.name}. Компьютер не уснёт даже с закрытой крышкой.")
    if args.timer:
        print(f"  Авто-выключение через {args.timer} мин · Ctrl+C — выйти сейчас.")
    else:
        print("  Ctrl+C — выйти и вернуть штатный сон.")

    started = time.monotonic()
    deadline = started + args.timer * 60 if args.timer else None
    try:
        while True:
            now = time.monotonic()
            if deadline is not None:
                remaining = int(deadline - now)
                if remaining <= 0:
                    break
                print(f"\r  ⏱  осталось {_fmt(remaining)}    ", end="", flush=True)
            else:
                print(f"\r  ⏱  {_fmt(int(now - started))} активен    ", end="", flush=True)
            time.sleep(1)
    finally:
        cleanup()
