""" Module for demo api. """

import flask

app = flask.Flask(__name__)

@app.route("/")
def welcome():
    """Function on '/' printing welcome message."""
    return "Welcome to demo api!"

@app.route("/rds")
def rds():
    """Function on '/rds' getting data from rds mysql database."""
    pass

@app.route("/s3")
def s3():
    """Function on '/s3' getting file from s3."""
    pass

@app.route("/redis")
def redis():
    """Function on '/redis' getting data from redis."""
    pass
