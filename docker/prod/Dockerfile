FROM registry.gitlab.com/ekylibre/docker-base-images/ruby2.6:2

COPY . /app

RUN useradd --create-home --home-dir /home/ekylibre -s /bin/bash ekylibre && \
    usermod -aG sudo ekylibre && \
    chown -R ekylibre:ekylibre /app

USER ekylibre

WORKDIR /app

RUN mkdir -p private
RUN mkdir -p tmp

COPY /docker/staging/unicorn.rb config/unicorn.rb
COPY --chown=ekylibre /docker/staging/tenants.yml config/tenants.yml

RUN bundle install -j $(nproc) --path "/app/vendor/bundle" --without development test
RUN SECRET_KEY_BASE=1 RAILS_ENV=production bundle exec rake assets:precompile