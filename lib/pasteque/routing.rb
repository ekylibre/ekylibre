require 'routing/params'

module Pasteque
  ACTION_MATCHINGS = {
    get: :show,
    getAll: :index,
    getAllShared: :index_shared,
    getCat: :category,
    getCategory: :category,
    getChildren: :children,
    getOpen: :open,
    getPM: :payment_method,
    getPrd: :product,
    getRes: :resource,
    getShared: :shared,
    getTop: :top,
    getMain: :main,
    delete: :destroy,
    delShared: :destroy_shared,
    updPwd: :update_password
  }.freeze
  module V5
    API = {
      AttributesAPI: [:getAll],
      CashesAPI: [:get, :update, :search, :zticket],
      CashMvtsAPI: [:move],
      CashRegistersAPI: [:get, :getAll],
      CategoriesAPI: [:get, :getChildren, :getAll],
      CompositionsAPI: [:getAll],
      CurrenciesAPI: [:get, :getMain, :getAll],
      CustomersAPI: [:get, :getAll, :getTop, :addPrepaid],
      DiscountProfilesAPI: [:getAll],
      ImagesAPI: [:getCat, :getPM, :getPrd, :getRes],
      LocationsAPI: [:get, :getAll],
      PlacesAPI: [:get, :getAll],
      ProductsAPI: [:get, :getAll, :getCategory],
      ResourcesAPI: [:get],
      RolesAPI: [:get, :getAll],
      StocksAPI: [:getAll],
      TariffAreasAPI: [:getAll],
      TaxesAPI: [:get, :getAll],
      TicketsAPI: [:getShared, :getAllShared, :delShared, :share, :save, :get, :getOpen, :search, :delete],
      UsersAPI: [:get, :getAll, :updPwd]
    }.stringify_keys.freeze
  end
  module V6
    API = {
      AttributesAPI: [:getAll],
      CashesAPI: [:get, :update, :search, :zticket],
      CashMvtsAPI: [:move],
      CashRegistersAPI: [:get, :getAll],
      CategoriesAPI: [:get, :getChildren, :getAll],
      CompositionsAPI: [:getAll],
      CurrenciesAPI: [:get, :getMain, :getAll],
      CustomersAPI: [:get, :getAll, :getTop, :addPrepaid],
      DiscountProfilesAPI: [:getAll],
      ImagesAPI: [:getCat, :getPM, :getPrd, :getRes],
      LocationsAPI: [:get, :getAll],
      PlacesAPI: [:get, :getAll],
      ProductsAPI: [:get, :getAll, :getCategory],
      ResourcesAPI: [:get],
      RolesAPI: [:get, :getAll],
      StocksAPI: [:getAll],
      TariffAreasAPI: [:getAll],
      TaxesAPI: [:get, :getAll],
      TicketsAPI: [:getShared, :getAllShared, :delShared, :share, :save, :get, :getOpen, :search],
      UsersAPI: [:get, :getAll, :updPwd]
    }.stringify_keys.freeze
  end
end

module ActionDispatch::Routing
  class Mapper
    def pasteque_v5
      pasteque(Pasteque::V5::API)
    end

    def pasteque_v6
      pasteque(Pasteque::V6::API)
    end

    protected

    def pasteque(apis)
      apis.each do |api, actions|
        actions.each do |action|
          controller_name = api.to_s.gsub(/API$/, '').underscore
          action_name = Pasteque::ACTION_MATCHINGS[action] || (action == :* ? :index : action.to_s.underscore)
          http_method = (action.to_s =~ /^(get|search|\*)/ ? :get : :post)
          send http_method, 'api.php', constraints: params(p: api.to_s, action: action.to_s), to: "#{controller_name}##{action_name}", format: false, defaults: { format: :json }
        end
      end
      get 'api.php', constraints: params(p: 'VersionAPI'), to: 'version#index', format: false, defaults: { format: :json }
    end
  end
end
