""" Module for command line interface (cli). """

import json
import os

from structlog import get_logger

from . import config, db, lib, redis_client, s3


def read_rds() -> str:
    """Read from rds database."""
    logger = get_logger()

    logger.info("Starting read rds")
    rows = db.read_demo_table()
    result = json.dumps([dict(row) for row in rows])
    logger.info("Completed read rds")

    return result


def read_s3() -> str:
    """Read from s3."""
    logger = get_logger()

    logger.info("Starting read s3")
    result = s3.read_s3_file()
    logger.info("Completed read s3")

    return result


def read_redis() -> str:
    """Read from redis database."""
    logger = get_logger()

    logger.info("Starting read readis")
    result = redis_client.read_redis_key()
    logger.info("Completed read redis")

    return result


def init() -> None:
    """Entry point if called as an executable."""
    cli_args = lib.parse_cli_args()
    config.DEBUG_MODE = cli_args.debug_mode
    config.DB_CONNECTION_URL = os.environ.get("DB_CONNECTION_URL")
    config.REDIS_HOST = os.environ.get("REDIS_HOST")
    config.AWS_REGION = os.environ.get("AWS_REGION")
    config.AWS_S3_BUCKET = os.environ.get("AWS_S3_BUCKET")
    config.AWS_ACCESS_KEY_ID = os.environ.get("AWS_ACCESS_KEY_ID")
    config.AWS_SECRET_ACCESS_KEY = os.environ.get("AWS_SECRET_ACCESS_KEY")

    lib.configure_global_logging_level(config.DEBUG_MODE)
    db.configure_db_engine(config.DB_CONNECTION_URL, config.DEBUG_MODE)
    redis_client.configure_redis_client(config.REDIS_HOST)
    s3.configure_s3_bucket_client(
        config.AWS_REGION,
        config.AWS_S3_BUCKET,
        config.AWS_ACCESS_KEY_ID,
        config.AWS_SECRET_ACCESS_KEY,
    )


if __name__ == "__main__":
    init()
    print(read_rds())
    print(read_s3())
    print(read_redis())
