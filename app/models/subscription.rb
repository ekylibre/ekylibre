# == Schema Information
#
# Table name: subscriptions
#
#  comment       :text          
#  company_id    :integer       not null
#  contact_id    :integer       
#  created_at    :datetime      not null
#  creator_id    :integer       
#  entity_id     :integer       
#  first_number  :integer       
#  id            :integer       not null, primary key
#  invoice_id    :integer       
#  last_number   :integer       
#  lock_version  :integer       default(0), not null
#  nature_id     :integer       
#  product_id    :integer       
#  quantity      :decimal(, )   
#  sale_order_id :integer       
#  started_on    :date          
#  stopped_on    :date          
#  suspended     :boolean       not null
#  updated_at    :datetime      not null
#  updater_id    :integer       
#

class Subscription < ActiveRecord::Base
  belongs_to :company
  belongs_to :contact
  belongs_to :entity
  belongs_to :invoice
  belongs_to :nature, :class_name=>SubscriptionNature.name
  belongs_to :product
  belongs_to :sale_order
  #belongs_to :sale_order_line

  attr_readonly :company_id

  validates_presence_of :started_on, :stopped_on, :if=>Proc.new{|u| u.nature and u.nature.nature=="period"}
  validates_presence_of :first_number, :last_number, :if=>Proc.new{|u| u.nature and u.nature.nature=="quantity"}
  validates_presence_of :nature_id, :entity_id


  def before_validation
    self.sale_order_id ||= self.invoice.sale_order_id if self.invoice
    self.nature_id ||= self.product.nature_id if self.product
    unless self.entity
      self.entity_id ||= self.contact.entity_id if self.contact
      self.entity_id ||= self.invoice.client_id if self.invoice
      self.entity_id ||= self.sale_order.client_id if self.sale_order
    end
  end

  def validates
    if self.contact and self.entity
      errors.add(:entity_id, tc('errors.entity_must_be_the_same_as_the_contact_entity')) if self.contact.entity_id!=self.entity_id
    end
    if self.invoice and self.entity
      errors.add(:entity_id, tc('errors.entity_must_be_the_same_as_the_invoice_client')) if self.invoice.client_id!=self.entity_id
    end
    if self.sale_order and self.entity
      errors.add(:entity_id, tc('errors.entity_must_be_the_same_as_the_sale_order_client')) if self.sale_order.client_id!=self.entity_id
    end
  end
  
  

  def entity_name
    if self.entity
      self.entity.full_name
    elsif self.contact
      if self.contact.entity.is_a?(Entity)
        self.contact.entity.full_name
      else
        '--'
      end
    else
      '-'
    end
  end

  # TODO: Changer le nom de la méthode
#  def natura
#    self.nature||(self.product ? self.product.subscription_nature : 'unknown_nature')
#  end

  def start
    self.nature.nature == "quantity" ? self.first_number : ::I18n.localize(self.started_on)
  end

  def finish
    self.nature.nature == "quantity" ? self.last_number : ::I18n.localize(self.stopped_on  )
  end

  def active?(instant=nil)
    if self.nature.nature == "quantity"
      instant ||= self.nature.actual_number
      self.first_number<=instant and instant<=self.last_number
    else
      instant ||= Date.today
      self.started_on<=instant and instant<=self.stopped_on
    end
  end


end
