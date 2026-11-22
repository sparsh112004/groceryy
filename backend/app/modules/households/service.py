"""
Households service layer.

Manages household details, member lookups, code regeneration,
join rate-limiting, and household migration on join.
"""

from collections import defaultdict
from datetime import datetime, timezone
import time
from typing import List
from bson import ObjectId
from fastapi import HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo.errors import OperationFailure, PyMongoError

from app.db import db_manager
from app.modules.auth.service import create_access_token, generate_unique_invite_code
from app.modules.items.service import parse_object_id
from app.modules.households.schemas import (
    HouseholdDetailResponse,
    JoinHouseholdResponse,
    MemberSummary,
)

# In-memory sliding window rate limiter: maps user_id -> list of timestamp floats
_join_attempts = defaultdict(list)
RATE_LIMIT_WINDOW_SECONDS = 3600  # 1 hour
MAX_JOIN_ATTEMPTS = 10


def enforce_join_rate_limit(user_id: str) -> None:
    """
    Limits household join attempts to 10 per hour per user to prevent
    invite code brute-force guessing.
    """
    now = time.time()
    # Prune attempts older than 1 hour
    _join_attempts[user_id] = [
        t for t in _join_attempts[user_id] if now - t < RATE_LIMIT_WINDOW_SECONDS
    ]
    if len(_join_attempts[user_id]) >= MAX_JOIN_ATTEMPTS:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many join attempts. Please try again later.",
        )
    _join_attempts[user_id].append(now)


async def fetch_household_members(
    db: AsyncIOMotorDatabase,
    member_ids: List[ObjectId],
) -> List[MemberSummary]:
    """
    Retrieves safe member representations (id and name only, never identifiers or secrets).
    """
    if not member_ids:
        return []
    cursor = db.users.find(
        {"_id": {"$in": member_ids}},
        {"_id": 1, "name": 1},
    )
    members: List[MemberSummary] = []
    async for u in cursor:
        members.append(MemberSummary(id=str(u["_id"]), name=u.get("name", "Unknown")))
    return members


async def get_household_details(
    db: AsyncIOMotorDatabase,
    household_id: str,
) -> HouseholdDetailResponse:
    """
    Fetches the household details and member list for the specified household.
    """
    hh_oid = parse_object_id(household_id)
    household = await db.households.find_one({"_id": hh_oid})
    if not household:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Household not found.",
        )

    members = await fetch_household_members(db, household.get("member_ids", []))

    return HouseholdDetailResponse(
        id=str(household["_id"]),
        name=household.get("name", "My Kitchen"),
        invite_code=household.get("invite_code", ""),
        is_active=household.get("is_active", True),
        members=members,
    )


async def regenerate_code(
    db: AsyncIOMotorDatabase,
    household_id: str,
) -> HouseholdDetailResponse:
    """
    Generates a new unique 6-character invite code for the household.
    The previous code is immediately invalidated.
    """
    hh_oid = parse_object_id(household_id)
    new_code = await generate_unique_invite_code(db)
    now = datetime.now(timezone.utc)

    result = await db.households.find_one_and_update(
        {"_id": hh_oid},
        {"$set": {"invite_code": new_code, "updated_at": now}},
    )
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Household not found.",
        )

    return await get_household_details(db, household_id)


async def join_household_by_code(
    db: AsyncIOMotorDatabase,
    user_id: str,
    old_household_id: str,
    code: str,
) -> JoinHouseholdResponse:
    """
    Joins an existing household via invite code:
    - Enforces rate limiting per user (10/hour).
    - Normalises code. Unknown or inactive code returns 404.
    - Joining current household returns 400.
    - If user was the sole member of old household: moves all pantry and shopping items
      to the new household, sets old household is_active=false, and clears its member list.
    - If old household still has other members: does not move items, removes user from old household.
    - Adds user to new household and updates users.household_id.
    - Returns a fresh JWT containing the new household_id plus the new household details.
    """
    enforce_join_rate_limit(user_id)
    normalized_code = code.strip().upper()

    # 1. Look up target household
    new_household = await db.households.find_one(
        {"invite_code": normalized_code, "is_active": True}
    )
    if not new_household:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invalid or inactive invite code.",
        )

    new_hh_oid = new_household["_id"]
    old_hh_oid = parse_object_id(old_household_id)
    user_oid = parse_object_id(user_id)

    # 2. Cannot join own current household
    if new_hh_oid == old_hh_oid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You are already a member of this household.",
        )

    # 3. Retrieve old household to check member count
    old_household = await db.households.find_one({"_id": old_hh_oid})
    if not old_household:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Current household not found.",
        )

    old_member_ids = old_household.get("member_ids", [])
    is_sole_member = (len(old_member_ids) <= 1) and (
        len(old_member_ids) == 0 or old_member_ids[0] == user_oid
    )

    now = datetime.now(timezone.utc)

    # 4. Attempt transaction if supported
    client = db_manager.client
    use_tx = False
    session = None
    if client is not None:
        try:
            session = await client.start_session()
            use_tx = True
        except (OperationFailure, PyMongoError):
            session = None
            use_tx = False

    if use_tx and session is not None:
        try:
            async with session:
                async with session.start_transaction():
                    if is_sole_member:
                        # Move items and shopping items to new household
                        await db.items.update_many(
                            {"household_id": old_hh_oid},
                            {"$set": {"household_id": new_hh_oid, "updated_at": now}},
                            session=session,
                        )
                        await db.shopping_items.update_many(
                            {"household_id": old_hh_oid},
                            {"$set": {"household_id": new_hh_oid, "updated_at": now}},
                            session=session,
                        )
                        # Deactivate old household and clear members (do not delete)
                        await db.households.update_one(
                            {"_id": old_hh_oid},
                            {"$set": {"is_active": False, "member_ids": [], "updated_at": now}},
                            session=session,
                        )
                    else:
                        # Remove user from old household
                        await db.households.update_one(
                            {"_id": old_hh_oid},
                            {"$pull": {"member_ids": user_oid}, "$set": {"updated_at": now}},
                            session=session,
                        )

                    # Add user to new household
                    await db.households.update_one(
                        {"_id": new_hh_oid},
                        {"$addToSet": {"member_ids": user_oid}, "$set": {"updated_at": now}},
                        session=session,
                    )

                    # Update user record
                    await db.users.update_one(
                        {"_id": user_oid},
                        {"$set": {"household_id": new_hh_oid, "updated_at": now}},
                        session=session,
                    )
        except (OperationFailure, PyMongoError) as tx_err:
            if "Transaction numbers are only allowed" in str(tx_err) or "standalone" in str(tx_err):
                use_tx = False
            else:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Database transaction error: {str(tx_err)}",
                )

    if not use_tx:
        # Resilient non-transactional execution
        if is_sole_member:
            # Move items first
            await db.items.update_many(
                {"household_id": old_hh_oid},
                {"$set": {"household_id": new_hh_oid, "updated_at": now}},
            )
            await db.shopping_items.update_many(
                {"household_id": old_hh_oid},
                {"$set": {"household_id": new_hh_oid, "updated_at": now}},
            )
            # Deactivate old household
            await db.households.update_one(
                {"_id": old_hh_oid},
                {"$set": {"is_active": False, "member_ids": [], "updated_at": now}},
            )
        else:
            # Remove from old household
            await db.households.update_one(
                {"_id": old_hh_oid},
                {"$pull": {"member_ids": user_oid}, "$set": {"updated_at": now}},
            )

        # Add to new household
        await db.households.update_one(
            {"_id": new_hh_oid},
            {"$addToSet": {"member_ids": user_oid}, "$set": {"updated_at": now}},
        )

        # Update user's active household
        await db.users.update_one(
            {"_id": user_oid},
            {"$set": {"household_id": new_hh_oid, "updated_at": now}},
        )

    # 5. Issue new JWT token containing new household_id
    new_token = create_access_token(user_id=user_id, household_id=str(new_hh_oid))
    updated_household_details = await get_household_details(db, str(new_hh_oid))

    return JoinHouseholdResponse(
        access_token=new_token,
        token_type="bearer",
        household=updated_household_details,
    )
