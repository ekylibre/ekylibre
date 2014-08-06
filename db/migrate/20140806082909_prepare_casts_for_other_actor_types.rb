class PrepareCastsForOtherActorTypes < ActiveRecord::Migration

  def up
    # add_column :intervention_casts, :actor_type, :string
    add_column :intervention_casts, :nature, :string

    execute "UPDATE intervention_casts SET nature = 'product'"
    # execute "UPDATE intervention_casts SET actor_type = products.type FROM products WHERE products.id = actor_id"
    # execute "UPDATE intervention_casts SET actor_type = 'Product' WHERE actor_type IS NULL OR LENGTH(TRIM(actor_type)) <= 0"

    change_column_null :intervention_casts, :nature, false

    # change_column_type :crumbs, :accuracy, :decimal, precision: 19, scale: 4
    # change_column_null :crumbs, :user_id, true
    # add_reference :crumbs, :intervention_cast, index: true
  end

end
