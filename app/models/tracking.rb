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
# == Table: trackings
#
#  active             :boolean          default(TRUE), not null
#  created_at         :datetime         not null
#  creator_id         :integer
#  description        :text
#  id                 :integer          not null, primary key
#  lock_version       :integer          default(0), not null
#  name               :string           not null
#  producer_id        :integer
#  product_id         :integer
#  serial             :string
#  updated_at         :datetime         not null
#  updater_id         :integer
#  usage_limit_nature :string
#  usage_limit_on     :date
#
class Tracking < Ekylibre::Record::Base
  enumerize :usage_limit_nature, in: %i[no_limit used_by best_before], default: :no_limit, predicates: true
  belongs_to :producer, class_name: 'Entity'
  belongs_to :product
  has_many :products, class_name: 'Product', foreign_key: :tracking_id, inverse_of: :tracking
  has_many :parcel_items, through: :products
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :active, inclusion: { in: [true, false] }
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :serial, length: { maximum: 500 }, allow_blank: true
  validates :usage_limit_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years }, type: :date }, allow_blank: true
  # ]VALIDATORS]
  validates :usage_limit_on, presence: { unless: :no_limit? }

  alias_attribute :serial_number, :serial

  protect(on: :destroy) do
    products.any?
  end

  # get outgoing parcel quantity throught tracking
  def outgoing_parcel_quantity(unit = :kilogram)
    if parcel_items.any?
      qty = parcel_items.map(&:population).sum
      qty.in(unit)
    end
  end

  # get sale amount throught tracking
  def sales_pretax_amount(currency = Preference[:currency].to_s)
    sale_items = SaleItem.where(id: parcel_items.pluck(:sale_item_id))
    if sale_items.any?
      sale_items.map(&:pretax_amount).compact.sum.l(currency: currency)
    end
  end
end
