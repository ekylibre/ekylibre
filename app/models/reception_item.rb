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
class ReceptionItem < ParcelItem
  belongs_to :reception, inverse_of: :items, class_name: 'Reception', foreign_key: :parcel_id
  belongs_to :project_budget, class_name: 'ProjectBudget', foreign_key: :project_budget_id
  belongs_to :purchase_order_to_close, class_name: 'PurchaseOrder', foreign_key: :purchase_order_to_close_id

  has_one :storage, through: :reception
  has_one :contract, through: :reception

  validates :product_name, presence: { if: -> { product_is_identifiable? } }

  delegate :allow_items_update?, :remain_owner, :planned_at,
           :ordered_at, :recipient, :in_preparation_at,
           :prepared_at, :given_at,
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
    self.pretax_amount = unit_pretax_amount * quantity
  end

  after_save do
    if Preference[:catalog_price_item_addition_if_blank]
      for usage in %i[stock purchase]
        # set stock catalog price if blank
        catalog = Catalog.by_default!(usage)
        unless variant.catalog_items.of_usage(usage).any? || unit_pretax_amount.blank? || unit_pretax_amount.zero?
          variant.catalog_items.create!(catalog: catalog, all_taxes_included: false, amount: unit_pretax_amount, currency: currency) if catalog
        end
      end
    end
    reception.save if pretax_amount_changed?

    if purchase_order_to_close.present? && !purchase_order_to_close.closed?
      purchase_order_to_close.close
    end
  end

  # protect(allow_update_on: ALLOWED, on: %i[create destroy update]) do
  #  !reception_allow_items_update?
  # end

  def prepared?
    variant.present?
  end

  def trade_item
    purchase_order_item
  end

  # Set started_at/stopped_at in tasks concerned by preparation of item
  # It takes product in stock
  def check
    checked_at = reception_prepared_at
    state = true
    state, msg = check_incoming(checked_at)
    return state, msg unless state
    save!
  end

  # Mark items as given, and so change enjoyer and ownership if needed at
  # this moment.
  def give
    transaction do
      give_outgoing if reception.outgoing?
      check_incoming if reception.incoming?
    end
  end

  protected

  def check_incoming
    fusing = merge_stock? || product_is_unitary?

    # Create a matter for each storing
    storings.each do |storing|
      product_params = {}
      product_params[:name] = product_name || "#{variant.name} (#{reception.number})"
      product_params[:identification_number] = product_identification_number
      product_params[:work_number] = product_work_number
      product_params[:initial_born_at] = [reception_prepared_at, reception_given_at].compact.min
      product = existing_reception_product_in_storage(storing) if fusing
      product ||= variant.create_product(product_params)
      storing.update(product: product)
      return false, product.errors if product.errors.any?
      ProductMovement.create!(product: product, delta: storing.quantity, started_at: reception_given_at, originator: self) unless product_is_unitary?
      ProductLocalization.create!(product: product, nature: :interior, container: storing.storage, started_at: reception_given_at, originator: self)
      ProductEnjoyment.create!(product: product, enjoyer: Entity.of_company, nature: :own, started_at: reception_given_at, originator: self)
      ProductOwnership.create!(product: product, owner: Entity.of_company, nature: :own, started_at: reception_given_at, originator: self) unless reception_remain_owner
    end
    true
  end

  def give_incoming
    check_incoming(reception_prepared_at)
  end
end
