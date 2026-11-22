"""
Pydantic schemas for items (inventory) module.
"""

from datetime import date, datetime
from typing import Literal, Optional
from pydantic import BaseModel, Field, field_validator


class ItemCreate(BaseModel):
    """Payload to create a new pantry item."""

    name: str = Field(..., min_length=1, max_length=150, description="Item name (required)")
    expiry_date: date = Field(..., description="Expiration date in YYYY-MM-DD format (required)")
    quantity: Optional[float] = Field(None, ge=0, description="Optional numerical quantity")
    unit: Optional[str] = Field(None, max_length=50, description="Optional unit of measurement (e.g. kg, liters, pcs)")
    category: Optional[str] = Field(None, max_length=50, description="Optional category (e.g. Dairy, Produce, Bakery)")
    location: Optional[str] = Field(None, max_length=50, description="Optional storage location (e.g. Fridge, Freezer, Pantry)")
    barcode: Optional[str] = Field(None, max_length=100, description="Optional barcode string")

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        cleaned = v.strip()
        if not cleaned:
            raise ValueError("Item name cannot be empty or blank.")
        return cleaned

    @field_validator("unit", "category", "location", "barcode")
    @classmethod
    def clean_optional_strings(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        cleaned = v.strip()
        return cleaned if cleaned else None


class ItemUpdate(BaseModel):
    """
    Payload to update an existing item.
    Only allows modifying non-administrative fields.
    household_id, status, and added_by can NEVER be modified through this schema.
    """

    name: Optional[str] = Field(None, min_length=1, max_length=150)
    expiry_date: Optional[date] = None
    quantity: Optional[float] = Field(None, ge=0)
    unit: Optional[str] = Field(None, max_length=50)
    category: Optional[str] = Field(None, max_length=50)
    location: Optional[str] = Field(None, max_length=50)
    barcode: Optional[str] = Field(None, max_length=100)

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        cleaned = v.strip()
        if not cleaned:
            raise ValueError("Item name cannot be empty.")
        return cleaned

    @field_validator("unit", "category", "location", "barcode")
    @classmethod
    def clean_optional_strings(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        cleaned = v.strip()
        return cleaned if cleaned else None


class ItemResponse(BaseModel):
    """
    Detailed item representation returned by API endpoints.
    Includes computed days_left and expiry_status dynamically evaluated on read.
    """

    id: str
    household_id: str
    name: str
    expiry_date: date
    status: Literal["active", "used", "thrown"]
    days_left: int
    expiry_status: Literal["expired", "soon", "fresh"]
    quantity: Optional[float] = None
    unit: Optional[str] = None
    category: Optional[str] = None
    location: Optional[str] = None
    barcode: Optional[str] = None
    added_by: str
    used_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
