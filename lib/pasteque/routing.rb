require 'routing/params'

module ActionDispatch::Routing
  class Mapper

    def pasteque_v5

      action_matchings = {
        get: :show,
        getAll: :index,
        getAllShared: :index_shared,
        getCategory: :category,
        getChildren: :children,
        getOpen: :open,
        getShared: :shared,
        getTop: :top,
        getMain: :main,
        delete: :destroy,
        delShared: :destroy_shared,
        updPwd: :update_password
      }

      apis = {
        AttributesAPI: [:getAll],
        CashesAPI: [:get, :update, :search, :zticket],
        CashMvtsAPI: [:move],
        CashRegistersAPI: [:get, :getAll],
        CategoriesAPI: [:get, :getChildren, :getAll],
        CompositionsAPI: [:getAll],
        CurrenciesAPI: [:get, :getMain, :getAll],
        CustomersAPI: [:getAll, :getAll, :getTop, :addPrepaid],
        DiscountProfilesAPI: [:getAll],
        LocationsAPI: [:get, :getAll],
        PlacesAPI: [:get, :getAll],
        ProductsAPI: [:get, :getAll, :getCategory],
        ResourcesAPI: [:get],
        RolesAPI: [:get, :getAll],
        StocksAPI: [:getAll],
        TariffAreasAPI: [:getAll],
        TaxesAPI: [:get, :getAll],
        TicketsAPI: [:getShared, :getAllShared, :delShared, :share, :save, :get, :getOpen, :search, :delete],
        UsersAPI: [:get, :getAll, :updPwd],
        # VersionAPI: [:get]
      }.stringify_keys

      apis.each do |api, actions|
        actions.each do |action|
          controller_name = api.to_s.gsub(/API$/, '').underscore
          action_name = action_matchings[action] || (action == :* ? :index : action.to_s.underscore)
          http_method = (action.to_s =~ /^(get|search|\*)/ ? :get : :post)
          # puts "#{http_method} api.php?p=#{api}&action=#{action} => #{controller_name.red}##{action_name.to_s.yellow}"
          send http_method, "api.php", constraints: params(p: api.to_s, action: action.to_s), to: "#{controller_name}##{action_name}", format: false , defaults: {format: :json}
        end
      end
      get "api.php", constraints: params(p: "VersionAPI"), to: "version#index", format: false, defaults: {format: :json}

    end


  end
end


