class HistoricalRecoveryTargetsDistributions < ActiveRecord::Migration
  def up
    products_without_production = LandParcel.where(activity_production_id: nil)

    ActivityProduction.all.each do |activity_production|
      language = activity_production.creator.language

      computed_support_name = []
      computed_support_name << activity_production.activity.name
      computed_support_name << activity_production.campaign.name if activity_production.campaign
      computed_support_name << :rank.t(number: activity_production.rank_number, locale: language)

      finded_land_parcel = products_without_production
                             .where("name like ?", "%#{computed_support_name.join(' ')}%")

      if finded_land_parcel.any?
        finded_land_parcel.first.update_attribute(:activity_production_id, activity_production.id)
      end
    end
  end

  def down
  end
end
