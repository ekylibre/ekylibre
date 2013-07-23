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
  attr_accessible :active, :commercial_name, :nature_id, :nature_name, :name, :purchase_indicator, :purchase_indicator_unit, :sale_indicator, :sale_indicator_unit, :usage_indicator, :usage_indicator_unit
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

  delegate :variety, :matching_model, :individual, :to => :nature

  acts_as_numbered

  default_scope -> { order(:name) }
  scope :of_variety, Proc.new { |*varieties| where(:nature_id => ProductNature.of_variety(*varieties).pluck(:id)) }
  # Variety scopes
  scope :animals, lambda { joins(:nature).merge(ProductNature.animals).order(:name)}
  scope :plants, lambda { joins(:nature).merge(ProductNature.plants).order(:name)}
  scope :plant_medicines, lambda { joins(:nature).merge(ProductNature.plant_medicines).order(:name)}
  scope :animal_medicines, lambda { joins(:nature).merge(ProductNature.animal_medicines).order(:name)}
  scope :equipments, lambda { joins(:nature).merge(ProductNature.equipments).order(:name)}
  scope :buildings, lambda { joins(:nature).merge(ProductNature.buildings).order(:name)}
  scope :organic_matters, lambda { joins(:nature).merge(ProductNature.organic_matters).order(:name)}
  scope :mineral_matters, lambda { joins(:nature).merge(ProductNature.mineral_matters).order(:name)}
  scope :matters, lambda { joins(:nature).merge(ProductNature.matters).order(:name)}
  scope :land_parcels, lambda { joins(:nature).merge(ProductNature.land_parcels).order(:name)}
  scope :land_parcel_groups, lambda { joins(:nature).merge(ProductNature.land_parcel_groups).order(:name)}
  scope :land_parcel_clusters, lambda { joins(:nature).merge(ProductNature.land_parcel_clusters).order(:name)}
  scope :cultivable_land_parcels, lambda { joins(:nature).merge(ProductNature.cultivable_land_parcels).order(:name)}


  before_validation :on => :create do
    if self.nature
      self.nature_name ||= self.nature.name
    end
  end


  # Returns indicators from the nomenclature
  def indicators
    self.nature.indicators.to_s.strip.split(/[\,\s]/).collect do |i|
      Nomen::Indicators.find(i)
    end.compact
  end

end
