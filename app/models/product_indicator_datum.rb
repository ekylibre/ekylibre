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
#  boolean_value       :boolean          not null
#  choice_value        :string(255)
#  created_at          :datetime         not null
#  creator_id          :integer
#  decimal_value       :decimal(19, 4)
#  geometry_value      :spatial({:srid=>
#  id                  :integer          not null, primary key
#  indicator           :string(255)      not null
#  indicator_datatype  :string(255)      not null
#  lock_version        :integer          default(0), not null
#  measure_value_unit  :string(255)
#  measure_value_value :decimal(19, 4)
#  measured_at         :datetime         not null
#  product_id          :integer          not null
#  string_value        :text
#  updated_at          :datetime         not null
#  updater_id          :integer
#


class ProductIndicatorDatum < Ekylibre::Record::Base
  attr_accessible :value, :created_at, :product_id, :indicator, :measured_at, :description, :geometry_value, :decimal_value, :measure_value_unit, :measure_value_value, :string_value, :boolean_value, :choice_value
  belongs_to :product
  enumerize :indicator, :in => Nomen::Indicators.all, :default => Nomen::Indicators.default, :predicates => {:prefix => true}
  enumerize :indicator_datatype, :in => Nomen::Indicators.datatype.choices
  enumerize :measure_value_unit, :in => Nomen::Units.all, :default => Nomen::Units.default, :predicates => {:prefix => true}

  composed_of :measure_value, :class_name => "Measure", :mapping => [%w(measure_value_value value), %w(measure_value_unit unit)]

  # belongs_to :indicator, :class_name => "ProductNatureIndicator", :inverse_of => :data
  # belongs_to :measure_unit, :class_name => "Unit"
  # TODO: enumerize :choice_value dynamicly
  # belongs_to :choice_value, :class_name => "ProductIndicatorChoice"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :decimal_value, :measure_value_value, :allow_nil => true
  validates_length_of :choice_value, :indicator, :indicator_datatype, :measure_value_unit, :allow_nil => true, :maximum => 255
  validates_inclusion_of :boolean_value, :in => [true, false]
  validates_presence_of :indicator, :indicator_datatype, :measured_at, :product
  #]VALIDATORS]
  validates_inclusion_of :indicator, :in => self.indicator.values
  validates_inclusion_of :indicator_datatype, :in => self.indicator_datatype.values

  before_validation do
    self.indicator_datatype = self.theoric_datatype
  end

  # validate do
  #   if self.indicator
  #     errors.add(:value, :required, :field => self.indicator.name) if self.value.blank?
  #     unless self.value.blank?
  #       if self.indicator_type == "string"
  #         unless self.indicator.maximal_length.blank? or self.indicator.maximal_length <= 0
  #           errors.add(:value, :too_long, :field => self.indicator.name, :length => self.indicator.length_max) if self.string_value.length > self.indicator.maximal_length
  #         end
  #         unless self.indicator.minimal_length.blank? or self.indicator.minimal_length <= 0
  #           errors.add(:value, :too_short, :field => self.indicator.name, :length => self.indicator.length_max) if self.string_value.length < self.indicator.minimal_length
  #         end
  #       elsif self.indicator_type == "decimal"
  #         unless self.indicator.minimal_value.blank?
  #           errors.add(:value, :less_than, :field => self.indicator.name, :minimum => self.indicator.minimal_value) if self.decimal_value < self.indicator.minimal_value
  #         end
  #         unless self.indicator.maximal_value.blank?
  #           errors.add(:value, :greater_than, :field => self.indicator.name, :maximum => self.indicator.maximal_value) if self.decimal_value > self.indicator.maximal_value
  #         end
  #       end
  #     end
  #   end
  # end

  # Read value from good place
  def value
    datatype = self.indicator_datatype || self.theoric_datatype
    self.send(datatype.to_s + '_value')
  end

  # Write value into good place
  def value=(object)
    datatype = self.indicator_datatype || self.theoric_datatype
    self.send(datatype.to_s + '_value=', object)
  end

  # Retrieve datatype from nomenclature NOT from database
  def theoric_datatype
    return nil if self.indicator.blank?
    Nomen::Indicators.items[self.indicator].datatype.to_sym
  end

end
