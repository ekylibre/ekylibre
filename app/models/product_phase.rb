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
# == Table: product_phases
#
#  category_id     :integer          not null
#  created_at      :datetime         not null
#  creator_id      :integer
#  id              :integer          not null, primary key
#  intervention_id :integer
#  lock_version    :integer          default(0), not null
#  nature_id       :integer          not null
#  originator_id   :integer
#  originator_type :string
#  product_id      :integer          not null
#  started_at      :datetime
#  stopped_at      :datetime
#  updated_at      :datetime         not null
#  updater_id      :integer
#  variant_id      :integer          not null
#
class ProductPhase < Ekylibre::Record::Base
  include Taskable, TimeLineable
  belongs_to :product
  belongs_to :variant,  class_name: 'ProductNatureVariant'
  belongs_to :nature,   class_name: 'ProductNature'
  belongs_to :category, class_name: 'ProductNatureCategory'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :started_at, :stopped_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_presence_of :category, :nature, :product, :variant
  # ]VALIDATORS]

  delegate :variety, :derivative_of, :name, :nature, to: :variant, prefix: true

  # Sets nature and variety from variant
  before_validation on: :create do
    self.nature   = variant.nature if variant
    self.category = nature.category if nature
  end

  # Updates product
  after_save do
    if self.last_for_now?
      product.update_columns(variant_id: variant_id, nature_id: nature_id, category_id: category_id)
    end
  end

  # Updates product
  before_destroy do
    if self.last_for_now?
      if previous = self.previous
        product.update_columns(variant_id: previous.variant_id, nature_id: previous.nature_id, category_id: previous.category_id)
      else
        fail 'Cannot destroy this product phase' unless destroyed_by_association
      end
    end
  end

  private

  def siblings
    product.phases
  end
end
