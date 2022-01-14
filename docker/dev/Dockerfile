ARG RUBY_VERSION=2.6

FROM ruby:${RUBY_VERSION}

ARG UID=1000
ARG GID=1000

ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash
RUN apt-get -y update && apt-get -y upgrade && \
    mkdir -p /usr/lib/jvm/java-11-openjdk-amd64/jre/lib/amd64 && \
    ln -s /usr/lib/jvm/java-11-openjdk-amd64/lib/server /usr/lib/jvm/java-11-openjdk-amd64/jre/lib/amd64/server && \
    apt-get -y install netcat build-essential libreadline-dev libssl-dev zlib1g-dev \
		nodejs \
        graphicsmagick \
        postgresql-client \
        libproj-dev libgeos-dev libgeos++-dev `#rgeo` \
        openjdk-11-jdk  `#rjb` \
        libicu-dev `#charlock_holmes` \
        libpq-dev `#pq` \
        libreoffice \
        libsodium-dev \
        poppler-utils tesseract-ocr tesseract-ocr-fra tesseract-ocr-ara tesseract-ocr-eng  `#ocr` \
        tesseract-ocr-jpn tesseract-ocr-osd tesseract-ocr-spa  `#ocr` && \
	npm install -g yarn && \
	gem install bundler

RUN mkdir /eky
WORKDIR /eky

COPY . /eky
COPY ./docker/dev/database.yml.sample /eky/config/database.yml

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get -y install --no-install-recommends postgresql-client-11 python3-pip git

RUN addgroup --gid $GID ekylibre  && \
    useradd --create-home --home-dir /home/ekylibre -s /bin/bash -g $GID -u $UID ekylibre && \
    chown -R ekylibre:ekylibre /eky

RUN git clone https://gitlab.com/ekylibre/lexicon/lexicon-cli.git /lexicon-client
WORKDIR /lexicon-client

RUN mv /eky/docker/dev/lexicon-tmp.env ./.env && mkdir ./out && chown -R ekylibre:ekylibre . 

WORKDIR /eky
USER ekylibre
