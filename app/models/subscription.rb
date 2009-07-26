# == Schema Information
#
# Table name: subscriptions
#
#  company_id    :integer       not null
#  contact_id    :integer       not null
#  created_at    :datetime      not null
#  creator_id    :integer       
#  finished_on   :date          
#  first_number  :integer       
#  id            :integer       not null, primary key
#  last_number   :integer       
#  lock_version  :integer       default(0), not null
#  product_id    :integer       not null
#  sale_order_id :integer       
#  started_on    :date          
#  updated_at    :datetime      not null
#  updater_id    :integer       
#

class Subscription < ActiveRecord::Base



  belongs_to :company
  belongs_to :contact
  belongs_to :product
  #belongs_to :sale_order_line

  validates_presence_of :started_on, :finished_on, :if=>Proc.new{|u| u.product.nature=="period"}


  def before_validation
   
  end


  def entity_name
    self.contact.entity.full_name
  end

  def beginning
    self.product.subscription_nature.nature == "quantity" ? self.first_number : self.started_on 
  end

  def finish
    self.product.subscription_nature.nature == "quantity" ? self.last_number : self.finished_on  
  end

end
