class AddCadastralRefUpdatedToCviCadastralPlant < ActiveRecord::Migration
  def change
    add_column :cvi_cadastral_plants, :cadastral_ref_updated, :boolean, default: false

    reversible do |dir|
      dir.down { execute('DROP VIEW IF EXISTS formatted_cvi_cadastral_plants') }
    end
  end
end
