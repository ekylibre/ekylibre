# Installation for developers

This process is for Ubuntu 18.04.

Please note that Ubuntu 20.04 and Debuan Buster are not supported yet as they are missing libraries for the old version of rgeo we are using.
This can be fixed by manually downloading/compiling and installing proj4.

Please don't use Windows, you are just hurting yourself. And if you are using MacOS, you are on your own.

## 0. Ruby and Node.js installation

We recommend installing Ruby using rbenv and Node with nvm 

``` bash
# Base packages needed
apt-get -y install git curl build-essential libreadline-dev libssl1.0-dev zlib1g-dev lsb-release wget
```

### Node

``` bash
# https://github.com/nvm-sh/nvm#install--update-script
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
```
If you are using bash it is done automatically, but if not, it may be possible you need to add the following lines in your configuration:
``` bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
```

Then, install the latest LTS
``` bash
nvm install --lts
nvm alias default lts

# Install yarn globally
npm i -g yarn
```

### Ruby
#### rbenv and ruby-build

Install rbenv and ruby-build through rbenv-installer
``` bash
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash
```

You may have an error-message at the end:

    Running doctor script to verify installation...
    Checking for `rbenv' in PATH: not found
      You seem to have rbenv installed in `/root/.rbenv/bin', but that
      directory is not present in PATH. Please add it to PATH by configuring
      your `~/.bashrc', `~/.zshrc', or `~/.config/fish/config.fish'.
    
In this case you should put `export PATH="$HOME/.rbenv/bin:$PATH` and `eval "$(rbenv init -)"` in the configuration file of your shell

You can re-run the command above to make sure everything is set-up correctly

#### Install Ruby

``` bash
MAKEFLAGS="-j $(nproc)" rbenv install 2.6.6

rbenv global 2.6.6
gem install bundler --version==1.17.3
```

## 1. Ekylibre dependencies

Postgres 9.6 and postgis 2.X are used. Redis is also required.
``` bash
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
sudo apt-get update
 
sudo apt-get -y install postgresql-9.6-postgis-2.5 postgresql-contrib-9.6 redis-server
```

Configure postgres with:
``` bash
sudo su - postgres
createuser -d -P -s ekylibre
echo "ALTER USER ekylibre SUPERUSER;" | psql
``` 


The gems used in ekylibre require the following dependencies:
``` bash
sudo apt install \
    graphicsmagick \
    libproj-dev libgeos-dev libgeos++-dev `#rgeo` \
    openjdk-8-jdk  `#rjb` \
    libqtwebkit-dev `#capybara` \
    libicu-dev `#charlock_holmes` \
    libpq-dev `#pq`
```

JAVA_HOME needs to be set in your shell configuration file (example is for bash, change it based on your shell):
``` bash
echo 'export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"' >> ~/.bashrc
```

## 3. Ekylibre installation

Get the code
``` bash
# Everything related to ekylibre is in the ekylibre folder
mkdir ekylibre && cd ekylibre

# Clone the repository
git clone git@gitlab.com:ekylibre/eky.git
cd eky
```

Configure the app
``` bash
# Copy the default database configuration. You should edit the username and password configuration to match your postgres installation
cp config/database.yml.sample config/database.yml

# Configure the application
cp .env.dist .env

# TODO: edit the .env file with sensible values
```

Get the gems and js packages then initialize the database
``` bash
# Install dependencies
yarn
bundle install -j $(nproc)

# Create database
bin/rake db:{create,migrate}

# Create the demo farm
bin/rake tenant:init TENANT=demo
```
