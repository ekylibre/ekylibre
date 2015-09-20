class AddNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, index: true
      t.string :message,       null: false
      t.string :level,         null: false
      t.datetime :read_at
      t.references :target, polymorphic: true, index: true
      t.string :target_url
      t.json :interpolations
      t.stamps
      t.index :read_at
      t.index :level
    end
  end
end
