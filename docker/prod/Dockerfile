ARG RUBY_VERSION=2.3

FROM registry.gitlab.com/ekylibre/docker-base-images/ruby${RUBY_VERSION}:master AS builder

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock /app/
RUN BUNDLE_WITHOUT=test:development bundle install -j $(nproc) --deployment

COPY . /app

RUN cp /app/docker/prod/build_config/application.yml /app/docker/prod/build_config/database.yml /app/config && \
    RAILS_ENV=production bundle exec rake assets:precompile


FROM registry.gitlab.com/ekylibre/docker-base-images/ruby${RUBY_VERSION}-prod:master AS rails

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get -y install --no-install-recommends postgresql-client-11 python3-pip && \
    pip3 install minio
RUN mkdir /app && \
    gem install procodile && \
    echo 'BUNDLE_PATH: "/app/vendor/bundle"' >> $BUNDLE_APP_CONFIG/config && \
    echo 'BUNDLE_WITHOUT: "development:test"' >> $BUNDLE_APP_CONFIG/config && \
    useradd --create-home --home-dir /home/ekylibre -s /bin/bash -u 1000 ekylibre && \
    chown -R ekylibre:ekylibre /app

WORKDIR /app
USER ekylibre

COPY --from=builder --chown=ekylibre /app /app/
COPY docker/prod/config/database.yml config/database.yml

CMD ["/app/docker/waitpg", "/app/docker/prod/serve"]
HEALTHCHECK CMD ["procodile", "status", "--simple"]
