"""
API router for the households module.

Exposes:
- GET  /v1/household
- POST /v1/household/join
- POST /v1/household/regenerate-code
"""

from fastapi import APIRouter, Depends, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db import get_database
from app.deps import AuthenticatedUser, get_current_auth
from app.modules.households.schemas import (
    HouseholdDetailResponse,
    JoinHouseholdRequest,
    JoinHouseholdResponse,
)
from app.modules.households.service import (
    get_household_details,
    join_household_by_code,
    regenerate_code,
)

router = APIRouter(prefix="/household", tags=["Household"])


@router.get(
    "",
    response_model=HouseholdDetailResponse,
    summary="Get current household",
    description="Returns household details, invite code, active status, and members list (id and name only).",
)
async def get_household(
    auth: AuthenticatedUser = Depends(get_current_auth),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> HouseholdDetailResponse:
    """Retrieve details and member list of the authenticated user's household."""
    return await get_household_details(db, auth.household_id)


@router.post(
    "/join",
    response_model=JoinHouseholdResponse,
    summary="Join household via invite code",
    description="Joins an active household by invite code. Rate limited to 10 attempts/hour per user. Moves items if sole member. Returns a fresh JWT token.",
)
async def join_household(
    payload: JoinHouseholdRequest,
    auth: AuthenticatedUser = Depends(get_current_auth),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> JoinHouseholdResponse:
    """Join an existing household using a 6-character invite code."""
    return await join_household_by_code(
        db=db,
        user_id=auth.user_id,
        old_household_id=auth.household_id,
        code=payload.code,
    )


@router.post(
    "/regenerate-code",
    response_model=HouseholdDetailResponse,
    summary="Regenerate household invite code",
    description="Generates a new unique 6-character invite code for the household. The old code stops working immediately.",
)
async def regenerate_invite_code(
    auth: AuthenticatedUser = Depends(get_current_auth),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> HouseholdDetailResponse:
    """Regenerate the invite code for the current household."""
    return await regenerate_code(db, auth.household_id)
