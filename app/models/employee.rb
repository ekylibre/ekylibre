# == Schema Information
# Schema version: 20090407073247
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
#  profession_id    :integer       not null
#  commercial       :boolean       not null
#

class Employee < ActiveRecord::Base







end
