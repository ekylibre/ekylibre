# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
  has_many :part_replacements, class_name: 'InterventionInput', inverse_of: :component, foreign_key: :component_id, dependent: :restrict_with_exception
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :deleted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :product_nature_variant, presence: true
  # ]VALIDATORS]
  # acts_as_nested_set scope: :product_nature_variant_id
  accepts_nested_attributes_for :children, allow_destroy: true

  scope :components_of, ->(variant_id) { variant_id == 'nil' ? none : where(product_nature_variant_id: variant_id) }
  scope :components_of_product, ->(product_id) { product_id == 'nil' ? none : where(product_nature_variant_id: Product.find(product_id).variant_id) }

  before_validation do
    self.product_nature_variant = parent.product_nature_variant if parent
  end

  validate do
    if product_nature_variant && part_product_nature_variant
      if product_nature_variant == part_product_nature_variant
        errors.add :part_product_nature_variant_id, :invalid
      end
      unless product_nature_variant.of_variety?(:equipment)
        errors.add :product_nature_variant_id, :invalid
      end
      unless errors[:part_product_nature_variant_id]
        if parent_variants.include?(part_product_nature_variant)
          errors.add :part_product_nature_variant_id, :invalid
        end
      end
    end

    # Validates uniqueness due to sequential creation messing it up:
    # Ex of a Rails execution:
    #   "C1.name ALREADY EXISTS ?" => false
    #   "C2.name ALREADY EXISTS ?" => false
    #   "C1.create"
    #   "C2.create"
    # Here we go through all Ruby objects (not in-DB records) and to avoid both being flagged
    # as erroring we ignore the first one with the name.
    if product_nature_variant
      unless self == product_nature_variant.components.select { |c| c.name == name }.first
        errors.add :name, :taken if (product_nature_variant.components - [self]).map(&:name).include?(name)
      end
    end
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
