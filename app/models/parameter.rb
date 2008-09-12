# == Schema Information
# Schema version: 20080819191919
#
# Table name: parameters
#
#  id            :integer       not null, primary key
#  name          :string(255)   not null
#  nature        :string(1)     not null
#  string_value  :text          
#  boolean_value :boolean       
#  integer_value :integer       
#  decimal_value :decimal(, )   
#  element_type  :string(255)   
#  element_id    :integer       
#  user_id       :integer       
#  company_id    :integer       not null
#  created_at    :datetime      not null
#  updated_at    :datetime      not null
#  created_by    :integer       
#  updated_by    :integer       
#  lock_version  :integer       default(0), not null
#

class Parameter < ActiveRecord::Base

  def value
    v = nil
    case self.nature.to_sym
    when :s:
        v = self.string_value
    when :b: 
        v = self.boolean_value
    when :i: 
        v = self.integer_value
    when :d: 
        v = self.decimal_value
    when :f: 
        begin 
          v = self.element_type.constantize.find(self.element_id)
        rescue
          v = nil
        end
    end
    
    return v
  end
end
