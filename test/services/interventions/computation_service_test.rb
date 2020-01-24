require 'test_helper'

module Interventions
  class ComputationServiceTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures

    test 'computation of simple intervention' do

      input_product = create(:fertilizer_product)
      input_product.variant.read!(:net_volume, '1 liter')

      ewkt = "SRID=4326;MultiPolygon (((-1.017533540725708 44.23605999218229, -1.0204195976257324 44.236744122959124, -1.0197114944458008 44.238758034804555, -1.0165786743164062 44.238143107200145, -1.017533540725708 44.23605999218229)))"

      target_product = create(:corn_plant, initial_shape: Charta.new_geometry(ewkt))


      tool_product = create(:tractor)

      attributes = {
        procedure_name: "spraying",
        working_periods_attributes: [
          {
            started_at: (Time.zone.now + 1.hour).localtime.strftime("%Y-%m-%d %H:%M"),
            stopped_at: (Time.zone.now + 2.hours).localtime.strftime("%Y-%m-%d %H:%M")
          }
        ],
        targets_attributes: [
          {
            reference_name: "cultivation",
            product_id: target_product.id,
            dead: "false"
          }
        ],
        inputs_attributes: [
          {
            reference_name: "plant_medicine",
            product_id: input_product.id,
            quantity_value: "21",
            quantity_handler: "volume_area_density"
          }
        ],
        tools_attributes: [
          {
            reference_name: "tractor",
            product_id: tool_product.id
          }
        ]
      }.with_indifferent_access

      options = {
        auto_calculate_working_periods: true,
        nature: :record,
        state: :done
      }

      @attributes = Interventions::Computation::Compute
                            .new(parameters: attributes)
                            .perform(options: options)

      assert @attributes.present?
      assert @attributes.key? :procedure_name
    end

    test 'computation of complex intervention' do

      ## seed
      input_product = create(:seed_product)
      input_product.variant.read!(:net_mass, '2000 kilogram')

      ## land parcel
      ewkt = "SRID=4326;MultiPolygon (((-1.017533540725708 44.23605999218229, -1.0204195976257324 44.236744122959124, -1.0197114944458008 44.238758034804555, -1.0165786743164062 44.238143107200145, -1.017533540725708 44.23605999218229)))"

      target_product = create(:land_parcel, initial_shape: Charta.new_geometry(ewkt))

      ## tractor
      tool_product = create(:tractor)

      ## plant
      output_variant = create(:corn_plant_variant)

      attributes = {
        procedure_name: "sowing",
        working_periods_attributes: [
          {
            started_at: (Time.zone.now + 1.hour).localtime.strftime("%Y-%m-%d %H:%M"),
            stopped_at: (Time.zone.now + 2.hours).localtime.strftime("%Y-%m-%d %H:%M")
          }
        ],

        group_parameters_attributes: [{
          reference_name: 'zone',
          targets_attributes: [{
            product_id: target_product.id,
            reference_name: 'land_parcel'
          }],
          outputs_attributes: [{
            variant_id: output_variant.id,
            reference_name: 'plant'
          }]
        }],
        inputs_attributes: [
          {
            reference_name: "seeds",
            product_id: input_product.id,
            quantity_value: "20",
            quantity_handler: "mass_area_density"
          }
        ],
        tools_attributes: [
          {
            reference_name: "tractor",
            product_id: tool_product.id
          }
        ]

      }.with_indifferent_access

      options = {
        auto_calculate_working_periods: true,
        nature: :record,
        state: :done
      }

      @attributes = Interventions::Computation::Compute
                            .new(parameters: attributes)
                            .perform(options: options)

      assert @attributes.present?
      assert @attributes.key? :procedure_name
    end
  end
end
