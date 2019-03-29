# Installation for developers on Debian 9 (Stretch)

This a short explanation on installation steps for developers.

Architecture is assumed to be `amd64`. Replace it where it's necessary.

We assume that you are a valid sudoer. To get ready, add your account in
`sudo` group.
``` bash
su
apt-get install sudo # if you don't know if sudo is installed
adduser bob sudo
```
Logout and login and you can sudo.

## 1. Dependencies

Then, install all distribution dependencies:

    sudo apt-get install imagemagick graphicsmagick tesseract-ocr tesseract-ocr-ara tesseract-ocr-jpn tesseract-ocr-fra tesseract-ocr-eng tesseract-ocr-spa pdftk libreoffice poppler-utils poppler-data ghostscript openjdk-8-jdk libicu57 redis-server postgresql-9.6-postgis-2.3 postgresql-contrib-9.6 libcurl4-openssl-dev libgeos-dev libgeos++-dev libproj-dev libpq-dev libxml2-dev libxslt1-dev zlib1g-dev libicu-dev libqtwebkit-dev build-essential


## 2. Ruby

Install Ruby 2.2.3. If your distribution isn't up-to-date, you need to install
[rbenv](https://github.com/sstephenson/rbenv) to install the good version
([RVM](https://rvm.io) can be used if you prefer):

*   Before install, marke sure you have compilation dependencies:

        sudo apt-get install git build-essential libreadline-dev

*   [Installation of rbenv](https://github.com/sstephenson/rbenv#installation)

        git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
        echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
        echo 'eval "$(rbenv init -)"' >> ~/.bashrc
        source ~/.bashrc

*   [Installation of
    ruby-build](https://github.com/sstephenson/ruby-build#installation) which
    permit to download and compile ruby compiler for rbenv

        git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build

*   Install ruby 2.2.3:

        rbenv install 2.2.3

*   Set this compiler as the default:

        rbenv global 2.2.3


## 3. Get sources

*   Clone sources from repository

        git clone https://github.com/ekylibre/ekylibre.git /path/to/ekylibre

## 4. Configure Database

*   Go at sources root:

        cd /path/to/ekylibre

*   Create a PostgreSQL superuser for Ekylibre

        sudo su postgres
        createuser -s -P ekylibre

*   Copy `config/database.yml.sample` into `config/database.yml`.

        cp config/database.yml.sample config/database.yml

*   Update your `database.yml` in `config/` with your informations like in
    this example:
    ``` yaml
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
    ```

    If you haven't customized PostgreSQL configuration, you must set `host`
    parameter to 127.0.0.1



## 5. Configure ruby dependencies

Rjb gem use Java OpenJDK, so we need to set JAVA_HOME to install gem.

*   Install bundler:

        gem install bundler

*   Install gems with bundler:

        JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 bundle install

    Or you can add the following lines in your +~/.bashrc+ in your home
    directory and run +bundle install+ after:

        export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64


The last operation could take time.

## 6. Initialize database

*   Create and migrate database:

        rake db:create db:migrate


See [rails guide](http://guides.rubyonrails.org/active_record_migrations.html#running-migrations) for more informations on migrations.

## 7. Create an empty farm

*   Execute command:

        rake tenant:init TENANT=my-little-farm

*   Add in `/etc/hosts` a line to configure an artificial subdomain
    corresponding to your instance:

        echo '127.0.0.1 my-little-farm.ekylibre.lan' | sudo tee --append /etc/hosts


## 8. Try it

*   Launch server:
        foreman start

*   Open your web browser and go to http://my-little-farm.ekylibre.lan:8080
