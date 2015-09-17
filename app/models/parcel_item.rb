# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
#  analysis_id                          :integer
#  created_at                           :datetime         not null
#  creator_id                           :integer
#  id                                   :integer          not null, primary key
#  lock_version                         :integer          default(0), not null
#  parcel_id                            :integer          not null
#  parted                               :boolean          default(FALSE), not null
#  population                           :decimal(19, 4)
#  product_enjoyment_id                 :integer
#  product_id                           :integer
#  product_localization_id              :integer
#  product_ownership_id                 :integer
#  product_population_reading_id        :integer
#  product_shape_reading_id             :integer
#  purchase_item_id                     :integer
#  sale_item_id                         :integer
#  shape                                :geometry({:srid=>4326, :type=>"geometry"})
#  source_product_division_id           :integer
#  source_product_id                    :integer
#  source_product_population_reading_id :integer
#  source_product_shape_reading_id      :integer
#  updated_at                           :datetime         not null
#  updater_id                           :integer
#  variant_id                           :integer
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
  belongs_to :product_population_reading, class_name: 'ProductReading', dependent: :destroy
  belongs_to :product_shape_reading,      class_name: 'ProductReading', dependent: :destroy
  belongs_to :purchase_item
  belongs_to :sale_item
  belongs_to :source_product, class_name: 'Product'
  belongs_to :source_product_division, class_name: 'ProductJunction', dependent: :destroy
  belongs_to :source_product_population_reading, class_name: 'ProductReading', dependent: :destroy
  belongs_to :source_product_shape_reading, class_name:      'ProductReading', dependent: :destroy
  belongs_to :variant, class_name: 'ProductNatureVariant'
  has_one :category, through: :variant
  has_one :nature, through: :variant
  has_one :delivery, through: :parcel
  has_one :storage, through: :parcel

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :population, allow_nil: true
  validates_inclusion_of :parted, in: [true, false]
  validates_presence_of :parcel
  # ]VALIDATORS]
  validates_presence_of :source_product, if: :prepared?
  validates_presence_of :product, if: :prepared?

  scope :with_nature, ->(nature) { joins(:parcel).merge(Parcel.with_nature(nature)) }

  accepts_nested_attributes_for :product
  delegate :name, to: :product, prefix: true
  # delegate :net_mass, to: :product
  delegate :planned_at, :draft?, :ordered_at, :in_preparation?, :in_preparation_at, :prepared?, :prepared_at, :given?, :given_at, :outgoing?, :incoming?, :internal?, to: :parcel

  # sums :parcel, :items, :net_mass, from: :measure

  before_validation do
    if source_product
      if source_product.population_counting_unitary?
        self.parted = false
        self.population = 1
      end
      unless self.parted?
        self.product = source_product
        read_at = prepared_at || Time.zone.now
        if parcel
          self.population ||= product.population(at: read_at)
          self.shape ||= product.shape(at: read_at) if product.has_indicator?(:shape)
        end
      end
    end
    if product
      self.variant = product.variant
    elsif source_product
      self.variant = source_product.variant
    elsif sale_item
      self.variant = sale_item.variant
    elsif purchase_item
      self.variant = purchase_item.variant
    end
    true
  end

  def prepared?
    source_product.present?
  end

  def status
    self.prepared? ? :go : variant.present? ? :caution : :stop
  end

  # Set started_at/stopped_at in tasks concerned by preparation of item
  # It takes product in stock
  def check
    checked_at = prepared_at
    if source_product
      if self.population != source_product.population(at: checked_at)
        update_attribute(:parted, true)
      end
    end
    if parted
      divide_source_product(checked_at)
    else
      self.product = source_product
      self.population = product.population(at: checked_at)
      self.shape = product.shape(at: checked_at)
    end
  end

  # Mark items as given, and so change enjoyer and ownership if needed at
  # this moment.
  def give
    if outgoing?
      self.create_product_enjoyment!(product: product, nature: :other, started_at: given_at, enjoyer: parcel.recipient)
      unless parcel.remain_owner
        self.create_product_ownership!(product: product, nature: :other, started_at: given_at, owner: parcel.recipient)
      end
      if storage
        self.create_product_localization!(product: product, nature: :exterior, container: storage, started_at: given_at)
      else
        self.create_product_localization!(product: product, nature: :exterior, started_at: given_at)
      end
    else
      if storage
        self.create_product_localization!(product: product, nature: :interior, container: storage, started_at: given_at)
      end
      self.create_product_enjoyment!(product: product, nature: :own, started_at: given_at)
      unless parcel.remain_owner
        self.create_product_ownership!(product: product, nature: :own, started_at: given_at)
      end
    end
  end

  protected

  def divide_source_product(divided_at)
    if product
      product.initial_population = population # (at: divided_at)
      product.initial_shape = shape # (at: divided_at)
      product.initial_born_at = divided_at
      product.save!
    else
      self.product = source_product.part_with!(population, shape: shape, born_at: divided_at)
    end
    update_division_task(divided_at)
    update_division_readings(divided_at)
  end

  # Create or update division task
  def update_division_task(divided_at)
    separated = product
    reduced = source_product
    attributes = {
      nature: :division,
      started_at: divided_at,
      ways_attributes: [
        { role: :separated, product: separated },
        { role: :reduced, product: reduced }
      ]
    }
    if source_product_division
      source_product_division.update_attributes!(attributes)
    else
      self.create_source_product_division!(attributes)
    end
  end

  # Create or update division readings
  def update_division_readings(divided_at)
    product.copy_readings_of!(source_product, at: divided_at, originator: source_product_division)
    source_population = source_product.get!(:population, at: divided_at)
    self.source_product_population_reading = source_product.read!(:population, source_population - population, at: divided_at)
    self.product_population_reading = product.read!(:population, population, at: divided_at)
    if source_product.has_indicator?(:shape) && shape
      source_shape = Charta::Geometry.new(source_product.get!(:shape, at: divided_at))
      self.source_product_shape_reading = source_product.read!(:shape, source_shape - shape, at: divided_at)
      self.product_shape_reading = product.read!(:shape, shape, at: divided_at)
    end
  end
end
