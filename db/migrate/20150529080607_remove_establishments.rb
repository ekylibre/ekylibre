class RemoveEstablishments < ActiveRecord::Migration
  def up
    drop_table :establishments
    remove_column :users, :establishment_id
  end

  def down
    create_table "establishments", force: :cascade do |t|
      t.string   "name",                     null: false
      t.string   "code"
      t.text     "description"
      t.datetime "created_at",               null: false
      t.datetime "updated_at",               null: false
      t.integer  "creator_id"
      t.integer  "updater_id"
      t.integer  "lock_version", default: 0, null: false
    end
    add_index "establishments", ["created_at"], name: "index_establishments_on_created_at", using: :btree
    add_index "establishments", ["creator_id"], name: "index_establishments_on_creator_id", using: :btree
    add_index "establishments", ["updated_at"], name: "index_establishments_on_updated_at", using: :btree
    add_index "establishments", ["updater_id"], name: "index_establishments_on_updater_id", using: :btree
    add_column :users, :establishment_id, :integer
  end

end
