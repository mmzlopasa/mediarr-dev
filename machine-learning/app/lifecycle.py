"""Keeps models in memory only while they are needed."""

import ctypes
import gc
import logging
import threading
import time
from collections.abc import Callable, Iterator
from contextlib import contextmanager
from typing import Any

from . import config

logger = logging.getLogger(__name__)

MAX_POLL_SECONDS = 30.0


class Slot:
    """One model, opened by the first request that needs it."""

    def __init__(self, name: str, loader: Callable[[], Any]) -> None:
        self.name = name
        self._loader = loader
        # Held while loading, so a second first request waits and shares the result.
        self._lock = threading.Lock()
        self._value: Any = None
        self._users = 0
        self._last_used = 0.0

    @contextmanager
    def use(self) -> Iterator[Any]:
        with self._lock:
            if self._value is None:
                self._value = self._loader()
            self._users += 1
            value = self._value
        try:
            yield value
        finally:
            with self._lock:
                self._users -= 1
                self._last_used = time.monotonic()

    def release_if_idle(self, idle_seconds: float) -> bool:
        # A slot that is busy loading is not idle, and this thread has no reason to wait for it.
        if not self._lock.acquire(blocking=False):
            return False
        try:
            if self._value is None or self._users > 0:
                return False
            if time.monotonic() - self._last_used < idle_seconds:
                return False
            self._value = None
            return True
        finally:
            self._lock.release()

    def status(self) -> dict[str, Any]:
        loaded = self._value is not None
        idle = None
        if loaded and self._users == 0:
            idle = round(time.monotonic() - self._last_used, 1)
        return {"name": self.name, "loaded": loaded, "in_use": self._users, "idle_seconds": idle}


def return_memory() -> None:
    """Hands freed memory back to the system, which glibc otherwise keeps for later."""
    gc.collect()
    try:
        ctypes.CDLL("libc.so.6").malloc_trim(0)
    except (OSError, AttributeError):
        logger.debug("malloc_trim is not available here")


class Registry:
    """All the models, and the thread that releases the ones nobody has used for a while."""

    def __init__(self, idle_seconds: float) -> None:
        self.idle_seconds = idle_seconds
        self.slots: list[Slot] = []
        self._stop = threading.Event()
        self._thread: threading.Thread | None = None

    def add(self, name: str, loader: Callable[[], Any]) -> Slot:
        slot = Slot(name, loader)
        self.slots.append(slot)
        return slot

    def release_idle(self) -> list[str]:
        released = [slot.name for slot in self.slots if slot.release_if_idle(self.idle_seconds)]
        if released:
            return_memory()
            logger.info("released after being idle: %s", ", ".join(released))
        return released

    def start(self) -> None:
        if self.idle_seconds <= 0 or self._thread is not None:
            return
        self._stop.clear()
        self._thread = threading.Thread(target=self._run, daemon=True, name="model-release")
        self._thread.start()

    def stop(self) -> None:
        if self._thread is None:
            return
        self._stop.set()
        self._thread.join()
        self._thread = None

    def _run(self) -> None:
        poll = min(self.idle_seconds / 4, MAX_POLL_SECONDS)
        while not self._stop.wait(poll):
            try:
                self.release_idle()
            except Exception:
                logger.exception("releasing idle models failed")


registry = Registry(config.IDLE_MINUTES * 60)
