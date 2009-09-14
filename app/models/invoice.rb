# == Schema Information
#
# Table name: invoices
#
#  amount             :decimal(16, 2 default(0.0), not null
#  amount_with_taxes  :decimal(16, 2 default(0.0), not null
#  annotation         :text          
#  client_id          :integer       not null
#  company_id         :integer       not null
#  contact_id         :integer       
#  created_at         :datetime      not null
#  created_on         :date          
#  creator_id         :integer       
#  credit             :boolean       not null
#  currency_id        :integer       
#  downpayment_amount :decimal(16, 2 default(0.0), not null
#  has_downpayment    :boolean       not null
#  id                 :integer       not null, primary key
#  lock_version       :integer       default(0), not null
#  lost               :boolean       not null
#  nature             :string(1)     not null
#  number             :string(64)    not null
#  origin_id          :integer       
#  paid               :boolean       not null
#  payment_delay_id   :integer       not null
#  payment_on         :date          not null
#  sale_order_id      :integer       
#  updated_at         :datetime      not null
#  updater_id         :integer       
#

class Invoice < ActiveRecord::Base
  belongs_to :client, :class_name=>Entity.to_s
  belongs_to :company
  belongs_to :contact
  belongs_to :origin, :class_name=>Invoice.to_s
  belongs_to :payment_delay, :class_name=>Delay.to_s
  belongs_to :sale_order
  has_many :deliveries
  has_many :lines, :class_name=>InvoiceLine.name
  has_many :credits, :class_name=>Invoice.name, :foreign_key=>:origin_id

  attr_readonly :company_id, :number, :sale_order_id, :client_id, :contact_id, :currency_id, :annotation # , :amount, :amount_with_taxes

  def before_validation
    self.created_on = Date.today unless self.created_on.is_a? Date
    if self.number.blank?
      last = self.client.invoices.find(:first, :order=>"number desc")
      self.number = if last
                      last.number.succ!
                    else
                      '00000001'
                    end
    end
    self.payment_on = self.payment_delay.compute(self.created_on) if self.payment_delay
    if self.credit
      self.amount = 0
      self.amount_with_taxes = 0
      for line in self.lines
        self.amount += line.amount
        self.amount_with_taxes += line.amount_with_taxes
      end
    end
  end
  
  def before_validation_on_create
    if self.credit and self.origin
      self.payment_on = Date.today if self.payment_on.nil?
      self.contact_id = self.origin.contact_id
      self.nature = "C"
      self.payment_delay_id = self.origin.payment_delay_id
      self.sale_order_id = self.origin.sale_order_id
    end
  end
  
  def after_validation_on_create
    specific_numeration = self.company.parameter("management.invoicing.numeration").value
    if not specific_numeration.nil?
      self.number = specific_numeration.next_value
    end
  end

  def after_create
    self.client.add_event(:invoice, self.updater_id) if self.updater
  end
  
  def status
    if not self.creditable? 
      "error"
    elsif self.credited_amount<0
      "warning"
    else
      ""
    end
  end

  def product_name
    self.product.name
  end

  def taxes
    self.amount_with_taxes - self.amount
  end

  def address
    a = self.client.full_name+"\n"
    a += (self.contact ? self.contact.address : self.client.default_contact.address).gsub(/\s*\,\s*/, "\n")
    a
  end

  def unpaid_amount
    self.sale_order.invoices.sum(:amount_with_taxes)-self.sale_order.payment_parts.sum(:amount)
  end

  def credited_amount
    self.credits.sum(:amount_with_taxes)
  end

  def creditable?
    not self.credit and self.amount_with_taxes + self.credited_amount > 0
  end

  # this method links the accountancy and management modules.
  def to_accountancy
    unless self.lost or not self.paid or self.sale_order.state == 'C'
      financialyear = self.company.financialyears.find(:first, :conditions => ["code LIKE ? and closed='false'", '%'+self.payment_on.year+'%'])
      journal_sale =  self.company.journals.find(:first, :conditions => ['nature = ? AND closed_on < ?', tc(:sale), self.payment_on])
      
      record = self.company.journal_records.create!(:resource_id=>self.id, :resource_type=>tc(:facture), :created_on=>self.payment_on, :printed_on => self.created_on, :journal_id=>journal_sale.id, :financialyear_id => financialyear.id)
     
      self.lines.each do |line|

        entry = self.company.entries.create!(:record_id=>record.id, :account_id=> self.client_id, :name=> self.client.label, :debit=>(line.amount_with_taxes*line.quantity), :credit=>0.0)

        entry = self.company.entries.create!(:record_id=>record.id, :account_id=>line.product.product_account_id, :name=>tc(:sale)+line.product.name, :debit=>0.0, :credit=>(line.amount*line.quantity))

         entry = self.company.entries.create!(:record_id=>record.id, :account_id=>line.order_line.tax.account_collected_id, :name=>line.order_line.tax.name, :debit=>0.0, :credit=>self.taxes)

      end


      #entry = self.company.entries.create!(:record_id=>record.id, :account_id=>self.sale_order.lines.first.tax.account_collected_id, :name=>self.sale_order.lines.first.tax.name, :debit=>0.0, :credit=>self.taxes)
 
      
      # entry = self.company.entries.create!(:record_id=>record.id, :account_id=> , :name=> , :debit=>self.amount_with_taxes, :credit=>0.0)
      
    end

  end
  
end
