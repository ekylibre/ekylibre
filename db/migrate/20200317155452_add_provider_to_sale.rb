class AddProviderToSale < ActiveRecord::Migration
  def change
    %i[sales catalogs journals sale_natures product_natures product_nature_categories accounts product_nature_variants entities incoming_payments].each{|table_name| add_provider_to_(table_name)}
  end

  def add_provider_to_(table_name)
    add_column table_name, :provider, :jsonb

    reversible do |dir|
      dir.up do
        query("CREATE INDEX #{table_name.to_s.singularize}_provider_index ON #{table_name} USING gin ((provider -> 'vendor'), (provider -> 'name'), (provider -> 'id'))")
      end
      dir.down do
        query("DROP INDEX #{table_name.to_s.singularize}_provider_index")
      end
    end
  end
end
