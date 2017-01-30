# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
# == Table: product_mergings
#
#  created_at     :datetime         not null
#  creator_id     :integer
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  merged_at      :datetime
#  merged_with_id :integer
#  originator_id  :integer
#  product_id     :integer
#  updated_at     :datetime         not null
#  updater_id     :integer
#
class ProductMerging < Ekylibre::Record::Base
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :merged_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  # ]VALIDATORS]
  belongs_to :product
  belongs_to :originator, class_name: 'InterventionProductParameter'
  belongs_to :merged_with, class_name: 'Product'

  validates :product, presence: true
  validates :merged_with, presence: true

  after_save do
    product.update(dead_at: merged_at)
  end

  before_destroy do
    dead_ats  = Issue.where(target_id: product.id).where.not(observed_at: nil).pluck(:observed_at)
    dead_ats += InterventionTarget.where(product_id: product.id).joins(:intervention).where.not(interventions: { stopped_at: nil }).pluck('interventions.stopped_at')
    product.dead_at = dead_ats.min
  end

  validate do
    unless ProductMerging.where(product: product).where.not(id: id).count.zero?
      errors.add :product, :cannot_merge_product_thats_already_merged
    end
    errors.add :product, :cannot_merge_dead_product if product.dead_at && product.dead_at < merged_at
  end
end
