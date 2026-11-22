"""
API router for items (pantry inventory).

Exposes:
- POST  /v1/items
- GET   /v1/items
- GET   /v1/items/use-first
- PATCH /v1/items/{id}
- POST  /v1/items/{id}/use
- POST  /v1/items/{id}/throw
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db import get_database
from app.deps import AuthenticatedUser, get_current_auth
from app.modules.items.schemas import ItemCreate, ItemResponse, ItemUpdate
from app.modules.items.service import (
    change_item_status,
    create_item,
    get_use_first_items,
    list_items,
    update_item,
)

router = APIRouter(prefix="/items", tags=["Pantry Items"])


@router.post(
    "",
    response_model=ItemResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Add a new pantry item",
    description="Creates an active item in the authenticated user's household pantry.",
)
async def add_item(
    payload: ItemCreate,
    auth: AuthenticatedUser = Depends(get_current_auth),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> ItemResponse:
    """Add a new item to the household pantry."""
    return await create_item(
        db=db,
        household_id=auth.household_id,
        user_id=auth.user_id,
        payload=payload,
    )


@router.get(
    "/use-first",
    response_model=List[ItemResponse],
    summary="Get Use First items",
    description="Returns the top 5 active items expiring soonest (expired first) for the Home screen.",
)
async def get_use_first(
    auth: AuthenticatedUser = Depends(get_current_auth),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> List[ItemResponse]:
    """Retrieve up to 5 items to prioritize using."""
    return await get_use_first_items(db=db, household_id=auth.household_id)


@router.get(
    "",
    response_model=List[ItemResponse],
    summary="List pantry items",
    description="Returns pantry items sorted by expiry date ascending. Supports status, category, and name search filters.",
)
async def get_items(
    status: Optional[str] = Query(
        "active",
        description="Filter by item status: 'active' (default), 'used', 'thrown', or 'all'",
    ),
    category: Optional[str] = Query(
        None,
        description="Optional category filter (e.g. Dairy, Produce)",
    ),
    q: Optional[str] = Query(
        None,
        description="Case-insensitive search query matching item name",
    ),
    auth: AuthenticatedUser = Depends(get_current_auth),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> List[ItemResponse]:
    """List and filter household items."""
    return await list_items(
        db=db,
        household_id=auth.household_id,
        status_filter=status,
        category_filter=category,
        q=q,
    )


@router.patch(
    "/{id}",
    response_model=ItemResponse,
    summary="Update pantry item",
    description="Updates item details (name, expiry_date, quantity, unit, category, location, barcode).",
)
async def edit_item(
    id: str,
    payload: ItemUpdate,
    auth: AuthenticatedUser = Depends(get_current_auth),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> ItemResponse:
    """Update editable fields of an item."""
    return await update_item(
        db=db,
        household_id=auth.household_id,
        item_id=id,
        payload=payload,
    )


@router.post(
    "/{id}/use",
    response_model=ItemResponse,
    summary="Mark item as used",
    description="Soft-deletes item by marking status as 'used' and recording the used_at timestamp.",
)
async def mark_used(
    id: str,
    auth: AuthenticatedUser = Depends(get_current_auth),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> ItemResponse:
    """Mark an item as used."""
    return await change_item_status(
        db=db,
        household_id=auth.household_id,
        item_id=id,
        new_status="used",
    )


@router.post(
    "/{id}/throw",
    response_model=ItemResponse,
    summary="Mark item as thrown away",
    description="Soft-deletes item by marking status as 'thrown' and recording the used_at timestamp.",
)
async def mark_thrown(
    id: str,
    auth: AuthenticatedUser = Depends(get_current_auth),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> ItemResponse:
    """Mark an item as thrown away."""
    return await change_item_status(
        db=db,
        household_id=auth.household_id,
        item_id=id,
        new_status="thrown",
    )
