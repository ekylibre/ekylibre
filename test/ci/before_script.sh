script_path=`readlink -f $0`
script_dir=`dirname $script_path`

cp -f $script_dir/database.yml $script_dir/../../config/database.yml

psql -U postgres -c "CREATE DATABASE ekylibre_test;"
psql -U postgres -d ekylibre_test -c "CREATE SCHEMA postgis;"
psql -U postgres -d ekylibre_test -c "CREATE EXTENSION postgis;"

bundle exec rake db:migrate