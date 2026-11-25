"""
Shopping list service layer.

Handles shopping list items, cross-household scoping, status updates,
and atomic transition of bought items into the active pantry inventory.
"""

from datetime import datetime, timezone
from typing import List, Optional
from bson import ObjectId
from fastapi import HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo import ReturnDocument
from pymongo.errors import OperationFailure, PyMongoError

from app.db import db_manager
from app.modules.items.schemas import ItemCreate, ItemResponse
from app.modules.items.service import create_item, parse_object_id
from app.modules.shopping.schemas import (
    BoughtResponse,
    BulkBoughtItemResult,
    BulkBoughtRequest,
    BulkBoughtResponse,
    MarkBoughtRequest,
    ShoppingItemCreate,
    ShoppingItemResponse,
    ShoppingItemUpdate,
)


def format_shopping_doc(doc: dict) -> ShoppingItemResponse:
    """Serializes a raw MongoDB shopping document to ShoppingItemResponse."""
    return ShoppingItemResponse(
        id=str(doc["_id"]),
        household_id=str(doc["household_id"]),
        name=doc["name"],
        quantity=doc.get("quantity"),
        unit=doc.get("unit"),
        category=doc.get("category"),
        bought=doc.get("bought", False),
        bought_at=doc.get("bought_at"),
        archived=doc.get("archived", False),
        added_by=str(doc.get("added_by", "")),
        created_at=doc.get("created_at", datetime.now(timezone.utc)),
        updated_at=doc.get("updated_at", datetime.now(timezone.utc)),
    )


async def create_shopping_item(
    db: AsyncIOMotorDatabase,
    household_id: str,
    user_id: str,
    payload: ShoppingItemCreate,
) -> ShoppingItemResponse:
    """Creates a new shopping list item scoped to the user's household."""
    hh_oid = parse_object_id(household_id)
    now = datetime.now(timezone.utc)

    doc = {
        "household_id": hh_oid,
        "name": payload.name,
        "quantity": payload.quantity,
        "unit": payload.unit,
        "category": payload.category,
        "bought": False,
        "bought_at": None,
        "archived": False,
        "added_by": user_id,
        "created_at": now,
        "updated_at": now,
    }

    result = await db.shopping_items.insert_one(doc)
    doc["_id"] = result.inserted_id

    return format_shopping_doc(doc)


async def list_shopping_items(
    db: AsyncIOMotorDatabase,
    household_id: str,
    bought: Optional[bool] = None,
    include_archived: bool = False,
) -> List[ShoppingItemResponse]:
    """
    Retrieves shopping items for a household.
    Ordering:
    - If bought is None: unbought items first (newest created_at first),
      followed by bought items (most recently bought_at first).
    - If bought is False: only unbought items, newest first.
    - If bought is True: only bought items, most recently bought first.
    By default, excludes archived items.
    """
    hh_oid = parse_object_id(household_id)
    base_query: dict = {"household_id": hh_oid}

    if not include_archived:
        base_query["archived"] = {"$ne": True}

    if bought is False:
        query = {**base_query, "bought": False}
        docs = await db.shopping_items.find(query).sort("created_at", -1).to_list(length=2000)
        return [format_shopping_doc(doc) for doc in docs]

    if bought is True:
        query = {**base_query, "bought": True}
        docs = await db.shopping_items.find(query).sort("bought_at", -1).to_list(length=2000)
        return [format_shopping_doc(doc) for doc in docs]

    # When bought is None, retrieve unbought first (newest first), then bought (newest bought_at first)
    unbought_query = {**base_query, "bought": False}
    bought_query = {**base_query, "bought": True}

    unbought_docs = await db.shopping_items.find(unbought_query).sort("created_at", -1).to_list(length=1000)
    bought_docs = await db.shopping_items.find(bought_query).sort("bought_at", -1).to_list(length=1000)

    combined = unbought_docs + bought_docs
    return [format_shopping_doc(doc) for doc in combined]


async def update_shopping_item(
    db: AsyncIOMotorDatabase,
    household_id: str,
    item_id: str,
    payload: ShoppingItemUpdate,
) -> ShoppingItemResponse:
    """
    Updates allowed fields (name, quantity, unit, category, archived) of a shopping item.
    Enforces that household_id, bought, and added_by cannot be changed.
    """
    item_oid = parse_object_id(item_id)
    hh_oid = parse_object_id(household_id)

    raw_data = payload.model_dump(exclude_unset=True)
    allowed_keys = {"name", "quantity", "unit", "category", "archived"}
    update_data = {k: v for k, v in raw_data.items() if k in allowed_keys}

    now = datetime.now(timezone.utc)
    update_data["updated_at"] = now

    updated_doc = await db.shopping_items.find_one_and_update(
        {"_id": item_oid, "household_id": hh_oid},
        {"$set": update_data},
        return_document=ReturnDocument.AFTER,
    )

    if not updated_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Shopping item not found.",
        )

    return format_shopping_doc(updated_doc)


async def mark_item_bought(
    db: AsyncIOMotorDatabase,
    household_id: str,
    user_id: str,
    item_id: str,
    payload: MarkBoughtRequest,
) -> BoughtResponse:
    """
    Marks shopping item bought=true and creates an active pantry item in one operation.
    - If already bought, returns 409 Conflict without creating a duplicate pantry item.
    - Attempts a MongoDB transaction; falls back gracefully to resilient rollback pattern
      if transactions are not supported on the target cluster.
    """
    item_oid = parse_object_id(item_id)
    hh_oid = parse_object_id(household_id)

    # 1. Fetch shopping item to verify existence and household scoping
    shopping_item = await db.shopping_items.find_one({"_id": item_oid, "household_id": hh_oid})
    if not shopping_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Shopping item not found.",
        )

    # 2. Prevent duplicate buying
    if shopping_item.get("bought", False):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Shopping item is already marked as bought.",
        )

    now = datetime.now(timezone.utc)
    item_quantity = payload.quantity if payload.quantity is not None else shopping_item.get("quantity")
    item_unit = payload.unit if payload.unit is not None else shopping_item.get("unit")
    item_category = payload.category if payload.category is not None else shopping_item.get("category")

    pantry_payload = ItemCreate(
        name=shopping_item["name"],
        expiry_date=payload.expiry_date,
        quantity=item_quantity,
        unit=item_unit,
        category=item_category,
        location=payload.location,
    )

    # 3. Attempt transaction with client session if available
    client = db_manager.client
    use_transaction = False
    session = None

    if client is not None:
        try:
            session = await client.start_session()
            use_transaction = True
        except (OperationFailure, PyMongoError):
            session = None
            use_transaction = False

    if use_transaction and session is not None:
        try:
            async with session:
                async with session.start_transaction():
                    # Create pantry item with session
                    pantry_doc = {
                        "household_id": hh_oid,
                        "name": pantry_payload.name,
                        "expiry_date": pantry_payload.expiry_date.isoformat(),
                        "status": "active",
                        "quantity": pantry_payload.quantity,
                        "unit": pantry_payload.unit,
                        "category": pantry_payload.category,
                        "location": pantry_payload.location,
                        "barcode": None,
                        "added_by": user_id,
                        "used_at": None,
                        "created_at": now,
                        "updated_at": now,
                    }
                    res = await db.items.insert_one(pantry_doc, session=session)
                    pantry_doc["_id"] = res.inserted_id

                    # Mark shopping item bought with session
                    updated_shopping = await db.shopping_items.find_one_and_update(
                        {"_id": item_oid, "household_id": hh_oid, "bought": False},
                        {
                            "$set": {
                                "bought": True,
                                "bought_at": now,
                                "updated_at": now,
                            }
                        },
                        return_document=ReturnDocument.AFTER,
                        session=session,
                    )

                    if not updated_shopping:
                        # Item was concurrently bought
                        raise HTTPException(
                            status_code=status.HTTP_409_CONFLICT,
                            detail="Shopping item was already marked as bought.",
                        )

            from app.modules.items.service import format_item_doc
            return BoughtResponse(
                shopping_item=format_shopping_doc(updated_shopping),
                pantry_item=format_item_doc(pantry_doc),
            )
        except (OperationFailure, PyMongoError) as err:
            # If transaction fails specifically because replica set is not configured, fall through to resilient approach
            if "Transaction numbers are only allowed" in str(err) or "standalone" in str(err):
                pass
            elif isinstance(err, HTTPException):
                raise err
            else:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Database transaction error: {str(err)}",
                )

    # 4. Resilient Fallback (Create Pantry Item -> Update Shopping Item -> Rollback on error)
    created_pantry_item: Optional[ItemResponse] = None
    try:
        created_pantry_item = await create_item(
            db=db,
            household_id=household_id,
            user_id=user_id,
            payload=pantry_payload,
        )

        updated_shopping = await db.shopping_items.find_one_and_update(
            {"_id": item_oid, "household_id": hh_oid, "bought": False},
            {
                "$set": {
                    "bought": True,
                    "bought_at": now,
                    "updated_at": now,
                }
            },
            return_document=ReturnDocument.AFTER,
        )

        if not updated_shopping:
            # Shopping item could not be marked bought (e.g. concurrent request already marked it)
            # Rollback: delete created pantry item so failure cannot leave orphan
            if created_pantry_item:
                await db.items.delete_one({"_id": ObjectId(created_pantry_item.id)})
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Shopping item is already marked as bought.",
            )

        return BoughtResponse(
            shopping_item=format_shopping_doc(updated_shopping),
            pantry_item=created_pantry_item,
        )
    except Exception as exc:
        # If any unexpected exception happened after pantry creation, rollback pantry item
        if created_pantry_item:
            await db.items.delete_one({"_id": ObjectId(created_pantry_item.id)})
        if isinstance(exc, HTTPException):
            raise exc
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to complete bought transition: {str(exc)}",
        )


async def mark_items_bought_bulk(
    db: AsyncIOMotorDatabase,
    household_id: str,
    user_id: str,
    payload: BulkBoughtRequest,
) -> BulkBoughtResponse:
    """
    Marks multiple shopping items (1..50) as bought and creates corresponding pantry items.
    Applies mark_item_bought logic per entry; a failure on one entry does not stop the rest.
    Returns results in the same order as the input list.
    """
    results: List[BulkBoughtItemResult] = []

    for entry in payload.items:
        try:
            bought_res = await mark_item_bought(
                db=db,
                household_id=household_id,
                user_id=user_id,
                item_id=entry.id,
                payload=entry,
            )
            results.append(
                BulkBoughtItemResult(
                    id=entry.id,
                    status="ok",
                    code=status.HTTP_200_OK,
                    message="Shopping item marked as bought.",
                    shopping_item=bought_res.shopping_item,
                    pantry_item=bought_res.pantry_item,
                )
            )
        except HTTPException as exc:
            results.append(
                BulkBoughtItemResult(
                    id=entry.id,
                    status="error",
                    code=exc.status_code,
                    message=str(exc.detail),
                )
            )
        except Exception as exc:
            results.append(
                BulkBoughtItemResult(
                    id=entry.id,
                    status="error",
                    code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    message=f"Failed to complete bought transition: {str(exc)}",
                )
            )

    return BulkBoughtResponse(results=results)
