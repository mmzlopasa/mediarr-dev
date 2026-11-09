"""Optional shared secret, for a service that runs on another computer."""

import hmac
import json

from starlette.types import ASGIApp, Receive, Scope, Send

from . import config

OPEN_PATHS = {"/health"}
_REFUSAL = json.dumps({"detail": "a valid token is required"}).encode()


def _presented_token(scope: Scope) -> bytes:
    for name, value in scope["headers"]:
        if name == b"authorization":
            scheme, _, token = value.partition(b" ")
            return token.strip() if scheme.lower() == b"bearer" else b""
    return b""


class TokenMiddleware:
    """Refuses before the body is read, so that nobody without the token can send a picture."""

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if (
            scope["type"] != "http"
            or not config.TOKEN
            or scope["path"] in OPEN_PATHS
            or hmac.compare_digest(_presented_token(scope), config.TOKEN.encode())
        ):
            await self.app(scope, receive, send)
            return
        await send(
            {
                "type": "http.response.start",
                "status": 401,
                "headers": [
                    (b"content-type", b"application/json"),
                    (b"content-length", str(len(_REFUSAL)).encode()),
                    (b"www-authenticate", b"Bearer"),
                ],
            }
        )
        await send({"type": "http.response.body", "body": _REFUSAL})
