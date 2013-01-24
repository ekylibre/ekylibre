class CreateAffairs < ActiveRecord::Migration
  TABLES = [:sales, :purchases, :incoming_payments, :outgoing_payments, :transfers]

  def up
    create_table :affairs do |t|
      t.belongs_to :origin, :polymorphic => true, :null => false
      t.boolean  :closed,   :null => false, :default => false
      t.datetime :closed_at
      t.string   :currency,  :null => false, :limit => 3
      t.decimal  :debit, :precision => 19, :scale => 4, :null => false, :default => 0.0
      t.decimal  :credit, :precision => 19, :scale => 4, :null => false, :default => 0.0
      t.datetime :accounted_at
      t.belongs_to :journal_entry
      t.stamps
    end
    add_stamps_indexes :affairs

    add_column :incoming_payments, :currency, :string, :limit => 3
    add_column :incoming_payments, :downpayment, :boolean, :null => false, :default => true
    execute("UPDATE #{quoted_table_name(:incoming_payments)} SET currency = c.currency FROM #{quoted_table_name(:incoming_payment_modes)} AS ipm JOIN #{quoted_table_name(:cashes)} AS c ON (c.id = ipm.cash_id) WHERE ipm.id = mode_id")
    execute("UPDATE #{quoted_table_name(:incoming_payments)} SET downpayment = #{quoted_true} FROM #{quoted_table_name(:incoming_payment_uses)} AS ipu WHERE ipu.payment_id = #{quoted_table_name(:incoming_payments)}.id AND ipu.downpayment AND ipu.amount = #{quoted_table_name(:incoming_payments)}.amount")
    change_column_null :incoming_payments, :currency, false

    add_column :outgoing_payments, :currency, :string, :limit => 3
    add_column :outgoing_payments, :downpayment, :boolean, :null => false, :default => true
    execute("UPDATE #{quoted_table_name(:outgoing_payments)} SET currency = c.currency FROM #{quoted_table_name(:outgoing_payment_modes)} AS ipm JOIN #{quoted_table_name(:cashes)} AS c ON (c.id = ipm.cash_id) WHERE ipm.id = mode_id")
    execute("UPDATE #{quoted_table_name(:outgoing_payments)} SET downpayment = #{quoted_true} FROM #{quoted_table_name(:outgoing_payment_uses)} AS opu WHERE opu.payment_id = #{quoted_table_name(:outgoing_payments)}.id AND opu.downpayment AND opu.amount = #{quoted_table_name(:outgoing_payments)}.amount")
    change_column_null :outgoing_payments, :currency, false

    add_column :transfers, :currency, :string, :limit => 3
    execute("UPDATE #{quoted_table_name(:transfers)} SET currency = 'EUR'")
    change_column_null :transfers, :currency, false

    for table in TABLES
      deal = table.to_s.singularize
      add_column table, :affair_id, :integer
      add_column table, :initial_affair_id, :integer
      da = {:origin_type => "'#{table.to_s.classify}'", :origin_id => :id, :currency => :currency, :debit => (table == :sales ? "CASE WHEN credit THEN #{deal}.amount ELSE 0 END" : [:purchases, :incoming_payments].include?(table) ? "#{deal}.amount" : "0"), :credit => (table == :sales ? "CASE WHEN credit THEN 0 ELSE #{deal}.amount END" : [:purchases, :incoming_payments].include?(table) ? "0" : "#{deal}.amount"), :created_at => :created_at, :creator_id => :creator_id, :lock_version => :lock_version, :updated_at => :updated_at, :updater_id => :updater_id}
      execute("INSERT INTO #{quoted_table_name(:affairs)} (" + da.keys.join(', ') + ") SELECT " + da.values.join(', ') + " FROM #{quoted_table_name(table)} AS #{deal}")
      execute("UPDATE #{quoted_table_name(table)} SET affair_id = dg.id, initial_affair_id = dg.id FROM #{quoted_table_name(:affairs)} AS dg WHERE dg.origin_type = '#{table.to_s.classify}' AND dg.origin_id = #{quoted_table_name(table)}.id")
      add_index table, :affair_id
    end

    # Merge incoming_payment_uses
    for expense_type in ["Sale", "Transfer"]
      # Add payments to existing groups
      execute("UPDATE #{quoted_table_name(:incoming_payments)} SET affair_id = e.affair_id FROM #{quoted_table_name(:incoming_payment_uses)} AS ipu JOIN #{quoted_table_name(expense_type.tableize)} AS e ON (e.id = ipu.expense_id AND ipu.expense_type = '#{expense_type}') WHERE ipu.payment_id = #{quoted_table_name(:incoming_payments)}.id")
      # Refresh debit/credit of groups
      execute("UPDATE #{quoted_table_name(:affairs)} SET debit = #{quoted_table_name(:affairs)}.debit + ip.amount FROM #{quoted_table_name(:incoming_payments)} AS ip WHERE ip.affair_id = #{quoted_table_name(:affairs)}.id AND ip.affair_id != ip.initial_affair_id")
    end

    # Merge outgoing_payment_uses
    execute("UPDATE #{quoted_table_name(:outgoing_payments)} SET affair_id = e.affair_id FROM #{quoted_table_name(:outgoing_payment_uses)} AS opu JOIN #{quoted_table_name(:purchases)} AS e ON (e.id = opu.expense_id) WHERE opu.payment_id = #{quoted_table_name(:outgoing_payments)}.id")
    execute("UPDATE #{quoted_table_name(:affairs)} SET credit = #{quoted_table_name(:affairs)}.credit + op.amount FROM #{quoted_table_name(:outgoing_payments)} AS op WHERE op.affair_id = #{quoted_table_name(:affairs)}.id AND op.affair_id != op.initial_affair_id")

    # Merge sale credits
    execute("UPDATE #{quoted_table_name(:sales)} SET affair_id = os.affair_id FROM #{quoted_table_name(:sales)} AS os WHERE #{quoted_table_name(:sales)}.credit AND os.id = #{quoted_table_name(:sales)}.origin_id")
    execute("UPDATE #{quoted_table_name(:affairs)} SET debit = #{quoted_table_name(:affairs)}.debit + sc.amount FROM #{quoted_table_name(:sales)} AS sc WHERE sc.credit AND sc.affair_id = #{quoted_table_name(:affairs)}.id AND sc.affair_id != sc.initial_affair_id")


    # Updates deals state
    execute("UPDATE #{quoted_table_name(:affairs)} SET closed = #{quoted_true}, closed_at = ipu.updated_at FROM #{quoted_table_name(:incoming_payments)} AS ip JOIN #{quoted_table_name(:incoming_payment_uses)} AS ipu ON (ip.id = ipu.payment_id) WHERE NOT closed AND ip.affair_id = #{quoted_table_name(:affairs)}.id AND debit = credit")
    execute("UPDATE #{quoted_table_name(:affairs)} SET closed = #{quoted_true}, closed_at = opu.updated_at FROM #{quoted_table_name(:outgoing_payments)} AS op JOIN #{quoted_table_name(:outgoing_payment_uses)} AS opu ON (op.id = opu.payment_id) WHERE NOT closed AND op.affair_id = #{quoted_table_name(:affairs)}.id AND debit = credit")
    execute("UPDATE #{quoted_table_name(:affairs)} SET closed = #{quoted_true}, closed_at = s.updated_at FROM #{quoted_table_name(:sales)} AS s WHERE s.affair_id = #{quoted_table_name(:affairs)}.id AND s.lost AND NOT closed AND #{quoted_table_name(:affairs)}.debit != #{quoted_table_name(:affairs)}.credit")

    for table in TABLES
      remove_column table, :initial_affair_id
    end

    remove_column :sales, :lost
    remove_column :sales, :paid_amount
    remove_column :transfers, :paid_amount
    remove_column :purchases, :paid_amount
    remove_column :incoming_payments, :used_amount
    remove_column :outgoing_payments, :used_amount

    drop_table :incoming_payment_uses
    drop_table :outgoing_payment_uses
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
