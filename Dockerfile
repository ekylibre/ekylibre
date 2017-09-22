#FROM debian:9
FROM ruby:2.2.3

ENV JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64

WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Procfile /app/Procfile

RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" >> /etc/apt/sources.list'
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN apt-get update && apt-get -y upgrade

RUN apt-get update -qq && apt-get install -yf \
    locales \
>---libqt4-dev libqtwebkit-dev \
>---libcurl4-openssl-dev \
>---openjdk-7-jdk \
>---libgeos-dev \
>---libgeos++-dev \
>---libproj-dev \
>---libpq-dev \
>---libxml2-dev \
>---libxslt1-dev \
>---zlib1g-dev \
>---libicu-dev \
>---imagemagick \
>---graphicsmagick \
    postgresql-client-9.6 \
>---tesseract-ocr \
>---tesseract-ocr-ara \
>---tesseract-ocr-jpn \
>---tesseract-ocr-fra \
>---tesseract-ocr-eng \
>---tesseract-ocr-spa \
>---pdftk \
>---libreoffice \
>---poppler-utils \
>---poppler-data \
>---ghostscript \
>---libicu52 \
>---&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


#RUN /bin/bash -l -c "gem install bundler"
RUN gem install bundler
RUN gem install rubygems-bundler
RUN gem regenerate_binstubs

#RUN /bin/bash -l -c "bundle install"
RUN bundle install

RUN gem update bundler

#RUN /bin/bash -l -c "gem install foreman"
#RUN gem install foreman

ADD ./ /app

CMD ["bin/run-dev.sh"]
#RUN /bin/bash -l -c "foreman s"
