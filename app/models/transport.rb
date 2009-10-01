# == Schema Information
#
# Table name: transports
#
#  comment        :text          
#  company_id     :integer       not null
#  created_at     :datetime      not null
#  created_on     :date          
#  creator_id     :integer       
#  id             :integer       not null, primary key
#  lock_version   :integer       default(0), not null
#  responsible_id :integer       
#  transport_on   :date          
#  transporter_id :integer       not null
#  updated_at     :datetime      not null
#  updater_id     :integer       
#  weight         :decimal(, )   
#

class Transport < ActiveRecord::Base

  belongs_to :company
  belongs_to :responsible, :class_name=>Employee.name
  belongs_to :transporter, :class_name=>Entity.name
  has_many :deliveries

  attr_readonly :company_id

  def before_validation_on_create
    self.created_on ||= Date.today
  end

  def before_validation
    self.weight = 0
    for delivery in self.deliveries
      self.weight += delivery.weight
    end
  end

  def refresh
    self.save
  end

  def before_destroy
    for delivery in self.deliveries
      delivery.update_attributes(:transport_id=>nil)
    end
  end

  def address
    a = self.transporter.full_name+"\n"
    a += self.transporter.default_contact.address.gsub(/\s*\,\s*/, "\n") if !self.transporter.default_contact.nil?
    a
  end
  

end
