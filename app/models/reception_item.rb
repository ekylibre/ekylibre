# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
#  activity_budget_id            :integer
#  analysis_id                   :integer
#  annotation                    :text
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
#  team_id                       :integer
#  transporter_id                :integer
#  type                          :string
#  unit_pretax_stock_amount      :decimal(19, 4)   default(0.0), not null
#  updated_at                    :datetime         not null
#  updater_id                    :integer
#  variant_id                    :integer
#
class ReceptionItem < ParcelItem
  belongs_to :reception, inverse_of: :items, class_name: 'Reception', foreign_key: :parcel_id
  belongs_to :project_budget, class_name: 'ProjectBudget', foreign_key: :project_budget_id
  belongs_to :purchase_order_to_close, class_name: 'PurchaseOrder', foreign_key: :purchase_order_to_close_id
  belongs_to :activity_budget
  belongs_to :team

  has_one :storage, through: :reception
  has_one :contract, through: :reception

  enumerize :role, in: %i[merchandise fees service], predicates: true

  validates :product_name, :product_identification_number, presence: { if: -> { product_is_identifiable? } }
  validates :conditioning_unit, :conditioning_quantity, presence: { unless: :merchandise? }
  validates :conditioning_unit, conditioning: { unless: :merchandise? }

  delegate :allow_items_update?, :planned_at,
           :ordered_at, :recipient, :in_preparation_at,
           :prepared_at, :given_at,
           :separated_stock?, :currency, :number, to: :reception, prefix: true

  delegate :sender, to: :reception
  delegate :unit_pretax_amount, :pretax_amount, to: :purchase_order_item, allow_nil: true

  scope :with_nature, ->(nature) { joins(:reception).merge(Reception.with_nature(nature)) }

  before_validation do
    self.currency = reception_currency if reception
    read_at = reception ? reception_prepared_at : Time.zone.now
  end

  def pretax_amount
    return if quantity.nil? || unit_pretax_amount.nil?

    unit_pretax_amount * quantity
  end

  after_save do
    if purchase_order_to_close.present? && !purchase_order_to_close.closed?
      purchase_order_to_close.close
    end
    reception.reload.save if quantity_changed?
  end

  after_destroy do
    purchase_order_item.purchase.update_reconciliation_status! if purchase_order_item
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

  def check
    ActiveSupport::Deprecation.warn "Use check! instead"
    check!
  end

  # Set started_at/stopped_at in tasks concerned by preparation of item
  # It takes product in stock
  def check!
    state, msg = check_incoming
    return state, msg unless state

    save!
  end

  # Mark items as given, and so change enjoyer and ownership if needed at
  # this moment.
  def give
    check_incoming
  end

  # Method used for merchandise parcel_items registered before purchase_process (without parcel_item_storings)
  def guess_conditioning
    matching_unit = Unit.find_by(base_unit: variant.default_unit, coefficient: variant.default_quantity)
    matching_unit ? { unit: matching_unit, quantity: quantity } : { unit: variant.default_unit, quantity: variant.default_quantity * quantity }
  end

  protected

    def check_incoming
      fusing = merge_stock? && !product_is_unitary?

      # Create a matter for each storing
      storings.each do |storing|
        product_params = {
          name: product_name || "#{variant.name} (#{reception.number})",
          identification_number: product_identification_number,
          work_number: product_work_number,
          initial_born_at: [reception_prepared_at, reception_given_at].compact.min,
          conditioning_unit_id: storing.conditioning_unit_id
        }

        product = existing_reception_product_in_storage(storing) if fusing
        product ||= variant.create_product(product_params)

        storing.update(product: product)
        return false, product.errors if product.errors.any?

        ProductMovement.create!(product: product, delta: storing.conditioning_quantity, started_at: reception_given_at, originator: self) unless product_is_unitary?
        ProductLocalization.create!(product: product, nature: :interior, container: storing.storage, started_at: reception_given_at, originator: self)
        ProductEnjoyment.create!(product: product, enjoyer: Entity.of_company, nature: :own, started_at: reception_given_at, originator: self)
        ProductOwnership.create!(product: product, owner: Entity.of_company, nature: :own, started_at: reception_given_at, originator: self) unless reception_remain_owner
      end
      true
    end

    def give_incoming
      ActiveSupport::Deprecation.warn "Use check_incoming instead"
      check_incoming
    end
end
