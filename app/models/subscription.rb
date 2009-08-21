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
  belongs_to :product
  belongs_to :nature, :class_name=>SubscriptionNature.name
  belongs_to :invoice
  belongs_to :entity
  #belongs_to :sale_order_line

  attr_readonly :company_id

  validates_presence_of :started_on, :stopped_on, :if=>Proc.new{|u| u.product.nature=="period"}

  def entity_name
    self.contact.entity.full_name
  end

  def beginning
    self.product.subscription_nature.nature == "quantity" ? self.first_number : self.started_on 
  end

  def finish
    self.product.subscription_nature.nature == "quantity" ? self.last_number : self.stopped_on  
  end

end
