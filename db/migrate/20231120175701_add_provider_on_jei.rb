class AddProviderOnJei < ActiveRecord::Migration[5.2]
  def change
    add_provider_to :journal_entry_items
  end

  def add_provider_to(table_name)
    if column_exists? table_name, :provider
      remove_column table_name, :provider, :jsonb
      add_column table_name, :provider, :jsonb, default: {}
    else
      add_column table_name, :provider, :jsonb, default: {}
    end

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


