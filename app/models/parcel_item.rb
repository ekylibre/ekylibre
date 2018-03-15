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
class ParcelItem < Ekylibre::Record::Base
  attr_readonly :parcel_id
  attr_accessor :product_nature_variant_id
  enumerize :delivery_mode, in: %i[transporter us third none], predicates: { prefix: true }, scope: true, default: :us
  belongs_to :analysis
  # belongs_to :parcel, inverse_of: :items
  # belongs_to :reception, inverse_of: :items, class_name: 'Reception', foreign_key: :parcel_id
  with_options class_name: 'PurchaseItem' do
    belongs_to :purchase_order_item, foreign_key: 'purchase_order_item_id'
    belongs_to :purchase_invoice_item, foreign_key: 'purchase_invoice_item_id'
  end

  belongs_to :product
  belongs_to :sale_item
  belongs_to :delivery
  belongs_to :transporter, class_name: 'Entity'
  belongs_to :source_product, class_name: 'Product'
  belongs_to :source_product_movement, class_name: 'ProductMovement', dependent: :destroy
  belongs_to :variant, class_name: 'ProductNatureVariant'
  belongs_to :equipment, class_name: 'Product'
  has_one :nature, through: :variant
  has_one :product_enjoyment, as: :originator, dependent: :destroy
  has_one :product_localization, as: :originator, dependent: :destroy
  has_one :product_movement, as: :originator, dependent: :destroy
  has_one :product_ownership, as: :originator, dependent: :destroy
  has_many :storings, class_name: 'ParcelItemStoring', inverse_of: :parcel_item, foreign_key: :parcel_item_id, dependent: :destroy
  has_many :products, through: :storings

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :currency, :non_compliant_detail, :product_identification_number, :product_name, :product_work_number, :role, length: { maximum: 500 }, allow_blank: true
  validates :merge_stock, :non_compliant, inclusion: { in: [true, false] }, allow_blank: true
  validates :parted, inclusion: { in: [true, false] }
  validates :population, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :pretax_amount, :unit_pretax_amount, :unit_pretax_stock_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  # ]VALIDATORS]
  validates :variant, presence: true
  # validates :product, presence: true, unless: proc { |item| !item.parcel.try(:prepared?) }

  validates :population, presence: true, numericality: { less_than_or_equal_to: 1,
                                                         if: :product_is_unitary?,
                                                         message: 'activerecord.errors.messages.unitary_in_parcel'.t }
  # validates :product_identification_number, presence: { if: -> { product_is_identifiable? && parcel_incoming? } }

  alias_attribute :quantity, :population

  accepts_nested_attributes_for :products
  accepts_nested_attributes_for :storings, allow_destroy: true

  delegate :draft?, :given?, to: :reception, prefix: true, allow_nil: true
  delegate :draft?, :in_preparation?, :prepared?, :given?, to: :shipment, prefix: true
  delegate :unit_name, to: :variant

  delegate :unit_name, to: :variant

  before_validation do
    if variant
      catalog_item = variant.catalog_items.of_usage(:stock)
      if catalog_item.any? && catalog_item.first.pretax_amount != 0.0
        self.unit_pretax_stock_amount = catalog_item.first.pretax_amount
      end
    end

    self.population ||= product_is_unitary? ? 1 : 0

    # Use the unit_amount of purchase_order_item if amount equal to zero
    if purchase_order_item.present? && unit_pretax_amount.zero?
      self.unit_pretax_amount = purchase_order_item.unit_pretax_amount
    else
      self.unit_pretax_amount ||= 0.0
    end

    self.pretax_amount = population * self.unit_pretax_amount

    true
  end

  ALLOWED = %w[
    product_localization_id
    product_movement_id
    product_enjoyment_id
    product_ownership_id
    unit_pretax_stock_amount
    unit_pretax_amount
    pretax_amount
    purchase_order_item_id
    purchase_invoice_item_id
    sale_item_id
    updated_at
    updater_id
  ].freeze

  def stock_amount
    population * unit_pretax_stock_amount
  end

  def status
    prepared? ? :go : variant.present? ? :caution : :stop
  end

  def prepared?
    false
  end

  def product_is_identifiable?
    [variant, source_product].reduce(false) do |acc, product_input|
      acc || Maybe(product_input).identifiable?.or_else(false)
    end
  end

  def product_is_unitary?
    [variant, source_product].reduce(false) do |acc, product_input|
      acc || Maybe(product_input).population_counting_unitary?.or_else(false)
    end
  end

  def name
    Maybe(source_product || variant || products).name.or_else(nil)
  end

  def purchase_order_number
    return nil if purchase_order_item.nil?

    purchase_order_item.purchase.number
  end

  def purchase_invoice_number
    return nil if purchase_invoice_item.nil?
    purchase_invoice_item.purchase.number
  end

  protected

  def check_outgoing(_checked_at)
    update! product: source_product
  end

  def existing_reception_product_in_storage(storing)
    similar_products = Product.where(variant: variant)
    product_in_storage = similar_products.find do |p|
      location = p.localizations.last.container
      owner = p.owner
      location == storing.storage && owner = Entity.of_company
    end
  end

  def existing_product_in_storage
    similar_products = Product.where(variant: variant)
    product_in_storage = similar_products.find do |p|
      location = p.localizations.last.container
      owner = p.owner
      location == storage && owner = Entity.of_company
    end
    product_in_storage
  end
end
