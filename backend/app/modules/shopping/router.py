"""
API router for the shopping list module.

Exposes:
- GET   /v1/shopping
- POST  /v1/shopping
- PATCH /v1/shopping/{id}
- POST  /v1/shopping/bought-bulk
- POST  /v1/shopping/{id}/bought
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db import get_database
from app.deps import AuthenticatedUser, get_current_auth
from app.modules.shopping.schemas import (
    BoughtResponse,
    BulkBoughtRequest,
    BulkBoughtResponse,
    MarkBoughtRequest,
    ShoppingItemCreate,
    ShoppingItemResponse,
    ShoppingItemUpdate,
)
from app.modules.shopping.service import (
    create_shopping_item,
    list_shopping_items,
    mark_item_bought,
    mark_items_bought_bulk,
    update_shopping_item,
)

router = APIRouter(prefix="/shopping", tags=["Shopping List"])


@router.get(
    "",
    response_model=List[ShoppingItemResponse],
    summary="List shopping items",
    description="Returns shopping items for the household. Unbought items first (newest first), then bought items (most recently bought first). Supports ?bought=false and excludes archived items by default.",
)
async def get_shopping_items(
    bought: Optional[bool] = Query(
        None,
        description="Filter by bought flag: false (only unbought), true (only bought), or omit for both (unbought first)",
    ),
    include_archived: bool = Query(
        False,
        description="Whether to include archived shopping items (default: false)",
    ),
    auth: AuthenticatedUser = Depends(get_current_auth),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> List[ShoppingItemResponse]:
    """Retrieve shopping list items for the authenticated household."""
    return await list_shopping_items(
        db=db,
        household_id=auth.household_id,
        bought=bought,
        include_archived=include_archived,
    )


@router.post(
    "",
    response_model=ShoppingItemResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Add an item to shopping list",
    description="Adds a new unbought item to the authenticated household's shopping list.",
)
async def add_shopping_item(
    payload: ShoppingItemCreate,
    auth: AuthenticatedUser = Depends(get_current_auth),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> ShoppingItemResponse:
    """Create a new shopping item."""
    return await create_shopping_item(
        db=db,
        household_id=auth.household_id,
        user_id=auth.user_id,
        payload=payload,
    )


@router.patch(
    "/{id}",
    response_model=ShoppingItemResponse,
    summary="Update a shopping item",
    description="Updates name, quantity, unit, category, or archived flag of a shopping item. household_id, bought, and added_by cannot be changed.",
)
async def edit_shopping_item(
    id: str,
    payload: ShoppingItemUpdate,
    auth: AuthenticatedUser = Depends(get_current_auth),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> ShoppingItemResponse:
    """Update editable shopping item fields."""
    return await update_shopping_item(
        db=db,
        household_id=auth.household_id,
        item_id=id,
        payload=payload,
    )


@router.post(
    "/bought-bulk",
    response_model=BulkBoughtResponse,
    summary="Mark multiple shopping items as bought",
    description="Marks 1 to 50 shopping items bought=true and creates corresponding active pantry items. Per-item failures (404, 409, etc.) are reported in results without stopping remaining items.",
)
async def buy_items_bulk(
    payload: BulkBoughtRequest,
    auth: AuthenticatedUser = Depends(get_current_auth),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> BulkBoughtResponse:
    """Transition multiple shopping items to bought and add them to the pantry."""
    return await mark_items_bought_bulk(
        db=db,
        household_id=auth.household_id,
        user_id=auth.user_id,
        payload=payload,
    )


@router.post(
    "/{id}/bought",
    response_model=BoughtResponse,
    summary="Mark shopping item as bought",
    description="Marks a shopping item bought=true and automatically creates a corresponding active pantry item. Returns 409 if already bought.",
)
async def buy_item(
    id: str,
    payload: MarkBoughtRequest,
    auth: AuthenticatedUser = Depends(get_current_auth),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> BoughtResponse:
    """Transition a shopping item to bought and add to the pantry."""
    return await mark_item_bought(
        db=db,
        household_id=auth.household_id,
        user_id=auth.user_id,
        item_id=id,
        payload=payload,
    )
