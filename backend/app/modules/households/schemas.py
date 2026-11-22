"""
Pydantic schemas for the households module.
"""

from typing import List
from pydantic import BaseModel, Field, field_validator


class MemberSummary(BaseModel):
    """Safe public member representation exposing only id and display name."""

    id: str
    name: str


class HouseholdDetailResponse(BaseModel):
    """Detailed household representation including member summaries."""

    id: str
    name: str
    invite_code: str
    is_active: bool
    members: List[MemberSummary]


class JoinHouseholdRequest(BaseModel):
    """Payload to join an existing household via invite code."""

    code: str = Field(..., min_length=1, max_length=20, description="6-character invite code")

    @field_validator("code")
    @classmethod
    def normalize_code(cls, v: str) -> str:
        cleaned = v.strip().upper()
        if not cleaned:
            raise ValueError("Invite code cannot be empty.")
        return cleaned


class JoinHouseholdResponse(BaseModel):
    """Response returned upon joining a household, containing a fresh JWT."""

    access_token: str
    token_type: str = "bearer"
    household: HouseholdDetailResponse
