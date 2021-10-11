class CreateInterventionTemplateProductParameters < ActiveRecord::Migration
  def change
    unless table_exists?(:intervention_template_product_parameters)
      create_table :intervention_template_product_parameters do |t|
        t.references :intervention_template, index: { name: :intervention_template_id }, foreign_key: true
        t.references :product_nature, index: { name: :product_nature_id }, foreign_key: true
        t.references :product_nature_variant, index: { name: :product_nature_variant_id }, foreign_key: true
        t.references :activity, index: true, foreign_key: true
        t.integer :quantity
        t.string :unit
        t.string :type
        t.jsonb :procedure
        t.timestamps null: false
      end
    end
  end
end
