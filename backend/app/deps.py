"""
Authentication and request dependencies.

Provides reusable FastAPI dependencies to validate JWT tokens, fetch
the authenticated user, and enforce household isolation (SPEC Rule 5).
"""

from typing import Any, Dict
from bson import ObjectId
from bson.errors import InvalidId
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import jwt
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.config import settings
from app.db import get_database

# HTTPBearer scheme adds the standard 'Authorize' Bearer token button to OpenAPI /docs
security = HTTPBearer(auto_error=True)


class AuthenticatedUser:
    """
    Encapsulates the authenticated user and their active household context.
    Ensures downstream handlers always extract household_id securely.
    """

    def __init__(self, user: Dict[str, Any], household_id: str) -> None:
        self.user = user
        self.user_id = str(user["_id"])
        self.household_id = household_id


def decode_jwt_token(token: str) -> Dict[str, Any]:
    """
    Decodes and validates a JWT token signature and expiration.
    Raises HTTPException(401) on invalid or expired token.
    """
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET,
            algorithms=[settings.JWT_ALGORITHM],
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication token has expired. Please log in again.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token.",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_auth(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> AuthenticatedUser:
    """
    Core dependency that validates the Bearer token, checks if the user exists
    in the database, and returns the AuthenticatedUser context.
    """
    token = credentials.credentials
    payload = decode_jwt_token(token)

    user_id_str = payload.get("user_id") or payload.get("sub")
    household_id_from_token = payload.get("household_id")

    if not user_id_str or not household_id_from_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token payload is missing user or household identification.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        user_object_id = ObjectId(user_id_str)
    except (InvalidId, TypeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Malformed user ID in authentication token.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Fetch user from MongoDB to verify existence
    user = await db.users.find_one({"_id": user_object_id})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User no longer exists.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # IMPORTANT: Ensure household_id comes from the user's current live database record
    # so an old token cannot keep pointing to a household the user has left.
    user_household_id = user.get("household_id")
    if not user_household_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is not currently assigned to any household.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    current_household_id = str(user_household_id)

    return AuthenticatedUser(user=user, household_id=current_household_id)


def get_current_user(
    auth: AuthenticatedUser = Depends(get_current_auth),
) -> Dict[str, Any]:
    """Dependency helper returning the current MongoDB user document."""
    return auth.user


def get_current_household_id(
    auth: AuthenticatedUser = Depends(get_current_auth),
) -> str:
    """
    Dependency helper returning the authenticated user's household_id.
    Per SPEC Rule 5, all endpoints must take household_id from this dependency,
    never from request bodies or unauthenticated query parameters.
    """
    return auth.household_id
