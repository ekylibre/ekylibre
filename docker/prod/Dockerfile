FROM ghcr.io/ekylibre/docker-base-images/ruby2.6:latest

ARG UID=1000
ARG GID=1000

# Plugins prod : charges via docker/prod/Gemfile.prod (depots publics uniquement).
# Voir docker/prod/Gemfile.prod pour la liste exhaustive.
ENV CUSTOM_PLUGIN_GEMFILE=/app/docker/prod/Gemfile.prod

RUN mkdir /app
WORKDIR /app

COPY . /app

# Supprime Gemfile.local (config plugins dev, peut referencer des paths locaux).
# La config plugins prod vient de docker/prod/Gemfile.prod (via CUSTOM_PLUGIN_GEMFILE).
RUN rm -f /app/Gemfile.local /app/Gemfile.local.lock /app/Gemfile.plugins

RUN mkdir -p /app/vendor/bundle /app/private /app/tmp && \
    addgroup --gid $GID ekylibre && \
    useradd --create-home --home-dir /home/ekylibre -s /bin/bash -g $GID -u $UID ekylibre && \
    chown -R ekylibre:ekylibre /app

USER ekylibre

RUN bundle config set --local without 'development test' && \
    bundle install -j $(nproc) && \
    bundle clean --force

RUN yarn install --frozen-lockfile

RUN SECRET_KEY_BASE=dummy RAILS_ENV=production bundle exec rake assets:precompile

RUN chmod +x docker/prod/startup.sh docker/prod/sidekiq_startup.sh
