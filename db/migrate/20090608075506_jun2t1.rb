class Jun2t1 < ActiveRecord::Migration
  def self.up
    
    add_column :entity_categories, :code, :string, :limit=>8
    add_index :entity_categories, [:code, :company_id], :unique=>true
    
    add_column :invoices, :origin_id, :integer, :references=>:invoices, :on_update=>:restrict, :on_delete=>:restrict
    add_column :invoices, :credit,    :boolean, :null=>false,  :default=>false

    add_column :invoice_lines, :origin_id, :integer, :references=>:invoice_lines, :on_update=>:restrict, :on_delete=>:restrict

    add_column :users,  :credits,  :boolean, :null=>false, :default=>true

    add_column :invoices, :created_on, :date
    
    add_column :payments, :to_bank_on, :date
    
    create_table :embankments do |t|
      t.column :amount,            :decimal,  :null=>false
      t.column :payments_number,   :integer,  :null=>false
      t.column :created_on,        :date,     :null=>false
      t.column :comment,           :text
      t.column :bank_account_id,   :integer,  :null=>false, :references=>:bank_accounts, :on_delete=>:cascade, :on_update=>:cascade
      t.column :mode_id,           :integer,  :null=>false, :references=>:payment_modes, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,        :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    
    add_column :payments, :embankment_id, :integer, :references=>:payments_lists, :on_delete=>:cascade, :on_update=>:cascade
    
    
    EntityCategory.find(:all).each do |category|
      if category.code.blank?
        code = category.name.codeize      
        code = code[0..7]
        category.update_attributes!(:code=>code)
      end
    end
    
    Invoice.find(:all).each do |invoice|
      if invoice.created_on.nil?
        invoice.created_on = invoice.created_at.to_date
        invoice.save
      end
    end
    
    PaymentMode.find(:all).each do |mode|
      if mode.name == "Chèque"
        mode.mode = "check"
        mode.save
      end
    end
    
  end
  
  def self.down
    remove_column :payments, :embankment_id
    drop_table :embankments
    remove_column :payments, :to_bank_on
    remove_column :invoices, :created_on
    remove_column :users, :credits
    remove_column :invoice_lines, :origin_id
    remove_column :invoices, :credit
    remove_column :invoices, :origin_id
    remove_column :entity_categories, :code
  end
end
