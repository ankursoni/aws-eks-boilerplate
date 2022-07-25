""" Module for s3 query. """

import boto3
from structlog import get_logger

S3_BUCKET_CLIENT = None


def configure_s3_bucket_client(
    aws_region, aws_s3_bucket, aws_access_key_id, aws_secret_access_key
) -> None:
    """Configure s3 client."""
    logger = get_logger()

    logger.info("Starting configure s3 bucket client")
    s3_client = boto3.resource(
        service_name="s3",
        region_name=aws_region,
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
    )
    global S3_BUCKET_CLIENT
    S3_BUCKET_CLIENT = s3_client.Bucket(aws_s3_bucket)
    logger.debug(
        f"Configured s3 bucket client with region: {aws_region}"
        + f", access key id: {aws_access_key_id} and secret access key: {aws_secret_access_key}"
    )
    logger.info("Completed configure s3 bucket client")


def read_s3_file() -> str:
    """Read s3 file."""
    logger = get_logger()

    logger.debug("Starting read s3 file")
    result = S3_BUCKET_CLIENT.Object("s3_demo.txt").get()
    result = result["Body"].read()
    logger.debug("Completed read s3 file")

    return result
