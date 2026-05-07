FROM registry.gitlab.com/ekylibre/docker-base-images/ruby2.6:2

# HARICA Root CA 2021 — base image's ca-certificates 20210119 misses it,
# breaking TLS to alim*.api.agriculture.gouv.fr (PFI API).
COPY docker/certs/HARICA-TLS-Root-2021-RSA.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates

ARG UID=1000
ARG GID=1000

RUN mkdir /app
WORKDIR /app

COPY . /app

RUN mkdir -p /app/vendor/bundle && \
    addgroup --gid $GID ekylibre  && \
    useradd --create-home --home-dir /home/ekylibre -s /bin/bash -g $GID -u $UID ekylibre && \
    chown -R ekylibre:ekylibre /app

RUN chmod +x docker/dev/sidekiq_startup.sh

USER ekylibre
 