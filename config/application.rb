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
    config.load_defaults 7.0

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
        # Ces deux-là ne définissent aucune constante autochargeable : ce
        # sont des extensions du cœur, chargées explicitement par
        # config/initializers/20-start.rb.
        Rails.root.join('lib', 'enumerize', 'xml.rb'),
        Rails.root.join('lib', 'safe_string.rb'),
        # Infrastructure de démarrage, chargée explicitement en tête de ce
        # fichier : voir le commentaire là-haut.
        Rails.root.join('lib', 'ekylibre', 'core.rb'),
        Rails.root.join('lib', 'ekylibre', 'core'),
        Rails.root.join('lib', 'ekylibre', 'plugin.rb'),
        Rails.root.join('lib', 'ekylibre', 'plugin'),
        Rails.root.join('lib', 'ekylibre', 'access.rb'),
        Rails.root.join('lib', 'ekylibre', 'access'),
        Rails.root.join('lib', 'ekylibre', 'hook.rb'),
        Rails.root.join('lib', 'ekylibre', 'view.rb'),
        Rails.root.join('lib', 'ekylibre', 'view'),
        # Les générateurs sont trouvés par le mécanisme propre à Rails, pas par
        # l'autochargement : leurs classes sont à la racine (`XGenerator`) alors
        # que leur chemin sous `lib/` impliquerait `Generators::X::XGenerator`.
        # Les gabarits, eux, ne sont pas du Ruby à exécuter.
        Rails.root.join('lib', 'generators'),
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

    # Rails 7.0 bascule le processeur de variantes sur libvips. L'image de base
    # ne le fournit pas, et l'application s'appuie sur MiniMagick — qu'elle
    # emploie aussi directement dans Documents::DerivativesBuilder, avec des
    # transformations écrites en options ImageMagick. Bascule à reconsidérer
    # pour elle-même, pas en marge d'une montée de version.
    config.active_storage.variant_processor = :mini_magick

    # Les deux réglages d'inversion d'association, seuls défauts que l'on
    # n'adopte pas encore — `has_many_inversing` vient de Rails 6.1,
    # `automatic_scope_inversing` de Rails 7.0, et ils ont le même effet :
    # l'enfant chargé par une association pointe vers *l'objet même* qui le
    # détient, au lieu d'une instance rechargée.
    #
    # C'est la bonne sémantique, et elle met au jour une récursion mutuelle bien
    # réelle : `PurchaseInvoice#after_save` parcourt ses lignes pour leur créer
    # une immobilisation, et `PurchaseItem#after_save` termine par
    # `purchase.save!`. Jusqu'ici la boucle s'arrêtait par accident —
    # `item.purchase` était une autre instance, dont les lignes relues avaient
    # déjà leur `fixed_asset_id` ; avec l'inversion c'est le même objet en
    # mémoire, la garde ne devient jamais fausse et la pile déborde. Le même
    # partage rend périmés des `lock_version` à la duplication d'intervention,
    # et fait échouer la cession d'immobilisation faute d'exercice comptable.
    #
    # Lever ces deux lignes demande de casser la récursion à la source, pas de
    # la contourner : c'est une modification de callbacks comptables, à mener
    # pour elle-même. Les deux réglages subsistent dans Rails 8, le report
    # n'engage pas la suite des paliers.
    config.active_record.has_many_inversing = false
    config.active_record.automatic_scope_inversing = false

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

# Le registre de plugins est de l'infrastructure de démarrage : il est consulté
# par l'application elle-même, par `20-start.rb` et par `lib/ekylibre.rb`, tous
# exécutés pendant l'initialisation. Or Rails 7 n'installe le chargeur principal
# que dans le *finisher*, après les initialiseurs : plus rien n'est
# autochargeable à ce moment-là. Ce sous-arbre est donc chargé explicitement et
# retiré de l'index de Zeitwerk, plus haut.
#
# Le chargement a lieu ici, et non en tête de fichier, parce que `Rails.root`
# n'a de valeur qu'une fois la classe Application définie.
%w[
  ekylibre/plugin
  ekylibre/plugin/base
  ekylibre/plugin/theme
  ekylibre/core/plugin
  ekylibre/access
  ekylibre/hook
  ekylibre/view
].each { |lib| require File.expand_path("../lib/#{lib}", __dir__) }
