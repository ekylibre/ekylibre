require 'test_helper'
require 'ffaker'

module Api
  module V2
    class ProceduresControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      connect_with_token

      test 'index returns procedures' do
        get :index, params: {}
        assert_response :ok
        assert json_response.is_a?(Array)
        assert json_response.any? { |p| p['name'] == 'spraying' }
      end

      test 'show returns 404 for unknown procedure' do
        get :show, params: { id: 'does_not_exist_procedure' }
        assert_response :not_found
      end

      # Regression: handlers must be returned as detailed objects
      # (name + indicator + unit) so mobile clients send a valid
      # `quantity_handler` instead of guessing (cf. nil.unit bug from
      # quantity_handler: "area_density").
      test 'show exposes handler details (name, indicator, unit) for spraying' do
        get :show, params: { id: 'spraying' }
        assert_response :ok

        plant_medicine = find_parameter(json_response['parameters'], 'plant_medicine')
        assert plant_medicine, 'plant_medicine parameter missing'

        handlers = plant_medicine['handlers']
        assert handlers.is_a?(Array), 'handlers must be an array'
        assert handlers.all? { |h| h.is_a?(Hash) && h.key?('name') }, 'each handler must be an object with a name'

        by_name = handlers.index_by { |h| h['name'] }

        # population handler: name only, no indicator/unit
        assert by_name['population'], 'population handler missing'
        assert_not by_name['population'].key?('unit')
        assert_not by_name['population'].key?('indicator')

        # measure handler: name + indicator + unit
        vad = by_name['volume_area_density']
        assert vad, 'volume_area_density handler missing'
        assert_equal 'volume_area_density', vad['indicator']
        assert_equal 'liter_per_hectare', vad['unit']

        nm = by_name['net_mass']
        assert_equal 'net_mass', nm['indicator']
        assert_equal 'kilogram', nm['unit']

        # When a handler has no explicit `name` in the procedure XML, Procedo
        # defaults its name to the indicator (lib/procedo/xml.rb). All spraying
        # measure handlers are un-named, so name must equal indicator here.
        handlers.select { |h| h['indicator'].present? }.each do |h|
          assert_equal h['indicator'], h['name'],
                       "handler #{h.inspect} should have name == indicator"
        end
      end

      private

        # Depth-first lookup of a parameter by name across nested group parameters.
        def find_parameter(parameters, name)
          return nil unless parameters
          parameters.each do |param|
            return param if param['name'] == name
            if param['parameters']
              found = find_parameter(param['parameters'], name)
              return found if found
            end
          end
          nil
        end
    end
  end
end
