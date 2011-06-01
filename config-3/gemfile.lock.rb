GIT
  remote: git://github.com/rails/prototype-rails.git
  revision: 24ff6e3caf53bf2c3cf035e6898c383a5cd112fc
  specs:
    prototype-rails (0.3.1)
      rails (~> 3.1.0.beta1)

PATH
  remote: vendor/ogems/exception_notification-1.0.0
  specs:
    exception_notification (1.0.0)

PATH
  remote: vendor/ogems/state_machine-0.9.4
  specs:
    state_machine (0.9.4)

GEM
  remote: http://rubygems.org/
  specs:
    actionmailer (3.1.0.rc1)
      actionpack (= 3.1.0.rc1)
      mail (~> 2.3.0)
    actionpack (3.1.0.rc1)
      activemodel (= 3.1.0.rc1)
      activesupport (= 3.1.0.rc1)
      builder (~> 3.0.0)
      erubis (~> 2.7.0)
      i18n (~> 0.6.0beta1)
      rack (~> 1.3.0.beta2)
      rack-cache (~> 1.0.1)
      rack-mount (~> 0.8.1)
      rack-test (~> 0.6.0)
      sprockets (~> 2.0.0.beta.5)
      tzinfo (~> 0.3.27)
    activemodel (3.1.0.rc1)
      activesupport (= 3.1.0.rc1)
      bcrypt-ruby (~> 2.1.4)
      builder (~> 3.0.0)
      i18n (~> 0.6.0beta1)
    activerecord (3.1.0.rc1)
      activemodel (= 3.1.0.rc1)
      activesupport (= 3.1.0.rc1)
      arel (~> 2.1.1)
      tzinfo (~> 0.3.27)
    activeresource (3.1.0.rc1)
      activemodel (= 3.1.0.rc1)
      activesupport (= 3.1.0.rc1)
    activesupport (3.1.0.rc1)
      multi_json (~> 1.0)
    arel (2.1.1)
    bcrypt-ruby (2.1.4)
    builder (3.0.0)
    coffee-script (2.2.0)
      coffee-script-source
      execjs
    coffee-script-source (1.1.1)
    erubis (2.7.0)
    execjs (1.0.0)
      multi_json (~> 1.0)
    fastercsv (1.5.4)
    haml (3.1.1)
    hike (1.0.0)
    i18n (0.6.0)
    jquery-rails (1.0.9)
      railties (~> 3.0)
      thor (~> 0.14)
    json (1.5.1)
    libxml-ruby (1.1.3)
    mail (2.3.0)
      i18n (>= 0.4.0)
      mime-types (~> 1.16)
      treetop (~> 1.4.8)
    mime-types (1.16)
    multi_json (1.0.3)
    mysql (2.8.1)
    pg (0.11.0)
    polyglot (0.3.1)
    rack (1.3.0)
    rack-cache (1.0.2)
      rack (>= 0.4)
    rack-mount (0.8.1)
      rack (>= 1.0.0)
    rack-ssl (1.3.2)
      rack
    rack-test (0.6.0)
      rack (>= 1.0)
    rails (3.1.0.rc1)
      actionmailer (= 3.1.0.rc1)
      actionpack (= 3.1.0.rc1)
      activerecord (= 3.1.0.rc1)
      activeresource (= 3.1.0.rc1)
      activesupport (= 3.1.0.rc1)
      bundler (~> 1.0)
      railties (= 3.1.0.rc1)
    railties (3.1.0.rc1)
      actionpack (= 3.1.0.rc1)
      activesupport (= 3.1.0.rc1)
      rack-ssl (~> 1.3.2)
      rake (>= 0.8.7)
      thor (~> 0.14.6)
    rake (0.8.7)
    rubyzip (0.9.4)
    sass (3.1.2)
    sprockets (2.0.0.beta.9)
      hike (~> 1.0)
      rack (~> 1.0)
      tilt (~> 1.1, != 1.3.0)
    thor (0.14.6)
    thoughtbot-shoulda (2.11.1)
    tilt (1.3.2)
    treetop (1.4.9)
      polyglot (>= 0.3.1)
    tzinfo (0.3.27)
    uglifier (0.5.4)
      execjs (>= 0.3.0)
      multi_json (>= 1.0.2)
    will_paginate (3.0.pre2)

PLATFORMS
  ruby

DEPENDENCIES
  coffee-script
  exception_notification!
  fastercsv
  haml
  jquery-rails
  json
  libxml-ruby (= 1.1.3)
  mysql
  pg
  prototype-rails!
  rails (= 3.1.0.rc1)
  rake (= 0.8.7)
  rubyzip
  sass
  state_machine!
  thoughtbot-shoulda
  uglifier
  will_paginate (~> 3.0.pre2)
