# Eky/Ekylibre

<https://ekylibre.atlassian.net/spaces/EKYLIBRE/pages/7405675>

* * *

Assume that you have completed the global installation of your development environment.  

1.  Go to your development directory :  
    `cd ~/projects/`  
    
2.  Clone the repo :  
    `git clone git@gitlab.com:ekylibre/eky.git` or `git clone git@github.com:ekylibre/ekylibre.git` if you work with open source version  
    
3.  Install gems and yarn packages :  
    `bundle install && yarn install`  
    
4.  Copy of the necessary configuration files :  
    `cp config/database.yml.sample config/database.yml`  
    `cp .env.dist .env`  
    **<u>Then ask any developer to share the credentials to put in these files.</u>**  
    
5.  Create and migrate the database :  
    `bundle exec rails db:create db:migrate`  
    
6.  Add a local GPG key  
    `gpg --gen-key`  
    Follow the instructions.  
    Then add an environment variable in your .env file  
    `GPG_EMAIL: EMAIL_USED_TO_GENERATE_THE_KEY`  
    
7.  Load the lexicon data in eky database  
    `bin/rake lexicon:load`  
    
8.  Add first\_run data
    
    1.  Go to eky/ekylibre folder  
        `cd ~/projects/ekylibre`
        
    2.  Create a folder for demo data  
        `mkdir db/first_runs`
        
    3.  Clone demo repository  
        `git clone git@github.com:ekylibre/first_run-demo.git db/first_runs`
        
    4.  Launch first run  
        `bin/rake first_run`
        
    5.  Configure hosts  
        `echo '127.0.0.1 demo.ekylibre.lan' | sudo tee --append /etc/hosts`  
        
9.  Or create you own instance
    
    1.  Init you farm ; Exemple: my-farm
        
        `rake tenant:init TENANT=my-farm`
        
    2.  Configure hosts
        
        `echo '127.0.0.1 my-farm.ekylibre.lan' | sudo tee --append /etc/hosts`  
        
10.  Start the servers
    
a. Rails server
        
`bundle exec rails s`

b. Sidekiq  
`bundle exec sidekiq`

c. Webpack dev server _\*optional_  
`bundle exec webpack-dev-server` or `bin/webpackdev-server`

Go to [http://demo.ekylibre.lan:3000](http://demo.ekylibre.lan:3000/backend)