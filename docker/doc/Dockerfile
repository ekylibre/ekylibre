ARG TEST_IMAGE
FROM ${TEST_IMAGE} AS files
RUN gem install yard
RUN yardoc

FROM caddy:latest
COPY docker/doc/Caddyfile /etc/caddy/Caddyfile
COPY doc/yard/ /app/
WORKDIR /app
