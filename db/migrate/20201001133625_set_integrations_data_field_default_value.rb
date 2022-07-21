class SetIntegrationsDataFieldDefaultValue < ActiveRecord::Migration[4.2]
  def change
    reversible do |dir|
      dir.up do 
        change_column_default :integrations, :data, {}
        execute <<-SQL
          UPDATE integrations
          SET data = '{}'
          WHERE data IS NULL
        SQL
      end
    end
  end
end