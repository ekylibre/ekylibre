# == Schema Information
#
# Table name: complement_data
#
#  boolean_value   :boolean       
#  choice_value_id :integer       
#  company_id      :integer       not null
#  complement_id   :integer       not null
#  created_at      :datetime      not null
#  creator_id      :integer       
#  date_value      :date          
#  datetime_value  :datetime      
#  decimal_value   :decimal(, )   
#  entity_id       :integer       not null
#  id              :integer       not null, primary key
#  lock_version    :integer       default(0), not null
#  string_value    :text          
#  updated_at      :datetime      not null
#  updater_id      :integer       
#

class ComplementDatum < ActiveRecord::Base
  belongs_to :choice_value, :class_name=>ComplementChoice.to_s
  belongs_to :company
  belongs_to :complement
  belongs_to :entity
  attr_readonly :company_id, :complement_id, :entity_id

  #  def after_initialize
  #   if self.complement
  #    if self.complement.nature == "choice"
  #     self.
  #  end
  # end
  # end

  def validate
    complement = self.complement
    errors.add_to_base(tc('error_field_required', :field=>complement.name)) if complement.required and self.value.blank?
    unless self.value.blank?
      if complement.nature == 'string'
        unless complement.length_max.blank? or complement.length_max<=0
          errors.add_to_base(tc('error_too_long', :field=>complement.name, :length=>complement.length_max)) if self.string_value.length>complement.length_max
        end
      elsif complement.nature =='decimal'
        unless complement.decimal_min.blank?
          errors.add_to_base(tc('error_less_than', :field=>complement.name, :minimum=>complement.decimal_min)) if self.decimal_value<complement.decimal_min
        end
        unless complement.decimal_max.blank?
          errors.add_to_base(tc('error_greater_than', :field=>complement.name, :maximum=>complement.decimal_max)) if self.decimal_value>complement.decimal_max
        end
      end
    end
  end
  
  def value
    self.send self.complement.nature+'_value'
  end
  
  def value=(object)
    #raise Exception.new object.inspect if self.complement.nature == "date"
    nature = self.complement.nature
    if nature == "choice"
      begin
        self.choice_value_id = object.to_i
      rescue  
        self.choice_value_id = nil
      end
    elsif nature == "date" and object.is_a? Hash
      self.date_value = Date.civil(object["(1i)"].to_i, object["(2i)"].to_i, object["(3i)"].to_i)
    elsif nature == "datetime" and object.is_a? Hash
       self.datetime_value = Time.utc(object["(1i)"].to_i, object["(2i)"].to_i, object["(3i)"].to_i, object["(4i)"].to_i, object["(5i)"].to_i, object["(6i)"].to_i )
    else
      self.send(nature+'_value=',object)
    end
  end
  
end
