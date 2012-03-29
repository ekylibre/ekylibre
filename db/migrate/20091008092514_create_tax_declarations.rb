class CreateTaxDeclarations < ActiveRecord::Migration
  def self.up
    create_table :tax_declarations do |t|
      t.column :nature, :string, :null=>false, :default=>"normal"
      t.column :address, :string
      t.column :declared_on, :date
      t.column :paid_on, :date
      t.column :collected_amount, :decimal, :precision=>16, :scale=>2
      t.column :paid_amount, :decimal, :precision=>16, :scale=>2
      t.column :balance_amount, :decimal, :precision=>16, :scale=>2
      t.column :deferred_payment, :boolean, :default=>false
      t.column :assimilated_taxes_amount, :decimal, :precision=>16, :scale=>2
      t.column :acquisition_amount, :decimal, :precision=>16, :scale=>2
      t.column :amount, :decimal, :precision=>16, :scale=>2
      t.column :company_id, :integer,  :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict 
      t.column :financialyear_id, :integer, :references=>:financialyears, :on_delete=>:restrict, :on_update=>:restrict 
      t.column :started_on, :date
      t.column :stopped_on, :date
      t.stamps
    end
    add_stamps_indexes :tax_declarations

   add_index :tax_declarations, :company_id
  end
  
  def self.down
    drop_table :tax_declarations
  end
end

