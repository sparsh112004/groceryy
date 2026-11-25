"""
Pydantic schemas for the shopping module.
"""

from datetime import date, datetime
from typing import List, Literal, Optional
from pydantic import BaseModel, Field, field_validator

from app.modules.items.schemas import ItemResponse


class ShoppingItemCreate(BaseModel):
    """Payload to add an item to the shopping list."""

    name: str = Field(..., min_length=1, max_length=150, description="Item name (required)")
    quantity: Optional[float] = Field(None, ge=0, description="Optional numerical quantity")
    unit: Optional[str] = Field(None, max_length=20, description="Optional unit (e.g. kg, liters, pcs)")
    category: Optional[str] = Field(None, max_length=40, description="Optional category (e.g. Dairy, Produce)")

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        cleaned = v.strip()
        if not cleaned:
            raise ValueError("Item name cannot be empty or whitespace.")
        return cleaned

    @field_validator("unit", "category")
    @classmethod
    def clean_optional_strings(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        cleaned = v.strip()
        return cleaned if cleaned else None


class ShoppingItemUpdate(BaseModel):
    """
    Payload to update an existing shopping list item.
    Only name, quantity, unit, category, and archived can be changed.
    household_id, bought, and added_by can NEVER be modified through this schema.
    """

    name: Optional[str] = Field(None, min_length=1, max_length=150)
    quantity: Optional[float] = Field(None, ge=0)
    unit: Optional[str] = Field(None, max_length=20)
    category: Optional[str] = Field(None, max_length=40)
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

    @field_validator("unit", "category")
    @classmethod
    def clean_optional_strings(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        cleaned = v.strip()
        return cleaned if cleaned else None


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
    unit: Optional[str] = None
    category: Optional[str] = None
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


class BulkBoughtItemRequest(MarkBoughtRequest):
    """Single item entry in a bulk mark-bought request."""

    id: str = Field(..., min_length=1, description="Shopping item ID")

    @field_validator("id")
    @classmethod
    def clean_id(cls, v: str) -> str:
        return v.strip()


class BulkBoughtRequest(BaseModel):
    """Payload to mark 1 to 50 shopping items as bought in one request."""

    items: List[BulkBoughtItemRequest] = Field(
        ...,
        min_length=1,
        max_length=50,
        description="List of 1 to 50 shopping items to mark as bought",
    )


class BulkBoughtItemResult(BaseModel):
    """Per-item outcome in a bulk mark-bought response."""

    id: str
    status: Literal["ok", "error"]
    code: int
    message: str
    shopping_item: Optional[ShoppingItemResponse] = None
    pantry_item: Optional[ItemResponse] = None


class BulkBoughtResponse(BaseModel):
    """Response returned for bulk mark-bought, preserving input order."""

    results: List[BulkBoughtItemResult]
