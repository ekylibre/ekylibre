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
#  purchase_invoice_item_id      :integer
#  purchase_order_item_id        :integer
#  role                          :string
#  sale_item_id                  :integer
#  shape                         :geometry({:srid=>4326, :type=>"multi_polygon"})
#  source_product_id             :integer
#  source_product_movement_id    :integer
#  transporter_id                :integer
#  unit_pretax_amount            :decimal(19, 4)   default(0.0), not null
#  unit_pretax_stock_amount      :decimal(19, 4)   default(0.0), not null
#  updated_at                    :datetime         not null
#  updater_id                    :integer
#  variant_id                    :integer
#
class ReceptionItem < ParcelItem
  belongs_to :reception, inverse_of: :items, class_name: 'Reception', foreign_key: :parcel_id

  has_one :storage, through: :reception
  has_one :contract, through: :reception

  validates :source_product, presence: { if: :reception_outgoing? }
  validates :product_name, presence: { if: -> { product_is_identifiable? && reception_incoming? } }

  delegate :allow_items_update?, :remain_owner, :planned_at,
           :ordered_at, :recipient, :in_preparation_at,
           :prepared_at, :given_at, :outgoing?, :incoming?,
           :separated_stock?, :currency, to: :reception, prefix: true

  scope :with_nature, ->(nature) { joins(:reception).merge(Reception.with_nature(nature)) }

  before_validation do
    self.currency = reception_currency if reception
    read_at = reception ? reception_prepared_at : Time.zone.now

    # purchase contrat case
    if variant && contract && contract.items.where(variant: variant).any?
      item = contract.items.where(variant_id: variant.id).first
      self.unit_pretax_amount ||= item.unit_pretax_amount if item && item.unit_pretax_amount
    end

    next if reception_incoming?

    if sale_item
      self.variant = sale_item.variant
    elsif purchase_order_item
      self.variant = purchase_order_item.variant
    elsif reception_outgoing?
      self.variant = source_product.variant if source_product
      self.population = source_product.population if population.nil? || population.zero?
    end

    true
  end

  after_save do
    if Preference[:catalog_price_item_addition_if_blank]
      if reception_incoming?
        for usage in %i[stock purchase]
          # set stock catalog price if blank
          catalog = Catalog.by_default!(usage)
          unless variant.catalog_items.of_usage(usage).any? || unit_pretax_amount.blank? || unit_pretax_amount.zero?
            variant.catalog_items.create!(catalog: catalog, all_taxes_included: false, amount: unit_pretax_amount, currency: currency) if catalog
          end
        end
      end
    end
  end

  protect(allow_update_on: ALLOWED, on: %i[create destroy update]) do
    !reception_allow_items_update?
  end

  def prepared?
    (!reception_incoming? && source_product.present?) ||
      (reception_incoming? && variant.present?)
  end

  def trade_item
    reception_incoming? ? purchase_order_item : sale_item
  end

  # Set started_at/stopped_at in tasks concerned by preparation of item
  # It takes product in stock
  def check
    checked_at = reception_prepared_at
    state = true
    state, msg = check_incoming(checked_at) if reception_incoming?
    check_outgoing(checked_at) if reception_outgoing?
    return state, msg unless state
    save!
  end

  # Mark items as given, and so change enjoyer and ownership if needed at
  # this moment.
  def give
    transaction do
      give_outgoing if reception_outgoing?
      give_incoming if reception_incoming?
    end
  end

  protected

  def check_incoming(checked_at)
    product_params = {}
    no_fusing = reception_separated_stock? || product_is_unitary?

    product_params[:name] = product_name
    product_params[:name] ||= "#{variant.name} (#{reception.number})"
    product_params[:identification_number] = product_identification_number
    product_params[:work_number] = product_work_number
    product_params[:initial_born_at] = [checked_at, reception_given_at].compact.min

    self.product = existing_product_in_storage unless no_fusing || storage.blank?

    self.product ||= variant.create_product(product_params)

    return false, self.product.errors if self.product.errors.any?
    true
  end

  def give_incoming
    check_incoming(reception_prepared_at)
    ProductMovement.create!(product: product, delta: population, started_at: reception_given_at, originator: self) unless product_is_unitary?
    ProductLocalization.create!(product: product, nature: :interior, container: storage, started_at: reception_given_at, originator: self)
    ProductEnjoyment.create!(product: product, enjoyer: Entity.of_company, nature: :own, started_at: reception_given_at, originator: self)
    ProductOwnership.create!(product: product, owner: Entity.of_company, nature: :own, started_at: reception_given_at, originator: self) unless reception_remain_owner
  end

  def give_outgoing
    if population == source_product.population(at: reception_given_at) && !reception_remain_owner
      ProductOwnership.create!(product: product, owner: reception_recipient, started_at: reception_given_at, originator: self)
      ProductLocalization.create!(product: product, nature: :exterior, started_at: reception_given_at, originator: self)
      ProductEnjoyment.create!(product: product, enjoyer: reception_recipient, nature: :other, started_at: reception_given_at, originator: self)
    end
    ProductMovement.create!(product: product, delta: -1 * population, started_at: reception_given_at, originator: self)
  end
end
