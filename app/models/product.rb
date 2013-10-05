# -*- coding: utf-8 -*-
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
# == Table: products
#
#  active                   :boolean          not null
#  address_id               :integer
#  asset_id                 :integer
#  born_at                  :datetime
#  content_indicator        :string(255)
#  content_indicator_unit   :string(255)
#  content_maximal_quantity :decimal(19, 4)   default(0.0), not null
#  content_nature_id        :integer
#  created_at               :datetime         not null
#  creator_id               :integer
#  dead_at                  :datetime
#  default_storage_id       :integer
#  derivative_of            :string(120)
#  description              :text
#  external                 :boolean          not null
#  father_id                :integer
#  id                       :integer          not null, primary key
#  identification_number    :string(255)
#  lock_version             :integer          default(0), not null
#  mother_id                :integer
#  name                     :string(255)      not null
#  nature_id                :integer          not null
#  number                   :string(255)      not null
#  owner_id                 :integer          not null
#  parent_id                :integer
#  picture_content_type     :string(255)
#  picture_file_name        :string(255)
#  picture_file_size        :integer
#  picture_updated_at       :datetime
#  reservoir                :boolean          not null
#  tracking_id              :integer
#  type                     :string(255)
#  updated_at               :datetime         not null
#  updater_id               :integer
#  variant_id               :integer          not null
#  variety                  :string(120)      not null
#  work_number              :string(255)
#


class Product < Ekylibre::Record::Base
  enumerize :variety, :in => Nomen::Varieties.all, :predicates => {:prefix => true}
  enumerize :content_indicator, :in => Nomen::Indicators.all, :predicates => {:prefix => true}
  enumerize :content_indicator_unit, :in => Nomen::Units.all, :predicates => {:prefix => true}
  belongs_to :nature, :class_name => "ProductNature"
  belongs_to :asset
  belongs_to :tracking
  belongs_to :content_nature, :class_name => "ProductNature"
  belongs_to :father, :class_name => "Product"
  belongs_to :mother, :class_name => "Product"
  belongs_to :owner, :class_name => "Entity"
  belongs_to :variant, :class_name => "ProductNatureVariant"
  has_many :incidents, :class_name => "Incident", :as => :target
  has_many :indicator_data, :class_name => "ProductIndicatorDatum", :dependent => :destroy
  has_many :intervention_casts, foreign_key: :actor_id, inverse_of: :actor
  has_many :groups, :through => :memberships
  has_many :memberships, :class_name => "ProductMembership", :foreign_key => :member_id
  has_many :operation_tasks, :foreign_key => :subject_id
  has_many :product_localizations
  has_many :supports, :class_name => "ProductionSupport", :foreign_key => :storage_id, :inverse_of => :storage
  has_attached_file :picture, {
    :url => '/backend/:class/:id/picture/:style',
    :path => ':rails_root/private/:class/:attachment/:id_partition/:style.:extension',
    :styles => {
      :thumb => ["64x64#", :jpg],
      :identity => ["180x180#", :jpg]
      # :large => ["600x600", :jpg]
    }
  }

  scope :members_of, lambda { |group, viewed_at| where("id IN (SELECT member_id FROM #{ProductMembership.table_name} WHERE group_id = ? AND ? BETWEEN COALESCE(started_at, ?) AND COALESCE(stopped_at, ?))", group.id, viewed_at, viewed_at, viewed_at)}
  scope :of_variety, lambda { |*varieties|
    where(:variety => varieties.collect{|v| Nomen::Varieties.all(v.to_sym) }.flatten.map(&:to_s).uniq)
  }
  scope :derivative_of, lambda { |*varieties|
    where(:derivative_of => varieties.collect{|v| Nomen::Varieties.all(v.to_sym) }.flatten.map(&:to_s).uniq)
  }
  # scope :of_variety, lambda { |*varieties| joins(:nature).merge(ProductNature.of_variety(*varieties)) }
  # scope :derivative_of, lambda { |nature| joins(:nature).merge(ProductNature.derivative_of(nature)) }

  # for a product_nature
  scope :of_nature, lambda { |nature|
    where(:nature_id => nature.id)
  }
  # scope :saleables, -> { joins(:nature).where(:active => true, :product_natures => {:saleable => true}) }
  scope :indicate, lambda { |indicators, options = {}|
    measured_at = options[:at] || Time.now
    conditions = []
    # TODO Build conditions to filter on indicators
    for name, value in indicators

      conditions << " id IN (" + order(:id).indicator(name, :at => measured_at).where("#{Nomen::Indicators[name].datatype}_value" => value).pluck(:product_id).join(", ") + ")"

    end
    where(conditions.join(" AND "))
  }
  scope :can, lambda { |*abilities|
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
    joins(:nature).where(query.join(" OR "), *parameters)
  }
  scope :saleables, -> { joins(:nature).merge(ProductNature.saleables) }
  scope :deliverables, -> { where(active: true, external: false).joins(:nature).merge(ProductNature.stockables) }
  scope :production_supports,  -> { where(variety: ["cultivable_land_parcel"]) }

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :picture_file_size, :allow_nil => true, :only_integer => true
  validates_numericality_of :content_maximal_quantity, :allow_nil => true
  validates_length_of :derivative_of, :variety, :allow_nil => true, :maximum => 120
  validates_length_of :content_indicator, :content_indicator_unit, :identification_number, :name, :number, :picture_content_type, :picture_file_name, :work_number, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :external, :reservoir, :in => [true, false]
  validates_presence_of :content_maximal_quantity, :name, :nature, :number, :owner, :variant, :variety
  #]VALIDATORS]
  validates_presence_of :nature, :variant, :name, :owner

  accepts_nested_attributes_for :memberships, :reject_if => :all_blank, :allow_destroy => true
  accepts_nested_attributes_for :indicator_data, :allow_destroy => true#, :reject_if => :all_blank,
  acts_as_numbered force: false
  delegate :serial_number, :producer, :to => :tracking
  delegate :name, :to => :nature, :prefix => true
  delegate :subscribing?, :deliverable?, :to => :nature
  delegate :variety, :name, :to => :variant, :prefix => true
  delegate :abilities, :abilities_array, :indicators, :indicators_array, :unit_name, :to => :variant

  after_initialize :choose_default_name
  before_validation :set_default_values, :on => :create

  validate do
    if self.variant
      # puts Nomen::Varieties.all(self.variant_variety).inspect
      errors.add(:variety, :invalid) unless Nomen::Varieties.all(self.variant_variety).include?(self.variety.to_s)
    end
    if self.external
      errors.add(:owner_id, :invalid) unless self.owner_id != Entity.of_company.id
    end
  end

  class << self
    # Auto-cast product to best matching class with type column
    def new_with_cast(*attributes, &block)
      if (h = attributes.first).is_a?(Hash) && !h.nil? && (type = h[:type] || h['type']) && type.length > 0 && (klass = type.constantize) != self
        raise "Can not cast #{self.name} to #{klass.name}" unless klass <= self
        return klass.new(*attributes, &block)
      end
      new_without_cast(*attributes, &block)
    end
    alias_method_chain :new, :cast
  end

  # TODO: Removes this ASAP
  def deliverable?
    false
  end


  # Try to find the best name for the new products
  def choose_default_name
    if self.new_record? and self.name.blank?
      if self.variant
        if last = self.class.where(:variant_id => self.variant_id).reorder("id DESC").first
          self.name = last.name
          array = self.name.split(/\s+/)
          if array.last.match(/^\(+\d+\)+?$/)
            self.name = array[0..-2].join(" ") + " (" + array.last.gsub(/(^\(+|\)+$)/, '').to_i.succ.to_s + ")"
          else
            self.name << " (1)"
          end
        else
          self.name = self.variant_name
        end
      else
        # By default, choose a random name
        self.name = Faker::Name.first_name
      end
    end
  end

  # Sets nature and variety from variant
  def set_default_values
    unless self.external
      self.owner_id = Entity.of_company.id
    end
    if self.variant
      self.nature    = self.variant.nature
      self.variety ||= self.variant_variety
    end
  end


  # Returns the matching model for the record
  def matching_model
    return ProductNature.matching_model(self.variety)
  end


  # Returns the price for the product.
  # It's a shortcut for CatalogPrice::give
  def price(options = {})
    return CatalogPrice.price(self, options)
  end

  # Add an operation for the product
  def operate(action, *args)
    options = (args[-1].is_a?(Hash) ? options.delete_at(-1) : {})
    if operand = (args[0].is_a?(Product) ? args[0] : nil)
      options[:operand] = operand
    end
    return self.operations.create(options)
  end

  # Returns groups of the product at a given time (or now by default)
  def groups_at(viewed_at = nil)
    ProductGroup.groups_of(self, viewed_at || Time.now)
  end

  def picture_path(style=:original)
    self.picture.path(style)
  end


  # Measure a product for a given indicator
  def is_measured!(indicator, value, options = {})
    unless Nomen::Indicators[indicator]
      raise ArgumentError.new("Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}.")
    end
    datum = self.indicator_data.new(:indicator => indicator, :measured_at => (options[:at] || Time.now) )
    datum.value = value
    datum.save!
    return datum
  end


  # Return the indicator datum
  def indicator(indicator, options = {})
    measured_at = options[:at] || Time.now
    return self.indicator_data.where(:indicator => indicator.to_s).where("measured_at <= ?", measured_at).reorder("measured_at DESC").first
  end

  # Returns indicators for a set of product
  def self.indicator(name, options = {})
    measured_at = options[:at] || Time.now
    ProductIndicatorDatum.where("id IN (SELECT p1.id FROM #{self.indicator_table_name(name)} AS p1 LEFT OUTER JOIN #{self.indicator_table_name(name)} AS p2 ON (p1.product_id = p2.product_id AND p1.indicator = p2.indicator AND (p1.measured_at < p2.measured_at OR (p1.measured_at = p2.measured_at AND p1.id < p2.id)) AND p2.measured_at <= ?) WHERE p1.measured_at <= ? AND p1.product_id IN (?) AND p1.indicator = ? AND p2 IS NULL)", measured_at, measured_at, self.pluck(:id), name)
  end


  # Get indicator value
  # if option :at specify at which moment
  # if option :datum is true, it returns the ProductIndicatorDatum record
  # if option :interpolate is true, it returns the interpolated value
  # :interpolate and :datum options are incompatible
  def method_missing(method_name, *args)
    return super unless Nomen::Indicators.all.include?(method_name.to_s)
    options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})
    measured_at = args.shift || options[:at] || Time.now
    indicator = Nomen::Indicators.items[method_name]

    if options[:interpolate]
      if [:measure, :decimal].include?(indicator.datatype)
        raise NotImplementedError.new("Interpolation is not available for now")
      end
      raise StandardError("Can not use :interpolate option with #{indicator.datatype.inspect} datatype")
    else
      if datum = self.indicator(indicator.name.to_s, :at => measured_at)
        x = datum.value
        x.define_singleton_method(:measured_at) do
          measured_at
        end
        product_id = self.id
        x.define_singleton_method(:product_id) do
          product_id
        end
        return x
      end
    end
    return nil
  end

  # Give the indicator table name
  def self.indicator_table_name(indicator)
    ProductIndicatorDatum.table_name
  end

end
