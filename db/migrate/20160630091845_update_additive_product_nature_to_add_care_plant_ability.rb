class UpdateAdditiveProductNatureToAddCarePlantAbility < ActiveRecord::Migration
  def change

    abilities_string = select_value("SELECT abilities_list FROM product_natures WHERE reference_name = 'additive'")

    arr = WorkingSet::AbilityArray.load(abilities_string)
    arr << 'care(plant)'
    query =  "UPDATE product_natures SET lock_version = lock_version + 1, abilities_list = #{quote WorkingSet::AbilityArray.dump(arr)}"
    query << " WHERE reference_name = 'additive'"
    execute query
  end
end
