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
    config.load_defaults 6.0

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
    # classique, qui part de la constante pour deviner le fichier. Il est actif
    # depuis `load_defaults 6.0` ci-dessus.
    #
    # `bin/rails zeitwerk:check` ne contrôle que les chemins de chargement
    # hâtif ; pour couvrir aussi `lib`, `app/models/bookkeepers` et
    # `app/models/lexicon`, qui sont seulement autochargés, il faut rejouer
    # `eager_load` sur `Rails.autoloaders.main` en collectant les erreurs.
    #
    # La garde reste en place : elle rend le bloc inerte si le chargeur
    # classique revenait (`config.autoloader = :classic`, ou un retour à
    # `load_defaults 5.2`), où `autoloaders.main` vaut nil.
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
        'fiea' => 'FIEA',
        'upra' => 'UPRA',
        'omniauth' => 'OmniAuth',
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
        # `app/themes` n'est pas du code : Rails indexe tout sous-répertoire de
        # `app/` comme racine d'autochargement, et Zeitwerk bute sur le tiret de
        # `tekyla-sunrise`, qui ne donne pas un nom de constante valide. Les
        # thèmes ne contiennent que des feuilles de style et des polices.
        Rails.root.join('app', 'themes'),
        # Fichiers que `config/initializers/20-start.rb` charge explicitement.
        # Ce sont des extensions de boot — monkey-patches, `include` dans des
        # classes du framework, définition des unités de Measure — donc des
        # effets de bord, ce que Zeitwerk demande justement de ne pas
        # autocharger. Les laisser indexés est pire qu'inutile : en
        # développement le rechargeur les décharge après les initialiseurs, et
        # `require` ne les rejoue pas, d'où un `uninitialized constant` au
        # premier accès.
        Rails.root.join('lib', 'clients.rb'),
        Rails.root.join('lib', 'delay.rb'),
        Rails.root.join('lib', 'ekylibre.rb'),
        Rails.root.join('lib', 'enumerize', 'xml.rb'),
        Rails.root.join('lib', 'measure.rb'),
        Rails.root.join('lib', 'migration_helper.rb'),
        Rails.root.join('lib', 'open_weather_map.rb'),
        Rails.root.join('lib', 'safe_string.rb'),
        Rails.root.join('lib', 'userstamp.rb'),
        Rails.root.join('lib', 'userstamp'),
        Rails.root.join('lib', 'working_set.rb'),
        # Les générateurs sont trouvés par le mécanisme propre à Rails, pas par
        # l'autochargement : leurs classes sont à la racine (`XGenerator`) alors
        # que leur chemin sous `lib/` impliquerait `Generators::X::XGenerator`.
        # Les gabarits, eux, ne sont pas du Ruby à exécuter.
        Rails.root.join('lib', 'generators'),
        # Rouvre ActionDispatch::Routing::Mapper pour y ajouter `plugins` ; ne
        # définit aucune constante autochargeable et est requis explicitement
        # par lib/ekylibre/plugin.rb.
        Rails.root.join('lib', 'ekylibre', 'plugin', 'routing.rb'),
        # `Ekylibre::VERSION` est une constante, pas une classe : Zeitwerk
        # attendrait `Ekylibre::Version` de ce chemin. On ne peut pas inflechir
        # `version` en `VERSION` pour autant — `app/models/version.rb` définit
        # le modèle `Version` de la piste d'audit, et l'inflecteur est global au
        # chargeur. Le fichier est donc exclu et déclaré en autoload maison dans
        # lib/ekylibre.rb, comme aujourd'hui.
        Rails.root.join('lib', 'ekylibre', 'version.rb')
      )

      # 3. Code de support des tests : autochargeable — les tests s'en servent —
      #    mais pas chargeable hâtivement. `fixtures` n'existe que sur une
      #    classe de test, et le chargement hâtif a lieu hors de tout contexte
      #    de test (démarrage en production).
      main.do_not_eager_load(
        Rails.root.join('lib', 'ekylibre', 'testing'),
        Rails.root.join('lib', 'active_exchanger', 'test_case.rb')
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
