class AddResponsibleOnParcels < ActiveRecord::Migration
  def change
    change_table :parcels do |t|
      t.references(:responsible, index: true)
    end
  end
end
