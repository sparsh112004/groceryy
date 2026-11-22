"""
Database connection module using Motor (asynchronous MongoDB driver).

Provides connection lifecycle handlers and helper functions to access
the active database client and database instance.
"""

from typing import Optional
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from app.config import settings


class MongoDBManager:
    """Manages the lifecycle of the AsyncIOMotorClient connection."""

    def __init__(self) -> None:
        self.client: Optional[AsyncIOMotorClient] = None
        self.db: Optional[AsyncIOMotorDatabase] = None

    def connect(self) -> None:
        """Initialize the Motor client and connect to the configured database."""
        # Motor connects lazily, so creating the client is non-blocking.
        self.client = AsyncIOMotorClient(
            settings.MONGODB_URI,
            serverSelectionTimeoutMS=5000  # 5-second timeout for server discovery
        )
        self.db = self.client[settings.MONGODB_DB_NAME]

    def close(self) -> None:
        """Close the Motor client connection pool."""
        if self.client is not None:
            self.client.close()
            self.client = None
            self.db = None

    async def ping(self) -> bool:
        """
        Verify database reachability with a ping command.
        Returns True if successful, False otherwise.
        """
        if self.client is None:
            return False
        try:
            # Issue a lightweight ping command to admin database
            await self.client.admin.command("ping")
            return True
        except Exception:
            return False


# Singleton database manager instance
db_manager = MongoDBManager()


def get_database() -> AsyncIOMotorDatabase:
    """Dependency helper to get the active database instance."""
    if db_manager.db is None:
        raise RuntimeError("Database connection has not been initialized.")
    return db_manager.db


async def init_db_indexes() -> None:
    """
    Ensure required unique and query indexes exist in MongoDB collections on startup.
    This operation is idempotent (MongoDB avoids recreating existing matching indexes).
    """
    if db_manager.db is None:
        return
    # Enforce unique constraint on user identifier (email/phone)
    await db_manager.db.users.create_index("identifier", unique=True)
    # Enforce unique constraint on household invite codes
    await db_manager.db.households.create_index("invite_code", unique=True)
    # Compound index on items for fast household status and expiry sorting
    await db_manager.db.items.create_index(
        [("household_id", 1), ("status", 1), ("expiry_date", 1)]
    )

