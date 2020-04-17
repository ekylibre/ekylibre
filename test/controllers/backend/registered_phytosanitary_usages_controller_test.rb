require 'test_helper'

module Backend
  class RegisteredPhytosanitaryUsagesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures

    setup do
      @land_parcel = create :lemon_land_parcel, born_at: DateTime.new(2018, 1, 1)
      @product = create :phytosanitary_product, variant: ProductNatureVariant.find_by_reference_name('2000087_copless')
      @usage = RegisteredPhytosanitaryUsage.find('20191211165323116925')
      2.times { |index| create_intervention(index) }
      user_sign_in
    end

    test 'get_usage_infos returns correct data according to the usage provided' do
      get :get_usage_infos, id: @usage.id, targets_data: { '0' => { id: @land_parcel.id, shape: @land_parcel.shape.to_json_feature_collection.to_json } }
      json = JSON.parse(response.body)

      assert_equal json['usage_infos']['applications_count'], @usage.applications_count
    end

    test 'get_usage_infos allows the user to select a usage if its maximum amount of applications has not been reached' do
      get :get_usage_infos, id: @usage.id, targets_data: { '0' => { id: @land_parcel.id, shape: @land_parcel.shape.to_json_feature_collection.to_json } }
      json = JSON.parse(response.body)

      assert json['usage_application'].has_key?('go')
    end

    test 'get_usage_infos warns the user when selecting a usage if its maximum amount of applications has been reached' do
      create_intervention(2)

      get :get_usage_infos, id: @usage.id, targets_data: { '0' => { id: @land_parcel.id, shape: @land_parcel.shape.to_json_feature_collection.to_json } }
      json = JSON.parse(response.body)

      assert json['usage_application'].has_key?('caution')
    end

    test 'get_usage_infos warns the user when selecting a usage if its maximum amount of applications has been exceeded' do
      [2, 3].each { |i| create_intervention(i) }

      get :get_usage_infos, id: @usage.id, targets_data: { '0' => { id: @land_parcel.id, shape: @land_parcel.shape.to_json_feature_collection.to_json } }
      json = JSON.parse(response.body)

      assert json['usage_application'].has_key?('stop')
    end

    test 'get_usage_infos does not take into consideration the intervention being edited when computing a usage amount of applications' do
      interventions = [2, 3].map { |i| create_intervention(i) }

      get :get_usage_infos, id: @usage.id,
                            intervention_id: interventions.last.id,
                            targets_data: { '0' => { id: @land_parcel.id, shape: @land_parcel.shape.to_json_feature_collection.to_json } }
      json = JSON.parse(response.body)

      assert json['usage_application'].has_key?('caution')
    end

    cases = [%w[allows inferior 3.2 go], %w[warns equal 3.3 caution], %w[forbids superior 3.4 stop]]
    cases.each do |(verb, comparator, quantity, status)|
      test "dose_validations #{verb} input quantity if it is #{comparator} to usage maximum dose" do
        get :dose_validations, id: @usage.id,
                               product_id: @product.id,
                               dimension: 'mass_area_density',
                               quantity: quantity,
                               targets_data: { '0' => { id: @land_parcel.id, shape: @land_parcel.shape.to_json_feature_collection.to_json } }
        json = JSON.parse(response.body)

        assert json['dose_validation'].has_key?(status)
      end
    end

    %w[population net_mass].each do |dimension|
      test "dose_validations correctly handles conversion from #{dimension} to mass_area_density" do
        surface = Measure.new(@land_parcel.shape.area, :square_meter).in(:hectare)
        max_dose = (surface * @usage.dose_quantity).to_d
        max_dose = max_dose / @product.net_mass.in(:kilogram).to_d if dimension == 'population'

        [%w[- go], %w[+ stop]].each do |(operator, status)|
          get :dose_validations, id: @usage.id,
                                 product_id: @product.id,
                                 dimension: dimension,
                                 quantity: max_dose.send(operator, 0.01),
                                 targets_data: { '0' => { id: @land_parcel.id, shape: @land_parcel.shape.to_json_feature_collection.to_json } }
          json = JSON.parse(response.body)

          assert json['dose_validation'].has_key?(status)
        end
      end
    end

    test 'user modifications tracking returns false if quantity or dimension values are changed' do
      intervention = create_intervention(2)

      get :dose_validations, id: @usage.id,
                             product_id: @product.id,
                             dimension: 'population',
                             quantity: 1,
                             targets_data: { '0' => { id: @land_parcel.id, shape: @land_parcel.shape.to_json_feature_collection.to_json } },
                             intervention_id: intervention.id,
                             input_id: intervention.inputs.order(:id).last.id
      json = JSON.parse(response.body)

      refute json['modified']
    end

    test 'user modifications tracking returns true if product, usage or target values are changed' do
      intervention = create_intervention(2)

      cases = [[RegisteredPhytosanitaryUsage.first, @product, @land_parcel], [@usage, Product.first, @land_parcel], [@usage, @product, LandParcel.first]]

      cases.each do |(usage, product, land_parcel)|
        get :dose_validations, id: usage.id,
                               product_id: product.id,
                               dimension: 'mass_area_density',
                               quantity: 2,
                               targets_data: { '0' => { id: land_parcel.id, shape: land_parcel.shape.to_json_feature_collection.to_json } },
                               intervention_id: intervention.id,
                               input_id: intervention.inputs.order(:id).last.id
        json = JSON.parse(response.body)

        assert json['modified']
      end
    end

    test 'authorizations are computed based on saved reference_data if there is no major user modification in the form' do
      intervention = create_intervention(2)
      input = intervention.inputs.order(:id).last
      dose_max = @usage.dose_quantity

      get :dose_validations, id: @usage.id,
                             product_id: @product.id,
                             dimension: 'mass_area_density',
                             quantity: dose_max - 0.01,
                             targets_data: { '0' => { id: @land_parcel.id, shape: @land_parcel.shape.to_json_feature_collection.to_json } },
                             intervention_id: intervention.id,
                             input_id: input.id
      json = JSON.parse(response.body)

      refute json['modified']
      assert json['dose_validation'].has_key?('go')

      input.reference_data['usage']['dose_quantity'] = dose_max - 0.02
      input.save!

      get :dose_validations, id: @usage.id,
                             product_id: @product.id,
                             dimension: 'mass_area_density',
                             quantity: dose_max - 0.01,
                             targets_data: { '0' => { id: @land_parcel.id, shape: @land_parcel.shape.to_json_feature_collection.to_json } },
                             intervention_id: intervention.id,
                             input_id: input.id
      json = JSON.parse(response.body)

      refute json['modified']
      assert json['dose_validation'].has_key?('stop')
    end

    private

      def user_sign_in
        user = User.find_by(administrator: true)
        sign_in(user)
      end

      def create_intervention(index)
        started_at = DateTime.new(2018, 1, 1) + index.days
        intervention = create :intervention, :spraying, started_at: started_at, stopped_at: started_at + 1.hour
        create :intervention_target, :with_cultivation, intervention: intervention, product: @land_parcel
        create :phyto_intervention_input, intervention: intervention, product: @product, usage: @usage
        intervention
      end
  end
end
