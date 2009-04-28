# == Schema Information
# Schema version: 20090410102120
#
# Table name: employees
#
#  id               :integer       not null, primary key
#  department_id    :integer       not null
#  establishment_id :integer       not null
#  user_id          :integer       
#  title            :string(32)    not null
#  last_name        :string(255)   not null
#  first_name       :string(255)   not null
#  arrived_on       :date          
#  departed_on      :date          
#  role             :string(255)   
#  office           :string(32)    
#  comment          :text          
#  company_id       :integer       not null
#  created_at       :datetime      not null
#  updated_at       :datetime      not null
#  created_by       :integer       
#  updated_by       :integer       
#  lock_version     :integer       default(0), not null
#  profession_id    :integer       
#  commercial       :boolean       not null
#

class Employee < ActiveRecord::Base
  belongs_to :company
  belongs_to :department
  belongs_to :establishment
  belongs_to :profession
  belongs_to :user
  has_many :clients, :class_name=>Entity.to_s
  has_many :shape_operations

  def full_name
    full_name = (self.last_name.to_s+" "+self.first_name.to_s).strip
  end
  

end
