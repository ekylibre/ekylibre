# Ubuntu 20.04 LTS

<https://ekylibre.atlassian.net/spaces/EKYLIBRE/pages/11829377/Ubuntu+20.04+LTS>

* * *

#### Rbenv & Ruby

1.  Install curl

    ```java
    sudo apt install git curl
    ```

2.  Clone Rbenv && Ruby-build

    ```java
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    git clone https://github.com/rbenv/ruby-build.git .rbenv/plugins/ruby-build
    ```


    then :

    ```java
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    ```

3.  Apply changes in your .bashrc

    ```java
    source ~/.bashrc
    ```

4.  Ruby dependencies

    ```java
    sudo apt install git build-essential libreadline-dev libssl-dev zlib1g-dev redis-server
    ```


    Then you can run :

    ```java
    rbenv install 2.6.6
    rbenv global 2.6.6
    gem install bundler

    ```


#### Node.js

1.  Install nvm

    ```java
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
    ```


    If it does not works

    ```java
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

    ```

    Then you can run

    ```java
    nvm v14.17.3
    > Installing latest LTS version.
    > v14.16.1 is already installed.
    > Now using node v14.17.4 (npm v6.14.12)
    nvm alias default 14.17.3
    ```

2.  Install yarn

    ```java
    npm i -g yarn
    ```


#### Postgresql

1.  Install postgresql/postgis/contrib

    # Add postgresql repository and key
    ```java
    sudo sh -c 'echo "deb [arch=$(dpkg --print-architecture)] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    ```

    ```java
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    ```
    ```java
    sudo apt install postgresql-13 postgresql-13-postgis-2.5 postgresql-13-postgis-2.5-scripts
    ```

2.  Configure Postgres

    ```java
    sudo -su postgres
    createuser -d -P -s ekylibre
    echo "ALTER USER ekylibre SUPERUSER;" | psql

    # set 'ekylibre' as password

    ```

3.  Edit pg\_hba.conf to use md5 password authentication instead of peer authentication for unix sockets

    `sudo vim /etc/postgresql/13/main/pg_hba.conf`

    replace

    ```java
    local   all             all                                peer
    ```

    with

    ```java
    local   all             all                                md5
    ```


4\. \[Optionnal\] For developer who wants checking data, install PgAdmin4 Desktop

[https://www.pgadmin.org/download/pgadmin-4-apt/](https://www.pgadmin.org/download/pgadmin-4-apt/)

```java
sudo curl https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo apt-key add
sudo sh -c 'echo "deb https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'
sudo apt install pgadmin4 pgadmin4-desktop
```

#### Renater certificates

Renater CA certificates (used by pfi api) is not included in Ubuntu 20.04 and should be added.

```java
sudo wget https://services.renater.fr/_media/tcs/geant_ov_rsa_ca_4_usertrust_rsa_certification_authority.pem -O /usr/local/share/ca-certificates/geant_ov_rsa_ca_4_usertrust_rsa_certification_authority.crt \
&& sudo wget https://services.renater.fr/_media/tcs/geant_ov_rsa_ca_4.pem -O /usr/local/share/ca-certificates/geant_ov_rsa_ca_4.crt \
&& sudo update-ca-certificates
```

#### Proj

1.  Check your version of PROJ

    ```java
    dpkg -l | grep proj
    ```

2.  If the version is greater than 5.2.0 then

    1.  Download this file:


[![](https://ekylibre.atlassian.net/wiki/download/thumbnails/11829377/proj.tar.gz?version=2&modificationDate=1648452693448&cacheVersion=1&api=v2&viewType=fileMacro)](/wiki/download/attachments/11829377/proj.tar.gz?version=2&modificationDate=1648452693448&cacheVersion=1&api=v2)

1.  Extract the content of proj.tar.gz

    1.  Create a new directory

        ```java
        sudo mkdir -p /opt/proj/share
        ```

    2.  Then move the extracted proj file into the new repo

        ```java
        sudo mv proj /opt/proj/share
        ```


### Java & Redis

1.  Install dependencies

    ```java
    sudo add-apt-repository ppa:rock-core/qt4
    sudo apt-get update
    sudo apt-get install libqtcore4
    sudo apt install imagemagick graphicsmagick libproj-dev libgeos-dev libffi-dev libgeos++-dev openjdk-8-jdk libqtwebkit-dev libicu-dev libpq-dev tesseract-ocr pdftk python2
    ```

2.   Add JAVA\_HOME in your .bashrc && .profile

    ```java
    echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> ~/.bashrc
    echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> ~/.profile
    source ~/.bashrc
    source ~/.profile
    ```


# **<u>That’s it!</u>**
