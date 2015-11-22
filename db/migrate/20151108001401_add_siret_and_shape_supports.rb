class AddSiretAndShapeSupports < ActiveRecord::Migration
  def change
    rename_column :entities, :siren, :siret
  end
end
