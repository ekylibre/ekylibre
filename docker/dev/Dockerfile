FROM registry.gitlab.com/ekylibre/docker-base-images/ruby2.6:2

ARG UID=1000
ARG GID=1000

RUN mkdir /app
WORKDIR /app

COPY . /app

RUN addgroup --gid $GID ekylibre  && \
    useradd --create-home --home-dir /home/ekylibre -s /bin/bash -g $GID -u $UID ekylibre && \
    chown -R ekylibre:ekylibre /app

RUN chmod +x docker/dev/sidekiq_startup.sh

USER ekylibre
 