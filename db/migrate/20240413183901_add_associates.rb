class AddAssociates < ActiveRecord::Migration[5.2]
  def change
    create_table :associates do |t|
      t.decimal :share_unit_amount, precision: 19, scale: 4, null: false
      t.integer :share_quantity, default: 0, null: false
      t.references :associate_account, index: true
      t.references :entity, index: true, null: false
      t.string :currency, null: false
      t.text :description
      t.string :associate_nature
      t.date :started_on, null: false
      t.date :stopped_on
      t.jsonb :custom_fields, default: {}
      t.stamps
    end
  end
end


