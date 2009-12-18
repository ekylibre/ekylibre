# == Schema Information
#
# Table name: invoices
#
#  accounted          :boolean       not null
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

  validates_presence_of :currency_id

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

    if self.credit
      self.amount = 0
      self.amount_with_taxes = 0
      for line in self.lines
        self.amount += line.amount
        self.amount_with_taxes += line.amount_with_taxes
      end
    end
    self.currency_id ||= self.sale_order.currency_id if self.sale_order
  end
  
  def before_validation_on_create
    self.payment_on ||= self.payment_delay.compute if self.payment_delay
    self.payment_on ||= Date.today
    if self.credit and self.origin
      self.payment_on = Date.today if self.payment_on.nil?
      self.contact_id = self.origin.contact_id
      self.nature = "C"
      self.payment_delay_id = self.origin.payment_delay_id
      self.sale_order_id = self.origin.sale_order_id
      self.currency_id = self.origin.currency_id
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

  def responsible_name
    if self.sale_order and self.sale_order.responsible
      self.sale_order.responsible.label
    else
      ""
    end
  end

  def label
    tc('label.'+(self.credit ? 'credit' : 'normal'), :number=>self.number, :created_on=>::I18n.localize(self.created_on))
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

  #this method accountizes the invoice.
  def to_accountancy
    unless self.amount.zero?
      
      financialyear = self.company.financialyears.find(:first, :conditions => ["? BETWEEN started_on AND stopped_on AND closed=?", Date.today, false])
      
      journal =  self.company.journals.find(:first, :conditions =>{:nature=>'sale'}, :order=>:id)
      
      unless journal.nil? or financialyear.nil?
        
        client_account = self.client.account(:client)
        
        record = self.company.journal_records.create!(:resource_id=>self.id, :resource_type=>self.class.name, :created_on=>Date.today, :printed_on => self.created_on, :journal_id=>journal.id, :financialyear_id => financialyear.id)
             
        record.add_debit(self.client.full_name, client_account.id, self.amount_with_taxes, :draft=>false)
      
        self.lines.each do |line|
      
          record.add_credit(line.product.name, line.product.product_account_id, line.amount, :draft=>false)
       
          record.add_credit(line.price.tax.name, line.price.tax.account_collected_id, line.taxes, :draft=>false)
      
        end
          
        self.update_attribute(:accounted, true)
           
      end
    end
  end
  

end
