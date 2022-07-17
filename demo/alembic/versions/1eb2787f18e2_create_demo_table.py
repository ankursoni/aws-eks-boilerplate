"""create demo table

Revision ID: 1eb2787f18e2
Revises: 
Create Date: 2022-07-15 16:59:52.060470

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "1eb2787f18e2"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    demo_table = op.create_table(
        "demo",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("description", sa.String(200)),
    )
    op.bulk_insert(
        demo_table,
        [
            {
                "id": 1,
                "description": "demo1",
            },
            {
                "id": 2,
                "description": "demo2",
            },
        ],
    )


def downgrade() -> None:
    op.drop_table("demo")
