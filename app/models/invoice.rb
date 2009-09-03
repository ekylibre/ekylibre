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

  attr_readonly :company_id, :number, :sale_order_id, :amount, :amount_with_taxes, :client_id, :contact_id, :currency_id, :annotation

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
    status = ""
    status = "critic" if self.credit
    status
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
  
end
