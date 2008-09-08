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
