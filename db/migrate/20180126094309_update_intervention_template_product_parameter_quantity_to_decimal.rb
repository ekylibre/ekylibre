class UpdateInterventionTemplateProductParameterQuantityToDecimal < ActiveRecord::Migration[4.2]
  def self.up
    change_column :intervention_template_product_parameters, :quantity, :decimal
  end

  def self.down
    change_column :intervention_template_product_parameters, :quantity, :integer
  end
end
