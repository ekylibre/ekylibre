# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
# == Table: parcel_items
#
#  analysis_id                   :integer
#  created_at                    :datetime         not null
#  creator_id                    :integer
#  currency                      :string
#  delivery_id                   :integer
#  delivery_mode                 :string
#  equipment_id                  :integer
#  id                            :integer          not null, primary key
#  lock_version                  :integer          default(0), not null
#  merge_stock                   :boolean          default(TRUE)
#  non_compliant                 :boolean
#  non_compliant_detail          :string
#  parcel_id                     :integer          not null
#  parted                        :boolean          default(FALSE), not null
#  population                    :decimal(19, 4)
#  pretax_amount                 :decimal(19, 4)   default(0.0), not null
#  product_enjoyment_id          :integer
#  product_id                    :integer
#  product_identification_number :string
#  product_localization_id       :integer
#  product_movement_id           :integer
#  product_name                  :string
#  product_ownership_id          :integer
#  product_work_number           :string
#  project_budget_id             :integer
#  purchase_invoice_item_id      :integer
#  purchase_order_item_id        :integer
#  purchase_order_to_close_id    :integer
#  role                          :string
#  sale_item_id                  :integer
#  shape                         :geometry({:srid=>4326, :type=>"multi_polygon"})
#  source_product_id             :integer
#  source_product_movement_id    :integer
#  transporter_id                :integer
#  type                          :string
#  unit_pretax_amount            :decimal(19, 4)   default(0.0), not null
#  unit_pretax_stock_amount      :decimal(19, 4)   default(0.0), not null
#  updated_at                    :datetime         not null
#  updater_id                    :integer
#  variant_id                    :integer
#
class ShipmentItem < ParcelItem
  belongs_to :shipment, inverse_of: :items, class_name: 'Shipment', foreign_key: :parcel_id

  has_one :storage, through: :shipment
  has_one :contract, through: :shipment

  validates :source_product, presence: true

  delegate :allow_items_update?, :remain_owner, :planned_at,
           :ordered_at, :recipient, :in_preparation_at,
           :prepared_at, :given_at,
           :separated_stock?, :currency, to: :shipment, prefix: true

  scope :with_nature, ->(nature) { joins(:shipment).merge(Shipment.with_nature(nature)) }

  before_validation do
    self.currency = shipment_currency if shipment
    read_at = shipment ? shipment_prepared_at : Time.zone.now

    # purchase contrat case
    if variant && contract && contract.items.where(variant: variant).any?
      item = contract.items.where(variant_id: variant.id).first
      self.unit_pretax_amount ||= item.unit_pretax_amount if item && item.unit_pretax_amount
    end

    if sale_item
      self.variant = sale_item.variant
    elsif purchase_order_item
      self.variant = purchase_order_item.variant
    else
      self.variant = source_product.variant if source_product
      self.population = source_product.population if population.nil? || population.zero?
    end

    true
  end

  protect(allow_update_on: ALLOWED, on: %i[create destroy update]) do
    !shipment_allow_items_update?
  end

  def prepared?
    source_product.present?
  end

  def trade_item
    sale_item
  end

  # Set started_at/stopped_at in tasks concerned by preparation of item
  # It takes product in stock
  def check
    checked_at = shipment_prepared_at
    state = true
    check_outgoing(checked_at)
    return state, msg unless state
    save!
  end

  # Mark items as given, and so change enjoyer and ownership if needed at
  # this moment.
  def give
    give_outgoing
  end

  protected

  def check_outgoing(_checked_at)
    update! product: source_product
  end

  def give_outgoing
    if population == source_product.population(at: shipment_given_at) && !shipment_remain_owner
      ProductOwnership.create!(product: product, owner: shipment_recipient, started_at: shipment_given_at, originator: self)
      ProductLocalization.create!(product: product, nature: :exterior, started_at: shipment_given_at, originator: self)
      ProductEnjoyment.create!(product: product, enjoyer: shipment_recipient, nature: :other, started_at: shipment_given_at, originator: self)
    end
    ProductMovement.create!(product: product, delta: -1 * population, started_at: shipment_given_at, originator: self)
  end
end
