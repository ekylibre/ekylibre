require 'test_helper'
module Api
  module V1
    class ProductsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      connect_with_token

      setup do
        [Crumb, InterventionWorkingPeriod, InterventionParticipation, ParcelItemStoring, Product, Equipment, Worker, LandParcel, BuildingDivision, Plant].each(&:delete_all)
      end

      test 'create and get all products' do
        add_auth_header
        create_list(:equipment, 10)
        create_list(:worker, 10)
        create_list(:land_parcel, 10)
        create_list(:building_division, 10)
        # Corn plant create an additionnal land_parcel product so we count 2 products for each corn plant
        create_list(:corn_plant, 10)
        get :index
        products = JSON.parse response.body
        assert_equal 60, products.count
        assert_response :ok
      end

      test 'create and get product of a given type' do
        add_auth_header

        create_list(:worker, 10, updated_at: '15/12/2016')
        create_list(:equipment, 10, updated_at: '15/12/2016')

        # create_list(:worker, 10, updated_at: '05/01/2017')
        # create_list(:equipment, 10, updated_at: '05/01/2017')
        # create_list(:land_parcel, 5, updated_at: '05/01/2017')
        # create_list(:building_division, 10, updated_at: '05/01/2017')
        # Corn plant create an additionnal land_parcel product so we count 2 products for each corn plant
        # create_list(:corn_plant, 10, updated_at: '05/01/2017')

        modified_since = DateTime.parse('2017-01-01 05:00')

        types = %w(Worker Equipment LandParcel BuildingDivision Plant)
        types.each do |type|
          create_list(type.underscore.to_sym, 10, updated_at: '05/01/2017')

          get :index, product_type: type.underscore.pluralize, modified_since: modified_since

          products = JSON.parse response.body
          p type

          assert_equal 10, products.count
        end

        assert_response :ok
      end

      test 'get records from a given date' do
        add_auth_header
        create_list(:worker, 10, updated_at: '15/12/2016')
        create_list(:worker, 5, updated_at: '05/01/2017')
        modified_since = '01/01/2017'
        get :index, modified_since: modified_since
        products = JSON.parse response.body
        assert_equal 5, products.count
        assert_response :ok
      end
    end
  end
end
