"""
Main FastAPI application entrypoint.

Sets up application lifecycle (startup/shutdown database hooks),
CORS middleware, and core endpoints including health check.
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.db import db_manager, init_db_indexes
from app.modules.auth.router import router as auth_router
from app.modules.items.router import router as items_router
from app.modules.shopping.router import router as shopping_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for FastAPI.
    Initializes database connection, ensures indexes on startup,
    and closes the connection pool gracefully on shutdown.
    """
    # Connect Motor client on startup
    db_manager.connect()
    # Create required database indexes (idempotent)
    await init_db_indexes()
    yield
    # Close Motor client pool gracefully on shutdown
    db_manager.close()


app = FastAPI(
    title="Household Pantry API",
    version="1.0.0",
    description="Backend API for household food inventory and shopping management.",
    lifespan=lifespan,
)

# Configure Cross-Origin Resource Sharing (CORS)
# If origins is ['*'], allow_credentials cannot be True per the CORS specification.
is_wildcard = settings.CORS_ORIGINS == ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=not is_wildcard,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register API routers with /v1 prefix
app.include_router(auth_router, prefix="/v1")
app.include_router(items_router, prefix="/v1")
app.include_router(shopping_router, prefix="/v1")


@app.get("/v1/health", tags=["Health"])
async def health_check():
    """
    Health check endpoint.
    Verifies service status and MongoDB connectivity.
    """
    db_alive = await db_manager.ping()
    return {
        "status": "ok",
        "database": "connected" if db_alive else "disconnected",
        "environment": settings.ENVIRONMENT,
    }
