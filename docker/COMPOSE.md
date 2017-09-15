# How to use docker-compose for local dev

First, export your current UID so that docker-compose doesn't mess up with your
file permissions when creating files from a docker container:

    export UID

Build the necessary docker images (this will take a long time the first time):

    docker-compose build

Then you need to initialize the database:

    docker-compose run web bundle exec rake db:extensions db:migrate

You can now launch the stack:

    docker-compose up

Your local directory is mounted in the docker containers, so that means you can
edit files, and the changes should be picked up.

If you need to re-run `bundle` or any other commands, it is best to open a
shell, and launch the commands from there:

    docker-compose run web bash
    # then
    bundle install
    # or
    bundle exec rails c
    # or
    bundle exec rake TASK

