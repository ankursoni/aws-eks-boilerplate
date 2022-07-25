"""  Module for library functions. """

import argparse
import json
import logging
from dataclasses import dataclass

import structlog
from structlog import get_logger


@dataclass(init=True)
class CLIArgs:
    """Class for command line interface (cli) arguments."""

    debug_mode: bool = None


def parse_cli_args() -> CLIArgs:
    """Parse cli arguments"""
    logger = get_logger()

    logger.info("Starting parse cli arguments")
    parser = argparse.ArgumentParser(description="CLI arguments")
    parser.add_argument("--debug-mode", help="Enable debug mode logging")
    args = parser.parse_args()
    debug_mode = json.loads(args.debug_mode) if args.debug_mode else False
    result = CLIArgs(debug_mode=debug_mode)
    logger.info("Completed parse cli arguments")

    return result


def configure_global_logging_level(debug_mode) -> None:
    """Configure global logging level."""

    logger = get_logger()

    logger.info("Starting configure global logging level")
    structlog.configure_once(
        wrapper_class=structlog.make_filtering_bound_logger(
            logging.DEBUG if debug_mode else logging.INFO
        )
    )
    if debug_mode:
        logger.debug("Global logging level is set as DEBUG")
    else:
        logger.info("Global logging level is set as INFO")
    logger.info("Completed configure global logging level")
