class UpdateAdditiveProductNatureToAddCarePlantAbility < ActiveRecord::Migration
  def up
    execute "UPDATE product_natures SET lock_version = lock_version + 1, abilities_list = COALESCE(NULLIF(TRIM(abilities_list), '') || ', ') || 'care(plant)' WHERE reference_name = 'additive'"
  end
end
