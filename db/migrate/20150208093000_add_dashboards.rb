class AddDashboards < ActiveRecord::Migration[4.2]
  def change
    create_table :dashboards do |t|
      t.references :owner,      null: false, index: true
      t.string :name, null: false
      t.text :description
      t.stamps
    end
  end
end
