FROM registry.gitlab.com/ekylibre/docker-base-images/ruby2.6:2

# HARICA Root CA 2021 — base image's ca-certificates 20210119 misses it,
# breaking TLS to alim*.api.agriculture.gouv.fr (PFI API).
COPY docker/certs/HARICA-TLS-Root-2021-RSA.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock package.json yarn.lock /app/
RUN bundle config --local build.sassc --disable-march-tune-native && \
    bundle install -j $(nproc) --path vendor/ruby && \
    yarn

COPY . /app
