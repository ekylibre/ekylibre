module ActionDispatch::Routing
  class Mapper

    # This methods adds all plugin routes
    def plugins
      Ekylibre::Plugin.each do |plugin|
        if plugin.routes.present?
          instance_exec &plugin.routes
        end
      end
    end

  end
end
