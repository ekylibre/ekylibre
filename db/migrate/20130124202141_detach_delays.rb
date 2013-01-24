class DetachDelays < ActiveRecord::Migration
  COLUMNS = {
    :entities => {
      :payment_delay_id => :payment_delay
    },
    :sales => {
      :expiration_id => :expiration_delay,
      :payment_delay_id => :payment_delay
    },
    :sale_natures => {
      :expiration_id => :expiration_delay,
      :payment_delay_id => :payment_delay
    }
  }

  def up
    for table, renamings in COLUMNS
      for old_column, new_column in renamings
        add_column table, new_column, :string
        execute("UPDATE #{quoted_table_name(table)} SET #{new_column} = d.expression FROM #{quoted_table_name(:delays)} AS d WHERE d.id = #{old_column}")
        ref = columns(table).select{|c| c.name.to_s == old_column.to_s}.first
        change_column_null table, new_column, ref.null
        remove_column table, old_column
      end
    end
    drop_table :delays
  end

  def down
    create_table "delays", :force => true do |t|
      t.string   "name",                           :null => false
      t.boolean  "active",       :default => true, :null => false
      t.string   "expression",                     :null => false
      t.text     "comment"
      t.datetime "created_at",                     :null => false
      t.datetime "updated_at",                     :null => false
      t.integer  "creator_id"
      t.integer  "updater_id"
      t.integer  "lock_version", :default => 0,    :null => false
    end
    add_index "delays", ["created_at"], :name => "index_delays_on_created_at"
    add_index "delays", ["creator_id"], :name => "index_delays_on_creator_id"
    add_index "delays", ["updated_at"], :name => "index_delays_on_updated_at"
    add_index "delays", ["updater_id"], :name => "index_delays_on_updater_id"


    for table, renamings in COLUMNS
      for new_column, old_column in renamings
        execute("INSERT INTO #{quoted_table_name(:delays)} (name, expression, created_at, updated_at) SELECT DISTINCT #{old_column}, #{old_column}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM #{quoted_table_name(table)} WHERE #{old_column} NOT IN (SELECT expression FROM #{quoted_table_name(:delays)})")
        add_column table, new_column, :integer
        execute("UPDATE #{quoted_table_name(table)} SET #{new_column} = d.id FROM #{quoted_table_name(:delays)} AS d WHERE d.expression = #{old_column}")
        ref = columns(table).select{|c| c.name.to_s == old_column.to_s}.first
        change_column_null table, new_column, ref.null
        remove_column table, old_column
      end
    end
  end
end
