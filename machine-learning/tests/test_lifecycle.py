import threading
import time

import pytest

from app.lifecycle import Registry


class Counting:
    """A model that counts how often it is opened, and can be slow about it."""

    def __init__(self, delay: float = 0.0) -> None:
        self.loads = 0
        self.delay = delay

    def __call__(self) -> object:
        self.loads += 1
        time.sleep(self.delay)
        return object()


def wait_until(condition, timeout: float = 3.0) -> bool:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if condition():
            return True
        time.sleep(0.005)
    return False


@pytest.fixture
def registry():
    created = Registry(0.05)
    yield created
    created.stop()


def test_nothing_loads_before_it_is_needed(registry):
    load = Counting()
    slot = registry.add("fake", load)
    assert load.loads == 0
    assert slot.status() == {"name": "fake", "loaded": False, "in_use": 0, "idle_seconds": None}
    with slot.use() as model:
        assert model is not None
        assert slot.status()["loaded"] and slot.status()["in_use"] == 1
    assert load.loads == 1


def test_two_first_requests_load_once_and_share_the_model(registry):
    load = Counting(delay=0.05)
    slot = registry.add("fake", load)
    seen = []
    start = threading.Barrier(8)

    def request() -> None:
        start.wait()
        with slot.use() as model:
            seen.append(model)

    threads = [threading.Thread(target=request) for _ in range(8)]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()
    assert load.loads == 1
    assert len(seen) == 8 and len({id(model) for model in seen}) == 1


def test_released_after_idle_by_the_thread_and_loaded_again(registry):
    load = Counting()
    slot = registry.add("fake", load)
    registry.start()
    with slot.use():
        pass
    assert wait_until(lambda: not slot.status()["loaded"])
    with slot.use():
        pass
    assert load.loads == 2


def test_a_recently_used_model_stays(registry):
    registry.idle_seconds = 60
    slot = registry.add("fake", Counting())
    with slot.use():
        pass
    assert registry.release_idle() == []
    assert slot.status()["loaded"]


def test_a_model_in_use_is_never_released(registry):
    slot = registry.add("fake", Counting())
    with slot.use():
        time.sleep(0.1)
        assert registry.release_idle() == []
        assert slot.status()["loaded"]
    # The idle time counts from the end of the last use, not its start.
    assert registry.release_idle() == []
    time.sleep(0.1)
    assert registry.release_idle() == ["fake"]


def test_a_model_being_loaded_is_not_released(registry):
    entered, finish = threading.Event(), threading.Event()

    def load() -> object:
        entered.set()
        finish.wait(3)
        return object()

    slot = registry.add("fake", load)

    def request() -> None:
        with slot.use():
            pass

    thread = threading.Thread(target=request)
    thread.start()
    assert entered.wait(3)
    assert registry.release_idle() == []
    assert slot.status()["loaded"] is False
    finish.set()
    thread.join()
    assert slot.status()["loaded"]


def test_a_failed_load_is_tried_again(registry):
    calls = []

    def load() -> object:
        calls.append(1)
        if len(calls) == 1:
            raise OSError("no network")
        return object()

    slot = registry.add("fake", load)
    with pytest.raises(OSError), slot.use():
        pass
    with slot.use() as model:
        assert model is not None
    assert slot.status()["in_use"] == 0


def test_zero_never_starts_the_release_thread():
    registry = Registry(0)
    registry.start()
    assert registry._thread is None
