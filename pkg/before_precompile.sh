#!/bin/bash

echo ""
echo "--------------------------------------------------------------------------------"
echo "Configure PPA:"
sudo apt-get install python-software-properties
echo "yes" | sudo apt-add-repository ppa:sharpie/for-science
echo "yes" | sudo apt-add-repository ppa:sharpie/postgis-stable
echo "yes" | sudo apt-add-repository ppa:ubuntugis/ubuntugis-unstable
sudo apt-get update

echo ""
echo "--------------------------------------------------------------------------------"
echo "List postgis related packages:"
sudo apt-cache search postgis

echo ""
echo "--------------------------------------------------------------------------------"
echo "Install packages:"
sudo apt-get install -qq openjdk-7-jdk postgresql-9.3 postgresql-server-dev-9.3  postgresql-9.3-postgis-2.1 graphicsmagick tesseract-ocr tesseract-ocr-fra tesseract-ocr-eng tesseract-ocr-spa pdftk libreoffice poppler-utils poppler-data ghostscript
echo "Start Postgresql"
sudo service postgresql start