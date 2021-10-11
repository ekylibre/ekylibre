class AddOptionsToImports < ActiveRecord::Migration[4.2]
  def change
    add_column :imports, :options, :jsonb
  end
end
