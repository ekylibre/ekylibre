FROM ruby:2.2.3

ARG DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
ENV BUNDLE_JOBS=4
ENV NODE_VERSION="0.12.7"
ENV BUNDLER_VERSION="1.13.7"

RUN useradd -d /home/app -m app
RUN mkdir -p /usr/src/app
RUN chown -R app /usr/src/app /usr/local/bundle
RUN gem install bundler --version "${BUNDLER_VERSION}"
WORKDIR /usr/src/app

# install node for asset precompilation
RUN curl https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz | tar xzf - -C /usr/local --strip-components=1

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" >> /etc/apt/sources.list && \
	wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN apt-get update -qq && apt-get install -yf \
	locales \
	libqt4-dev libqtwebkit-dev \
	libcurl4-openssl-dev \
	openjdk-7-jdk \
	libgeos-dev \
	libgeos++-dev \
	libproj-dev \
	libpq-dev \
	libxml2-dev \
	libxslt1-dev \
	zlib1g-dev \
	libicu-dev \
	imagemagick \
	graphicsmagick \
	postgresql-9.5-postgis-2.2 \
	postgresql-contrib \
	tesseract-ocr \
	tesseract-ocr-ara \
	tesseract-ocr-jpn \
	tesseract-ocr-fra \
	tesseract-ocr-eng \
	tesseract-ocr-spa \
	pdftk \
	libreoffice \
	apt-utils \
	poppler-utils \
	poppler-data \
	ghostscript \
	libicu52 \
	&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale && echo "LANG=en_US.UTF-8" >> /etc/default/locale && locale-gen en_US en_US.UTF-8 && \
	dpkg-reconfigure locales

ENV GITHUB_OAUTH_TOKEN 12526f5306239359dfba56b197eccede79cd1b10
RUN echo "[url \"https://${GITHUB_OAUTH_TOKEN}@github.com/\"]\n  insteadOf = git@github.com:" > /etc/gitconfig

# Copy Gemfile first, and run bundle install so that the result gets cached in
# further runs if the Gemfile doesn't change.
COPY Gemfile ./Gemfile
# COPY Gemfile.* ./
COPY vendor ./vendor
RUN chown -R app:app /usr/src/app

USER app
RUN bundle install --retry 3

USER root
ADD . /usr/src/app
RUN chown -R app:app /usr/src/app

USER app
RUN CRON=0 DEVISE_SECRET_KEY=12345678 DATABASE_URL=postgres://foo:bar@127.0.0.1/foobar SECRET_TOKEN=foobar RAILS_ENV=production bundle exec rake assets:precompile

# RUN DATABASE_URL=sqlite3:///tmp/fake.db bundle exec rake reporting:compile

CMD ["./docker/web"]
