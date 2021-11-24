# How to use Ekylibre docker-compose

run `docker-compose up` # This should take a long time at first.
run `sudo sh -c "echo '127.0.0.1  default.ekylibre.lan' >>  /etc/hosts"` # Will create an alias for localhost
This will build Ekylibre, it's lexicon and create a default tenant `default`
Once your containers are up, you can log in to http://default.ekylibre.lan:3000
