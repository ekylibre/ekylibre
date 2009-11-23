# == Schema Information
#
# Table name: employees
#
#  arrived_on       :date          
#  comment          :text          
#  commercial       :boolean       not null
#  company_id       :integer       not null
#  created_at       :datetime      not null
#  creator_id       :integer       
#  departed_on      :date          
#  department_id    :integer       not null
#  establishment_id :integer       not null
#  first_name       :string(255)   not null
#  id               :integer       not null, primary key
#  last_name        :string(255)   not null
#  lock_version     :integer       default(0), not null
#  office           :string(32)    
#  profession_id    :integer       
#  role             :string(255)   
#  title            :string(32)    not null
#  updated_at       :datetime      not null
#  updater_id       :integer       
#  user_id          :integer       
#

class Employee < ActiveRecord::Base
  belongs_to :company
  belongs_to :department
  belongs_to :establishment
  belongs_to :profession
  belongs_to :user
  has_many :clients, :class_name=>Entity.to_s
  has_many :events
  has_many :sale_orders, :foreign_key=>:responsible_id
  has_many :shape_operations
  has_many :transports

  attr_readonly :company_id

  def before_validation
    self.last_name ||= self.user.last_name  
    self.first_name ||= self.user.first_name  
  end

  def full_name
    (self.last_name.to_s+" "+self.first_name.to_s).strip
  end

  def label
    (self.first_name.to_s+" "+self.last_name.to_s).strip
  end  

end
