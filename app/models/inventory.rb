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
# == Table: inventories
#
#  accounted_at      :datetime
#  achieved_at       :datetime
#  created_at        :datetime         not null
#  creator_id        :integer
#  currency          :string
#  custom_fields     :jsonb
#  financial_year_id :integer
#  id                :integer          not null, primary key
#  journal_entry_id  :integer
#  lock_version      :integer          default(0), not null
#  name              :string           not null
#  number            :string           not null
#  reflected         :boolean          default(FALSE), not null
#  reflected_at      :datetime
#  responsible_id    :integer
#  updated_at        :datetime         not null
#  updater_id        :integer
#

class Inventory < Ekylibre::Record::Base
  include Attachable
  include Customizable
  attr_readonly :currency
  refers_to :currency
  belongs_to :responsible, -> { contacts }, class_name: 'Entity'
  has_many :items, class_name: 'InventoryItem', dependent: :destroy, inverse_of: :inventory
  belongs_to :journal_entry, dependent: :destroy
  belongs_to :financial_year
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, :achieved_at, :reflected_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :name, :number, presence: true, length: { maximum: 500 }
  validates :reflected, inclusion: { in: [true, false] }
  # ]VALIDATORS]
  validates :achieved_at, presence: true
  validates :name, uniqueness: true
  validates :financial_year, presence: true

  acts_as_numbered

  scope :unreflecteds, -> { where(reflected: false) }
  scope :before, ->(at) { where(arel_table[:achieved_at].lt(at)) }

  accepts_nested_attributes_for :items

  before_validation do
    self.achieved_at ||= Time.zone.now
    self.currency ||= Preference[:currency]
  end

  #          Mode Inventory     |     Debit                      |            Credit            |
  #     exchange current balance|    - balance (3X)              |   - balance (603X/71X)       |
  #     physical inventory      |    stock(3X)                   |   stock_movement(603X/71X)   |
  bookkeep do |b|
    journal = unsuppress { Journal.find_or_create_by!(nature: :stocks, name: :stocks.to_s.upper) }

    # get all variants corresponding to current items
    variants = ProductNatureVariant.where(id: Product.where(id: items.pluck(:product_id)).pluck(:variant_id).uniq)
    b.journal_entry(journal, printed_on: printed_at.to_date, if: (financial_year && reflected?)) do |entry|
      if journal.entries.any?
        first_started_at = journal.entries.reorder(:printed_on).first.printed_on.to_time
      end
      fy_started_at = first_started_at || financial_year.started_on.to_time
      fy_stopped_at = financial_year.stopped_on.to_time
      variants.each do |variant|
        # for all items of current variant (if storable)
        next unless variant.storable? && variant.stock_account && variant.stock_movement_account

        s = variant.stock_account
        sm = variant.stock_movement_account

        # step 1 : neutralize last current stock in stock journal for current variant
        # by exchanging the current balance
        label = tc(:bookkeep_exchange, resource: self.class.model_name.human, number: number)
        entry.add_credit(label, sm.id, sm.journal_entry_items_calculate(:balance, fy_started_at, fy_stopped_at), resource: variant, as: :stock_movement_reset, variant: variant)
        entry.add_credit(label, s.id, s.journal_entry_items_calculate(:balance, fy_started_at, fy_stopped_at), resource: variant, as: :stock_reset, variant: variant)

        # step 2 : record inventory stock in stock journal
        # TODO update methods to evaluates price stock or open unit_pretax-
        # stock_amount field to the user during inventory
        # build the global value of the stock for each item
        stock_amount = items.of_variant(variant).map(&:actual_pretax_stock_amount).compact.sum
        # bookkeep step 2
        next if stock_amount.zero?
        label = tc(:bookkeep, resource: self.class.model_name.human, number: number)
        entry.add_credit(label, sm.id, stock_amount, resource: variant, as: :stock, variant: variant)
        entry.add_debit(label, s.id, stock_amount, resource: variant, as: :stock_movement, variant: variant)
      end
    end
  end

  def printed_at
    (reflected? ? reflected_at : achieved_at? ? self.achieved_at : created_at)
  end

  protect do
    old_record.reflected?
  end

  def reflectable?
    !reflected? # && self.class.unreflecteds.before(self.achieved_at).empty?
  end

  # Apply deltas on products and raises an error if any problem
  def reflect!
    raise StandardError, 'Cannot reflect inventory on stocks' unless reflect
  end

  # Apply deltas on products
  def reflect
    unless reflectable?
      errors.add(:reflected, :invalid)
      return false
    end
    self.reflected_at = Time.zone.now
    self.reflected = true
    return false unless valid? && items.all?(&:valid?)
    save
    items.find_each(&:save)
    true
  end

  def build_missing_items
    self.achieved_at ||= Time.zone.now
    Matter.at(achieved_at).mine_or_undefined(achieved_at).find_each do |product|
      next if items.detect { |i| i.product_id == product.id }
      population = product.population(at: self.achieved_at)
      # shape = product.shape(at: self.achieved_at)
      items.build(product_id: product.id, actual_population: population, expected_population: population)
    end
  end

  def refresh!
    raise StandardError, 'Cannot refresh uneditable inventory' unless editable?
    items.clear
    build_missing_items
    save!
  end
end
