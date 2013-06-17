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
# == Table: product_indicator_data
#
#  boolean_value :boolean          not null
#  choice_value  :string(255)
#  created_at    :datetime         not null
#  creator_id    :integer
#  decimal_value :decimal(19, 4)
#  id            :integer          not null, primary key
#  indicator     :string(255)      not null
#  lock_version  :integer          default(0), not null
#  measure_unit  :string(255)
#  measure_value :decimal(19, 4)
#  measured_at   :datetime
#  product_id    :integer          not null
#  string_value  :text
#  updated_at    :datetime         not null
#  updater_id    :integer
#


class ProductIndicatorDatum < Ekylibre::Record::Base
  attr_accessible :value, :created_at, :product_id, :indicator_id, :measured_at, :description, :decimal_value, :measure_unit, :measure_value, :string_value, :boolean_value, :choice_value
  belongs_to :product
  enumerize :indicator, :in => Nomenclatures["indicators"].list, :default => Nomenclatures["indicators"].list.first, :predicates => {:prefix => true}
  # belongs_to :indicator, :class_name => "ProductNatureIndicator", :inverse_of => :data
  # belongs_to :measure_unit, :class_name => "Unit"
  # TODO: enumerize :choice_value dynamicly
  # belongs_to :choice_value, :class_name => "ProductIndicatorChoice"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :decimal_value, :measure_value, :allow_nil => true
  validates_length_of :choice_value, :indicator, :measure_unit, :allow_nil => true, :maximum => 255
  validates_inclusion_of :boolean_value, :in => [true, false]
  validates_presence_of :indicator, :product
  #]VALIDATORS]
    
    
    
  def indicator_type
    "string"
  end


  validate do
    if self.indicator
      errors.add(:value, :required, :field => self.indicator.name) if self.value.blank?
      unless self.value.blank?
        if self.indicator.nature == "string"
          unless self.indicator.maximal_length.blank? or self.indicator.maximal_length <= 0
            errors.add(:value, :too_long, :field => self.indicator.name, :length => self.indicator.length_max) if self.string_value.length > self.indicator.maximal_length
          end
          unless self.indicator.minimal_length.blank? or self.indicator.minimal_length <= 0
            errors.add(:value, :too_short, :field => self.indicator.name, :length => self.indicator.length_max) if self.string_value.length < self.indicator.minimal_length
          end
        elsif self.indicator.nature == "decimal"
          unless self.indicator.minimal_value.blank?
            errors.add(:value, :less_than, :field => self.indicator.name, :minimum => self.indicator.minimal_value) if self.decimal_value < self.indicator.minimal_value
          end
          unless self.indicator.maximal_value.blank?
            errors.add(:value, :greater_than, :field => self.indicator.name, :maximum => self.indicator.maximal_value) if self.decimal_value > self.indicator.maximal_value
          end
        end
      end
    end
  end

  def value
    self.send(self.indicator.nature.to_s + '_value')
  end

  def value=(object)
    if self.indicator.nature.to_s == "choice"
      begin
        self.choice_value_id = object.to_i
      rescue
        self.choice_value_id = nil
      end
    else
      self.send(self.indicator.nature.to_s + '_value=',object)
    end
  end

end
