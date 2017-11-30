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
          next unless File.directory?(directory)
          load_plugin(directory)
        end
      end

      # Load a given plugin
      def load_plugin(path)
        plugfile = File.join(path, 'Plugfile')
        if File.file?(plugfile)
          plugin = new(plugfile)
          registered_plugins[plugin.name] = plugin
          Rails.logger.info "Load #{plugin.name} plugin"
        else
          Rails.logger.warn "No Plugfile found in #{path}"
        end
      end

      def load_integrations
        Dir.glob(File.join(directory, '*')).sort.each do |directory|
          next unless File.directory?(directory)
          Dir.glob(File.join(directory, 'app', 'integrations', '**', '*.rb')).sort.each do |integration|
            require integration
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
            script << "#= require #{path}\n"
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
              next unless addons[:stylesheets]
              addons[:stylesheets].each do |file|
                stylesheet << "@import \"#{file}\";\n"
              end
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
          plugin.initializers.each do |name, block|
            if block.is_a?(Pathname)
              Rails.logger.info "Require initializer #{name}"
              require block
            else
              Rails.logger.info "Run initialize #{name}"
              block.call(Rails.application)
            end
          end
        end
      end

      def after_login_plugin
        registered_plugins.values.detect(&:redirect_after_login?)
      end
      alias redirect_after_login? after_login_plugin

      # Call after_login_path on 'after login' plugin
      def after_login_path(resource)
        after_login_plugin.name.to_s.camelize.constantize.after_login_path(resource)
      end
    end

    attr_reader :root, :themes_assets, :routes, :javascripts, :initializers
    field_accessor :name, :summary, :description, :url, :author, :author_url, :version

    # Links plugin into app
    def initialize(plugfile_path)
      @root = Pathname.new(plugfile_path).dirname
      @view_path = @root.join('app', 'views')
      @themes_assets = {}.with_indifferent_access
      @javascripts = []
      @initializers = {}

      lib = @root.join('lib')
      if File.directory?(lib)
        $LOAD_PATH.unshift lib
        ActiveSupport::Dependencies.autoload_paths += [lib]
      end

      instance_eval(File.read(plugfile_path), plugfile_path, 1)

      if @name
        @name = @name.to_sym
      else
        raise "Need a name for plugin #{plugfile_path}"
      end
      raise "Plugin name cannot be #{@name}." if [:ekylibre].include?(@name)

      # Adds lib
      @lib_dir = @root.join('lib')
      if @lib_dir.exist?
        $LOAD_PATH.unshift(@lib_dir.to_s)
        require @name.to_s unless @required.is_a?(FalseClass)
      end

      # Adds rights
      @right_file = root.join('config', 'rights.yml')
      Ekylibre::Access.load_file(@right_file) if @right_file.exist?

      # Adds aggregators
      @aggregators_path = @root.join('config', 'aggregators')
      if @aggregators_path.exist?
        Aggeratio.load_path += Dir.glob(@aggregators_path.join('**', '*.xml'))
      end

      # Adds initializers
      @initializers_path = @root.join('config', 'initializers')
      if @initializers_path.exist?
        Dir.glob(@initializers_path.join('**', '*.rb')).each do |file|
          path = Pathname.new(file)
          @initializers[path.relative_path_from(@initializers_path).to_s] = path
        end
      end

      # Adds locales (translation and reporting)
      @locales_path = @root.join('config', 'locales')
      if @locales_path.exist?
        Rails.application.config.i18n.load_path += Dir.glob(@locales_path.join('**', '*.{rb,yml}'))
        DocumentTemplate.load_path << @locales_path
      end

      # Adds view path
      if @view_path.directory?
        ActionController::Base.prepend_view_path(@view_path)
        ActionMailer::Base.prepend_view_path(@view_path)
      end

      # Adds the app/{controllers,helpers,models} directories of the plugin to the autoload path
      Dir.glob File.expand_path(@root.join('app', '{controllers,exchangers,guides,helpers,inputs,integrations,jobs,mailers,models}')) do |dir|
        ActiveSupport::Dependencies.autoload_paths += [dir]
        $LOAD_PATH.unshift(dir) if Dir.exist?(dir)
      end

      # Load all exchanger
      Dir.glob(@root.join('app', 'exchangers', '**', '*.rb')).each do |path|
        require path
      end

      # Adds the app/{controllers,helpers,models} concerns directories of the plugin to the autoload path
      Dir.glob File.expand_path(@root.join('app', '{controllers,models}/concerns')) do |dir|
        ActiveSupport::Dependencies.autoload_paths += [dir]
      end

      # Load helpers
      helpers_path = @root.join('app', 'helpers')
      Dir.glob File.expand_path(helpers_path.join('**', '*.rb')) do |dir|
        helper_module = Pathname.new(dir).relative_path_from(helpers_path).to_s.gsub(/\.rb$/, '').camelcase
        initializer "include helper #{helper_module}" do
          ::ActionView::Base.send(:include, helper_module.constantize)
        end
      end

      # Adds assets
      if assets_directory.exist?
        # Emulate "subdir by plugin" config
        # plugins/<plugin>/app/assets/*/ => tmp/plugins/assets/*/plugins/<plugin>/
        Dir.chdir(assets_directory) do
          Dir.glob('*') do |type|
            unless Rails.application.config.assets.paths.include?(assets_directory.join(type).to_s)
              Rails.application.config.assets.paths << assets_directory.join(type).to_s
            end
            unless %w[javascript stylesheets].include? type
              files_to_compile = Dir[type + '/**/*'].select { |f| File.file? f }.map do |f|
                Pathname.new(f).relative_path_from(Pathname.new(type)).to_s unless f == type
              end
              Rails.application.config.assets.precompile += files_to_compile
            end
          end
        end
      end
    end

    # Accessors
    def redirect_after_login?
      @redirect_after_login
    end

    # TODO: externalize all following methods in a DSL module

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
        unless requirement =~ /\A((~>|>=|>|<|<=)\s+)?\d+.\d+(\.[a-z0-9]+)*\z/
          raise PluginRequirementError, "Invalid version requirement expression: #{requirement}"
        end
      end

      version = Ekylibre.version
      version = version.split(' - ').first if version.include?('-')

      unless Gem::Requirement.new(*requirements) =~ Gem::Version.create(version)
        raise PluginRequirementError, "Plugin (#{@name}) is incompatible with current version of app (#{Ekylibre.version} not #{requirements.inspect})"
      end
      true
    end

    # Adds a snippet in app (for side or help places)
    def snippet(name, options = {})
      Ekylibre::Snippet.add("#{@name}-#{name}", snippets_directory.join(name.to_s), options)
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

    def add_toolbar_addon(partial_path, options = {})
      # Config main toolbar by default because with current tools, no way to specify
      # which toolbar use when many in the same page.
      Ekylibre::View::Addon.add(:main_toolbar, partial_path, options)
    end

    def add_cobble_addon(partial_path, options = {})
      Ekylibre::View::Addon.add(:cobbler, partial_path, options)
    end

    # Adds menus with DSL in Ekylibre backend nav
    def extend_navigation(&block)
      Ekylibre::Navigation.exec_dsl(&block)
    end

    def initializer(name, &block)
      @initializers[name] = block
    end

    def register_manure_management_method(name, class_name)
      Calculus::ManureManagementPlan.register_method(name, class_name)
    end

    def subscribe(message, proc = nil, &block)
      Ekylibre::Hook.subscribe(message, proc, &block)
    end

    # Will call method MyPlugin.after_login_path to get url to redirect to
    # CAUTION: Only one plugin can use it. Only first plugin will be called
    # if many are using this directive.
    def redirect_after_login
      @redirect_after_login = true
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
