script_path=`readlink -f $0`
script_dir=`dirname $script_path`

cp -f $script_dir/database.$DB.yml $script_dir/../../config/database.yml

if [[ "$DB" == "postgis" ]]; then
    psql -U postgres -c "CREATE DATABASE ekylibre_test;"
    psql -U postgres -d ekylibre_test -c "CREATE SCHEMA postgis;"
    if [[ "$POSTGIS" = "2.0" ]]; then
	psql -U postgres -d ekylibre_test -c "CREATE EXTENSION postgis;"
    else
	createlang -U postgres plpgsql ekylibre_test
	psql -U postgres -d ekylibre_test -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
	psql -U postgres -d ekylibre_test -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql
    fi
elif [ "$DB" == "mysql" ]; then
    mysql -e "CREATE DATABASE ekylibre_test;"
fi
