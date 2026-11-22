"""
Events service layer.

Stores validated application telemetry and usage events in the MongoDB events collection.
"""

from datetime import datetime, timezone
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.modules.events.schemas import EventCreate, EventResponse
from app.modules.items.service import parse_object_id


async def record_event(
    db: AsyncIOMotorDatabase,
    user_id: str,
    household_id: str,
    payload: EventCreate,
) -> EventResponse:
    """
    Inserts a validated event record into the events collection with server-side UTC timestamp.
    """
    hh_oid = parse_object_id(household_id)
    now = datetime.now(timezone.utc)

    event_doc = {
        "user_id": user_id,
        "household_id": hh_oid,
        "type": payload.type,
        "meta": payload.meta or {},
        "timestamp": now,
    }

    result = await db.events.insert_one(event_doc)
    event_doc["_id"] = result.inserted_id

    return EventResponse(
        id=str(event_doc["_id"]),
        user_id=event_doc["user_id"],
        household_id=str(event_doc["household_id"]),
        type=event_doc["type"],
        meta=event_doc["meta"],
        timestamp=event_doc["timestamp"],
    )
