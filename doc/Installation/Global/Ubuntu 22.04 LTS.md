# Ubuntu 22.04 LTS

* * *

#### Rbenv & Ruby

1.  Install curl

    ```bash
    sudo apt install git curl
    ```

2.  Clone Rbenv && Ruby-build

    ```bash
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    git clone https://github.com/rbenv/ruby-build.git .rbenv/plugins/ruby-build
    ```


    then :

    ```bash
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    ```

3.  Apply changes in your .bashrc

    ```bash
    source ~/.bashrc
    ```

4.  Ruby dependencies

    ```bash
    sudo apt install git build-essential libreadline-dev libssl-dev zlib1g-dev redis-server
    ```


    Then you can run :

    ```bash
    rbenv install 2.6.6
    rbenv global 2.6.6
    gem install bundler

    ```


#### Node.js

1.  Install nvm

    ```bash
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
    ```


    If it does not works

    ```bash
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

    ```

    Then you can run

    ```bash
    nvm install --lts
    > Installing latest LTS version.
    > Creating default alias: default -> lts/* (-> v18.13.0)
    ```

2.  Install yarn

    ```bash
    npm i -g yarn
    ```


#### Postgresql

1.  Install postgresql/postgis/contrib

    ```bash
    sudo apt install postgresql-14 postgresql-14-postgis-3 postgresql-14-postgis-3-scripts
    ```

2.  Configure Postgres

    ```bash
    sudo -su postgres
    createuser -d -P -s ekylibre
    echo "ALTER USER ekylibre SUPERUSER;" | psql

    # set 'ekylibre' as password

    ```

3.  Edit pg\_hba.conf to use md5 password authentication instead of peer authentication for unix sockets

    `sudo vim /etc/postgresql/14/main/pg_hba.conf`

    TIPS : Under VIM, to insert text press i.
    Press Esc and type :wq to save changes to a file and exit from vim.

    replace

    ```bash
    local   all             all                                peer
    ```

    with

    ```bash
    local   all             all                                md5
    ```


4\. \[Optionnal\] For developer who wants checking data, install PgAdmin4 Desktop

[https://www.pgadmin.org/download/pgadmin-4-apt/](https://www.pgadmin.org/download/pgadmin-4-apt/)

```bash
sudo curl https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo apt-key add
sudo sh -c 'echo "deb https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'
sudo apt install pgadmin4 pgadmin4-desktop
```

#### Renater certificates

Renater CA certificates (used by pfi api) is not included in Ubuntu 22.04 and should be added.

```bash
sudo wget https://services.renater.fr/_media/tcs/geant_ov_rsa_ca_4_usertrust_rsa_certification_authority.pem -O /usr/local/share/ca-certificates/geant_ov_rsa_ca_4_usertrust_rsa_certification_authority.crt \
&& sudo wget https://services.renater.fr/_media/tcs/geant_ov_rsa_ca_4.pem -O /usr/local/share/ca-certificates/geant_ov_rsa_ca_4.crt \
&& sudo update-ca-certificates
```

#### Proj (WIP)

1.  Check your version of PROJ

    ```bash
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

    ```bash
    sudo apt-get update
    sudo apt-get install libqt5core5a
    sudo apt install imagemagick graphicsmagick libproj-dev libgeos-dev libffi-dev libgeos++-dev openjdk-8-jdk libicu-dev libpq-dev tesseract-ocr pdftk
    ```

2.   Add JAVA\_HOME in your .bashrc && .profile

    Check your version of Java installed in folder /usr/lib/jvm/ and add it

    ```java
    echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64' >> ~/.bashrc
    echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64' >> ~/.profile
    source ~/.bashrc
    source ~/.profile
    ```


# **<u>That’s it!</u>**
