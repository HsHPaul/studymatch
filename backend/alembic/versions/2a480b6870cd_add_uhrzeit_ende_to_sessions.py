"""add_uhrzeit_ende_to_sessions

Revision ID: 2a480b6870cd
Revises: 28b0898b4d6e
Create Date: 2026-06-09 13:42:33.108863

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = '2a480b6870cd'
down_revision: Union[str, None] = '28b0898b4d6e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('study_sessions', sa.Column('uhrzeit_ende', sa.Time(), nullable=True))
    op.add_column('study_sessions', sa.Column('proposed_uhrzeit_ende', sa.Time(), nullable=True))


def downgrade() -> None:
    op.drop_column('study_sessions', 'proposed_uhrzeit_ende')
    op.drop_column('study_sessions', 'uhrzeit_ende')
