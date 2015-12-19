class PrepareCastsForOtherActorTypes < ActiveRecord::Migration
  def up
    # add_column :intervention_parameters, :actor_type, :string
    add_column :intervention_parameters, :nature, :string

    execute "UPDATE intervention_parameters SET nature = 'product'"
    # execute "UPDATE intervention_parameters SET actor_type = products.type FROM products WHERE products.id = actor_id"
    # execute "UPDATE intervention_parameters SET actor_type = 'Product' WHERE actor_type IS NULL OR LENGTH(TRIM(actor_type)) <= 0"

    change_column_null :intervention_parameters, :nature, false
  end
end
