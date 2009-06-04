# == Schema Information
# Schema version: 20090520140946
#
# Table name: parameters
#
#  id            :integer       not null, primary key
#  name          :string(255)   not null
#  nature        :string(1)     default("u"), not null
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
  belongs_to :company
  belongs_to :user

  CONV={:float=>:d, :string=>:s, :true_class=>:b, :false_class=>:b, :fixnum=>:i}

  def value
    v = nil
    case self.nature.to_sym
    when :s
      v = self.string_value
    when :b
      v = self.boolean_value
    when :i
      v = self.integer_value
    when :d
      v = self.decimal_value
    when :f
      begin 
        v = self.element_type.constantize.find(self.element_id)
      rescue
        v = nil
      end
    end    
    return v
  end

  def value=(v) 
    n = v.class.to_s.underscore.to_sym
    self.nature = CONV[n]
    if self.nature.nil?
      begin
        self.nature = :f if v.class.columns_hash["id"]
      rescue
      end
    end
    raise Exception.new("Undefined type for parameter object: "+v.class.to_s) if self.nature.nil?
    case self.nature
    when :s
      self.string_value  = v
    when :b
      self.boolean_value = v
    when :i
      self.integer_value = v
    when :d
      self.decimal_value = v
    when :f
      self.element_type = v.class.to_s
      self.element_id   = v.id
    end
    self.nature = self.nature.to_s
    self.save
  end

end
