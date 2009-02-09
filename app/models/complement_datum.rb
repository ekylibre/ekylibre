# == Schema Information
# Schema version: 20081111111111
#
# Table name: complement_data
#
#  id             :integer       not null, primary key
#  entity_id      :integer       not null
#  complement_id  :integer       not null
#  decimal_value  :decimal(, )   
#  string_value   :text          
#  boolean_value  :boolean       
#  date_value     :date          
#  datetime_value :datetime      
#  choice_value   :integer       
#  company_id     :integer       not null
#  created_at     :datetime      not null
#  updated_at     :datetime      not null
#  created_by     :integer       
#  updated_by     :integer       
#  lock_version   :integer       default(0), not null
#

class ComplementDatum < ActiveRecord::Base
  attr_readonly :company_id, :complement_id, :entity_id

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

end
