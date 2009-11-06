# == Schema Information
#
# Table name: transfers
#
#  amount       :decimal(16, 2 default(0.0), not null
#  comment      :string(255)   
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  created_on   :date          
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  label        :string(255)   
#  lock_version :integer       default(0), not null
#  parts_amount :decimal(16, 2 default(0.0), not null
#  started_on   :date          
#  stopped_on   :date          
#  supplier_id  :integer       
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class Transfer < ActiveRecord::Base
  belongs_to :company
  belongs_to :supplier, :class_name=>Entity.to_s
  attr_readonly :company_id, :comment
  has_many :payment_parts, :as=>:expense

  validates_presence_of :created_on

  def before_validation
    self.created_on ||= Date.today
    self.parts_amount = self.payment_parts.sum(:amount)||0
  end

  def unpaid_amount(options=nil)
    self.amount - self.parts_amount
  end

  #this method saves the transfer in the accountancy module.
  def to_accountancy
    journal_purchase=  self.company.journals.find(:first, :conditions => ['nature = ?', 'purchase'],:order=>:id)
    
    financialyear = self.company.financialyears.find(:first, :conditions => ["(? BETWEEN started_on and stopped_on) AND closed=?'", '%'+Date.today.to_s+'%', false])
    
    record = self.company.journal_records.create!(:resource_id=>self.id, :resource_type=>tc(:transfer), :created_on=>Date.today, :printed_on => self.started_on, :journal_id=>journal_purchase.id, :financialyear_id => financialyear.id)
    
    entry = self.company.entries.create!(:record_id=>record.id, :account_id=>self.supplier.supplier_account_id, :name=>self.supplier.full_name, :currency_debit=>self.amount, :currency_credit=>0.0, :currency_id=>journal_purchase.currency_id,:draft=>true)
    
    entry = self.company.entries.create!(:record_id=>record.id, :account_id=>("compte Effets à payer"), :name=>("Effets à payer"), :currency_debit=>0.0, :currency_credit=>self.amount, :currency_id=>journal_purchase.currency_id,:draft=>true)

    # all the payments matching to this transfer are looked for and comptabilized.
   #  payments = self.company.payments.find(:all, :conditions => ["p.expense_id = ? and payments.accounted=?", self.id, false] , :joins=>"inner join payment_parts p on p.payment_id=payments.id and p.expense_type=#{Transfer.name}")
    
#     payments.each do |payment|
#       payment.to_accountancy
#     end
   
    self.update_attribute(:accounted, true)
  end




end
