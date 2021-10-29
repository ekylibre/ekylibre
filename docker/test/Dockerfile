FROM registry.gitlab.com/ekylibre/docker-base-images/ruby2.6:2

# TODO: Move to docker-base-images
RUN wget https://services.renater.fr/_media/tcs/geant_ov_rsa_ca_4_usertrust_rsa_certification_authority.pem -O /usr/local/share/ca-certificates/geant_ov_rsa_ca_4_usertrust_rsa_certification_authority.crt \
    && wget https://services.renater.fr/_media/tcs/geant_ov_rsa_ca_4.pem -O /usr/local/share/ca-certificates/geant_ov_rsa_ca_4.crt \
    && update-ca-certificates

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock package.json yarn.lock /app/
RUN bundle config --local build.sassc --disable-march-tune-native && \
    bundle install -j $(nproc) --path vendor/ruby && \
    yarn

COPY . /app
