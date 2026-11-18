"""
Authentication and profile API router.

Exposes:
- POST /v1/auth/signup
- POST /v1/auth/login
- GET  /v1/me
"""

from fastapi import APIRouter, Depends, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db import get_database
from app.deps import get_current_user
from app.modules.auth.schemas import (
    AuthResponse,
    LoginRequest,
    MeResponse,
    SignupRequest,
)
from app.modules.auth.service import (
    get_me_profile,
    login_user,
    signup_user,
)

router = APIRouter(tags=["Authentication & Profile"])


@router.post(
    "/auth/signup",
    response_model=AuthResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register new user and household",
    description="Registers a user with email/phone and PIN/password, auto-creates their default household ('My Kitchen'), and returns a 30-day JWT token.",
)
async def signup(
    payload: SignupRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> AuthResponse:
    """Handle user signup."""
    return await signup_user(db, payload)


@router.post(
    "/auth/login",
    response_model=AuthResponse,
    summary="User login",
    description="Authenticates user credentials and returns a 30-day JWT access token.",
)
async def login(
    payload: LoginRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> AuthResponse:
    """Handle user login."""
    return await login_user(db, payload)


@router.get(
    "/me",
    response_model=MeResponse,
    summary="Get current user and household",
    description="Returns the profile and household details for the currently authenticated user.",
)
async def get_me(
    user_doc: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> MeResponse:
    """Retrieve profile and household of the token bearer."""
    return await get_me_profile(db, user_doc)


@router.get(
    "/auth/me",
    response_model=MeResponse,
    include_in_schema=False,
    summary="Get current user (alias)",
)
async def get_me_alias(
    user_doc: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> MeResponse:
    """Alias for /me endpoint under /auth."""
    return await get_me_profile(db, user_doc)
