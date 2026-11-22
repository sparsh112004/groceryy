"""
API router for the events telemetry module.

Exposes:
- POST /v1/events
"""

from fastapi import APIRouter, Depends, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db import get_database
from app.deps import AuthenticatedUser, get_current_auth
from app.modules.events.schemas import EventCreate, EventResponse
from app.modules.events.service import record_event

router = APIRouter(prefix="/events", tags=["Events"])


@router.post(
    "",
    response_model=EventResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Log application event",
    description="Records a telemetry event (app_open, item_added, etc.). Enforces strict whitelist of event types and 2 KB metadata limit.",
)
async def log_event(
    payload: EventCreate,
    auth: AuthenticatedUser = Depends(get_current_auth),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> EventResponse:
    """Log a usage event with user and household scoping."""
    return await record_event(
        db=db,
        user_id=auth.user_id,
        household_id=auth.household_id,
        payload=payload,
    )
