# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

git_source(:gitlab) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://gitlab.com/#{repo_name}.git"
end

ruby '>= 2.6.6', '< 3.0.0'

gem 'actionpack-xml_parser', '~> 2.0'
gem 'rack-cors' # CORS policy
gem 'rails', '~> 7.0.0'

# concurrent-ruby 1.3.5 retire `Concurrent::Logger`, dont ActiveSupport se sert
# dans `logger_thread_safe_level` jusqu'à Rails 6.x inclus : sans cette borne,
# l'application ne charge plus du tout. Mesuré deux fois pendant la préparation
# du lot B — la panne se présente comme une incompatibilité Rails/Ruby, ce
# qu'elle n'est pas. À lever quand Rails aura cessé d'en dépendre.
gem 'concurrent-ruby', '< 1.3.5'
gem 'turnout', '~> 2.5' # Maintenance mode

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# IRB and CLI
gem 'colored' # , require: false
gem 'fiddle'
gem 'irb', '~> 1.3'
gem 'rake', '~> 12.0'

# TO REMOVE ASAP
gem 'browser', '~> 5.2' # Only used in ApplicationController to check for IE
gem 'ffaker', '~> 2.0' # Should not be present in production. Is used to generate names for Products.
gem 'time_diff', '~> 0.3.0' # Only used in InterventionWorkingPeriod
gem 'wannabe_bool', '~> 0.7.1' # This Gem is a JOKE

# Database
gem 'activemodel-serializers-xml', '~> 1.0'
gem 'activerecord-postgis-adapter', '~> 8.0.0'
gem 'pg', '~> 1.0'
# scenic 1.9 emploie le passage de bloc anonyme (`&`), syntaxe de Ruby 3.1 :
# elle ne se charge pas sous 2.7. Borne à lever avec le passage à Ruby 3.
gem 'scenic', '< 1.9'

# Psych 4 désactive les alias YAML par défaut. `config/database.yml` en utilise
# (`<<: *default`), et Rails n'a appris à passer `aliases: true` qu'en 6.1.7 /
# 7.0.4 : sous Rails 6.0 la configuration de base devient illisible. Borne à
# lever au palier B.3, où le crochet existe.
gem 'psych', '< 4'

# json 3.0 retire l'option `quirks_mode`, que l'encodeur JSON d'ActiveSupport
# passe encore en Rails 6.x. Même famille de piège que concurrent-ruby et
# scenic : une gem par ailleurs transitive qui, laissée flotter, casse le boot.
gem 'json', '< 3'

# Multi-tenancy
# ros-apartment est le fork maintenu d'apartment (abandonnée en 2.2.1). Il
# conserve le namespace Apartment : aucun changement d'appelant.
# La série 2.11 accepte activerecord >= 5.0, < 7.1 — elle couvre donc le
# palier actuel (6.1) et le palier 7.0 sans nouvelle bascule.
# Passer en 3.x plus tard (3.0 exige AR >= 6.1, 3.4 exige AR >= 7.0).
gem 'ros-apartment', '~> 2.11', require: 'apartment'
gem 'ros-apartment-sidekiq', '~> 1.2', require: 'apartment-sidekiq'

# Assets pipeline
gem 'coffee-rails', '~> 4.1'
gem 'sassc-rails', '~> 2.0'

# Docsplit arrivait jusqu'ici par paperclip-document (retirée) : il reste
# nécessaire à Documents::DerivativesBuilder, qui extrait le texte, compte les
# pages et convertit en PDF.
gem 'burisu-docsplit', '~> 0.7.9', require: 'docsplit'

# Requis par les variantes Active Storage : Rails 6.1 a retiré
# `ActiveStorage::Transformers::MiniMagickTransformer`, seul repli quand
# `image_processing` est absent. `mini_magick` reste la dépendance de travail
# d'`image_processing`, et sert aussi directement à Documents::DerivativesBuilder.
gem 'image_processing', '~> 1.12'
gem 'mini_magick', '~> 4.11'
gem 'sprockets', '< 4.0'
gem 'uglifier', '>= 1.3.0'
gem 'webpacker', '~> 4.x'

# CSS
gem 'agric', github: 'ekylibre/agric', branch: '6.0'
gem 'bootstrap-sass', '~> 3.4.1'
# bootstrap-slider-rails retirée : son gemspec borne `railties < 6.0` et son
# amont est mort (9.8.0 est la dernière version, publiée il y a des années),
# ce qui bloquait la résolution vers Rails 6.0. La gem n'apportait que deux
# fichiers d'assets et un engine pour les exposer ; ils sont désormais versionnés
# dans vendor/assets, comme geographiclib, heatmap et daterangepicker avant eux.
# Licence MIT conservée à côté du script.
gem 'font-awesome-sass', '~> 5.15'

# JS
gem 'cocoon', '~> 1.2'
gem 'jquery-rails', '~> 4.4'
gem 'jquery-ui-rails', '~> 6.0'
gem 'momentjs-rails', '>= 2.9.0'
gem 'simple_calendar', '~> 2.4.0'
# therubyracer retiré : ExecJS >= 2.8 ne le liste plus parmi ses runtimes
# (therubyrhino, GraalVM, Duktape, mini_racer, Bun.sh, Node.js, ...), et
# l'image de base fournit Node 20, qu'ExecJS sélectionne déjà. La gem et
# son libv8 3.16 (abandonné en 2017) bloquaient la montée Ruby 3.
gem 'turbolinks', '~> 5.2.1'
gem 'twitter-typeahead-rails', '~> 0.11.1'

# Front
gem 'active_list', github: 'ekylibre/active_list', branch: '6.0'
gem 'formize', '~> 2.1.0'
gem 'kaminari', '~> 1.1'
gem 'remotipart', '~> 1.2'
gem 'simple_form', '~> 4.0'
# 6.1.3 declares `rails >= 5.0` with no upper bound: it runs on 5.2 today and
# stays valid through 6.x/7.x. 4.x was capped at `rails < 5.3` and was one of
# the nine gems blocking Rails 6. (7.x requires `rails ~> 7.1`.)
gem 'wice_grid', '~> 6.1'

# View Engines
gem 'haml', '~> 5.2'
gem 'jbuilder', '~> 2.0'

# Ruby extensions
gem 'code_string', '~> 0.0.1'
gem 'possibly', github: 'ekylibre/possibly', branch: 'master'
gem 'semantic', '~> 1.6'

# Exception analysis and metrics
gem 'binding_of_caller', '~> 1.0'
# gem 'elastic-apm', '~> 3.4.0'
gem 'exception_notification', '~> 4.4'
gem 'redis-namespace', '~> 1.8'

# Manipulate map data
gem 'charta', github: 'ekylibre/charta', branch: '6.0'
gem 'geocoder', '~> 1.6'
gem 'rgeo', '~> 2.2'
gem 'rgeo-geojson', '~> 2.1'
gem 'rgeo-shapefile', '~> 3.0'

# Background jobs
gem 'sidekiq', '~> 4.0'
gem 'sidekiq-cron', '~> 1.1'
gem 'sidekiq-unique-jobs', '~> 4.0'

# Reference data
# La gem publiée 0.9.8 borne `zeitwerk ~> 2.4.0`, ce qui bloque Rails 7.0 dont
# railties exige `~> 2.5`. La branche 6.0 du dépôt ne change que cette borne ;
# à repointer sur rubygems dès qu'une version le reprendra.
gem 'onoma', github: 'ekylibre/onoma', branch: '6.0'

# Parse LALR or LR-1 grammars
gem 'treetop', '~> 1.6'

# Models helpers
gem 'acts_as_list', '~> 1.0'
# 3.2 bornait `activerecord < 7.0` ; 3.5 va jusqu'à 7.1. La série corrige aussi
# les passages de hash en arguments nommés que Ruby 2.7 signale.
gem 'awesome_nested_set', '~> 3.5'
# 3.x accepts `activerecord >= 3.1.0, < 9` — valid on 5.2 and on every planned
# palier. 2.4 was capped at `activerecord < 6`.
gem 'deep_cloneable', '~> 3.0'
gem 'draper', "~> 3.0"
gem 'enumerize', '~> 2.4'
gem 'paranoia', '~> 2.2' # Hide and restore records without actually deleting them
gem 'uuidtools', '~> 2.2'
gem 'validates_timeliness', '~> 4'

# Authentication & Authorization
gem 'devise', '~> 4.7'
gem 'devise-i18n-views', '~> 0.3.7'
gem 'devise_invitable', '~> 2.0'
gem 'googleauth'
gem 'omniauth', '~> 1.9'
gem 'omniauth-oauth2', '~> 1.7'

# Attachments

# Emailing
gem 'liquid-rails'
gem "panoramic"
gem 'tinymce-rails'
gem 'tinymce-rails-langs'

# I18n and localeapp
gem 'http_accept_language', '~> 2.1'
gem 'humanize', '~> 2.5'
gem 'i18n-complements', git: 'https://github.com/ekylibre/i18n-complements.git', branch: '6.0'
gem 'i18n-js', '~> 3.8'


# Import/Export
gem 'caxlsx'
gem 'charlock_holmes', '~> 0.7.7'
gem 'combine_pdf', '~> 1.0'
gem 'ekylibre-ofx-parser', '~> 1.2'
gem 'gpgme', '~> 2.0'
gem 'holidays' # Deal with statutory and other holidays
gem 'luhn', '~> 1.0'
gem 'mimemagic', '~> 0.3.5'
gem 'nokogiri', '~> 1.8'
gem 'odf-report', github: 'ekylibre/odf-report', branch: 'master'
gem 'prawn', '~> 2.4'
gem 'prawn-table'
gem 'rodf', '~> 1.0'
gem 'roo', '~> 2.8'
gem 'rubyzip', '~> 1.3.0'
gem 'sepa_king', '~> 0.12.0'
gem 'xml_errors_parser', github: 'ekylibre/xsd_errors_parser', branch: 'main'

# Web services
gem 'faraday', '~> 2.5'
gem 'google-cloud-bigquery'
gem 'mechanize', '~> 2.7'
gem 'rest-client', '~> 2.0'
gem 'rubyntlm', '>= 0.3.2'
gem 'ruby-trello'
gem 'savon', '2.12'
gem 'stripe'

# Using git until we have a proper release system for cartography
gem 'cartography', github: 'ekylibre/cartography', branch: 'eky'

# Used to convert markdown to html
gem 'gitlab_kramdown', '~> 0.6'

# for loading lexicon 5 in test mode
gem 'lexicon-common', '~> 0.2.0'

group :production do
  # Use puma as the app server
  gem 'puma', '~> 5.6'
end

group :development do
  # 5.7 refuse de se charger au-delà d'ActiveRecord 6.0 (« Bullet does not
  # support active_record 6.1 yet ») ; la gem n'étant qu'en développement,
  # l'incompatibilité ne se voyait pas dans la suite.
  gem 'bullet', '~> 7.0'

  gem 'better_errors', '~> 2.9'
  gem 'rack-mini-profiler'
  # Get the time of a process
  gem 'ruby-prof', '~> 1.4'

  # Code metrics
  gem 'haml_lint', '0.40.0', require: false
  gem 'rails_best_practices', '~> 1.20', require: false
  gem 'rubocop', '1.11.0', require: false
  gem 'rubocop-ast', '1.15.0', require: false

  # Webservers
  gem 'rack-handlers'
  gem 'unicorn-rails'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 3.0'

  gem 'letter_opener', '~> 1.7'
end

group :development, :test do
  gem 'dotenv', '~> 2.7'

  gem 'pry', '~> 0.12.0'
  gem 'pry-byebug', '~> 3.8'
  gem 'pry-rails', '~> 0.3.9'

  # gem 'listen', '>= 3.0.5', '< 3.2' See config/environments/development.rb:68

  # For git manipulation in test:git task
  gem 'git', '~> 1.8'

  gem 'yard', '~> 0.9.26'
end

group :test do
  # Freeze time for demo and/or tests
  gem 'timecop', '~> 0.9.0'

  gem 'shoulda-context', '~> 2.0'

  gem 'database_cleaner', '~> 1.8'

  gem 'minitest', "~> 5.17.0"
  gem 'minitest-reporters', '~> 1.4'

  gem 'factory_bot', '< 5'

  gem 'pdf-reader', '~> 2.4'

  gem 'simplecov', '~> 0.21.2'
  gem 'simplecov-cobertura', '~> 2.1.0'

  gem 'rails-controller-testing', '~> 1.0'

  gem 'vcr', "~> 6.0.0"
  gem 'webmock', "~> 3.13.0"
end

# Load Gemfile.local, Gemfile.plugins, plugins', and custom Gemfiles
gemfiles = Dir.glob(File.expand_path('../{plugins/*/Gemfile,Gemfile.*}', __FILE__)).keep_if{|e| e !~/(.lock)$/}
gemfiles << ENV['CUSTOM_PLUGIN_GEMFILE'] unless ENV['CUSTOM_PLUGIN_GEMFILE'].nil?
gemfiles.each do |file|
  next unless File.readable?(file)

  eval_gemfile(file)
end
