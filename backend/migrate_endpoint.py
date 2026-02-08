"""
Temporary migration endpoint for Render free tier.
Add this to main.py temporarily to run migrations via HTTP.

IMPORTANT: Remove this after migration is complete for security!
"""

from fastapi import HTTPException
from alembic.config import Config
from alembic import command
import os


def create_migration_endpoint(app):
    """
    Add a temporary endpoint to run migrations.
    Call GET /run-migration?secret=your_secret_key
    """

    MIGRATION_SECRET = os.getenv("MIGRATION_SECRET", "changeme123")

    @app.get("/run-migration")
    async def run_migration(secret: str):
        """
        Run database migrations.

        Usage: GET /run-migration?secret=your_secret_key

        IMPORTANT: This is a temporary endpoint for running migrations
        on Render free tier. Remove after use!
        """
        # Security check
        if secret != MIGRATION_SECRET:
            raise HTTPException(status_code=403, detail="Invalid secret")

        try:
            # Configure Alembic
            alembic_cfg = Config("backend/alembic.ini")
            alembic_cfg.set_main_option("script_location", "backend/migrations")

            # Run upgrade to head
            command.upgrade(alembic_cfg, "head")

            return {
                "status": "success",
                "message": "Database migration completed successfully",
                "note": "Remove this endpoint after use!"
            }

        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Migration failed: {str(e)}"
            )
