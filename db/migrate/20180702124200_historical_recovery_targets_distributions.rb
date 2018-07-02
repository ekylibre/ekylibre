class HistoricalRecoveryTargetsDistributions < ActiveRecord::Migration
  def up
    add_activity_production_to_land_parcels
    add_activity_production_to_plants
  end

  def down; end

  def add_activity_production_to_land_parcels
    products_without_production = LandParcel.where(activity_production_id: nil)

    ActivityProduction.all.each do |activity_production|
      language = activity_production.creator.language if activity_production.creator
      language ||= 'fra'

      finded_land_parcel = products_without_production
                           .where('name like ?', "%#{activity_production.activity.name}%")
                           .where('name like ?', "%#{:rank.t(number: activity_production.rank_number, locale: language)}%")

      if finded_land_parcel.any?
        finded_land_parcel.first.update_attribute(:activity_production_id, activity_production.id)
      end
    end
  end

  def add_activity_production_to_plants
    products_without_production = Plant.where(activity_production_id: nil)

    products_without_production.each do |product|
      intervention_group_parameters = product
                                      .intervention_product_parameters
                                      .select { |parameter| parameter.is_a?(InterventionOutput) }
                                      .first
                                      .intervention
                                      .group_parameters

      product_group_parameter = intervention_group_parameters
                                .select { |parameter| parameter.outputs.first.product_id == product.id }

      activity_production_id = product_group_parameter
                               .first
                               .targets
                               .select { |target| target.reference_name.to_sym == :land_parcel }
                               .first
                               .product
                               .activity_production_id

      product.update_attribute(:activity_production_id, activity_production_id) unless activity_production_id.nil?
    end
  end
end
