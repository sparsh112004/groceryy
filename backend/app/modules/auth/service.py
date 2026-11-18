"""
Authentication service logic.

Handles password/PIN hashing via bcrypt, identifier normalisation,
invite code generation, and database operations for users and households.
"""

from datetime import datetime, timedelta, timezone
import secrets
from typing import Optional
import bcrypt
from bson import ObjectId
from fastapi import HTTPException, status
import jwt
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo.errors import DuplicateKeyError

from app.config import settings
from app.modules.auth.schemas import (
    AuthResponse,
    HouseholdResponse,
    LoginRequest,
    MeResponse,
    SignupRequest,
    UserResponse,
)

# 32-character alphabet omitting 0, O, 1, I to avoid human transcription confusion
INVITE_CODE_ALPHABET = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"


def normalize_identifier(identifier: str) -> str:
    """
    Trims whitespace and lowercases email identifiers.
    Phone numbers are trimmed.
    """
    ident = identifier.strip()
    if "@" in ident:
        ident = ident.lower()
    return ident


def hash_secret(secret: str) -> str:
    """Hashes a password or PIN using bcrypt directly."""
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(secret.encode("utf-8"), salt).decode("utf-8")


def verify_secret(plain_secret: str, hashed_secret: str) -> bool:
    """Verifies a plain password or PIN against its bcrypt hash."""
    try:
        return bcrypt.checkpw(
            plain_secret.encode("utf-8"),
            hashed_secret.encode("utf-8"),
        )
    except Exception:
        return False


async def generate_unique_invite_code(db: AsyncIOMotorDatabase) -> str:
    """
    Generates a unique 6-character alphanumeric invite code avoiding 0/O and 1/I.
    Verifies uniqueness against existing households collection.
    """
    for _ in range(25):
        code = "".join(secrets.choice(INVITE_CODE_ALPHABET) for _ in range(6))
        existing = await db.households.find_one({"invite_code": code})
        if not existing:
            return code
    raise RuntimeError("Failed to generate a unique invite code after several attempts.")


def create_access_token(user_id: str, household_id: str) -> str:
    """
    Generates a JWT access token with ~30 days expiration containing
    user_id and household_id in the payload.
    """
    now = datetime.now(timezone.utc)
    expire = now + timedelta(days=settings.JWT_EXPIRE_DAYS)
    payload = {
        "sub": user_id,
        "user_id": user_id,
        "household_id": household_id,
        "iat": now,
        "exp": expire,
    }
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


async def signup_user(
    db: AsyncIOMotorDatabase,
    req: SignupRequest,
) -> AuthResponse:
    """
    Registers a new user and automatically creates their default personal household.
    Links the user to the household and issues a 30-day JWT.
    """
    normalized_ident = normalize_identifier(req.identifier)

    # Check for existing user with identical normalized identifier
    existing_user = await db.users.find_one({"identifier": normalized_ident})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An account with this email or phone number already exists.",
        )

    now = datetime.now(timezone.utc)
    user_id = ObjectId()
    household_id = ObjectId()
    invite_code = await generate_unique_invite_code(db)

    # 1. Create personal default household ("My Kitchen", is_active=true)
    household_doc = {
        "_id": household_id,
        "name": "My Kitchen",
        "invite_code": invite_code,
        "member_ids": [user_id],
        "is_active": True,
        "created_at": now,
        "updated_at": now,
    }
    await db.households.insert_one(household_doc)

    # 2. Hash secret and create user doc linked to household
    secret_hash = hash_secret(req.secret.strip())
    user_doc = {
        "_id": user_id,
        "name": req.name.strip(),
        "identifier": normalized_ident,
        "secret_hash": secret_hash,
        "household_id": household_id,
        "created_at": now,
        "updated_at": now,
    }

    try:
        await db.users.insert_one(user_doc)
    except DuplicateKeyError:
        # Roll back household if unique index collision occurs
        await db.households.delete_one({"_id": household_id})
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An account with this email or phone number already exists.",
        )

    token = create_access_token(str(user_id), str(household_id))

    user_response = UserResponse(
        id=str(user_id),
        name=user_doc["name"],
        identifier=user_doc["identifier"],
        household_id=str(household_id),
        created_at=user_doc["created_at"],
    )

    return AuthResponse(access_token=token, token_type="bearer", user=user_response)


async def login_user(
    db: AsyncIOMotorDatabase,
    req: LoginRequest,
) -> AuthResponse:
    """
    Authenticates a user by identifier and secret.
    Returns identical generic error message on invalid identifier or wrong secret
    to prevent user enumeration.
    """
    normalized_ident = normalize_identifier(req.identifier)
    user = await db.users.find_one({"identifier": normalized_ident})

    # Return same generic error for wrong identifier or wrong secret
    generic_error = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid identifier or password/PIN.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    if not user:
        raise generic_error

    if not verify_secret(req.secret.strip(), user.get("secret_hash", "")):
        raise generic_error

    user_id_str = str(user["_id"])
    household_id_str = str(user["household_id"])
    token = create_access_token(user_id_str, household_id_str)

    user_response = UserResponse(
        id=user_id_str,
        name=user["name"],
        identifier=user["identifier"],
        household_id=household_id_str,
        created_at=user["created_at"],
    )

    return AuthResponse(access_token=token, token_type="bearer", user=user_response)


async def get_me_profile(
    db: AsyncIOMotorDatabase,
    user_doc: dict,
) -> MeResponse:
    """
    Retrieves the current user's profile and their associated household information.
    """
    user_id_str = str(user_doc["_id"])
    household_id_raw = user_doc.get("household_id")
    household_id_str = str(household_id_raw) if household_id_raw else ""

    user_response = UserResponse(
        id=user_id_str,
        name=user_doc["name"],
        identifier=user_doc["identifier"],
        household_id=household_id_str,
        created_at=user_doc["created_at"],
    )

    household_response: Optional[HouseholdResponse] = None
    if household_id_raw:
        hh_query_id = (
            household_id_raw
            if isinstance(household_id_raw, ObjectId)
            else ObjectId(str(household_id_raw))
        )
        household_doc = await db.households.find_one({"_id": hh_query_id})
        if household_doc:
            household_response = HouseholdResponse(
                id=str(household_doc["_id"]),
                name=household_doc.get("name", "My Kitchen"),
                invite_code=household_doc.get("invite_code", ""),
                member_ids=[str(m) for m in household_doc.get("member_ids", [])],
                is_active=household_doc.get("is_active", True),
                created_at=household_doc.get("created_at", datetime.now(timezone.utc)),
            )

    return MeResponse(user=user_response, household=household_response)
