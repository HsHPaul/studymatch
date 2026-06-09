"""add_last_login_at_to_users

Revision ID: 28b0898b4d6e
Revises: f5a6b7c8d9e0
Create Date: 2026-06-09 11:34:50.582931

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = '28b0898b4d6e'
down_revision: Union[str, None] = 'f5a6b7c8d9e0'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('users', sa.Column('last_login_at', sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    op.drop_column('users', 'last_login_at')
