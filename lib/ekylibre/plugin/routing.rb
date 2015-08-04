module ActionDispatch::Routing
  class Mapper
    # This methods adds all plugin routes
    def plugins
      Ekylibre::Plugin.each do |plugin|
        instance_exec &plugin.routes if plugin.routes.present?
      end
    end
  end
end
