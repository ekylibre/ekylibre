class RemoveVarietyFromInterventionParameter < ActiveRecord::Migration[5.0]
  def up

    execute <<~SQL
      UPDATE intervention_parameters
      SET specie_variety = json_build_object('specie_variety_name',variety)
      WHERE variety IS NOT NULL;
    SQL

    execute <<~SQL
      UPDATE products
      SET specie_variety = json_build_object('specie_variety_name', intervention_parameters.variety)
      FROM intervention_parameters
      WHERE intervention_parameters.product_id = products.id
        AND intervention_parameters.variety IS NOT NULL
        AND intervention_parameters.type = 'InterventionOutput';
    SQL

    remove_column :intervention_parameters, :variety

  end

  def down

    add_column :intervention_parameters, :variety, :string

    execute <<~SQL
      UPDATE intervention_parameters
      SET variety = specie_variety-> 'specie_variety_name'
      WHERE specie_variety-> 'specie_variety_name' IS NOT NULL;
    SQL

  end
end
