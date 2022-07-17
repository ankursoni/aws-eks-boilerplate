""" Module for redis query. """

import redis
from structlog import get_logger

DEFAULT_REDIS_HOST = "localhost"

REDIS_CLIENT = None


def configure_redis_client(redis_host=None) -> None:
    """Configure redis client."""
    logger = get_logger()

    logger.info("Starting configure redis client")
    host = redis_host if redis_host and redis_host.strip() != "" else DEFAULT_REDIS_HOST
    global REDIS_CLIENT
    REDIS_CLIENT = redis.Redis(host=host)
    logger.debug(f"Configured redis client with {host}")
    logger.info("Completed configure redis client")


def read_redis_key() -> str:
    """Read redis key."""
    logger = get_logger()

    logger.debug("Starting read redis key")
    result = REDIS_CLIENT.get("demo")
    result = result.decode("utf-8") if result else ""
    logger.debug("Completed read redis key")

    return result
