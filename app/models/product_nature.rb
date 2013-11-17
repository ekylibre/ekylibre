# encoding: UTF-8
# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: product_natures
#
#  abilities            :text
#  active               :boolean          not null
#  category_id          :integer          not null
#  created_at           :datetime         not null
#  creator_id           :integer
#  derivative_of        :string(120)
#  description          :text
#  evolvable            :boolean          not null
#  frozen_indicators    :text
#  id                   :integer          not null, primary key
#  lock_version         :integer          default(0), not null
#  name                 :string(255)      not null
#  nomen                :string(120)
#  number               :string(30)       not null
#  picture_content_type :string(255)
#  picture_file_name    :string(255)
#  picture_file_size    :integer
#  picture_updated_at   :datetime
#  population_counting  :string(255)      not null
#  updated_at           :datetime         not null
#  updater_id           :integer
#  variable_indicators  :text
#  variety              :string(120)      not null
#


class ProductNature < Ekylibre::Record::Base
  # attr_accessible :abilities, :active, :derivative_of, :description, :depreciable, :indicators, :purchasable, :saleable, :asset_account_id, :name, :nomen, :number, :population_counting, :stock_account_id, :charge_account_id, :product_account_id, :storable, :subscription_nature_id, :subscription_duration, :reductible, :subscribing, :variety
  enumerize :variety,       in: Nomen::Varieties.all
  enumerize :derivative_of, in: Nomen::Varieties.all
  # Be careful with the fact that it depends directly on the nomenclature definition
  enumerize :population_counting, in: Nomen::ProductNatures.attributes[:population_counting].choices, predicates: {prefix: true}, default: Nomen::ProductNatures.attributes[:population_counting].choices.first
   # has_many :available_stocks, class_name: "ProductStock", :conditions => ["quantity > 0"], foreign_key: :product_id
  #has_many :prices, foreign_key: :product_nature_id, class_name: "ProductPriceTemplate"
  belongs_to :category, class_name: "ProductNatureCategory"
  has_many :products, foreign_key: :nature_id
  has_many :variants, class_name: "ProductNatureVariant", foreign_key: :nature_id, inverse_of: :nature
  has_one :default_variant, -> { order(:id) }, class_name: "ProductNatureVariant", foreign_key: :nature_id
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :picture_file_size, allow_nil: true, only_integer: true
  validates_length_of :number, allow_nil: true, maximum: 30
  validates_length_of :derivative_of, :nomen, :variety, allow_nil: true, maximum: 120
  validates_length_of :name, :picture_content_type, :picture_file_name, :population_counting, allow_nil: true, maximum: 255
  validates_inclusion_of :active, :evolvable, in: [true, false]
  validates_presence_of :category, :name, :number, :population_counting, :variety
  #]VALIDATORS]
  validates_uniqueness_of :number
  validates_uniqueness_of :name

  accepts_nested_attributes_for :variants, :reject_if => :all_blank, :allow_destroy => true
  acts_as_numbered :force => false

  delegate :subscribing?, :deliverable?, :purchasable?, to: :category
  delegate :asset_account, :product_account, :charge_account, :stock_account, to: :category

  has_attached_file :picture, {
    :url => '/backend/:class/:id/picture/:style',
    :path => ':rails_root/private/:class/:attachment/:id_partition/:style.:extension',
    :styles => {
      :thumb => ["64x64#", :jpg],
      :identity => ["180x180#", :jpg]
      # :large => ["600x600", :jpg]
    }
  }

  # default_scope -> { order(:name) }
  scope :availables, -> { where(:active => true).order(:name) }
  scope :stockables, -> { joins(:category).merge(ProductNatureCategory.stockables).order(:name) }
  scope :saleables,  -> { joins(:category).merge(ProductNatureCategory.saleables).order(:name) }
  scope :purchaseables, -> { joins(:category).merge(ProductNatureCategory.purchaseables).order(:name) }
  # scope :producibles, -> { where(:variety => ["bos", "animal", "plant", "organic_matter"]).order(:name) }

  scope :of_variety, Proc.new { |*varieties|
    where(:variety => varieties.collect{|v| Nomen::Varieties.all(v.to_sym) }.flatten.map(&:to_s).uniq)
  }
  scope :derivative_of, Proc.new { |*varieties|
    where(:derivative_of => varieties.collect{|v| Nomen::Varieties.all(v.to_sym) }.flatten.map(&:to_s).uniq)
  }

  scope :can, Proc.new { |*abilities|
    query = []
    parameters = []
    for ability in abilities.flatten.join(', ').strip.split(/[\s\,]+/)
      if ability =~ /\(.*\)\z/
        params = ability.split(/\s*[\(\,\)]\s*/)
        ability = params.shift.to_sym
        item = Nomen::Abilities[ability]
        raise ArgumentError.new("Unknown ability: #{ability.inspect}") unless Nomen::Abilities[ability]
        for p in item.parameters
          v = params.shift
          if p == :variety
            raise ArgumentError.new("Unknown variety: #{v.inspect}") unless child = Nomen::Varieties[v]
            q = []
            for variety in child.self_and_parents
              q << "abilities ~ E?"
              parameters << "\\\\m#{ability}\\\\(#{variety.name}\\\\)\\\\Y"
            end
            query << "(" + q.join(" OR ") + ")"
          else
            raise StandardError.new("Unknown type of parameter for an ability: #{p.inspect}")
          end
        end
      else
        raise ArgumentError.new("Unknown ability: #{ability.inspect}") unless Nomen::Abilities[ability]
        query << "abilities ~ E?"
        parameters << "\\\\m#{ability}\\\\M"
      end
    end
    where(query.join(" OR "), *parameters)
  }

  protect(on: :destroy) do
    self.variants.count.zero? and self.products.count.zero?
  end

  before_validation do
    if self.derivative_of
      self.variety ||= self.derivative_of
    end
    self.derivative_of = nil if self.variety.to_s == self.derivative_of.to_s
    unless self.indicators_array.detect{|i| i.name.to_sym == :population}
      self.indicators ||= ""
      self.indicators << " population"
    end
    #self.indicators = self.indicators_array.map(&:name).sort.join(", ")
    self.abilities  = self.abilities_array.sort.join(", ")
    return true
  end

  # Returns the closest matching model based on the given variety
  def self.matching_model(variety)
    if item = Nomen::Varieties.find(variety)
      for ancestor in item.self_and_parents
        if model = ancestor.name.camelcase.constantize rescue nil
          return model if model <= Product
        end
      end
    end
    return nil
  end

  # Returns the matching model for the record
  def matching_model
    return self.class.matching_model(self.variety)
  end

  # Returns if population is frozen
  def population_frozen?
    return self.population_counting_unitary?
  end

  # Returns the minimum couting element
  def population_modulo
    return (self.population_counting_decimal? ? 0.0001 : 1)
  end

  def indicators
    return (self.frozen_indicators.to_s.strip.split(/[\,\s]/)+
           self.variable_indicators.to_s.strip.split(/[\,\s]/)).join(",")
  end

  # Returns list of indicators as an array of indicator items from the nomenclature
  def indicators_array
    return self.indicators.to_s.strip.split(/[\,\s]/).collect do |i|
      Nomen::Indicators[i]
    end.compact
  end

  # Returns list of abilities as an array of ability items from the nomenclature
  def abilities_array
    return self.abilities.to_s.strip.split(/[\,\s]/).collect do |i|
      (Nomen::Abilities[i.split(/\(/).first] ? i : nil)
    end.compact
  end

  def to
    to = []
    to << :sales if self.saleable?
    to << :purchases if self.purchasable?
    # to << :produce if self.producible?
    to.collect{|x| tc('to.'+x.to_s)}.to_sentence
  end


  # # Returns the default
  # def default_price(options)
  #   price = nil
  #   if template = self.templates.where(:listing_id => listing_id, :active => true, :by_default => true).first
  #     price = template.price
  #   end
  #   return price
  # end

  def label
    tc('label', :product_nature => self["name"])
  end

  def informations
    tc('informations.without_components', :product_nature => self.name, :unit => self.unit.label, :size => self.components.size)
  end


  # # TODO : move stock methods in operation / product
  # # Create real stocks moves to update the real state of stocks
  # def move_outgoing_stock(options={})
  #   add_stock_move(options.merge(:virtual => false, :incoming => false))
  # end

  # def move_incoming_stock(options={})
  #   add_stock_move(options.merge(:virtual => false, :incoming => true))
  # end

  # # Create virtual stock moves to reserve the products
  # def reserve_outgoing_stock(options={})
  #   add_stock_move(options.merge(:virtual => true, :incoming => false))
  # end

  # def reserve_incoming_stock(options={})
  #   add_stock_move(options.merge(:virtual => true, :incoming => true))
  # end

  # # Create real stocks moves to update the real state of stocks
  # def move_stock(options={})
  #   add_stock_move(options.merge(:virtual => false))
  # end

  # # Create virtual stock moves to reserve the products
  # def reserve_stock(options={})
  #   add_stock_move(options.merge(:virtual => true))
  # end

  # # Generic method to add stock move in product's stock
  # def add_stock_move(options={})
  #   return true unless self.stockable?
  #   incoming = options.delete(:incoming)
  #   attributes = options.merge(:generated => true)
  #   origin = options[:origin]
  #   if origin.is_a? ActiveRecord::Base
  #     code = [:number, :code, :name, :id].detect{|x| origin.respond_to? x}
  #     attributes[:name] = tc('stock_move', :origin => (origin ? ::I18n.t("activerecord.models.#{origin.class.name.underscore}") : "*"), :code => (origin ? origin.send(code) : "*"))
  #     for attribute in [:quantity, :unit, :tracking_id, :building_id, :product_id]
  #       unless attributes.keys.include? attribute
  #         attributes[attribute] ||= origin.send(attribute) rescue nil
  #       end
  #     end
  #   end
  #   attributes[:quantity] = -attributes[:quantity] unless incoming
  #   attributes[:building_id] ||= self.stocks.first.building_id if self.stocks.size > 0
  #   attributes[:planned_on] ||= Date.today
  #   attributes[:moved_on] ||= attributes[:planned_on] unless attributes.keys.include? :moved_on
  #   self.stock_moves.create!(attributes)
  # end


  # Load a product nature from product nature nomenclature
  def self.import_from_nomenclature(nomen)
    unless item = Nomen::ProductNatures.find(nomen)
      raise ArgumentError.new("The product_nature #{nomen.inspect} is not known")
    end
    unless category_item = Nomen::ProductNatureCategories.find(item.category)
      raise ArgumentError.new("The category of the product_nature #{item.category.inspect} is not known")
    end
    unless nature = ProductNature.find_by_nomen(nomen)
      attributes = {
        :variety => item.variety,
        :abilities => item.abilities.sort.join(" "),
        :active => true,
        :name => item.human_name,
        :population_counting => item.population_counting,
        :category => ProductNatureCategory.find_by_nomen(item.category) || ProductNatureCategory.import_from_nomenclature(item.category),
        :nomen => item.name,
        :frozen_indicators => item.frozen_indicators.sort.join(" "),
        :variable_indicators => item.variable_indicators.sort.join(" "),
        :derivative_of => item.derivative_of.to_s
      }
      nature = self.create!(attributes)
    end
    return nature
  end

  # Load.all product nature from product nature nomenclature
  def self.import_all_from_nomenclature
    for product_nature in Nomen::ProductNatures.all
      import_from_nomenclature(product_nature)
    end
  end

end
