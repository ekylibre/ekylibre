# Ruby 2.7 est le palier intermédiaire vers 3.3 (lot B.1 du plan v6) : c'est la
# version qui *avertit* sur la séparation des arguments nommés au lieu de lever,
# ce qui permet de trouver les ruptures restantes avant de basculer. Rails 5.2
# y démarre et la suite s'y exécute — vérifié.
#
# Attention : le volume `bundle-volume` contient des extensions natives compilées
# pour l'ABI de Ruby 2.6. Après cette bascule, un `bundle install` complet est
# nécessaire ; le plus simple est de supprimer le volume.
FROM ghcr.io/ekylibre/docker-base-images/ruby2.7:latest

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
 