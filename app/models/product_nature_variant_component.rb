# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: product_nature_variant_components
#
#  created_at                     :datetime         not null
#  creator_id                     :integer
#  deleted_at                     :datetime
#  id                             :integer          not null, primary key
#  lock_version                   :integer          default(0), not null
#  name                           :string           not null
#  parent_id                      :integer
#  part_product_nature_variant_id :integer
#  product_nature_variant_id      :integer          not null
#  updated_at                     :datetime         not null
#  updater_id                     :integer
#
class ProductNatureVariantComponent < Ekylibre::Record::Base
  belongs_to :product_nature_variant, class_name: 'ProductNatureVariant', inverse_of: :components
  belongs_to :part_product_nature_variant, class_name: 'ProductNatureVariant'
  belongs_to :parent, class_name: 'ProductNatureVariantComponent', inverse_of: :children
  has_many :children, class_name: 'ProductNatureVariantComponent', foreign_key: :parent_id, inverse_of: :parent
  has_many :part_replacements, class_name: 'ProductPartReplacement', inverse_of: :component, foreign_key: :component_id
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :deleted_at, timeliness: { allow_blank: true, on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  validates :name, :product_nature_variant, presence: true
  # ]VALIDATORS]
  validates :name, uniqueness: { case_sensitive: false, scope: :product_nature_variant_id }
  # acts_as_nested_set scope: :product_nature_variant_id
  accepts_nested_attributes_for :children, allow_destroy: true

  scope :components_of, -> (variant_id) { variant_id.nil? ? none : where(product_nature_variant_id: variant_id) }

  before_validation do
    if parent
    self.product_nature_variant = self.parent.product_nature_variant
    end
  end

  validate do
    if product_nature_variant && part_product_nature_variant
      errors.add :part_product_nature_variant_id, :invalid if (product_nature_variant_id == part_product_nature_variant_id)
      unless errors[:part_product_nature_variant_id]
        errors.add :part_product_nature_variant_id, :invalid if parent_variants.include?(part_product_nature_variant)
      end
    end
  end

 # Find the product_nature_variant_component corresponding to a component, for a given  product_nature_variant
  # There can't be many product_nature_variant_component
  # je retrouve le variant_component d'un component pour un variant donné.
  # Je ne peux pas avoir plusieur variant_component pour un component avec un variant donné
  def product_nature_variant_component_for(assembly_variant)
    list = product_nature_variant_components.select do |component|
      component.parent_components.detect do |parent|
        parent.product_nature_variant == assembly_variant
      end
    end
    if list.size > 1
      raise 'Unexpected count of component for given variant'
    end
    list.first
  end

  #For a given product, return part_product_nature_variant, if there is a product_nature_variant_component
  #If there is no product_nature_variant_component, return nil.
  #Pour un produit donné, on renvoie le part_product_nature_variant s'il exise un product_nature_variant_component
  #sinon retourne nul.
  def part_product_nature_variant_for(assembly)
    component = product_nature_variant_component_for(assembly.variant)
    if component
      return component.part_product_nature_variant
    end
    return nil
  end

  def self_and_parents
    unless @self_and_parents
      @self_and_parents = [self]
      @self_and_parents += parent.self_and_parents if parent
    end
    @self_and_parents
  end

  # return in the list all the parent's variant, and do this until there are no more parent's
  def parent_variants
    parents = self.class.where(part_product_nature_variant: part_product_nature_variant)
    list = []
    parents.each do |parent|
      list << parent.product_nature_variant
      list += parent.parent_variants
    end
    list
  end
end
