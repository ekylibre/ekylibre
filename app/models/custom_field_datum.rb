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
# == Table: custom_field_data
#
#  boolean_value   :boolean
#  choice_value_id :integer
#  created_at      :datetime         not null
#  creator_id      :integer
#  custom_field_id :integer          not null
#  customized_id   :integer          not null
#  customized_type :string(255)      not null
#  date_value      :date
#  datetime_value  :datetime
#  decimal_value   :decimal(19, 4)
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  string_value    :text
#  updated_at      :datetime         not null
#  updater_id      :integer
#


class CustomFieldDatum < Ekylibre::Record::Base
  attr_accessible :custom_field_id, :customized_id, :customized_type, :value, :choice_value_id
  attr_readonly :custom_field_id, :customized_id, :customized_type
  belongs_to :choice_value, :class_name => "CustomFieldChoice"
  belongs_to :custom_field, :inverse_of => :data
  belongs_to :customized, :polymorphic => true, :inverse_of => :custom_field_data
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :decimal_value, :allow_nil => true
  validates_length_of :customized_type, :allow_nil => true, :maximum => 255
  validates_presence_of :custom_field, :customized, :customized_type
  #]VALIDATORS]
  validates_uniqueness_of :custom_field_id, :scope => [:customized_id, :customized_type]

  validate do
    if self.custom_field
      errors.add(:value, :required, :field => self.custom_field.name) if self.custom_field.required? and self.value.blank?
      unless self.value.blank?
        if self.custom_field.string?
          unless self.custom_field.maximal_length.blank? or self.custom_field.maximal_length <= 0
            errors.add(:value, :too_long, :field => self.custom_field.name, :length => self.custom_field.length_max) if self.string_value.length > self.custom_field.maximal_length
          end
          unless self.custom_field.minimal_length.blank? or self.custom_field.minimal_length <= 0
            errors.add(:value, :too_short, :field => self.custom_field.name, :length => self.custom_field.length_max) if self.string_value.length < self.custom_field.minimal_length
          end
        elsif self.custom_field.decimal?
          unless self.custom_field.minimal_value.blank?
            errors.add(:value, :less_than, :field => self.custom_field.name, :minimum => self.custom_field.minimal_value) if self.decimal_value < self.custom_field.minimal_value
          end
          unless self.custom_field.maximal_value.blank?
            errors.add(:value, :greater_than, :field => self.custom_field.name, :maximum => self.custom_field.maximal_value) if self.decimal_value > self.custom_field.maximal_value
          end
        end
      end
    end
  end

  def value
    self.send(self.custom_field.nature + '_value')
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
