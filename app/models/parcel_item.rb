# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
#  analysis_id                     :integer
#  created_at                      :datetime         not null
#  creator_id                      :integer
#  id                              :integer          not null, primary key
#  lock_version                    :integer          default(0), not null
#  parcel_id                       :integer          not null
#  parted                          :boolean          default(FALSE), not null
#  population                      :decimal(19, 4)
#  product_enjoyment_id            :integer
#  product_id                      :integer
#  product_localization_id         :integer
#  product_movement_id             :integer
#  product_ownership_id            :integer
#  product_shape_reading_id        :integer
#  purchase_item_id                :integer
#  sale_item_id                    :integer
#  shape                           :geometry({:srid=>4326, :type=>"multi_polygon"})
#  source_product_id               :integer
#  source_product_movement_id      :integer
#  source_product_shape_reading_id :integer
#  updated_at                      :datetime         not null
#  updater_id                      :integer
#  variant_id                      :integer
#
class ParcelItem < Ekylibre::Record::Base
  attr_readonly :parcel_id
  attr_accessor :product_nature_variant_id
  belongs_to :analysis
  belongs_to :parcel, inverse_of: :items
  belongs_to :product
  belongs_to :product_enjoyment,          dependent: :destroy
  belongs_to :product_localization,       dependent: :destroy
  belongs_to :product_ownership,          dependent: :destroy
  belongs_to :product_movement,           dependent: :destroy
  belongs_to :purchase_item
  belongs_to :sale_item
  belongs_to :source_product, class_name: 'Product'
  belongs_to :source_product_movement, class_name: 'ProductMovement', dependent: :destroy
  belongs_to :variant, -> { of_variety :matter }, class_name: 'ProductNatureVariant'
  has_one :category, through: :variant
  has_one :nature, through: :variant
  has_one :delivery, through: :parcel
  has_one :storage, through: :parcel

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :population, allow_nil: true
  validates_inclusion_of :parted, in: [true, false]
  validates_presence_of :parcel
  # ]VALIDATORS]
  validates_presence_of :source_product, if: :parcel_prepared?
  validates_presence_of :product, if: :parcel_prepared?

  validates_numericality_of :population, less_than_or_equal_to: 1,
    if: :product_is_unitary?,
    message: "activerecord.errors.messages.unitary_in_parcel".t
  validates_presence_of :product_name, if: -> { product_is_unitary? && parcel_incoming? }
  validates_presence_of :product_identification_number, if: -> { product_is_unitary? && parcel_incoming? }

  scope :with_nature, ->(nature) { joins(:parcel).merge(Parcel.with_nature(nature)) }

  alias_attribute :quantity, :population

  accepts_nested_attributes_for :product
  # delegate :net_mass, to: :product
  delegate :allow_items_update?, :remain_owner, :planned_at, :draft?, :ordered_at, :recipient, :in_preparation?, :in_preparation_at, :prepared?, :prepared_at, :given?, :given_at, :outgoing?, :incoming?, :separated_stock?, to: :parcel, prefix: true

  before_validation do
    read_at = parcel ? parcel_prepared_at : Time.zone.now
    self.population ||= product_is_unitary? ? 1 : 0
    next if parcel_incoming?

    if sale_item
      self.variant = sale_item.variant
    elsif purchase_item
      self.variant = purchase_item.variant
    end
    true
  end

  allowed = [
              "product_localization_id",
              "product_enjoyment_id",
              "product_ownership_id",
              "purchase_item_id",
              "updated_at",
            ]
  protect(allow_update_on: allowed, on: [:create, :destroy, :update]) do
    !parcel_allow_items_update?
  end

  def prepared?
    (!parcel_incoming? && source_product.present?) ||
      (parcel_incoming? && variant.present?)
  end

  def status
    prepared? ? :go : variant.present? ? :caution : :stop
  end

  def product_is_unitary?
    [self.variant, self.source_product].reduce(false) do |acc, product_input|
      acc || Maybe(product_input).population_counting_unitary?.or_else(false)
    end
  end

  # Set started_at/stopped_at in tasks concerned by preparation of item
  # It takes product in stock
  def check
    checked_at = parcel_prepared_at
    check_incoming(checked_at) if parcel_incoming?
    check_outgoing(checked_at) if parcel_outgoing?
    save!
  end

  # Mark items as given, and so change enjoyer and ownership if needed at
  # this moment.
  def give
    if parcel_outgoing?
      create_product_enjoyment!(product: product, nature: :other, started_at: parcel_given_at, enjoyer: parcel.recipient)
      unless parcel_remain_owner
        create_product_ownership!(product: product, nature: :other, started_at: parcel_given_at, owner: parcel.recipient)
      end
      if storage
        create_product_localization!(product: product, nature: :exterior, container: storage, started_at: parcel_given_at)
      else
        create_product_localization!(product: product, nature: :exterior, started_at: parcel_given_at)
      end
    else
      if storage
        create_product_localization!(product: product, nature: :interior, container: storage, started_at: parcel_given_at)
      end
      create_product_enjoyment!(product: product, nature: :own, started_at: parcel_given_at)
      unless parcel_remain_owner
        create_product_ownership!(product: product, nature: :own, started_at: parcel_given_at)
      end
    end
  end

  protected

  def check_incoming(checked_at)
    product_params = {}
    no_fusing = self.parcel_separated_stock? || self.product_is_unitary?

    unless no_fusing
      self.product = existing_product_in_storage
      product_params[:name] = "#{variant.name} (#{parcel.number})"
    else
      product_params[:name] = self.product_name
      product_params[:identification_number] = self.product_identification_number
    end

    product_params[:initial_population] = quantity
    product_params[:initial_container] = parcel.storage
    product_params[:initial_born_at] = checked_at

    self.product ||= variant.create_product!(product_params)
    self.product.movements.create!(delta: population, started_at: checked_at) unless no_fusing
  end

  def check_outgoing(checked_at)
    if self.population == source_product.population(at: checked_at)
      source_product.ownerships.create!(owner: parcel_recipient, started_at: checked_at)
    end
    update! product: source_product
    source_product.movements.create!(delta: -1 * population, started_at: checked_at)
  end

  def existing_product_in_storage
    similar_products = Product.where(variant: self.variant)
    product_in_storage = similar_products.find do |p|
      location = p.localizations.last
      location == self.storage
    end
    product_in_storage
  end

end
