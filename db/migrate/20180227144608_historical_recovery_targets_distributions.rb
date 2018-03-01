class HistoricalRecoveryTargetsDistributions < ActiveRecord::Migration
  def up
    products_without_production = LandParcel.where(activity_production_id: nil)

    ActivityProduction.all.each do |activity_production|
      language = activity_production.creator.language

      finded_land_parcel = products_without_production
                             .where("name like ?", "%#{activity_production.activity.name}%")
                             .where("name like ?", "%#{:rank.t(number: activity_production.rank_number, locale: language)}%")

      if finded_land_parcel.any?
        finded_land_parcel.first.update_attribute(:activity_production_id, activity_production.id)
      end
    end
  end

  def down
  end
end
