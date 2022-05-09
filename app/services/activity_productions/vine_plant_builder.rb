# frozen_string_literal: true

module ActivityProductions
  # Build vine_plant from activity_production if not exist
  class VinePlantBuilder
    def initialize(activity_production, campaign)
      @activity_production = activity_production
      @campaign = campaign
    end

    def create_vine_plant_from_production
      return 'Plant already exist for this activity production' if Plant.where(activity_production_id: @activity_production.id).any?

      vine_variety_name = 'Cépage non défini'

      plant_name = @activity_production.custom_name + " | #{vine_variety_name}"
      plant_with_same_name = Plant.where('name like ?', "#{plant_name}%").count
      plant_name += " n° #{plant_with_same_name + 1}" if plant_with_same_name.positive?

      # change when Lexicon is OK
      variant = ProductNatureVariant.import_from_nomenclature(:vine_grape_crop)
      start_at = Time.zone.local(@campaign.harvest_year, 1, 1)

      plant = Plant.create!(variant_id: variant.id,
                            name: plant_name,
                            initial_born_at: start_at,
                            initial_shape: @activity_production.support_shape,
                            specie_variety: { specie_variety_name: vine_variety_name,
                                              specie_variety_uuid: '',
                                              specie_variety_providers: '' },
                            type_of_occupancy: :owner,
                            initial_owner: Entity.of_company,
                            activity_production_id: @activity_production.id)
      plant.read!(:rows_interval, Measure.new(200, :centimeter), at: start_at)
      plant.read!(:plants_interval, Measure.new(100, :centimeter), at: start_at)
      plant.read!(:certification_label, 'Non défini', at: start_at)
      plant.read!(:missing_vine_stock, 0, at: start_at)
      plant.read!(:shape, @activity_production.support_shape, at: start_at, force: true)
      plant.reload
      plant.read!(:plants_count, plant.estimated_vine_stock(at: start_at), at: start_at)
      plant
    end

  end
end
