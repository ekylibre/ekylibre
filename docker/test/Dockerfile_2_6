FROM registry.gitlab.com/ekylibre/docker-base-images/ruby2.6:1

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock package.json yarn.lock /app/
RUN bundle config --local build.sassc --disable-march-tune-native && \
    bundle install -j $(nproc) --path vendor/ruby && \
    yarn

COPY . /app
