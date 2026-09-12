# Ruby 3.4.10. Ruby 2.7 a servi de palier intermédiaire jusqu'à Rails 7.0 :
# c'est la version qui *avertit* sur la séparation des arguments nommés au lieu
# de lever, ce qui a permis de trouver les ruptures avant de basculer.
#
# Le saut se fait avec Rails 7.1 parce que les deux sont couplés :
# `activerecord-postgis-adapter` 9.0, seule série qui accepte ActiveRecord 7.1,
# exige Ruby >= 3.0.
#
# Attention : le volume `bundle-volume` contient des extensions natives
# compilées pour l'ABI de Ruby 2.7. Après cette bascule, un `bundle install`
# complet est nécessaire ; le plus simple est de supprimer le volume.
FROM ghcr.io/ekylibre/docker-base-images/ruby3.4.10:latest

ARG UID=1000
ARG GID=1000

RUN mkdir /app
WORKDIR /app

COPY . /app

RUN mkdir -p /app/vendor/bundle && \
    addgroup --gid $GID ekylibre  && \
    useradd --create-home --home-dir /home/ekylibre -s /bin/bash -g $GID -u $UID ekylibre && \
    chown -R ekylibre:ekylibre /app

RUN chmod +x docker/dev/sidekiq_startup.sh

USER ekylibre
 