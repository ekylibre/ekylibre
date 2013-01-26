class DropCompanies < ActiveRecord::Migration
  def up
    drop_table :companies
  end

  def down
    create_table "companies", :force => true do |t|
      t.string   "code",         :limit => 16,                :null => false
      t.text     "log"
      t.integer  "creator_id"
      t.datetime "created_at"
      t.integer  "updater_id"
      t.datetime "updated_at"
      t.integer  "lock_version",               :default => 0, :null => false
    end
    add_index "companies", ["code"], :name => "index_companies_on_code", :unique => true
  end
end
