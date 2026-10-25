class AddBeneficiarySiretToInterventions < ActiveRecord::Migration[5.2]
  def change
    add_column :interventions, :beneficiary_siret, :string
  end
end
