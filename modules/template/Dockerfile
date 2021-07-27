FROM python:3.8-slim-buster

ENV PORT=8080
ENV APP_RUN=app
ENV APP_USER=gunicorn
ENV APP_PATH=/app

COPY requirements.txt /

RUN echo -n \
    && mkdir $APP_PATH /creds \
    && useradd --system --shell /bin/true --home $APP_PATH $APP_USER \
    && chown $APP_USER:$APP_USER /creds \
    && apt-get update \
    && apt-get -y install --no-install-recommends \
        libpq5 \
        build-essential \
        libpq-dev \
    && python -m pip install -r /requirements.txt \
    && rm -f /requirements.txt \
    && apt-get -y remove \
        build-essential \
        libpq-dev \
    && apt-get -y autopurge \
    && rm -rf /var/lib/apt/lists/*

COPY src/ $APP_PATH/

ENV TIMEOUT=900
ENV CONCURRENCY=3
ENV MAIN=main

EXPOSE $PORT
USER $APP_USER
WORKDIR $APP_PATH

CMD gunicorn -b :$PORT -t $TIMEOUT -w $CONCURRENCY $DEBUG_FLAG $MAIN:app
