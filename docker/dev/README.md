Before to up your app docker, you need to add lexicon to your db. You should :
1. `docker-compose run app bash`, to acceed a bash from inside your container not up.
2. `cd /lexicon-cli` (if not working, check if the volume is well connected.)
3. `bin/lexicon remote download VERSION` (if not working, check if you've a `.env` with the required environment variables.
4. `bin/lexicon production load VERSION`
5. `bin/lexicon production enable VERSION`
5. `docker-compose down && docker-compose up -d`

Hint :
	- `docker/dev/dl_tenant.sh` dl tenant from specified server, and apply tenant restore.
	- When your applications is not working cause of the eager_loading, just use restart your docker :
	`docker-compose down && docker-compose up -d`

	- You can execute command inside the launched docker with :
		`docker exec -it eky_app_1 bin/rails c`
		where `eky_app_1` is the name of your docker.
		`bin/rails c` is the command.
	- Run test with
		`docker exec -it -e RAILS_ENV=test eky_app_1 bin/rails test test/models/[...]`
	- And don't forget to RTFMs to go further : 
		`man docker-compose`
		`man docker`
		`man docker exec`
		`man docker attach`
		`man docker logs`
		`man docker ps`
		`[...]`
