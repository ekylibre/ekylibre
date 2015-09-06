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
# == Table: product_nature_categories
#
#  active                              :boolean          default(FALSE), not null
#  charge_account_id                   :integer
#  created_at                          :datetime         not null
#  creator_id                          :integer
#  depreciable                         :boolean          default(FALSE), not null
#  description                         :text
#  fixed_asset_account_id              :integer
#  fixed_asset_allocation_account_id   :integer
#  fixed_asset_depreciation_method     :string
#  fixed_asset_depreciation_percentage :decimal(19, 4)   default(0.0)
#  fixed_asset_expenses_account_id     :integer
#  id                                  :integer          not null, primary key
#  lock_version                        :integer          default(0), not null
#  name                                :string           not null
#  number                              :string           not null
#  pictogram                           :string
#  product_account_id                  :integer
#  purchasable                         :boolean          default(FALSE), not null
#  reductible                          :boolean          default(FALSE), not null
#  reference_name                      :string
#  saleable                            :boolean          default(FALSE), not null
#  stock_account_id                    :integer
#  storable                            :boolean          default(FALSE), not null
#  subscribing                         :boolean          default(FALSE), not null
#  subscription_duration               :string
#  subscription_nature_id              :integer
#  updated_at                          :datetime         not null
#  updater_id                          :integer
#
class ProductNatureCategory < Ekylibre::Record::Base
  # Be careful with the fact that it depends directly on the nomenclature definition
  enumerize :pictogram, in: Nomen::ProductNatureCategory.pictogram.choices
  # refers_to :pictogram, class_name: 'ProductPictograms'
  belongs_to :fixed_asset_account, class_name: 'Account'
  belongs_to :fixed_asset_allocation_account, class_name: 'Account'
  belongs_to :fixed_asset_expenses_account, class_name: 'Account'
  belongs_to :charge_account,    class_name: 'Account'
  belongs_to :product_account,   class_name: 'Account'
  belongs_to :stock_account,     class_name: 'Account'
  belongs_to :subscription_nature
  has_many :subscriptions, foreign_key: :product_nature_id
  has_many :natures, class_name: 'ProductNature', foreign_key: :category_id, inverse_of: :category
  has_many :products, foreign_key: :category_id
  has_many :taxations, class_name: 'ProductNatureCategoryTaxation'
  has_many :variants, class_name: 'ProductNatureVariant', foreign_key: :category_id, inverse_of: :category
  has_many :sale_taxations, -> { where(usage: 'sale') }, class_name: 'ProductNatureCategoryTaxation', inverse_of: :product_nature_category
  has_many :sale_taxes, class_name: 'Tax', through: :sale_taxations, source: :tax
  has_many :purchase_taxations, -> { where(usage: 'purchase') }, class_name: 'ProductNatureCategoryTaxation', inverse_of: :product_nature_category
  has_many :purchase_taxes, class_name: 'Tax', through: :purchase_taxations, source: :tax
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :fixed_asset_depreciation_percentage, allow_nil: true
  validates_inclusion_of :active, :depreciable, :purchasable, :reductible, :saleable, :storable, :subscribing, in: [true, false]
  validates_presence_of :name, :number
  # ]VALIDATORS]
  validates_length_of :number, allow_nil: true, maximum: 30
  validates_length_of :pictogram, allow_nil: true, maximum: 120
  validates_presence_of :subscription_nature,   if: :subscribing?
  validates_presence_of :subscription_duration, if: proc { |u| u.subscribing? && u.subscription_nature && u.subscription_nature.period? }
  validates_presence_of :subscription_quantity, if: proc { |u| u.subscribing? && u.subscription_nature && u.subscription_nature.quantity? }
  validates_presence_of :product_account, if: :saleable?
  validates_presence_of :charge_account,  if: :purchasable?
  validates_presence_of :stock_account,   if: :storable?
  validates_presence_of :fixed_asset_account, if: :depreciable?
  validates_presence_of :fixed_asset_allocation_account, if: :depreciable?
  validates_presence_of :fixed_asset_expenses_account, if: :depreciable?
  validates_uniqueness_of :number
  validates_uniqueness_of :name

  accepts_nested_attributes_for :natures,            reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :sale_taxations,     reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :purchase_taxations, reject_if: :all_blank, allow_destroy: true
  acts_as_numbered force: false

  scope :availables,    -> { where(active: true).order(:name) }
  scope :stockables,    -> { where(storable: true).order(:name) }
  scope :saleables,     -> { where(saleable: true).order(:name) }
  scope :purchaseables, -> { where(purchasable: true).order(:name) }
  scope :depreciables, -> { where(depreciable: true).order(:name) }
  scope :stockables_or_depreciables, -> { where('depreciable = ? OR storable = ?', true, true).order(:name) }
  scope :with_catalog_items, -> { where(id: Catalog.joins(items: { variant: :category }).pluck('category_id')) }
  scope :with_sale_catalog_items, -> { where(id: Catalog.for_sale.joins(items: { variant: :category }).pluck('category_id')) }

  protect(on: :destroy) do
    natures.any? && products.any?
  end

  before_validation do
    self.storable = false unless self.deliverable?
    self.subscription_nature_id = nil unless self.subscribing?
  end

  def to
    to = []
    to << :sales if self.saleable?
    to << :purchases if self.purchasable?
    # to << :produce if self.producible?
    to.collect { |x| tc('to.' + x.to_s) }.to_sentence
  end

  def deliverable?
    self.storable?
  end

  def label
    name # tc('label', :product_nature_category => self["name"])
  end

  def duration
    # raise StandardError.new self.subscription_nature.nature.inspect+" blabla"
    if subscription_nature
      send('subscription_' + subscription_nature.nature)
    else
      return nil
    end
  end

  def duration=(value)
    # raise StandardError.new subscription.inspect+self.subscription_nature_id.inspect
    if subscription_nature
      send('subscription_' + subscription_nature.nature + '=', value)
    end
  end

  def default_start
    # self.subscription_nature.nature == "period" ? Date.today.beginning_of_year : self.subscription_nature.actual_number
    subscription_nature.nature == 'period' ? Date.today : subscription_nature.actual_number
  end

  def default_finish
    period = subscription_duration || '1 year'
    # self.subscription_nature.nature == "period" ? Date.today.next_year.beginning_of_year.next_month.end_of_month : (self.subscription_nature.actual_number + ((self.subscription_quantity-1)||0))
    subscription_nature.nature == 'period' ? Delay.compute(period + ', 1 day ago', Date.today) : (subscription_nature.actual_number + ((subscription_quantity - 1) || 0))
  end

  def default_subscription_label_for(entity)
    return nil unless nature == 'subscrip'
    entity  = nil unless entity.is_a? Entity
    address = begin
                entity.default_contact.address
              rescue
                nil
              end
    entity = begin
               entity.full_name
             rescue
               '???'
             end
    if subscription_nature.nature == 'period'
      return tc('subscription_label.period', start: ::I18n.localize(Date.today), finish: ::I18n.localize(Delay.compute(subscription_duration.blank? ? '1 year, 1 day ago' : product.subscription_duration)), entity: entity, address: address, subscription_nature: subscription_nature.name)
    elsif subscription_nature.nature == 'quantity'
      return tc('subscription_label.quantity', start: subscription_nature.actual_number.to_i, finish: (subscription_nature.actual_number.to_i + ((subscription_quantity - 1) || 0)), entity: entity, address: address, subscription_nature: subscription_nature.name)
    end
  end

  # Load a product nature category from product nature category nomenclature
  def self.import_from_nomenclature(reference_name, force = false)
    unless item = Nomen::ProductNatureCategory.find(reference_name)
      fail ArgumentError, "The product_nature_category #{reference_name.inspect} is unknown"
    end
    if !force && category = ProductNatureCategory.find_by_reference_name(reference_name)
      return category
    end
    attributes = {
      active: true,
      name: item.human_name,
      reference_name: item.name,
      pictogram: item.pictogram,
      depreciable: item.depreciable,
      purchasable: item.purchasable,
      reductible: item.reductible,
      saleable: item.saleable,
      storable: item.storable,
      fixed_asset_depreciation_percentage: (item.depreciation_percentage.present? ? item.depreciation_percentage : 20),
      fixed_asset_depreciation_method: :simplified_linear
    }.with_indifferent_access
    for account in [:fixed_asset, :fixed_asset_allocation, :fixed_asset_expenses, :charge, :product, :stock]
      name = item.send("#{account}_account")
      unless name.blank?
        attributes["#{account}_account"] = Account.find_or_import_from_nomenclature(name)
      end
    end
    # TODO: add in rake clean method a way to detect same translation in nomenclatures by locale (to avoid conflict with validation on uniq name for example)
    # puts "#{item.human_name} - #{item.name}".red
    self.create!(attributes)
  end

  # Load.all product nature from product nature nomenclature
  def self.import_all_from_nomenclature
    for product_nature_category in Nomen::ProductNatureCategory.all
      import_from_nomenclature(product_nature_category)
    end
  end
end
