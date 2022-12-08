class FixActivityOnDailyCharge < ActiveRecord::Migration[5.1]

  def up
    if connection.select_value("SELECT count(*) FROM daily_charges") > 0
      execute <<~SQL
        UPDATE daily_charges SET activity_id = (SELECT ap.activity_id FROM activity_productions ap WHERE ap.id = activity_production_id)
        WHERE activity_production_id IS NOT NULL
      SQL
    end
    if connection.select_value("SELECT count(*) FROM intervention_template_product_parameters") > 0

      execute <<~SQL
        DELETE FROM daily_charges
        WHERE intervention_template_product_parameter_id IN (SELECT id FROM intervention_template_product_parameters WHERE product_nature_variant_id IS NULL) 
      SQL

      execute <<~SQL
        DELETE FROM intervention_template_product_parameters
        WHERE product_nature_variant_id IS NULL
      SQL

      execute <<~SQL
        UPDATE intervention_template_product_parameters SET product_nature_id = (SELECT nature_id FROM product_nature_variants pnv WHERE pnv.id = product_nature_variant_id)
        WHERE product_nature_variant_id IS NOT NULL
      SQL
    end
  end

  def down
    #NOPE
  end
end
