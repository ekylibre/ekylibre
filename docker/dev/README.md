# How to use Ekylibre docker-compose

run `docker-compose up` # This should take a long time at first.

## Additional configuration for Docker
In order to have programs executed in a docker container write files that belong to you, some more configuration may be needed.

If your user id and main group id are 1000, nothing to do, the defaults will work.

To know that, use the `id` command.

If the ids are not 1000, you need to edit the Dockerfile file accordingly.