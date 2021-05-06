class AddProvidersToCrumbs < ActiveRecord::Migration[4.2]
  def change
    add_column :crumbs, :provider, :jsonb
    add_reference :crumbs, :ride, index: true
    add_foreign_key :crumbs, :rides
  end
end
