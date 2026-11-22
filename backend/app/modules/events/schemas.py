"""
Pydantic schemas for the events module.
"""

from datetime import datetime
import json
from typing import Any, Dict, Literal, Optional
from pydantic import BaseModel, Field, field_validator

# SPEC Section 10: Permitted event types
AllowedEventType = Literal[
    "app_open",
    "signup",
    "login",
    "item_added",
    "item_used",
    "item_thrown",
    "shopping_added",
    "shopping_bought",
    "reminder_opened",
    "household_joined",
    "invite_shared",
]

MAX_META_BYTES = 2048  # 2 KB limit for payload metadata


class EventCreate(BaseModel):
    """Payload to log a client-side event."""

    type: AllowedEventType = Field(
        ...,
        description="Allowed event type (e.g. app_open, item_added, shopping_bought)",
    )
    meta: Optional[Dict[str, Any]] = Field(
        default_factory=dict,
        description="Optional metadata object (max 2 KB)",
    )

    @field_validator("meta")
    @classmethod
    def validate_meta_size(cls, v: Optional[Dict[str, Any]]) -> Dict[str, Any]:
        if v is None:
            return {}
        try:
            serialized = json.dumps(v)
        except (TypeError, ValueError) as err:
            raise ValueError(f"Meta must be valid JSON-serializable object: {err}")

        if len(serialized.encode("utf-8")) > MAX_META_BYTES:
            raise ValueError(f"Meta payload exceeds 2 KB limit ({MAX_META_BYTES} bytes).")
        return v


class EventResponse(BaseModel):
    """Event logging response."""

    id: str
    user_id: str
    household_id: str
    type: str
    meta: Dict[str, Any]
    timestamp: datetime
