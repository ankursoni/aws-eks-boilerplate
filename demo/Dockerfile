FROM python:3.9.13-slim-buster

RUN apt-get update && apt-get upgrade && \
    apt-get install -y python3-dev default-libmysqlclient-dev build-essential

WORKDIR /app
COPY . ./demo

RUN pip install --upgrade pip
RUN pip install -r ./demo/requirements.txt

ENV FLASK_ENV = development

ARG DB_CONNECTION_URL="mysql+mysqldb://user1:password1@host.docker.internal/demodb"
ENV DB_CONNECTION_URL=${DB_CONNECTION_URL}

ARG REDIS_HOST="host.docker.internal"
ENV REDIS_HOST=${REDIS_HOST}

ARG AWS_REGION=""
ENV AWS_REGION=${AWS_REGION}

ARG AWS_S3_BUCKET=""
ENV AWS_S3_BUCKET=${AWS_S3_BUCKET}

ARG AWS_ACCESS_KEY_ID=""
ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}

ARG AWS_SECRET_ACCESS_KEY=""
ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

ENTRYPOINT [ "./demo/entrypoint.sh" ]
CMD ["migrateThenApi", "--debug-mode", "false"]
