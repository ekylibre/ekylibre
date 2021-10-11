class AddProvidersOnProductions < ActiveRecord::Migration[4.2]
  def change
    add_column :products, :providers, :jsonb, default: {}
    add_column :activity_productions, :providers, :jsonb, default: {}
  end
end
