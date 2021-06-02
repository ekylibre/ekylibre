class AddProviderOnProductions < ActiveRecord::Migration[5.0]
  def change
    unless column_exists? :activity_productions, :provider
      add_column :activity_productions, :provider, :jsonb, default: {}
    end
  end
end
