class AddAttributesToSaleOpportunities < ActiveRecord::Migration[4.2]
  def change
    add_reference :affairs, :provider, index: true
    add_foreign_key :affairs, :entities, column: :provider_id

    create_table :affair_labellings do |t|
      t.references :affair, null: false, index: true, foreign_key: true
      t.references :label, null: false, index: true, foreign_key: true
      t.stamps
      t.index %i[affair_id label_id], unique: true
    end

    create_table :affair_natures do |t|
      t.string :name, null: false, index: true
      t.text :description
      t.stamps
    end

    add_reference :affairs, :nature, index: true
    add_foreign_key :affairs, :affair_natures, column: :nature_id
  end
end
