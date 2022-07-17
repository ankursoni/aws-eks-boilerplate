""" Module for demo web api. """

import flask

from . import config
from . import main as core

app = flask.Flask(__name__)


@app.route("/")
def welcome() -> str:
    """Function on '/' printing welcome message."""
    return "Welcome to demo api!"


@app.route("/rds")
def get_rds() -> str:
    """Function on '/rds' getting data from rds mysql database."""
    return core.read_rds()


@app.route("/s3")
def get_s3() -> str:
    """Function on '/s3' getting file from s3."""
    return core.read_s3()


@app.route("/redis")
def get_redis() -> str:
    """Function on '/redis' getting data from redis."""
    return core.read_redis()


def main():
    """Entry point if called as an executable."""
    core.init()
    app.run(host="0.0.0.0", port=8080, debug=config.DEBUG_MODE)


if __name__ == "__main__":
    main()
