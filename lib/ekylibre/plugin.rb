# Inspired from Redmine and Discourse
# http://www.redmine.org/projects/redmine/repository/entry/trunk/lib/redmine/plugin.rb
module Ekylibre
  class PluginRequirementError < StandardError
  end

  class Plugin
    @registered_plugins = {}

    cattr_accessor :directory, :mirrored_assets_directory
    self.directory = Ekylibre.root.join('plugins')
    # Where the plugins assets are gathered for asset pipeline
    self.mirrored_assets_directory = Ekylibre.root.join('tmp', 'plugins', 'assets')

    # Returns a type (stylesheets, fonts...) directory for all plugins
    def self.type_assets_directory(type)
      mirrored_assets_directory.join(type)
    end

    class << self
      attr_accessor :registered_plugins

      def field_accessor(*names)
        class_eval do
          names.each do |name|
            define_method(name) do |*args|
              args.empty? ? instance_variable_get("@#{name}") : instance_variable_set("@#{name}", *args)
            end
          end
        end
      end

      # Load all plugins
      def load
        Dir.glob(File.join(directory, '*')).sort.each do |directory|
          if File.directory?(directory)
            lib = File.join(directory, 'lib')
            if File.directory?(lib)
              $LOAD_PATH.unshift lib
              ActiveSupport::Dependencies.autoload_paths += [lib]
            end
            initializer = File.join(directory, 'Plugfile')
            if File.file?(initializer)
              plugin = new(initializer)
              registered_plugins[plugin.name] = plugin
              Rails.logger.info "Load #{plugin.name} plugin"
            else
              Rails.logger.warn "No Plugfile found in #{directory}"
            end
          end
        end
      end

      # Adds hooks for plugins
      # Must be done after load
      def plug
        # Adds helper 'plugins' for routes
        require 'ekylibre/plugin/routing'
        # Generate themes files
        generate_themes_stylesheets
        # Generate JS file
        generate_javascript_index
        # Load initializers
        run_initializers
      end

      def each
        registered_plugins.each do |_key, plugin|
          yield plugin
        end
      end

      # Generate a javascript for all plugins which refes by theme to add addons import.
      # This way permit to use natural sprocket cache approach without ERB filtering
      def generate_javascript_index
        base_dir = Rails.root.join('tmp', 'plugins', 'javascript-addons')
        Rails.application.config.assets.paths << base_dir.to_s
        script = "# This files contains JS addons from plugins\n"
        each do |plugin|
          plugin.javascripts.each do |path|
            script << "#= require plugins/#{plugin.name}/#{path}\n"
          end
        end
        # <base_dir>/plugins.js.coffee
        file = base_dir.join('plugins.js.coffee')
        FileUtils.mkdir_p file.dirname
        File.write(file, script)
      end

      # Generate a stylesheet by theme to add addons import.
      # This way permit to use natural sprocket cache approach without ERB filtering
      def generate_themes_stylesheets
        base_dir = Rails.root.join('tmp', 'plugins', 'theme-addons')
        Rails.application.config.assets.paths << base_dir.to_s
        Ekylibre.themes.each do |theme|
          stylesheet = "// This files contains #{theme} theme addons from plugins\n\n"
          each do |plugin|
            plugin.themes_assets.each do |name, addons|
              next unless name == theme || name == '*' || (name.respond_to?(:match) && theme.match(name))
              stylesheet << "// #{plugin.name}\n"
              addons[:stylesheets].each do |file|
                stylesheet << "@import \"plugins/#{plugin.name}/#{file}\";"
              end if addons[:stylesheets]
            end
          end
          # <base_dir>/themes/<theme>/plugins.scss
          file = base_dir.join('themes', theme.to_s, 'plugins.scss')
          FileUtils.mkdir_p file.dirname
          File.write(file, stylesheet)
        end
      end

      # Run all initializers of plugins
      def run_initializers
        each do |plugin|
          plugin.initializers do |name, block|
            Rails.logger.info "Run initialize #{name}"
            block.call(Rails.application)
          end
        end
      end
    end

    attr_reader :root, :themes_assets, :routes, :javascripts, :initializers
    field_accessor :name, :summary, :description, :url, :author, :author_url, :version

    # Links plugin into app
    def initialize(plugfile_path)
      @root = Pathname.new(plugfile_path).dirname
      @themes_assets = {}.with_indifferent_access
      @javascripts = []
      @initializers = {}

      instance_eval(File.read(plugfile_path), plugfile_path, 1)

      if @name
        @name = @name.to_sym
      else
        fail "Need a name for plugin #{plugfile_path}"
      end
      fail "Plugin name cannot be #{@name}." if [:ekylibre].include?(@name)

      # Adds lib
      @lib_dir = @root.join('lib')
      if @lib_dir.exist?
        $LOAD_PATH.unshift(@lib_dir.to_s)
        require @name.to_s unless @required.is_a?(FalseClass)
      end

      # Adds rights
      @right_file = root.join('config', 'rights.yml')
      Ekylibre::Access.load_file(@right_file) if @right_file.exist?

      # Adds locales
      Rails.application.config.i18n.load_path += Dir.glob(@root.join('config', 'locales', '**', '*.{rb,yml}'))

      # Adds view path
      @view_path = @root.join('app', 'views')
      if @view_path.directory?
        ActionController::Base.prepend_view_path(@view_path)
        ActionMailer::Base.prepend_view_path(@view_path)
      end

      # Adds the app/{controllers,helpers,models} directories of the plugin to the autoload path
      Dir.glob File.expand_path(@root.join('app', '{controllers,helpers,models,jobs,mailers,inputs,guides}')) do |dir|
        ActiveSupport::Dependencies.autoload_paths += [dir]
      end

      # Adds assets
      if assets_directory.exist?
        # Emulate "subdir by plugin" config
        # plugins/<plugin>/app/assets/*/ => tmp/plugins/assets/*/plugins/<plugin>/
        Dir.chdir(assets_directory) do
          Dir.glob('*') do |type|
            type_dir = self.class.type_assets_directory(type)
            plugin_type_dir = type_dir.join('plugins', @name.to_s) # mirrored_assets_directory(type)
            FileUtils.rm_rf plugin_type_dir
            FileUtils.mkdir_p(plugin_type_dir.dirname) unless plugin_type_dir.dirname.exist?
            FileUtils.ln_sf(assets_directory.join(type).relative_path_from(plugin_type_dir.dirname), plugin_type_dir)
            unless Rails.application.config.assets.paths.include?(type_dir.to_s)
              Rails.application.config.assets.paths << type_dir.to_s
            end
          end
        end
      end
    end

    def app_version
      Ekylibre.version
    end

    # def gem
    # end

    # def plugin
    # end

    # Require app version, used for compatibility
    # app '1.0.0'
    # app '~> 1.0.0'
    # app '> 1.0.0'
    # app '>= 1.0.0', '< 2.0'
    def app(*requirements)
      options = requirements.extract_options!
      requirements.each do |requirement|
        unless requirement =~ /\A((~>|>=|>|<|<=)\s+)?\d.\d(\.[a-z0-9]+)*\z/
          fail PluginRequirementError, "Invalid version requirement expression: #{requirement}"
        end
      end
      unless Gem::Requirement.new(*requirements) =~ Gem::Version.create(Ekylibre.version)
        fail PluginRequirementError, "Plugin (#{@name}) is incompatible with current version of app (#{Ekylibre.version} not #{requirements.inspect})"
      end
      true
    end

    # Adds a snippet in app (for side or help places)
    def add_snippet(name, options = {})
      Ekylibre::Snippet.add("#{@name}-#{name}", snippets_directory.join(name), options)
    end

    # Require a JS file from application.js
    def require_javascript(path)
      @javascripts << path
    end

    # Adds a snippet in app (for side or help places)
    def add_stylesheet(name)
      Rails.application.config.assets.precompile << "plugins/#{@name}/#{name}"
    end

    # Adds a stylesheet inside a given theme
    def add_theme_stylesheet(theme, file)
      add_theme_asset(theme, file, :stylesheets)
    end

    # Adds routes to access controllers
    def add_routes(&block)
      @routes = block
    end

    # Adds menus with DSL in Ekylibre backend nav
    def extend_navigation(&block)
      Ekylibre::Navigation.exec_dsl(&block)
    end

    def initializer(name, &block)
      @initializers[name] = block
    end

    # TODO: Add other callback for plugin integration
    # def add_cell
    # end

    # def add_theme(name)
    # end

    private

    def snippets_directory
      @view_path.join('snippets')
    end

    def assets_directory
      @root.join('app', 'assets')
    end

    def themes_directory
      @root.join('app', 'themes')
    end

    def add_theme_asset(theme, file, type)
      @themes_assets[theme] ||= {}
      @themes_assets[theme][type] ||= []
      @themes_assets[theme][type] << file
    end
  end
end
