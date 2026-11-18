"""
Pydantic schemas for the authentication module.
"""

from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field, field_validator


class SignupRequest(BaseModel):
    """Payload for user registration."""

    name: str = Field(..., min_length=1, max_length=100, description="User's display name")
    identifier: str = Field(
        ...,
        min_length=3,
        max_length=255,
        description="User email or phone number",
    )
    secret: str = Field(
        ...,
        description="A numeric PIN (digits only, min 4 digits) or a password (min 6 characters)",
    )

    @field_validator("name")
    @classmethod
    def validate_name(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Name cannot be empty or just whitespace.")
        return cleaned

    @field_validator("identifier")
    @classmethod
    def validate_identifier(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Identifier cannot be empty.")
        return cleaned

    @field_validator("secret")
    @classmethod
    def validate_secret(cls, value: str) -> str:
        cleaned = value.strip()
        # Enforce Rule 12: min length 4 for PIN (digits only), 6 for password
        if cleaned.isdigit():
            if len(cleaned) < 4:
                raise ValueError("PIN must be at least 4 digits long.")
        else:
            if len(cleaned) < 6:
                raise ValueError("Password must be at least 6 characters long.")
        return cleaned


class LoginRequest(BaseModel):
    """Payload for user login."""

    identifier: str = Field(..., description="Registered email or phone number")
    secret: str = Field(..., description="Registered PIN or password")

    @field_validator("identifier")
    @classmethod
    def validate_identifier(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Identifier cannot be empty.")
        return cleaned


class UserResponse(BaseModel):
    """User profile response representation."""

    id: str
    name: str
    identifier: str
    household_id: str
    created_at: datetime


class HouseholdResponse(BaseModel):
    """Household response representation."""

    id: str
    name: str
    invite_code: str
    member_ids: List[str]
    is_active: bool
    created_at: datetime


class AuthResponse(BaseModel):
    """Response returned upon successful signup or login."""

    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class MeResponse(BaseModel):
    """Response for GET /v1/me endpoint."""

    user: UserResponse
    household: Optional[HouseholdResponse] = None
