"""
Configuration module.

Loads environment variables from a local `.env` file using `python-dotenv`
and validates key application settings with Pydantic.
"""

import os
from pathlib import Path
from typing import List
from dotenv import load_dotenv

# Locate the .env file in the backend root directory (one level above app/)
BASE_DIR = Path(__file__).resolve().parent.parent
ENV_PATH = BASE_DIR / ".env"

# Load variables into environment if .env file exists
load_dotenv(dotenv_path=ENV_PATH)


class Settings:
    """Application settings and environment configuration."""

    def __init__(self) -> None:
        self.ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
        self.HOST: str = os.getenv("HOST", "0.0.0.0")
        self.PORT: int = int(os.getenv("PORT", "8000"))

        # Database configuration
        self.MONGODB_URI: str = os.getenv(
            "MONGODB_URI",
            "mongodb://localhost:27017"
        )
        self.MONGODB_DB_NAME: str = os.getenv("MONGODB_DB_NAME", "pantry_db")

        # Parse comma-separated CORS origins into a list of strings
        raw_origins = os.getenv("CORS_ORIGINS", "*")
        if raw_origins.strip() == "*":
            self.CORS_ORIGINS: List[str] = ["*"]
        else:
            self.CORS_ORIGINS = [
                origin.strip()
                for origin in raw_origins.split(",")
                if origin.strip()
            ]

        # JWT configuration
        jwt_secret_raw = os.getenv("JWT_SECRET")
        if not jwt_secret_raw or not jwt_secret_raw.strip():
            raise RuntimeError(
                "CRITICAL CONFIG ERROR: 'JWT_SECRET' environment variable is missing or empty. "
                "Please configure JWT_SECRET in your .env file before starting the application."
            )
        self.JWT_SECRET: str = jwt_secret_raw.strip()
        self.JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
        self.JWT_EXPIRE_DAYS: int = int(os.getenv("JWT_EXPIRE_DAYS", "30"))


# Instantiate a singleton settings object for import across modules
settings = Settings()
