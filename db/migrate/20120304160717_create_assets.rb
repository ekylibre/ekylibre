class CreateAssets < ActiveRecord::Migration
  def change
    create_table :assets do |t|
      t.belongs_to :company,               :null=>false
      t.belongs_to :account,               :null=>false
      t.belongs_to :journal,               :null=>false
      t.belongs_to :currency,              :null=>false
      t.string     :name,                  :null=>false
      t.string     :number,                :null=>false
      t.text       :description
      t.text       :comment
      t.date       :purchased_on,          :null=>false
      t.belongs_to :purchase
      t.belongs_to :purchase_line
      t.boolean    :ceded
      t.date       :ceded_on
      t.belongs_to :sale
      t.belongs_to :sale_line
      t.decimal    :purchase_amount,       :null=>false, :precision=>16, :scale=>2
      # t.date       :depreciable_on,        :null=>false
      t.date       :started_on,            :null=>false
      t.date       :stopped_on,            :null=>false
      t.decimal    :depreciable_amount,    :null=>false, :precision=>16, :scale=>2
      t.decimal    :deprecated_amount,     :null=>false, :precision=>16, :scale=>2
      t.string     :depreciation_method,   :null=>false
      # t.integer    :depreciation_duration, :null=>false
    end
    add_stamps :assets
    add_index :assets, :company_id
    add_index :assets, :account_id
    add_index :assets, :journal_id
    add_index :assets, :currency_id
    add_index :assets, :purchase_id
    add_index :assets, :purchase_line_id
    add_index :assets, :sale_id
    add_index :assets, :sale_line_id

    create_table :asset_depreciations do |t|
      t.belongs_to :company,            :null=>false
      t.belongs_to :asset,              :null=>false
      t.belongs_to :journal_entry
      t.boolean    :accountable,        :null=>false, :default=>false
      t.date       :created_on,         :null=>false
      t.datetime   :accounted_at
      t.date       :started_on,         :null=>false
      t.date       :stopped_on,         :null=>false
      t.text       :depreciation
      t.decimal    :amount,             :null=>false, :precision=>16, :scale=>2
      t.integer    :position
    end
    add_stamps :asset_depreciations
    add_index :asset_depreciations, :company_id
    add_index :asset_depreciations, :asset_id
    add_index :asset_depreciations, :journal_entry_id

  end
end
