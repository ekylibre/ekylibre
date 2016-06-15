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
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  name             :string           not null
#  piece_variant_id :integer          not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#  variant_id       :integer          not null
#
class ProductNatureVariantComponent < Ekylibre::Record::Base
  belongs_to :variant, class_name: 'ProductNatureVariant', inverse_of: :components
  belongs_to :piece_variant, class_name: 'ProductNatureVariant'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_presence_of :name, :piece_variant, :variant
  # ]VALIDATORS]
  validates :name, uniqueness: { case_sensitive: false, scope: :variant_id }

  validate do
    if variant
      errors.add :piece_variant_id, :invalid if parent_variants.include?(piece_variant)
    end
  end

  # return in the list all the parent's variant, and do this until there are no more parent's
  def parent_variants
    parents = self.class.where(piece_variant: variant)
    list = []
    parents.each do |parent|
      list << parent.variant
      list += parent.parent_variants
    end
    list
  end
end
