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

class ProductBirth < ProductJunction
  has_start :product
  # include Taskable
  # has_one :producer
  # has_one :producer_route, -> { where(role: "producer") }, through: :routes
  # has_one :product_route, -> { where(role: "product") }, through: :routes
  # belongs_to :product, inverse_of: :birth
  # belongs_to :producer, class_name: "Product", foreign_key: :stakeholder_id
  # enumerize :nature, in: [:division, :creation], predicates: true
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  #]VALIDATORS]
  # validates_inclusion_of :nature, in: self.nature.values

  # before_update do
  #   if self.product_id != old_record.product_id
  #     old_record.product.update_column(:born_at, nil)
  #   end
  # end

  # after_save do
  #   if self.product
  #     if self.stopped_at != self.product.born_at
  #       self.product.update_column(:born_at, self.stopped_at)
  #     end
  #   end
  # end

  # before_destroy do
  #   old_record.product.update_attribute(:born_at, nil)
  # end
end
