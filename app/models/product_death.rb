# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
# == Table: product_junctions
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  operation_id    :integer
#  originator_id   :integer
#  originator_type :string(255)
#  started_at      :datetime
#  stopped_at      :datetime
#  tool_id         :integer
#  type            :string(255)
#  updated_at      :datetime         not null
#  updater_id      :integer
#
class ProductDeath < ProductJunction
  has_end :product
  # belongs_to :product, inverse_of: :death
  # belongs_to :absorber, class_name: "Product", foreign_key: :stakeholder_id
  # enumerize :nature, in: [:merging, :consumption]

  # before_update do
  #   if self.product.id != old_record.product_id
  #     old_record.product.update_column(:dead_at, nil)
  #   end
  # end

  # before_save do
  #   if self.product
  #     if self.stopped_at != self.product.dead_at
  #       self.product.update_column(:dead_at, self.stopped_at)
  #     end
  #   end
  # end

  # after_save do
  #   self.product.is_measured!(:population, 0, at: self.stopped_at)
  # end

  # before_destroy do
  #   old_record.product.indicator_data.where(indicator: "population", measured_at: old_record.stopped_at).destroy_all
  #   old_record.product.update_column(:dead_at, nil)
  # end

end
