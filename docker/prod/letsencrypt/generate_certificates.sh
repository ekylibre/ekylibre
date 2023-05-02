#!/usr/bin/env sh

certbot certonly \
  --manual \
  --agree-tos \
  --config-dir /etc/letsencrypt \
  --email !ChangeMe! \
  --preferred-challenges=dns \
  -d !ChangeMe! \ # Your domain 
  -d *.!ChangeMe! \  # Your domain 
  --server https://acme-v02.api.letsencrypt.org/directory