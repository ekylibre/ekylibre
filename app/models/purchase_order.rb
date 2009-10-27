# == Schema Information
#
# Table name: purchase_orders
#
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  comment           :text          
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  creator_id        :integer       
#  dest_contact_id   :integer       
#  id                :integer       not null, primary key
#  invoiced          :boolean       not null
#  lock_version      :integer       default(0), not null
#  moved_on          :date          
#  number            :string(64)    not null
#  planned_on        :date          
#  shipped           :boolean       not null
#  supplier_id       :integer       not null
#  updated_at        :datetime      not null
#  updater_id        :integer       
#

class PurchaseOrder < ActiveRecord::Base
  belongs_to :company
  belongs_to :dest_contact, :class_name=>Contact.name
  belongs_to :supplier, :class_name=>Entity.name
  has_many :lines, :class_name=>PurchaseOrderLine.name, :foreign_key=>:order_id
  has_many :payment_parts, :as=>:expense

  validates_presence_of :planned_on
  attr_readonly :company_id

  def before_validation
    if self.number.blank?
      last = self.supplier.purchase_orders.find(:first, :order=>"number desc")
      self.number = if last
                      last.number.succ!
                    else
                      '00000001'
                    end
    end


    self.amount = 0
    self.amount_with_taxes = 0
     for line in self.lines
       self.amount += line.amount
       self.amount_with_taxes += line.amount_with_taxes
     end
  end

  def after_create
    self.supplier.add_event(:purchase_order, self.updater_id) if self.updater
  end
  
  def refresh
    self.save
  end

  def stocks_moves_create
    locations = StockLocation.find_all_by_company_id(self.company_id)
    for line in self.lines
      if locations.size == 1
        line.update_attributes!(:location_id=>locations[0].id)
      end
      StockMove.create!(:name=>tc(:purchase)+"  "+self.number, :quantity=>line.quantity, :location_id=>line.location_id, :product_id=>line.product_id, :planned_on=>self.planned_on, :company_id=>line.company_id, :virtual=>true, :input=>true, :origin_type=>PurchaseOrder.to_s, :origin_id=>self.id, :generated=>true)
    end
  end

  def real_stocks_moves_create
    for line in self.lines
      StockMove.create!(:name=>tc(:purchase)+"  "+line.order.number, :quantity=>line.quantity, :location_id=>line.location_id, :product_id=>line.product_id, :planned_on=>self.planned_on, :moved_on=>Date.today, :company_id=>line.company_id, :virtual=>false, :input=>true, :origin_type=>PurchaseOrder.to_s, :origin_id=>self.id, :generated=>true)
    end
    self.moved_on = Date.today if self.moved_on.nil?
    self.save
  end

  def label 
     tc('label', :supplier=>self.supplier.full_name.to_s, :address=>self.dest_contact.address.to_s)
  end

  def quantity 
    ''
  end


  #this method saves the purchase in the accountancy module.
  def to_accountancy
    journal_purchase=  self.company.journals.find(:first, :conditions => ['nature = ? AND closed_on < ?', 'purchase', Date.today])
     
     financialyear = self.company.financialyears.find(:first, :conditions => ["(? BETWEEN started_on and stopped_on) AND closed=?'", '%'+self.created_on.year.to_s+'%', true])


     record = self.company.journal_records.create!(:resource_id=>self.id, :resource_type=>'purchase', :created_on=>Date.today, :printed_on => self.created_on, :journal_id=>journal_purchase.id, :financialyear_id => financialyear.id)
     
     
     if self.client.client_account_id.nil?
       self.client.reload.update_attribute(:client_account_id, self.client.create_update_account(:client).id)
     end
    

#      if the sale contains a downpayment
#     if self.has_downpayment
#       entry = self.company.entries.create!(:record_id=>record.id, :account_id=>payment_mode.bank_account.account_id, :name=>payment_mode.bank_account.label, :currency_debit=>self.downpayment_amount, :currency_credit=>0.0, :currency_id=>journal_bank.currency_id)
      
#       account_downpayment = self.company.accounts.find(self.client.client_account_id).number
      
#       account = self.company.accounts.find(:number=>account_downpayment.insert(2, '9').to_s)

#       if account.nil?
#         account = self.company.accounts.create!(:name=>"Clients, avances et acomptes reçus", :number=>account_downpayment, :company_id=>self.company.id)
#       end

#       entry = self.company.entries.create!(:record_id=>record.id, :account_id=>account.id, :name=>account.label, :currency_debit=>0.0, :currency_credit=>self.downpayment_amount, :currency_id=>journal_bank.currency_id)
      
#       entry = self.company.entries.create!(:record_id=>record.id, :account_id=>account.id, :name=>account.label, :currency_debit=>self.downpayment_amount, :currency_credit=>0.0, :currency_id=>journal_bank.currency_id)
      
#     end

#     bank_account = payments.first.mode.bank_account
#     sum = 0

#     payments.each do |payment|
#       sum += payment.amount
#       if [:card, :cash, :check, :transfer].include? payment.mode.mode.to_sym
      
#         entry = self.company.entries.create!(:record_id=>record.id, :account_id=>payment.mode.account_id, :name=>payment.mode.name, :currency_debit=>payment.amount, :currency_credit=>0.0, :currency_id=>journal_bank.currency_id)
        
#         entry = self.company.entries.create!(:record_id=>record.id, :account_id=>payment.mode.account_id, :name=>payment.mode.name, :currency_debit=>0.0, :currency_credit=>payment.amount, :currency_id=>journal_bank.currency_id)
        
#       end
    
   
#     end
   
#     entry = self.company.entries.create!(:record_id=>record.id, :account_id=>bank_account.account_id, :name=>bank_account.account.name, :currency_debit=>sum, :currency_credit=>0.0, :currency_id=>journal_bank.currency_id)

#     entry = self.company.entries.create!(:record_id=>record.id, :account_id=>self.client.client_account_id, :name=>self.client.full_name, :currency_debit=>0.0, :currency_credit=>self.lines.sum(:amount_with_taxes)*self.lines.sum(:quantity), :currency_id=>journal_bank.currency_id)
  
 
     entry = self.company.entries.create!(:record_id=>record.id, :account_id=>self.client.client_account_id, :name=>self.client.full_name, :currency_credit=>self.amount_with_taxes, :currency_debit=>0.0, :currency_id=>journal_bank.currency_id)
    
     self.lines.each do |line|
       line_amount = (line.amount * line.quantity)
       entry = self.company.entries.create!(:record_id=>record.id, :account_id=>line.product.product_account_id, :name=>'sale '+line.product.name.to_s, :currency_credit=>0.0, :currency_debit=>line_amount, :currency_id=>journal_sale.currency_id)
       unless line.price.tax_id.nil?
         entry = self.company.entries.create!(:record_id=>record.id, :account_id=>line.price.tax.account_collected_id, :name=>line.price.tax.name, :currency_credit=>0.0, :currency_debit=>line.price.tax.amount*line_amount, :currency_id=>journal_sale.currency_id)
       end
     end
       
  
   end



  def payments_sum
    self.payment_parts.sum(:amount)
  end

  def editable
    if self.amount_with_taxes == 0 
      return true
    else
      return self.payments_sum != self.amount_with_taxes
    end
  end


end
