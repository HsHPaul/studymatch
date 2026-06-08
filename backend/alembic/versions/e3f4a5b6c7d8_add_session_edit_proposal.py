"""add session edit proposal fields

Revision ID: e3f4a5b6c7d8
Revises: d2e9f1c3b5a7
Create Date: 2026-06-08
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = 'e3f4a5b6c7d8'
down_revision = 'd2e9f1c3b5a7'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('study_sessions', sa.Column('proposed_datum', sa.Date(), nullable=True))
    op.add_column('study_sessions', sa.Column('proposed_uhrzeit', sa.Time(), nullable=True))
    op.add_column('study_sessions', sa.Column('proposed_raum_id', postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column('study_sessions', sa.Column('edit_proposed_by_id', postgresql.UUID(as_uuid=True), nullable=True))


def downgrade() -> None:
    op.drop_column('study_sessions', 'edit_proposed_by_id')
    op.drop_column('study_sessions', 'proposed_raum_id')
    op.drop_column('study_sessions', 'proposed_uhrzeit')
    op.drop_column('study_sessions', 'proposed_datum')
