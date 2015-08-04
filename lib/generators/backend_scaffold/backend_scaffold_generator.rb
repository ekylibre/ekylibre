class BackendScaffoldGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)
  include Rails::Generators::ResourceHelpers

  def create_route
    route("resources :#{plural_name}, concerns: [:list, :unroll]")
  end

  def create_model
    template('model.rb', File.join('app', 'models', "#{singular_table_name}.rb"))
  end

  def create_controller
    template('controller.rb', File.join('app', 'controllers', 'backend', "#{controller_file_name}_controller.rb"))
  end

  def create_views
    template('index.html.haml', File.join('app', 'views', 'backend', controller_file_name, 'index.html.haml'))
    template('show.html.haml',  File.join('app', 'views', 'backend', controller_file_name, 'show.html.haml'))
    template('_form.html.haml', File.join('app', 'views', 'backend', controller_file_name, '_form.html.haml'))
  end

  def create_fixtures
    template('fixtures.yml', File.join('test', 'fixtures', "#{table_name}.yml"))
  end

  def create_model_test
    template('model_test.rb', File.join('test', 'models', "#{singular_table_name}_test.rb"))
  end

  def create_controller_test
    template('controller_test.rb', File.join('test', 'controllers', 'backend', "#{table_name}_controller_test.rb"))
  end
end
