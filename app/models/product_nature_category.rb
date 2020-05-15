# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
#  asset_fixable                       :boolean          default(FALSE)
#  charge_account_id                   :integer
#  created_at                          :datetime         not null
#  creator_id                          :integer
#  custom_fields                       :jsonb
#  depreciable                         :boolean          default(FALSE), not null
#  description                         :text
#  fixed_asset_account_id              :integer
#  fixed_asset_allocation_account_id   :integer
#  fixed_asset_depreciation_method     :string
#  fixed_asset_depreciation_percentage :decimal(19, 4)   default(0.0)
#  fixed_asset_expenses_account_id     :integer
#  id                                  :integer          not null, primary key
#  imported_from                       :string
#  lock_version                        :integer          default(0), not null
#  name                                :string           not null
#  number                              :string           not null
#  pictogram                           :string
#  product_account_id                  :integer
#  provider                            :jsonb
#  purchasable                         :boolean          default(FALSE), not null
#  reductible                          :boolean          default(FALSE), not null
#  reference_name                      :string
#  saleable                            :boolean          default(FALSE), not null
#  stock_account_id                    :integer
#  stock_movement_account_id           :integer
#  storable                            :boolean          default(FALSE), not null
#  subscribing                         :boolean          default(FALSE), not null
#  type                                :string           not null
#  updated_at                          :datetime         not null
#  updater_id                          :integer
#
class ProductNatureCategory < Ekylibre::Record::Base
  include Autocastable
  include Customizable
  include Importable
  include Providable

  # Be careful with the fact that it depends directly on the nomenclature definition
  enumerize :pictogram, in: Nomen::ProductNatureCategory.pictogram.choices
  enumerize :type, in: %w[Animal Article Crop Equipment Service Worker Zone].map { |t| "VariantCategories::#{t}Category" }
  # refers_to :pictogram, class_name: 'ProductPictograms'
  belongs_to :fixed_asset_account, class_name: 'Account'
  belongs_to :fixed_asset_allocation_account, class_name: 'Account'
  belongs_to :fixed_asset_expenses_account, class_name: 'Account'
  belongs_to :charge_account, class_name: 'Account'
  belongs_to :product_account, class_name: 'Account'
  belongs_to :stock_account, class_name: 'Account'
  belongs_to :stock_movement_account, class_name: 'Account'
  has_many :products, foreign_key: :category_id, dependent: :restrict_with_exception
  has_many :taxations, class_name: 'ProductNatureCategoryTaxation', dependent: :destroy
  has_many :variants, class_name: 'ProductNatureVariant', foreign_key: :category_id, inverse_of: :category, dependent: :restrict_with_exception
  has_many :sale_taxations, -> { where(usage: 'sale') }, class_name: 'ProductNatureCategoryTaxation', inverse_of: :product_nature_category
  has_many :sale_taxes, class_name: 'Tax', through: :sale_taxations, source: :tax
  has_many :purchase_taxations, -> { where(usage: 'purchase') }, class_name: 'ProductNatureCategoryTaxation', inverse_of: :product_nature_category
  has_many :purchase_taxes, class_name: 'Tax', through: :purchase_taxations, source: :tax
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :active, :depreciable, :purchasable, :reductible, :saleable, :storable, :subscribing, inclusion: { in: [true, false] }
  validates :asset_fixable, inclusion: { in: [true, false] }, allow_blank: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :fixed_asset_depreciation_method, :reference_name, length: { maximum: 500 }, allow_blank: true
  validates :fixed_asset_depreciation_percentage, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :number, presence: true, uniqueness: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :number, length: { allow_nil: true, maximum: 30 }
  validates :pictogram, length: { allow_nil: true, maximum: 120 }
  validates :product_account, presence: { if: :saleable? }
  validates :charge_account, presence: { if: :purchasable? }
  validates :stock_account, presence: { if: :storable? }
  validates :stock_movement_account, presence: { if: :storable? }
  validates :fixed_asset_account, presence: { if: :depreciable? }
  validates :fixed_asset_allocation_account, presence: { if: :depreciable? }
  validates :fixed_asset_expenses_account, presence: { if: :depreciable? }
  validates :number, uniqueness: true
  validates :name, uniqueness: true

  accepts_nested_attributes_for :sale_taxations, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :purchase_taxations, reject_if: :all_blank, allow_destroy: true
  acts_as_numbered force: false

  scope :availables, -> { where(active: true).order(:name) }
  scope :stockables, -> { where(storable: true).order(:name) }
  scope :saleables, -> { where(saleable: true).order(:name) }
  scope :purchaseables, -> { where(purchasable: true).order(:name) }
  scope :depreciables, -> { where(depreciable: true).order(:name) }
  scope :stockables_or_depreciables, -> { where("#{table_name}.depreciable = ? OR #{table_name}.storable = ?", true, true).order(:name) }
  scope :with_catalog_items, -> { where(id: Catalog.joins(items: { variant: :category }).pluck(:category_id)) }
  scope :with_sale_catalog_items, -> { where(id: Catalog.for_sale.joins(items: { variant: :category }).pluck(:category_id)) }

  scope :of_type, ->(nature) { where(type: "VariantCategories::#{nature.to_s.capitalize}Category") }

  protect(on: :destroy) do
    products.any? || variants.any?
  end

  before_validation do
    self.storable = false unless deliverable?
    asset_fixable = true if depreciable
    true
  end

  def to
    to = []
    to << :sales if saleable?
    to << :purchases if purchasable?
    # to << :produce if self.producible?
    to.collect { |x| tc('to.' + x.to_s) }.to_sentence
  end

  def deliverable?
    storable?
  end

  def label
    name # tc('label', :product_nature_category => self["name"])
  end

  def article_type
    return unless type.match /Article/

    case reference_name
      when 'fertilizer'
        return 'Variants::Articles::FertilizerArticle'
      when 'seed' || 'plant'
        return 'Variants::Articles::SeedAndPlantArticle'
      when 'plant_medicine'
        return 'Variants::Articles::PlantMedicineArticle'
    end

    case charge_account&.usages
      when 'fertilizer_expenses'
        'Variants::Articles::FertilizerArticle'
      when 'seed_expenses'
        'Variants::Articles::SeedAndPlantArticle'
      when 'plant_medicine_matter_expenses'
        'Variants::Articles::PlantMedicineArticle'
    end
  end

  delegate :count, to: :variants, prefix: true

  class << self
    # Returns some nomenclature items are available to be imported, e.g. not
    # already imported
    def any_reference_available?
      Nomen::ProductNatureCategory.without(ProductNatureCategory.pluck(:reference_name).uniq).any?
    end

    # Load a product nature category from product nature category nomenclature
    def import_from_nomenclature(reference_name, force = false)
      unless (item = Nomen::ProductNatureCategory.find(reference_name))
        raise ArgumentError, "The product_nature_category #{reference_name.inspect} is unknown"
      end
      unless force
        category = ProductNatureCategory.find_by(reference_name: reference_name)
        return category if category
      end
      nature = compute_type_from_nomenclature(reference_name) || :fee_and_service
      attributes = {
        active: true,
        name: item.human_name,
        reference_name: item.name,
        pictogram: item.pictogram,
        asset_fixable: item.asset_fixable,
        depreciable: item.depreciable,
        purchasable: item.purchasable,
        reductible: item.reductible,
        saleable: item.saleable,
        storable: item.storable,
        fixed_asset_depreciation_percentage: (item.depreciation_percentage.present? ? item.depreciation_percentage : 20),
        fixed_asset_depreciation_method: :linear,
        type: nature == :fee_and_service ? 'VariantCategories::ServiceCategory' : "VariantCategories::#{nature.to_s.capitalize}Category",
        imported_from: 'Nomenclature'
      }.with_indifferent_access
      accounts_usage_categories = {
        :charge => :purchasable,
        :product => :saleable,
        :stock => :storable,
        :stock_movement => :storable,
        :fixed_asset => :depreciable,
        :fixed_asset_allocation => :depreciable,
        :fixed_asset_expenses => :depreciable
      }.with_indifferent_access
      %i[fixed_asset fixed_asset_allocation fixed_asset_expenses charge product stock stock_movement].each do |account|
        account_name = item.send("#{account}_account")

        if account_name.present?
          a = Account.find_or_import_from_nomenclature(account_name)

          if a.present?
            attributes["#{account}_account"] = a
          else
            attributes[accounts_usage_categories[account].to_s] = false
          end
        end
      end

      # TODO: add in rake clean method a way to detect same translation in nomenclatures by locale (to avoid conflict with validation on uniq name for example)
      # puts "#{item.human_name} - #{item.name}".red
      create!(attributes)
    end

    def import_from_lexicon(reference_name, force = false)
      unless (item = VariantCategory.find_by(reference_name: reference_name))
        raise ArgumentError, "The product nature category #{reference_name.inspect} is unknown"
      end
      if !force && (category = ProductNatureCategory.find_by(reference_name: reference_name))
        return category
      end
      attributes = {
        active: true,
        name: item.name[I18n.locale.to_s] || item.reference_name.humanize,
        reference_name: item.reference_name,
        depreciable: item.depreciable,
        purchasable: item.purchasable,
        saleable: item.saleable,
        storable: item.storable,
        fixed_asset_depreciation_percentage: (item.depreciation_percentage.present? ? item.depreciation_percentage : 20),
        fixed_asset_depreciation_method: :linear,
        product_account: (item.sale_account.present? ? Account.find_or_import_from_nomenclature(item.sale_account) : nil),
        charge_account: (item.purchase_account.present? ? Account.find_or_import_from_nomenclature(item.purchase_account) : nil),
        type: item.nature == 'fee_and_service' ? 'VariantCategories::ServiceCategory' : "VariantCategories::#{item.nature.capitalize}Category",
        imported_from: 'Lexicon'
      }
      %i[fixed_asset fixed_asset_allocation fixed_asset_expenses stock stock_movement].each do |account|
        account_name = item.send("#{account}_account")
        attributes["#{account}_account"] = Account.find_or_import_from_nomenclature(account_name) if account_name.present?
      end
      create!(attributes)
    end

    def import_all_from_lexicon
      VariantCategory.find_each do |category|
        import_from_lexicon(category.reference_name)
      end
    end

    def load_defaults(**_options)
      Nomen::ProductNatureCategory.find_each do |product_nature_category|
        import_from_nomenclature(product_nature_category.name)
      end
    end

    private

      def compute_type_from_nomenclature(reference_name)
        Nomen::ProductNature.list.select { |n| n.category.to_s == reference_name.to_s }.map(&:nature).group_by { |n| n }.max_by { |_k, v| v.count }&.first
      end
  end
end
