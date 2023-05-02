* Clone eky


* From eky directory:


* Create .env


`cp .docker/prod/.env.sample .docker/prod/.env`


* Build

- Set your env variables in .env
- Edit you domain name and email in docker/prod/letsencrypt/generate_certificates.sh
- Edit you domain name in docker/prod/nginx.conf 


`docker compose -f docker/prod/docker-compose.yml build`


* Generate certificates


`docker compose -f docker/prod/docker-compose.yml run certbot`


`/bin/letsencrypt/generate_certificate.sh`


* Start 


`docker compose -f docker/prod/docker-compose.yml up -d`


* Update


`git pull`


`docker compose -f docker/prod/docker-compose.yml up -d --build --force-recreate`


