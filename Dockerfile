FROM ruby:2.3

ARG BUNDLE_WITHOUT
ARG RAILS_ENV

ENV BUNDLE_WITHOUT ${BUNDLE_WITHOUT}
ENV RAILS_ENV ${RAILS_ENV}
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

RUN apt-get -y update && apt-get -y upgrade && \
    apt-get install -y git curl gnupg netcat build-essential libreadline-dev libssl1.0-dev zlib1g-dev \
        graphicsmagick \
        postgresql-client \
        libproj-dev libgeos-dev libgeos++-dev `#rgeo` \
        libqtwebkit-dev `#capybara` \
        openjdk-8-jdk  `#rjb` \
        libicu-dev `#charlock_holmes` \
        libpq-dev `#pq` \
        libreoffice \
        pdftotext \
        poppler-utils

RUN apt-get install -y apt-transport-https

RUN curl -sL https://deb.nodesource.com/setup_11.x  | bash - \
    && apt-get -y install nodejs

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get -y update \
    && apt-get install -y yarn=1.9.4-1

RUN mkdir /app
WORKDIR /app

COPY docker/startup.sh /opt/startup.sh

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

RUN bundle install

COPY . /app
