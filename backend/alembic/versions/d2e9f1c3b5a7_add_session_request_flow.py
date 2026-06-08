"""add session angefragt status and created_by_id

Revision ID: d2e9f1c3b5a7
Revises: c4f8a2b1d9e3
Create Date: 2026-06-08
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = 'd2e9f1c3b5a7'
down_revision = 'c4f8a2b1d9e3'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("ALTER TYPE session_status_enum ADD VALUE IF NOT EXISTS 'angefragt'")
    op.add_column('study_sessions', sa.Column(
        'created_by_id', postgresql.UUID(as_uuid=True), nullable=True
    ))


def downgrade() -> None:
    op.drop_column('study_sessions', 'created_by_id')
