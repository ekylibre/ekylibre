# coding: utf-8
class Jun2t1 < ActiveRecord::Migration
  def self.up
    
    add_column :entity_categories, :code, :string, :limit=>8
    add_index :entity_categories, [:code, :company_id], :unique=>true
    
    add_column :invoices, :origin_id, :integer, :references=>:invoices, :on_update=>:restrict, :on_delete=>:restrict
    add_column :invoices, :credit,    :boolean, :null=>false,  :default=>false

    add_column :invoice_lines, :origin_id, :integer, :references=>:invoice_lines, :on_update=>:restrict, :on_delete=>:restrict

    add_column :users,  :credits,  :boolean, :null=>false, :default=>true

    add_column :invoices, :created_on, :date
    
    add_column :payments, :to_bank_on, :date, :null=>false, :default=>'1900-01-01'
 
    
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
      else
        mode.mode = "other"
      end
      mode.save
    end
    
  end
  
  def self.down
    remove_column :payments, :to_bank_on
    remove_column :invoices, :created_on
    remove_column :users, :credits
    remove_column :invoice_lines, :origin_id
    remove_column :invoices, :credit
    remove_column :invoices, :origin_id
    remove_column :entity_categories, :code
  end
end
