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
# == Table: product_nature_variant_indicator_data
#
#  boolean_value       :boolean          not null
#  choice_value        :string(255)
#  computation_method  :string(255)      not null
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
#  string_value        :text
#  updated_at          :datetime         not null
#  updater_id          :integer
#  variant_id          :integer          not null
#


class ProductNatureVariantIndicatorDatum < Ekylibre::Record::Base
  attr_accessible :value, :created_at, :variant_id, :indicator, :description, :geometry_value, :decimal_value, :measure_value_unit, :measure_value_value, :string_value, :boolean_value, :choice_value
  belongs_to :variant, :class_name => "ProductNatureVariant"
  enumerize :computation_method, :in => [:fixed, :proportionnal], :default => :fixed
  enumerize :indicator, :in => Nomen::Indicators.all, :default => Nomen::Indicators.default, :predicates => {:prefix => true}
  enumerize :indicator_datatype, :in => Nomen::Indicators.datatype.choices, :predicates => {:prefix => true}
  enumerize :measure_value_unit, :in => Nomen::Units.all, :predicates => {:prefix => true}

  composed_of :measure_value, :class_name => "Measure", :mapping => [%w(measure_value_value value), %w(measure_value_unit unit)]
  # composed_of :geometry_value, :class_name => "Geometry", :mapping => [%w(geometry_value value)]

  # belongs_to :indicator, :class_name => "ProductNatureIndicator", :inverse_of => :data
  # belongs_to :measure_unit, :class_name => "Unit"
  # TODO: enumerize :choice_value dynamicly
  # belongs_to :choice_value, :class_name => "ProductIndicatorChoice"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :decimal_value, :measure_value_value, :allow_nil => true
  validates_length_of :choice_value, :computation_method, :indicator, :indicator_datatype, :measure_value_unit, :allow_nil => true, :maximum => 255
  validates_inclusion_of :boolean_value, :in => [true, false]
  validates_presence_of :computation_method, :indicator, :indicator_datatype, :variant
  #]VALIDATORS]
  validates_inclusion_of :indicator, :in => self.indicator.values
  validates_inclusion_of :indicator_datatype, :in => self.indicator_datatype.values
  validates_presence_of :geometry_value, :if => :indicator_datatype_geometry?
  validates_presence_of :string_value, :if => :indicator_datatype_string?
  validates_presence_of :measure_value_value, :measure_value_unit, :if => :indicator_datatype_measure?
  validates_presence_of :boolean_value, :if => :indicator_datatype_boolean?
  validates_presence_of :choice_value, :if => :indicator_datatype_choice?
  validates_presence_of :decimal_value, :if => :indicator_datatype_decimal?

  before_validation do
    self.indicator_datatype = self.theoric_datatype
  end


  validate do
    if self.indicator_datatype_measure?
      # TODO Check unit
      # errors.add(:unit, :invalid) if unit.dimension != indicator.unit.dimension
    end
  end

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
    #return nil if self.indicator.blank?
    Nomen::Indicators.items[self.indicator].datatype.to_sym
  end

end
