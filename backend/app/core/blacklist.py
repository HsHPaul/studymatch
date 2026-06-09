import json
from pathlib import Path

_path = Path(__file__).parent.parent.parent / "blacklist.json"


def _load() -> dict:
    try:
        with open(_path, encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return {"email": [], "chat": []}


_data = _load()


def is_email_blocked(value: str) -> bool:
    lower = value.lower()
    return any(term.lower() in lower for term in _data.get("email", []))


def is_chat_blocked(value: str) -> bool:
    lower = value.lower()
    return any(term.lower() in lower for term in _data.get("chat", []))
