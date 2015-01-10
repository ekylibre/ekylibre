# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
# 
# == Table: custom_field_data
#
#  boolean_value   :boolean          
#  choice_value_id :integer          
#  company_id      :integer          not null
#  created_at      :datetime         not null
#  creator_id      :integer          
#  custom_field_id :integer          not null
#  date_value      :date             
#  datetime_value  :datetime         
#  decimal_value   :decimal(16, 4)   
#  entity_id       :integer          not null
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  string_value    :text             
#  updated_at      :datetime         not null
#  updater_id      :integer          
#


class CustomFieldDatum < CompanyRecord
  attr_readonly :company_id, :custom_field_id, :entity_id
  belongs_to :choice_value, :class_name=>"CustomFieldChoice"
  belongs_to :company
  belongs_to :custom_field
  belongs_to :entity
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :decimal_value, :allow_nil => true
  #]VALIDATORS]
  validates_uniqueness_of :custom_field_id, :scope=>[:company_id, :entity_id]

  validate do
    if custom_field = self.custom_field
      self.company_id = self.custom_field.company_id
      errors.add_to_base(:required, :field=>custom_field.name) if custom_field.required and ((custom_field == 'boolean' and self.value.nil?) or self.value.blank?)
      unless self.value.blank?
        if custom_field.nature == 'string'
          unless custom_field.length_max.blank? or custom_field.length_max<=0
            errors.add_to_base(:too_long, :field=>custom_field.name, :length=>custom_field.length_max) if self.string_value.length>custom_field.length_max
          end
        elsif custom_field.nature =='decimal'
          unless custom_field.decimal_min.blank?
            errors.add_to_base(:less_than, :field=>custom_field.name, :minimum=>custom_field.decimal_min) if self.decimal_value<custom_field.decimal_min
          end
          unless custom_field.decimal_max.blank?
            errors.add_to_base(:greater_than, :field=>custom_field.name, :maximum=>custom_field.decimal_max) if self.decimal_value>custom_field.decimal_max
          end
        end
      end
    end
  end
  
  def value
    self.send self.custom_field.nature+'_value'
  end
  
  def value=(object)
    #raise Exception.new object.inspect if self.custom_field.nature == "date"
    nature = self.custom_field.nature
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
