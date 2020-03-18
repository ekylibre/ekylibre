class AddProviderToSale < ActiveRecord::Migration
  def change
    add_column :sales, :provider, :jsonb

    reversible do |dir|
      dir.up do
        query("CREATE INDEX sale_provider_index ON sales USING gin ((provider -> 'vendor'), (provider -> 'name'), (provider -> 'id'))")
      end
      dir.down do
        query("DROP INDEX sale_provider_index")
      end
    end
  end
end
