"""add_restaurant_tables

Revision ID: 957ad4b4f43a
Revises: 001
Create Date: 2026-02-07 14:38:10.022758

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '957ad4b4f43a'
down_revision = '001'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create restaurants table
    op.create_table(
        'restaurants',
        sa.Column('id', sa.dialects.postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('google_place_id', sa.String(255), nullable=False, unique=True),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('address', sa.String(500), nullable=True),
        sa.Column('city', sa.String(100), nullable=True),
        sa.Column('state', sa.String(50), nullable=True),
        sa.Column('country', sa.String(50), nullable=True, server_default='US'),
        sa.Column('latitude', sa.String(50), nullable=True),
        sa.Column('longitude', sa.String(50), nullable=True),
        sa.Column('cuisine_type', sa.String(100), nullable=True),
        sa.Column('price_level', sa.String(10), nullable=True),
        sa.Column('phone', sa.String(50), nullable=True),
        sa.Column('website', sa.String(500), nullable=True),
        sa.Column('menu_last_scanned', sa.DateTime(timezone=True), nullable=True),
        sa.Column('total_scans', sa.String(10), nullable=True, server_default='0'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    # Create indexes
    op.create_index('ix_restaurants_google_place_id', 'restaurants', ['google_place_id'])
    op.create_index('ix_restaurants_name', 'restaurants', ['name'])
    op.create_index('ix_restaurants_city', 'restaurants', ['city'])
    op.create_index('ix_restaurants_state', 'restaurants', ['state'])

    # Create restaurant_menu_items table
    op.create_table(
        'restaurant_menu_items',
        sa.Column('id', sa.dialects.postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('restaurant_id', sa.dialects.postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(500), nullable=False),
        sa.Column('description', sa.Text, nullable=True),
        sa.Column('price', sa.String(50), nullable=True),
        sa.Column('category', sa.String(100), nullable=True),
        sa.Column('first_seen', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('last_seen', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('times_seen', sa.String(10), nullable=True, server_default='1'),
        sa.Column('is_active', sa.Boolean, nullable=False, server_default='true'),
        sa.ForeignKeyConstraint(['restaurant_id'], ['restaurants.id'], ondelete='CASCADE'),
    )

    # Create indexes
    op.create_index('ix_restaurant_menu_items_restaurant_id', 'restaurant_menu_items', ['restaurant_id'])


def downgrade() -> None:
    # Drop tables in reverse order
    op.drop_index('ix_restaurant_menu_items_restaurant_id', table_name='restaurant_menu_items')
    op.drop_table('restaurant_menu_items')

    op.drop_index('ix_restaurants_state', table_name='restaurants')
    op.drop_index('ix_restaurants_city', table_name='restaurants')
    op.drop_index('ix_restaurants_name', table_name='restaurants')
    op.drop_index('ix_restaurants_google_place_id', table_name='restaurants')
    op.drop_table('restaurants')
