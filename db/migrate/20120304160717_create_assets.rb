require 'migration_helper'

class CreateAssets < ActiveRecord::Migration
  def change
    create_table :assets do |t|
      t.belongs_to :company,   :null=>false
      t.string  :name,         :null=>false
      t.text    :description
      t.date    :acquired_on,  :null=>false
      t.decimal :amount,       :null=>false
      t.string  :depreciation_method, :null=>false
      t.stamps
    end
  end
end
