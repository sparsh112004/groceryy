"""
Pydantic schemas for the shopping module.
"""

from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, Field, field_validator

from app.modules.items.schemas import ItemResponse


class ShoppingItemCreate(BaseModel):
    """Payload to add an item to the shopping list."""

    name: str = Field(..., min_length=1, max_length=150, description="Item name (required)")
    quantity: Optional[float] = Field(None, ge=0, description="Optional numerical quantity")

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        cleaned = v.strip()
        if not cleaned:
            raise ValueError("Item name cannot be empty or whitespace.")
        return cleaned


class ShoppingItemUpdate(BaseModel):
    """
    Payload to update an existing shopping list item.
    Only name, quantity, and archived can be changed.
    household_id, bought, and added_by can NEVER be modified through this schema.
    """

    name: Optional[str] = Field(None, min_length=1, max_length=150)
    quantity: Optional[float] = Field(None, ge=0)
    archived: Optional[bool] = None

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        cleaned = v.strip()
        if not cleaned:
            raise ValueError("Item name cannot be empty or whitespace.")
        return cleaned


class MarkBoughtRequest(BaseModel):
    """
    Payload when marking a shopping item as bought.
    Prompts only for expiry_date, with optional pantry storage metadata.
    """

    expiry_date: date = Field(..., description="Expiry date for the pantry item (YYYY-MM-DD)")
    quantity: Optional[float] = Field(None, ge=0, description="Optional quantity override")
    unit: Optional[str] = Field(None, max_length=50, description="Optional unit (e.g. liters, kg)")
    category: Optional[str] = Field(None, max_length=50, description="Optional pantry category")
    location: Optional[str] = Field(None, max_length=50, description="Optional pantry storage location")

    @field_validator("unit", "category", "location")
    @classmethod
    def clean_strings(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        cleaned = v.strip()
        return cleaned if cleaned else None


class ShoppingItemResponse(BaseModel):
    """Shopping item response schema."""

    id: str
    household_id: str
    name: str
    quantity: Optional[float] = None
    bought: bool
    bought_at: Optional[datetime] = None
    archived: bool
    added_by: str
    created_at: datetime
    updated_at: datetime


class BoughtResponse(BaseModel):
    """Response returned after marking an item bought, including the created pantry item."""

    shopping_item: ShoppingItemResponse
    pantry_item: ItemResponse
