""" Module for database query. """

from dataclasses import dataclass

from sqlalchemy import Column, Integer, String, create_engine, select
from sqlalchemy.engine.row import Row
from sqlalchemy.orm import declarative_base
from structlog import get_logger

DEFAULT_DB_CONNECTION_URL = "mysql+mysqldb://user1:password1@localhost/demodb"

DB_ENGINE = None


def configure_db_engine(db_connection_url=None, debug_mode=False) -> None:
    """Configure db engine."""
    logger = get_logger()

    logger.info("Starting configure db engine")
    url = (
        db_connection_url
        if db_connection_url and db_connection_url.strip() != ""
        else DEFAULT_DB_CONNECTION_URL
    )
    global DB_ENGINE
    DB_ENGINE = create_engine(
        url,
        echo=debug_mode,
        future=True,
    )
    logger.debug(f"Configured db engine with {url}")
    logger.info("Completed configure db engine")


Base = declarative_base()


@dataclass
class Demo(Base):
    """Class for demo table."""

    __tablename__ = "demo"
    id = Column(Integer, primary_key=True)
    description = Column(String)

    def __repr__(self):
        return f"Demo(id={self.id!r}, description={self.description!r})"


def read_demo_table() -> list[Row]:
    """Read demo table."""
    logger = get_logger()

    logger.debug("Starting read demo table")
    statement = select(Demo)
    rows = []
    with DB_ENGINE.connect() as connection:
        for row in connection.execute(statement):
            rows.append(row)
    logger.debug("Completed read demo table")

    return rows
