# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: product_indicators
#
#  boolean_value   :boolean          not null
#  choice_value_id :integer
#  created_at      :datetime         not null
#  creator_id      :integer
#  decimal_value   :decimal(19, 4)
#  description     :string(255)
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  measure_unit_id :integer
#  measure_value   :decimal(19, 4)
#  measured_at     :datetime         not null
#  nature_id       :integer          not null
#  product_id      :integer          not null
#  string_value    :text
#  updated_at      :datetime         not null
#  updater_id      :integer
#


class ProductIndicator < Ekylibre::Record::Base
  attr_accessible :product_id, :nature_id, :measured_at, :description, :decimal_value, :measure_value, :string_value, :boolean_value, :choice_value_id
  belongs_to :product
  belongs_to :nature, :class_name => "ProductIndicatorNature", :inverse_of => :data
  belongs_to :measure_unit, :class_name => "Unit"
  belongs_to :choice_value, :class_name => "ProductIndicatorNatureChoice"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :decimal_value, :measure_value, :allow_nil => true
  validates_length_of :description, :allow_nil => true, :maximum => 255
  validates_inclusion_of :boolean_value, :in => [true, false]
  validates_presence_of :measured_at, :nature, :product
  #]VALIDATORS]
  
  validate do
    if self.nature
      errors.add(:value, :required, :field => self.nature.name) if self.nature.required? and self.value.blank?
      unless self.value.blank?
        if self.nature.string?
          unless self.nature.maximal_length.blank? or self.nature.maximal_length <= 0
            errors.add(:value, :too_long, :field => self.nature.name, :length => self.nature.length_max) if self.string_value.length > self.nature.maximal_length
          end
          unless self.nature.minimal_length.blank? or self.nature.minimal_length <= 0
            errors.add(:value, :too_short, :field => self.nature.name, :length => self.nature.length_max) if self.string_value.length < self.nature.minimal_length
          end
        elsif self.nature.decimal?
          unless self.nature.minimal_value.blank?
            errors.add(:value, :less_than, :field => self.nature.name, :minimum => self.nature.minimal_value) if self.decimal_value < self.nature.minimal_value
          end
          unless self.nature.maximal_value.blank?
            errors.add(:value, :greater_than, :field => self.nature.name, :maximum => self.nature.maximal_value) if self.decimal_value > self.nature.maximal_value
          end
        end
      end
    end
  end
  
    def value
    self.send(self.nature.nature + '_value')
  end

  def value=(object)
    #raise Exception.new object.inspect if self.custom_field.nature == "date"
    nature = self.nature.nature
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
