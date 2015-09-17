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
# == Table: product_natures
#
#  abilities_list           :text
#  active                   :boolean          default(FALSE), not null
#  category_id              :integer          not null
#  created_at               :datetime         not null
#  creator_id               :integer
#  derivative_of            :string
#  derivatives_list         :text
#  description              :text
#  evolvable                :boolean          default(FALSE), not null
#  frozen_indicators_list   :text
#  id                       :integer          not null, primary key
#  linkage_points_list      :text
#  lock_version             :integer          default(0), not null
#  name                     :string           not null
#  number                   :string           not null
#  picture_content_type     :string
#  picture_file_name        :string
#  picture_file_size        :integer
#  picture_updated_at       :datetime
#  population_counting      :string           not null
#  reference_name           :string
#  updated_at               :datetime         not null
#  updater_id               :integer
#  variable_indicators_list :text
#  variety                  :string           not null
#

class ProductNature < Ekylibre::Record::Base
  refers_to :variety
  refers_to :derivative_of, class_name: 'Variety'
  refers_to :reference_name, class_name: 'ProductNature'
  # Be careful with the fact that it depends directly on the nomenclature definition
  # refers_to :population_counting, class_name: 'ProductNature::PopulationCounting'
  enumerize :population_counting, in: [:unitary, :integer, :decimal], predicates: { prefix: true }
  # has_many :available_stocks, class_name: "ProductStock", :conditions => ["quantity > 0"], foreign_key: :product_id
  # has_many :prices, foreign_key: :product_nature_id, class_name: "ProductPriceTemplate"
  belongs_to :category, class_name: 'ProductNatureCategory'
  has_many :products, foreign_key: :nature_id, dependent: :restrict_with_exception
  has_many :variants, class_name: 'ProductNatureVariant', foreign_key: :nature_id, inverse_of: :nature, dependent: :restrict_with_exception
  has_one :default_variant, -> { order(:id) }, class_name: 'ProductNatureVariant', foreign_key: :nature_id

  has_picture

  serialize :abilities_list, WorkingSet::AbilityArray
  serialize :derivatives_list, SymbolArray
  serialize :frozen_indicators_list, SymbolArray
  serialize :variable_indicators_list, SymbolArray
  serialize :linkage_points_list, SymbolArray

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :picture_updated_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :picture_file_size, allow_nil: true, only_integer: true
  validates_inclusion_of :active, :evolvable, in: [true, false]
  validates_presence_of :category, :name, :number, :population_counting, :variety
  # ]VALIDATORS]
  validates_length_of :number, allow_nil: true, maximum: 30
  validates_length_of :derivative_of, :reference_name, :variety, allow_nil: true, maximum: 120
  validates_uniqueness_of :number
  validates_uniqueness_of :name
  validates_attachment_content_type :picture, content_type: /image/

  accepts_nested_attributes_for :variants, reject_if: :all_blank, allow_destroy: true
  acts_as_numbered force: false

  delegate :subscribing?, :deliverable?, :purchasable?, to: :category
  delegate :fixed_asset_account, :product_account, :charge_account, :stock_account, to: :category

  scope :availables, -> { where(active: true).order(:name) }
  scope :stockables, -> { joins(:category).merge(ProductNatureCategory.stockables).order(:name) }
  scope :saleables,  -> { joins(:category).merge(ProductNatureCategory.saleables).order(:name) }
  scope :purchaseables, -> { joins(:category).merge(ProductNatureCategory.purchaseables).order(:name) }
  scope :stockables_or_depreciables, -> { joins(:category).merge(ProductNatureCategory.stockables_or_depreciables).order(:name) }
  scope :storage, -> { of_expression('can store(matter) or can store_liquid or can store_fluid or can store_gaz') }

  # scope :producibles, -> { where(:variety => ["bos", "animal", "plant", "organic_matter"]).order(:name) }

  scope :of_variety, proc { |*varieties|
    where(variety: varieties.collect { |v| Nomen::Variety.all(v.to_sym) }.flatten.map(&:to_s).uniq)
  }
  scope :derivative_of, proc { |*varieties|
    where(derivative_of: varieties.collect { |v| Nomen::Variety.all(v.to_sym) }.flatten.map(&:to_s).uniq)
  }

  scope :can, lambda { |*abilities|
    of_expression(abilities.map { |a| "can #{a}" }.join(' or '))
  }

  scope :can_each, lambda { |*abilities|
    of_expression(abilities.map { |a| "can #{a}" }.join(' and '))
  }

  scope :of_working_set, lambda { |working_set|
    if item = Nomen::WorkingSet.find(working_set)
      of_expression(item.expression)
    else
      fail StandardError, "#{working_set.inspect} is not in Nomen::WorkingSet nomenclature"
    end
  }

  # Use working set query language to filter product nature
  scope :of_expression, lambda { |expression|
    where(WorkingSet.to_sql(expression))
  }

  protect(on: :destroy) do
    variants.any? || products.any?
  end

  before_validation do
    self.variety ||= derivative_of if derivative_of
    self.derivative_of = nil if self.variety.to_s == derivative_of.to_s
    # unless self.indicators_array.detect{|i| i.name.to_sym == :population}
    #   self.indicators ||= ""
    #   self.indicators << " population"
    # end
    # self.indicators = self.indicators_array.map(&:name).sort.join(", ")
    # self.abilities_list = self.abilities_list.sort.join(", ")
  end

  def has_indicator?(indicator)
    indicators_list.include? indicator
  end

  # Permit to check WSQL expression "locally" to ensure performance
  def of_expression(expression)
    WorkingSet.check_record(expression, self)
  end

  # Returns the closest matching model based on the given variety
  def self.matching_model(variety)
    if item = Nomen::Variety.find(variety)
      for ancestor in item.self_and_parents
        if model = begin
                     ancestor.name.camelcase.constantize
                   rescue
                     nil
                   end
          return model if model <= Product
        end
      end
    end
    nil
  end

  # Returns the matching model for the record
  def matching_model
    self.class.matching_model(self.variety)
  end

  # Returns if population is frozen
  def population_frozen?
    self.population_counting_unitary?
  end

  # Returns the minimum couting element
  def population_modulo
    (self.population_counting_decimal? ? 0.0001 : 1)
  end

  # Returns list of all indicators
  def indicators
    (frozen_indicators + variable_indicators)
  end

  # Returns list of all indicators names
  def indicators_list
    (frozen_indicators_list + variable_indicators_list)
  end

  # Returns list of froezen indicators as an array of indicator items from the nomenclature
  def frozen_indicators
    frozen_indicators_list.collect { |i| Nomen::Indicator[i] }.compact
  end

  # Returns list of variable indicators as an array of indicator items from the nomenclature
  def variable_indicators
    variable_indicators_list.collect { |i| Nomen::Indicator[i] }.compact
  end

  # Returns list of indicators as an array of indicator items from the nomenclature
  def indicators_related_to(aspect)
    indicators.select { |i| i.related_to == aspect }
  end

  # Returns whole indicators
  def whole_indicators
    indicators_related_to(:whole)
  end

  # Returns whole indicator names
  def whole_indicators_list
    whole_indicators.map { |i| i.name.to_sym }
  end

  # Returns individual indicators
  def individual_indicators
    indicators_related_to(:individual)
  end

  # Returns individual indicator names
  def individual_indicators_list
    individual_indicators.map { |i| i.name.to_sym }
  end

  # Returns list of abilities as an array of ability items from the nomenclature
  def abilities
    abilities_list.collect do |i|
      (Nomen::Ability[i.to_s.split(/\(/).first] ? i.to_s : nil)
    end.compact
  end

  def ability(name)
    abilities_list.select do |a|
      a.to_s.split(/\(/).first == name.to_s
    end
  end

  def able_to?(ability)
    of_expression("can #{ability}")
  end

  # tests if all abilities are present
  # @params: *abilities, a list of abilities to check. Can't be empty
  # @returns: true if all abilities are matched, false if at least one ability is missing
  def able_to_each?(abilities)
    of_expression(abilities.map { |a| "can #{a}" }.join(' and '))
  end

  # Returns list of abilities as an array of ability items from the nomenclature
  def linkage_points
    linkage_points_list
  end

  def to
    to = []
    to << :sales if self.saleable?
    to << :purchases if self.purchasable?
    # to << :produce if self.producible?
    to.collect { |x| tc('to.' + x.to_s) }.to_sentence
  end

  def picture_path(style = :original)
    picture.path(style)
  end

  # Load a product nature from product nature nomenclature
  def self.import_from_nomenclature(reference_name, force = false)
    unless item = Nomen::ProductNature.find(reference_name)
      fail ArgumentError, "The product_nature #{reference_name.inspect} is unknown"
    end
    unless category_item = Nomen::ProductNatureCategory.find(item.category)
      fail ArgumentError, "The category of the product_nature #{item.category.inspect} is unknown"
    end
    if !force && nature = ProductNature.find_by_reference_name(reference_name)
      return nature
    end
    attributes = {
      variety: item.variety,
      derivative_of: item.derivative_of.to_s,
      name: item.human_name,
      population_counting: item.population_counting,
      category: ProductNatureCategory.import_from_nomenclature(item.category),
      reference_name: item.name,
      abilities_list: WorkingSet::AbilityArray.load(item.abilities),
      derivatives_list: (item.derivatives ? item.derivatives.sort : nil),
      frozen_indicators_list: (item.frozen_indicators ? item.frozen_indicators.sort : nil),
      variable_indicators_list: (item.variable_indicators ? item.variable_indicators.sort : nil),
      active: true
    }
    attributes[:linkage_points_list] = item.linkage_points if item.linkage_points
    self.create!(attributes)
  end

  # Load.all product nature from product nature nomenclature
  def self.import_all_from_nomenclature
    for product_nature in Nomen::ProductNature.all
      import_from_nomenclature(product_nature)
    end
  end
end
