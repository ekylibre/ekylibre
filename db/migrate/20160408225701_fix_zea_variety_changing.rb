class FixZeaVarietyChanging < ActiveRecord::Migration
  # change zea to zea_mays according to nomenclature for variant
  def up
    execute "UPDATE product_nature_variants v SET derivative_of = 'zea_mays' WHERE v.derivative_of = 'zea' and v.reference_name = 'coop:class_a_corn_grain'"
    execute "UPDATE product_nature_variants v SET variety = 'zea_mays' WHERE v.variety = 'zea' and v.reference_name = 'corn_crop'"
    execute "UPDATE product_nature_variants v SET derivative_of = 'zea_mays' WHERE v.derivative_of = 'zea' and v.reference_name = 'corn_grain'"
    execute "UPDATE product_nature_variants v SET variety = 'zea_mays' WHERE v.variety = 'zea' and v.reference_name = 'corn_grain_crop'"
    execute "UPDATE product_nature_variants v SET derivative_of = 'zea_mays' WHERE v.derivative_of = 'zea' and v.reference_name = 'corn_seed_25'"
    execute "UPDATE product_nature_variants v SET derivative_of = 'zea_mays' WHERE v.derivative_of = 'zea' and v.reference_name = 'corn_seed_50tg'"
    execute "UPDATE product_nature_variants v SET variety = 'zea_mays' WHERE v.variety = 'zea' and v.reference_name = 'corn_seed_crop'"
    execute "UPDATE product_nature_variants v SET derivative_of = 'zea_mays' WHERE v.derivative_of = 'zea' and v.reference_name = 'corn_silage'"
    execute "UPDATE product_nature_variants v SET variety = 'zea_mays' WHERE v.variety = 'zea' and v.reference_name = 'corn_silage_crop'"
  end

  def down
    execute "UPDATE product_nature_variants v SET derivative_of = 'zea' WHERE v.derivative_of = 'zea_mays' and v.reference_name = 'coop:class_a_corn_grain'"
    execute "UPDATE product_nature_variants v SET variety = 'zea' WHERE v.variety = 'zea_mays' and v.reference_name = 'corn_crop'"
    execute "UPDATE product_nature_variants v SET derivative_of = 'zea' WHERE v.derivative_of = 'zea_mays' and v.reference_name = 'corn_grain'"
    execute "UPDATE product_nature_variants v SET variety = 'zea' WHERE v.variety = 'zea_mays' and v.reference_name = 'corn_grain_crop'"
    execute "UPDATE product_nature_variants v SET derivative_of = 'zea' WHERE v.derivative_of = 'zea_mays' and v.reference_name = 'corn_seed_25'"
    execute "UPDATE product_nature_variants v SET derivative_of = 'zea' WHERE v.derivative_of = 'zea_mays' and v.reference_name = 'corn_seed_50tg'"
    execute "UPDATE product_nature_variants v SET variety = 'zea' WHERE v.variety = 'zea_mays' and v.reference_name = 'corn_seed_crop'"
    execute "UPDATE product_nature_variants v SET derivative_of = 'zea' WHERE v.derivative_of = 'zea_mays' and v.reference_name = 'corn_silage'"
    execute "UPDATE product_nature_variants v SET variety = 'zea' WHERE v.variety = 'zea_mays' and v.reference_name = 'corn_silage_crop'"
  end
end
