"""Add image_data to scan_history

Revision ID: 002_add_image_data
Revises: 957ad4b4f43a
Create Date: 2026-02-10

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '002_add_image_data'
down_revision = '957ad4b4f43a'
branch_labels = None
depends_on = None


def upgrade():
    # Add image_data column to scan_history table
    op.add_column('scan_history', sa.Column('image_data', sa.Text(), nullable=True))


def downgrade():
    # Remove image_data column from scan_history table
    op.drop_column('scan_history', 'image_data')
