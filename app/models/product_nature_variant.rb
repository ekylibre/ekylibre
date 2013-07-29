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
# == Table: product_nature_variants
#
#  active                  :boolean          not null
#  commercial_description  :text
#  commercial_name         :string(255)      not null
#  contour                 :string(255)
#  created_at              :datetime         not null
#  creator_id              :integer
#  horizontal_rotation     :integer          default(0), not null
#  id                      :integer          not null, primary key
#  lock_version            :integer          default(0), not null
#  name                    :string(255)
#  nature_id               :integer          not null
#  nature_name             :string(255)      not null
#  number                  :string(255)
#  purchase_indicator      :string(127)
#  purchase_indicator_unit :string(255)
#  sale_indicator          :string(127)
#  sale_indicator_unit     :string(255)
#  updated_at              :datetime         not null
#  updater_id              :integer
#  usage_indicator         :string(127)
#  usage_indicator_unit    :string(255)
#
class ProductNatureVariant < Ekylibre::Record::Base
  attr_accessible :active, :commercial_name, :nature_id, :nature_name, :name, :purchase_indicator, :purchase_indicator_unit, :sale_indicator, :sale_indicator_unit, :usage_indicator, :usage_indicator_unit, :products_attributes
  enumerize :sale_indicator, :in => Nomen::Indicators.all, :predicates => {:prefix => true}
  enumerize :purchase_indicator, :in => Nomen::Indicators.all, :predicates => {:prefix => true}
  enumerize :usage_indicator, :in => Nomen::Indicators.all, :predicates => {:prefix => true}
  enumerize :sale_indicator_unit, :in => Nomen::Units.all, :predicates => {:prefix => true}
  enumerize :purchase_indicator_unit, :in => Nomen::Units.all, :predicates => {:prefix => true}
  enumerize :usage_indicator_unit, :in => Nomen::Units.all, :predicates => {:prefix => true}
  belongs_to :nature, :class_name => "ProductNature", :inverse_of => :variants
  has_many :products, :foreign_key => :variant_id
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :horizontal_rotation, :allow_nil => true, :only_integer => true
  validates_length_of :purchase_indicator, :sale_indicator, :usage_indicator, :allow_nil => true, :maximum => 127
  validates_length_of :commercial_name, :contour, :name, :nature_name, :number, :purchase_indicator_unit, :sale_indicator_unit, :usage_indicator_unit, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :in => [true, false]
  validates_presence_of :commercial_name, :horizontal_rotation, :nature, :nature_name
  #]VALIDATORS]

  delegate :variety, :matching_model, :indicators_array, :population_frozen?, :population_modulo, :to => :nature
  accepts_nested_attributes_for :products, :reject_if => :all_blank, :allow_destroy => true
  acts_as_numbered

  default_scope -> { order(:name) }
  scope :of_variety, Proc.new { |*varieties| where(:nature_id => ProductNature.of_variety(*varieties).pluck(:id)) }

  before_validation :on => :create do
    if self.nature
      self.nature_name ||= self.nature.name
      self.name ||= self.nature_name
      if indicator = self.indicators_array.first
        self.usage_indicator ||= indicator.name
      end
    end
    self.commercial_name ||= self.name
    if item = Nomen::Indicators.find(self.usage_indicator)
      self.usage_indicator_unit = item.unit
      self.sale_indicator ||= self.usage_indicator
      self.sale_indicator_unit ||= self.usage_indicator_unit
      self.purchase_indicator ||= self.usage_indicator
      self.purchase_indicator_unit ||= self.usage_indicator_unit
    end
    if item = Nomen::Indicators.find(self.sale_indicator)
      self.sale_indicator_unit ||= item.unit
    end
    if item = Nomen::Indicators.find(self.purchase_indicator)
      self.purchase_indicator_unit ||= item.unit
    end

  end

  validate do
    # Check that unit match indicator's unit
    for mode in [:usage, :sale, :purchase]
      unit = self.send("#{mode}_indicator_unit").to_s
      if item = Nomen::Indicators[self.send("#{mode}_indicator")] and !unit.blank?
        if Measure.dimension(item.unit) != Measure.dimension(unit)
          errors.add(:"#{mode}_indicator_unit", :invalid)
        end
      end
    end
  end

end
