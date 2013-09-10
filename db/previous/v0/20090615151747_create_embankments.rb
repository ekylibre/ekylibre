class CreateEmbankments < ActiveRecord::Migration
  def self.up
    create_table :embankments do |t|
      t.column :amount,            :decimal,  :null=>false, :precision=>16, :scale=>4, :default=>0.0.to_d
      t.column :payments_number,   :integer,  :null=>false, :default=>0.to_i
      t.column :created_on,        :date,     :null=>false
      t.column :comment,           :text
      t.column :bank_account_id,   :integer,  :null=>false, :references=>:bank_accounts, :on_delete=>:cascade, :on_update=>:cascade
      t.column :mode_id,           :integer,  :null=>false, :references=>:payment_modes, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,        :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
      t.stamps
    end
    add_stamps_indexes :embankments

    add_column :payments, :embankment_id, :integer, :references=>:payments_lists, :on_delete=>:cascade, :on_update=>:cascade
    add_column :embankments, :locked, :boolean, :null=>false, :default=>false
    add_column :bank_accounts, :address, :text
    add_column :payments, :embanker_id,  :integer,  :references=>:users, :on_delete=>:cascade, :on_update=>:cascade

    entities = connection.select_all("SELECT id, entity_id FROM #{quoted_table_name(:companies)}")
    execute "UPDATE #{quoted_table_name(:payments)} SET entity_id=CASE "+entities.collect{|x| "WHEN company_id=#{x['id']} THEN #{x['entity_id']}"}.join(" ")+" ELSE 0 END WHERE entity_id IS NULL" if entities.size > 0
  end

  def self.down
    remove_column :payments, :embanker_id
    remove_column :bank_accounts, :address
    remove_column :embankments,   :locked
    remove_column :payments, :embankment_id
    drop_table :embankments
  end
end
