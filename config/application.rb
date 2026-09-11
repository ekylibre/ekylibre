require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ekylibre
  class Application < Rails::Application
    # @return [Array<Ekylibre::Plugin::Base>]
    attr_reader :plugins

    def initialize(*args, **opts, &block)
      super

      @plugins = []
    end

    # @return [Procedo::ProcedureRegistry]
    def procedo_registry
      @procedo_registry ||= Procedo::ProcedureRegistry.new
    end

    # @return [Array<Ekylibre::Plugin::Theme>]
    def themes
      plugins.flat_map(&:themes).map { |name| Ekylibre::Plugin::Theme.new(name) }
    end

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.autoload_paths << Rails.root.join('lib')
    config.autoload_paths << Rails.root.join('app', 'models', 'bookkeepers')
    config.autoload_paths << Rails.root.join('app', 'models', 'lexicon')

    # --- Préparation Zeitwerk (Rails 6, lot B.2 du plan v6) ------------------
    #
    # Zeitwerk parcourt les chemins d'autoload et exige que chaque fichier
    # définisse la constante que son chemin implique — l'inverse du chargeur
    # classique, qui part de la constante pour deviner le fichier. Un contrôle
    # statique sur les 1 677 fichiers autochargés a relevé 20 écarts, de deux
    # natures seulement.
    #
    # Le bloc est inerte tant que `Rails.autoloaders` n'existe pas, c'est-à-dire
    # sur Rails 5.2 : il documente et prépare le palier sans rien changer ici.
    # La garde porte sur `zeitwerk_enabled?` et non sur la seule présence de
    # `Rails.autoloaders` : en Rails 6.0 l'objet existe toujours, mais tant que
    # l'application déclare `load_defaults 5.2` le chargeur reste le classique
    # et `autoloaders.main` vaut nil. Passer à Zeitwerk demande
    # `config.autoloader = :zeitwerk` — ou `load_defaults 6.0`.
    if Rails.respond_to?(:autoloaders) && Rails.autoloaders.respond_to?(:zeitwerk_enabled?) &&
       Rails.autoloaders.zeitwerk_enabled?
      main = Rails.autoloaders.main

      # 1. Acronymes. On passe par l'inflecteur *de Zeitwerk* et non par
      #    ActiveSupport::Inflector.acronym : ce dernier est global et
      #    changerait aussi les noms de routes, les clés i18n et `model_name`.
      main.inflector.inflect(
        'svf' => 'SVF',
        'geo_json' => 'GeoJSON',
        'xml' => 'XML',
        'html' => 'HTML',
        'json' => 'JSON',
        'csv' => 'CSV',
        'fec' => 'FEC',
        'ebp' => 'EBP',
        'dsl' => 'DSL',
        'sql_compiler' => 'SQLCompiler',
        'edi_exchanger' => 'EDIExchanger',
        # Fichier d'un plugin : en Rails 6 les chemins des engines sont indexés
        # par le chargeur principal, l'inflecteur de l'application s'y applique.
        'geo_json_model' => 'GeoJSONModel'
      )

      # 2. Fichiers qui ne définissent aucune constante autochargeable et
      #    n'ont donc rien à faire dans l'index de Zeitwerk :
      #    - extensions du cœur et monkey-patches, chargés explicitement par
      #      config/initializers/20-start.rb ;
      #    - gabarits de générateurs, qui ne sont pas du Ruby à exécuter.
      main.ignore(
        Rails.root.join('lib', 'safe_string.rb'),
        Rails.root.join('lib', 'enumerize', 'xml.rb'),
        Rails.root.join('lib', 'generators', '**', 'templates'),
        # `Ekylibre::VERSION` est une constante, pas une classe : Zeitwerk
        # attendrait `Ekylibre::Version` de ce chemin. On ne peut pas inflechir
        # `version` en `VERSION` pour autant — `app/models/version.rb` définit
        # le modèle `Version` de la piste d'audit, et l'inflecteur est global au
        # chargeur. Le fichier est donc exclu et déclaré en autoload maison dans
        # lib/ekylibre.rb, comme aujourd'hui.
        Rails.root.join('lib', 'ekylibre', 'version.rb')
      )
    end

    # We want to use the structure.sql file
    config.active_record.schema_format = :sql

    config.active_record.time_zone_aware_types = [:datetime, :time]

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # Confiure ActiveJob queue adapter
    config.active_job.queue_adapter = :sidekiq

    # Default starting from Rails 5
    # TODO: enable this when all optional belongs_to have been edited with 'optional: true'
    config.active_record.belongs_to_required_by_default = false

    # TODO: enable this when ready
    # config.action_controller.per_form_csrf_tokens = true
    # config.action_controller.forgery_protection_origin_check = true

    # for TinyMCE
    config.tinymce.install = :copy

    # Configure defaults for generators
    config.generators do |g|
      g.orm :active_record
      g.template_engine :haml
    end

    # APM
    # config.elastic_apm.service_name = ENV.fetch('APM_SERVICE_NAME', 'Ekylibre')

    config.middleware.use Rack::Cors do
      allow do
        # Anchored and dot-escaped: the previous unanchored regex matched any
        # origin merely *containing* the pattern (https://ekylibre.stoplight.io.attacker.com).
        origins %r{\Ahttps://ekylibre\.stoplight\.io\z}
        resource '*',
          headers: :any,
          methods: %i[get post put patch delete]
      end
    end

    # TODO: Rails 5 upgrade: check if removing this is OK
    # config.middleware.insert_after ActionDispatch::ParamsParser, ActiveSupport::XMLConverter

    initializer :register_core_plugin, before: :load_config_initializers do
      Ekylibre::Application.instance.plugins << Ekylibre::Core::Plugin.new
    end

    initializer :after_append_asset_paths, group: :all, after: :append_assets_path do
      { 'jquery-ui-rails' => ['app/assets/images'],
        'active_list' => ['app/assets/images'],
        'bootstrap-sass' => ['assets/images', 'assets/fonts'] }.each do |gem, paths|
        root = Pathname.new(Gem.loaded_specs[gem].full_gem_path)
        paths.each do |path|
          config.assets.paths.delete_if { |p| p.to_s == root.join(path).to_s }
        end
      end
    end
  end
end
