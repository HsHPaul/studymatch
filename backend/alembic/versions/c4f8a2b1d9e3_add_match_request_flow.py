"""add angefragt status and requested_by_id

Revision ID: c4f8a2b1d9e3
Revises: 64eba0ca281d
Create Date: 2026-06-08
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = 'c4f8a2b1d9e3'
down_revision = '64eba0ca281d'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("ALTER TYPE match_status_enum ADD VALUE IF NOT EXISTS 'angefragt'")
    op.add_column('matches', sa.Column(
        'requested_by_id', postgresql.UUID(as_uuid=True), nullable=True
    ))


def downgrade() -> None:
    op.drop_column('matches', 'requested_by_id')
    # PostgreSQL unterstützt kein Entfernen von Enum-Werten
