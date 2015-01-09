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
#  active                                                        :boolean          not null
#  charge_account_id                                             :integer
#  created_at                                                    :datetime         not null
#  creator_id                                                    :integer
#  depreciable                                                   :boolean          not null
#  description                                                   :text
#  financial_asset_account_id                                    :integer
#  financial_asset_depreciations_account_id                      :integer
#  financial_asset_depreciations_inputations_expenses_account_id :integer
#  id                                                            :integer          not null, primary key
#  lock_version                                                  :integer          default(0), not null
#  name                                                          :string(255)      not null
#  number                                                        :string(30)       not null
#  pictogram                                                     :string(120)
#  product_account_id                                            :integer
#  purchasable                                                   :boolean          not null
#  reductible                                                    :boolean          not null
#  reference_name                                                :string(255)
#  saleable                                                      :boolean          not null
#  stock_account_id                                              :integer
#  storable                                                      :boolean          not null
#  subscribing                                                   :boolean          not null
#  subscription_duration                                         :string(255)
#  subscription_nature_id                                        :integer
#  updated_at                                                    :datetime         not null
#  updater_id                                                    :integer
#
class ProductNatureCategory < Ekylibre::Record::Base
  # Be careful with the fact that it depends directly on the nomenclature definition
  enumerize :pictogram, in: Nomen::ProductNatureCategories.pictogram.choices, predicates: {prefix: true}
  belongs_to :financial_asset_account, class_name: "Account"
  belongs_to :financial_asset_depreciations_account, class_name: "Account"
  belongs_to :financial_asset_depreciations_inputations_expenses_account, class_name: "Account"
  belongs_to :charge_account,  class_name: "Account"
  belongs_to :product_account, class_name: "Account"
  belongs_to :stock_account,   class_name: "Account"
  belongs_to :subscription_nature
  has_many :subscriptions, foreign_key: :product_nature_id
  has_many :natures, class_name: "ProductNature", foreign_key: :category_id, inverse_of: :category
  has_many :products, foreign_key: :category_id
  has_many :taxations, class_name: "ProductNatureCategoryTaxation"
  has_many :variants, class_name: "ProductNatureVariant", foreign_key: :category_id, inverse_of: :category
  has_many :sale_taxations,     -> { where(usage: "sale") },     class_name: "ProductNatureCategoryTaxation", inverse_of: :product_nature_category
  has_many :sale_taxes,     class_name: "Tax", through: :sale_taxations,     source: :tax
  has_many :purchase_taxations, -> { where(usage: "purchase") }, class_name: "ProductNatureCategoryTaxation", inverse_of: :product_nature_category
  has_many :purchase_taxes, class_name: "Tax", through: :purchase_taxations, source: :tax
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :number, allow_nil: true, maximum: 30
  validates_length_of :pictogram, allow_nil: true, maximum: 120
  validates_length_of :name, :reference_name, :subscription_duration, allow_nil: true, maximum: 255
  validates_inclusion_of :active, :depreciable, :purchasable, :reductible, :saleable, :storable, :subscribing, in: [true, false]
  validates_presence_of :name, :number
  #]VALIDATORS]
  validates_presence_of :subscription_nature,   if: :subscribing?
  validates_presence_of :subscription_period,   if: Proc.new{|u| u.subscribing? and u.subscription_nature and u.subscription_nature.period? }
  validates_presence_of :subscription_quantity, if: Proc.new{|u| u.subscribing? and u.subscription_nature and u.subscription_nature.quantity? }
  validates_presence_of :product_account, if: :saleable?
  validates_presence_of :charge_account,  if: :purchasable?
  validates_presence_of :stock_account,   if: :storable?
  validates_presence_of :financial_asset_account,  if: :depreciable?
  validates_presence_of :financial_asset_depreciations_account, if: :depreciable?
  validates_presence_of :financial_asset_depreciations_inputations_expenses_account, if: :depreciable?
  validates_uniqueness_of :number
  validates_uniqueness_of :name

  accepts_nested_attributes_for :natures,            reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :sale_taxations,     reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :purchase_taxations, reject_if: :all_blank, allow_destroy: true
  acts_as_numbered :force => false

  scope :availables,    -> { where(active: true).order(:name) }
  scope :stockables,    -> { where(storable: true).order(:name) }
  scope :saleables,     -> { where(saleable: true).order(:name) }
  scope :purchaseables, -> { where(purchasable: true).order(:name) }

  protect(on: :destroy) do
    self.natures.any? and self.products.any?
  end

  before_validation do
    unless self.deliverable?
      self.storable = false
    end
    unless self.subscribing?
      self.subscription_nature_id = nil
    end
  end

  def to
    to = []
    to << :sales if self.saleable?
    to << :purchases if self.purchasable?
    # to << :produce if self.producible?
    to.collect{|x| tc('to.'+x.to_s)}.to_sentence
  end

  def deliverable?
    self.storable?
  end

  def label
    self.name # tc('label', :product_nature_category => self["name"])
  end

  def duration
    #raise StandardError.new self.subscription_nature.nature.inspect+" blabla"
    if self.subscription_nature
      self.send('subscription_'+self.subscription_nature.nature)
    else
      return nil
    end

  end

  def duration=(value)
    #raise StandardError.new subscription.inspect+self.subscription_nature_id.inspect
    if self.subscription_nature
      self.send('subscription_'+self.subscription_nature.nature+'=', value)
    end
  end

  def default_start
    # self.subscription_nature.nature == "period" ? Date.today.beginning_of_year : self.subscription_nature.actual_number
    self.subscription_nature.nature == "period" ? Date.today : self.subscription_nature.actual_number
  end

  def default_finish
    period = self.subscription_period || '1 year'
    # self.subscription_nature.nature == "period" ? Date.today.next_year.beginning_of_year.next_month.end_of_month : (self.subscription_nature.actual_number + ((self.subscription_quantity-1)||0))
    self.subscription_nature.nature == "period" ? Delay.compute(period+", 1 day ago", Date.today) : (self.subscription_nature.actual_number + ((self.subscription_quantity-1)||0))
  end

  def default_subscription_label_for(entity)
    return nil unless self.nature == "subscrip"
    entity  = nil unless entity.is_a? Entity
    address = entity.default_contact.address rescue nil
    entity = entity.full_name rescue "???"
    if self.subscription_nature.nature == "period"
      return tc('subscription_label.period', :start => ::I18n.localize(Date.today), :finish => ::I18n.localize(Delay.compute(self.subscription_period.blank? ? '1 year, 1 day ago' : self.product.subscription_period)), :entity => entity, :address => address, :subscription_nature => self.subscription_nature.name)
    elsif self.subscription_nature.nature == "quantity"
      return tc('subscription_label.quantity', :start => self.subscription_nature.actual_number.to_i, :finish => (self.subscription_nature.actual_number.to_i + ((self.subscription_quantity-1)||0)), :entity => entity, :address => address, :subscription_nature => self.subscription_nature.name)
    end
  end

  # Load a product nature category from product nature category nomenclature
  def self.import_from_nomenclature(reference_name, force = false)
    unless item = Nomen::ProductNatureCategories.find(reference_name)
      raise ArgumentError, "The product_nature_category #{reference_name.inspect} is unknown"
    end
    if !force and category = ProductNatureCategory.find_by_reference_name(reference_name)
      return category
    end
    attributes = {
      :active => true,
      :name => item.human_name,
      :reference_name => item.name,
      :pictogram => item.pictogram,
      :depreciable => item.depreciable,
      :purchasable => item.purchasable,
      :reductible => item.reductible,
      :saleable => item.saleable,
      :storable => item.storable
    }.with_indifferent_access
    for account in [:financial_asset, :financial_asset_depreciations, :financial_asset_depreciations_inputations_expenses, :charge, :product, :stock]
      name = item.send("#{account}_account")
      unless name.blank?
        attributes["#{account}_account"] = Account.find_or_create_in_chart(name)
      end
    end
    return self.create!(attributes)
  end

  # Load.all product nature from product nature nomenclature
  def self.import_all_from_nomenclature
    for product_nature_category in Nomen::ProductNatureCategories.all
      import_from_nomenclature(product_nature_category)
    end
  end

end
