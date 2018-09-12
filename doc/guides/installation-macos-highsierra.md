# Installation for developers

This a short explanation on installation steps for developers.

## 1. Dependencies

*   Before all, install all database. See http://www.postgresql.org/download/
    to install PostgreSQL on your system. PostgreSQL 9.5 is required at least
    with PostGIS 2.2 and PostgreSQL contrib for its `uuid-ossp` extension.

*   Install Qt4
    https://github.com/cartr/homebrew-qt4

*   Then, install all dependencies. Command and package can differ between
    distributions or OS:
        brew install zlib qt icu4c postgresql postgis yarn
        gem install charlock_holmes -- --with-icu-dir=/usr/local/opt/icu4c
        brew install imagemagick graphicsmagick tesseract-ocr tesseract-ocr-ara tesseract-ocr-jpn tesseract-ocr-fra tesseract-ocr-eng tesseract-ocr-spa pdftk libreoffice poppler-utils poppler-data ghostscript openjdk-7-jdk libicu52 redis-server postgresql-9.5-postgis-2.2 postgresql-contrib-9.5 libcurl4-openssl-dev libgeos-dev libgeos++-dev libproj-dev libpq-dev libxml2-dev libxslt1-dev zlib1g-dev libicu-dev libqtwebkit-dev


## 2. Ruby

*   Install Ruby. If your distribution isn't up-to-date, see
    [RbEnv](https://github.com/sstephenson/rbenv) to install the good version.


## 3. Get sources

*   Clone sources from repository

        git clone https://github.com/ekylibre/ekylibre.git /path/to/ekylibre

## 4. Configure Database

*   Configure a DB superuser as default user in your `config/database.yml`. In
    production mode, you'll need to use a normal user without SUPERUSER not
    CREATEDB right.

*   Create your `database.yml` in `config/`

        default: &default
          adapter: postgis
          encoding: unicode
          pool: 5
          postgis_extension: []
          schema_search_path: public,postgis
          username: ekylibre
          password: ekylibre
          host: 127.0.0.1

        development:
          <<: *default
          database: ekylibre_development


## 5. Configure ruby dependencies

*   Install bundler with rubygems:

        gem install bundler

*   Move to Ekylibre directory root and install gems with bundler:

        cd /path/to/ekylibre
        JAVA_HOME=/System/Library/Frameworks/JavaVM.framework NOKOGIRI_USE_SYSTEM_LIBRARIES=1 bundle install

    Or you can add the following lines in your +~/.bash_profile+ in your home
    directory and run +bundle install+ after:

        export JAVA_HOME=//System/Library/Frameworks/JavaVM.framework
        export NOKOGIRI_USE_SYSTEM_LIBRARIES=1


## 6. Initialize database

*   Create and migrate database:

        rake db:create db:migrate


See [rails guide](http://guides.rubyonrails.org/active_record_migrations.html#running-migrations) for more informations on migrations.

## 7. Create an empty farm

*  Execute command:

        rake tenant:init TENANT=my-little-farm

*   Add in `/etc/hosts` a line to configure an artificial subdomain
    corresponding to your instance:

        echo '127.0.0.1 my-little-farm.ekylibre.lan' | sudo tee --append /etc/hosts


Optionally, it's possible to load anonymized data of a real (french
polycultural-cattling) farm. Install data from
https://github.com/ekylibre/first_run-demo in
`/path/to/ekylibre/db/first_runs/demo`, and run:

    rake first_run TENANT=demo

Don't forget to update your `/etc/hosts` file.

## 8. Try it

*   Launch server:

        foreman start

*   Open your web browser and go to http://my-farm.ekylibre.lan:8080
