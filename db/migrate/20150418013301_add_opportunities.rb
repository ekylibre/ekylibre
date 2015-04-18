class AddOpportunities < ActiveRecord::Migration
  def change

    create_table :opportunities do |t|
      t.references :responsible,       index: true, null: false
      t.references :affair,      index: true
      t.references :client,      index: true, null: false
      t.string     :name
      t.string     :number
      t.text       :description
      t.decimal    :pretax_amount,   default: 0.0, precision: 19, scale: 4
      t.datetime   :dead_line_at
      t.string     :currency
      t.string     :origin
      t.string     :state
      t.decimal    :probability,   default: 0.0, precision: 19, scale: 4
      t.stamps
      t.index      :name
    end

  end
end
