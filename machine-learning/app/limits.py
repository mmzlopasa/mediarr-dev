"""Refuses a request body larger than the configured limit, before it fills the memory."""

import json

from fastapi import HTTPException
from starlette.types import ASGIApp, Message, Receive, Scope, Send

from . import config

_TOO_LARGE = json.dumps({"detail": "the picture is too large"}).encode()


def too_large() -> HTTPException:
    return HTTPException(status_code=413, detail="the picture is too large")


class BodyLimitMiddleware:
    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        limit = config.MAX_BODY_BYTES
        for name, value in scope["headers"]:
            if name == b"content-length" and value.isdigit() and int(value) > limit:
                await _refuse(send)
                return
        received = 0

        async def counted() -> Message:
            nonlocal received
            message = await receive()
            if message["type"] == "http.request":
                received += len(message.get("body", b""))
                if received > limit:
                    # Without a length up front the count stops the read as soon as it is too much.
                    raise too_large()
            return message

        await self.app(scope, counted, send)


async def _refuse(send: Send) -> None:
    await send(
        {
            "type": "http.response.start",
            "status": 413,
            "headers": [
                (b"content-type", b"application/json"),
                (b"content-length", str(len(_TOO_LARGE)).encode()),
                (b"connection", b"close"),
            ],
        }
    )
    await send({"type": "http.response.body", "body": _TOO_LARGE})
