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
# == Table: parcel_item_storings
#
#  created_at     :datetime         not null
#  creator_id     :integer
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  parcel_item_id :integer          not null
#  quantity       :integer
#  storage_id     :integer          not null
#  updated_at     :datetime         not null
#  updater_id     :integer
#
class ParcelItemStoring < Ekylibre::Record::Base
  belongs_to :parcel_item, inverse_of: :storings
  belongs_to :storage, class_name: 'Product'

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :quantity, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :parcel_item, :storage, presence: true
  # ]VALIDATORS]
end
