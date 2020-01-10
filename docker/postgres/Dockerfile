FROM postgres:9.6

ENV POSTGIS_VERSION 2.3

RUN apt-get update && apt-get install -y --no-install-recommends \
   postgresql-$PG_MAJOR-postgis-$POSTGIS_VERSION \
   postgresql-$PG_MAJOR-postgis-$POSTGIS_VERSION-scripts
