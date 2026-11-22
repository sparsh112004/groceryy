"""
Items service layer.

Handles pantry inventory business logic, dynamic expiry calculations,
household scoping, and database updates.
"""

from datetime import date, datetime, timezone
import re
from typing import List, Literal, Optional, Tuple
from bson import ObjectId
from fastapi import HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo import ReturnDocument

from app.modules.items.schemas import ItemCreate, ItemResponse, ItemUpdate


def parse_object_id(id_str: str) -> ObjectId:
    """
    Validates and converts a string ID to a BSON ObjectId.
    Returns HTTP 404 instead of throwing an internal 500 error if format is invalid.
    """
    if not ObjectId.is_valid(id_str):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item not found.",
        )
    return ObjectId(id_str)


def compute_expiry_info(exp_date: date) -> Tuple[int, Literal["expired", "soon", "fresh"]]:
    """
    Computes days_left and expiry_status dynamically on read.
    Rules (SPEC Section 6):
    - 'expired' if days_left < 0
    - 'soon' if 0 <= days_left <= 3
    - 'fresh' otherwise
    Uses UTC date as consistent reference point.
    """
    today = datetime.now(timezone.utc).date()
    days_left = (exp_date - today).days

    if days_left < 0:
        expiry_status = "expired"
    elif 0 <= days_left <= 3:
        expiry_status = "soon"
    else:
        expiry_status = "fresh"

    return days_left, expiry_status


def format_item_doc(doc: dict) -> ItemResponse:
    """
    Transforms a raw MongoDB document into a strongly-typed ItemResponse,
    calculating days_left and expiry_status on the fly.
    """
    expiry_raw = doc["expiry_date"]
    if isinstance(expiry_raw, str):
        exp_date = date.fromisoformat(expiry_raw)
    elif isinstance(expiry_raw, datetime):
        exp_date = expiry_raw.date()
    elif isinstance(expiry_raw, date):
        exp_date = expiry_raw
    else:
        exp_date = datetime.now(timezone.utc).date()

    days_left, expiry_status = compute_expiry_info(exp_date)

    return ItemResponse(
        id=str(doc["_id"]),
        household_id=str(doc["household_id"]),
        name=doc["name"],
        expiry_date=exp_date,
        status=doc.get("status", "active"),
        days_left=days_left,
        expiry_status=expiry_status,
        quantity=doc.get("quantity"),
        unit=doc.get("unit"),
        category=doc.get("category"),
        location=doc.get("location"),
        barcode=doc.get("barcode"),
        added_by=str(doc.get("added_by", "")),
        used_at=doc.get("used_at"),
        created_at=doc.get("created_at", datetime.now(timezone.utc)),
        updated_at=doc.get("updated_at", datetime.now(timezone.utc)),
    )


async def create_item(
    db: AsyncIOMotorDatabase,
    household_id: str,
    user_id: str,
    payload: ItemCreate,
) -> ItemResponse:
    """
    Creates a new pantry item strictly scoped to the authenticated household.
    """
    hh_oid = parse_object_id(household_id)
    now = datetime.now(timezone.utc)

    item_doc = {
        "household_id": hh_oid,
        "name": payload.name,
        "expiry_date": payload.expiry_date.isoformat(),
        "status": "active",
        "quantity": payload.quantity,
        "unit": payload.unit,
        "category": payload.category,
        "location": payload.location,
        "barcode": payload.barcode,
        "added_by": user_id,
        "used_at": None,
        "created_at": now,
        "updated_at": now,
    }

    result = await db.items.insert_one(item_doc)
    item_doc["_id"] = result.inserted_id

    return format_item_doc(item_doc)


async def list_items(
    db: AsyncIOMotorDatabase,
    household_id: str,
    status_filter: Optional[str] = "active",
    category_filter: Optional[str] = None,
    q: Optional[str] = None,
) -> List[ItemResponse]:
    """
    Lists pantry items sorted by expiry_date ascending.
    Filters:
    - status: defaults to 'active'; 'all' removes status filtering
    - category: exact match filter
    - q: case-insensitive partial substring match on item name
    """
    hh_oid = parse_object_id(household_id)
    query: dict = {"household_id": hh_oid}

    if status_filter and status_filter.lower() != "all":
        query["status"] = status_filter

    if category_filter:
        query["category"] = category_filter.strip()

    if q and q.strip():
        # Case-insensitive regular expression search with escaped special chars
        escaped_query = re.escape(q.strip())
        query["name"] = {"$regex": escaped_query, "$options": "i"}

    # Sort soonest expiry first
    cursor = db.items.find(query).sort("expiry_date", 1)
    docs = await cursor.to_list(length=2000)

    return [format_item_doc(doc) for doc in docs]


async def get_use_first_items(
    db: AsyncIOMotorDatabase,
    household_id: str,
) -> List[ItemResponse]:
    """
    Retrieves the top 5 active items that expire soonest (expired first).
    """
    hh_oid = parse_object_id(household_id)
    query = {"household_id": hh_oid, "status": "active"}

    cursor = db.items.find(query).sort("expiry_date", 1).limit(5)
    docs = await cursor.to_list(length=5)

    return [format_item_doc(doc) for doc in docs]


async def update_item(
    db: AsyncIOMotorDatabase,
    household_id: str,
    item_id: str,
    payload: ItemUpdate,
) -> ItemResponse:
    """
    Updates mutable fields of an item.
    Enforces that household_id, status, and added_by cannot be modified.
    Returns 404 if item does not exist or belongs to another household.
    """
    item_oid = parse_object_id(item_id)
    hh_oid = parse_object_id(household_id)

    # Exclude unset fields so only provided values are updated
    raw_data = payload.model_dump(exclude_unset=True)

    # Whitelist of allowed editable fields
    allowed_fields = {"name", "expiry_date", "quantity", "unit", "category", "location", "barcode"}
    update_data = {k: v for k, v in raw_data.items() if k in allowed_fields}

    if "expiry_date" in update_data and isinstance(update_data["expiry_date"], (date, datetime)):
        update_data["expiry_date"] = update_data["expiry_date"].isoformat()

    now = datetime.now(timezone.utc)
    update_data["updated_at"] = now

    updated_doc = await db.items.find_one_and_update(
        {"_id": item_oid, "household_id": hh_oid},
        {"$set": update_data},
        return_document=ReturnDocument.AFTER,
    )

    if not updated_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item not found.",
        )

    return format_item_doc(updated_doc)


async def change_item_status(
    db: AsyncIOMotorDatabase,
    household_id: str,
    item_id: str,
    new_status: Literal["used", "thrown"],
) -> ItemResponse:
    """
    Sets item status to 'used' or 'thrown' and records used_at timestamp.
    Items are soft-deleted and never physically removed (SPEC Rule 6).
    Returns 404 if item does not exist or belongs to another household.
    """
    item_oid = parse_object_id(item_id)
    hh_oid = parse_object_id(household_id)
    now = datetime.now(timezone.utc)

    updated_doc = await db.items.find_one_and_update(
        {"_id": item_oid, "household_id": hh_oid},
        {
            "$set": {
                "status": new_status,
                "used_at": now,
                "updated_at": now,
            }
        },
        return_document=ReturnDocument.AFTER,
    )

    if not updated_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item not found.",
        )

    return format_item_doc(updated_doc)
