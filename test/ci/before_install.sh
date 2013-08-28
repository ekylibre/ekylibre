sudo apt-get install python-software-properties
echo "yes" | sudo apt-add-repository ppa:sharpie/for-science
echo "yes" | sudo apt-add-repository ppa:sharpie/postgis-stable
echo "yes" | sudo apt-add-repository ppa:ubuntugis/ubuntugis-unstable
sudo apt-get update
# sudo apt-get install postgresql-9.1-postgis2 
# sudo apt-get install python-software-properties
# echo "yes" | sudo apt-add-repository ppa:ubuntugis/ubuntugis-unstable
# sudo apt-get update
sudo apt-get install -qq libgeos-dev libgeos++-dev libproj-dev postgresql-9.1-postgis2 libmagic-dev
