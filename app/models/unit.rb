# frozen_string_literal: true

class Unit < ApplicationRecord
  # INFO to convert unit or price, see service UnitComputation
  BASE_UNIT_PER_DIMENSION = { none: 'unity',
                              volume: 'liter',
                              mass: 'kilogram',
                              surface_area: 'square_meter',
                              distance: 'meter',
                              time: 'second',
                              energy: 'joule' }.freeze

  STOCK_INDICATOR_PER_DIMENSION = { volume: 'net_volume',
                                    mass: 'net_mass',
                                    surface_area: 'net_surface_area',
                                    distance: 'net_length',
                                    time: 'usage_duration',
                                    energy: 'energy' }.freeze

  has_many :catalog_items
  has_many :variants, class_name: 'ProductNatureVariant', foreign_key: :default_unit_id
  has_many :sale_items, foreign_key: :conditioning_unit_id
  has_many :purchase_items, foreign_key: :conditioning_unit_id
  has_many :reception_items, foreign_key: :conditioning_unit_id
  has_many :shipment_items, foreign_key: :conditioning_unit_id
  has_many :products, foreign_key: :conditioning_unit_id
  has_many :derivative_units, class_name: 'Unit', foreign_key: :base_unit_id
  belongs_to :base_unit, class_name: 'ReferenceUnit'

  enumerize :type, in: %w[ReferenceUnit Conditioning]
  enumerize :dimension, in: BASE_UNIT_PER_DIMENSION.keys

  validates :name, :coefficient, presence: true
  validates :symbol, uniqueness: true, allow_blank: true
  validates :name, uniqueness: true

  BASE_UNIT_PER_DIMENSION.keys.each do |dimension|
    scope "of_#{dimension}", -> { where(dimension: dimension) }
  end
  scope :multiple_of, ->(x) { where('coefficient % ? = 0', x) }
  scope :of_dimension_multiple_of, ->(dimension, x) { send("of_#{dimension}").multiple_of(x) }
  scope :of_dimensions, ->(*dimensions) { where(dimension: dimensions) }
  scope :of_reference, -> { where(reference_name: BASE_UNIT_PER_DIMENSION.values) }
  scope :references_for_dimensions, ->(*dimensions) { of_reference.of_dimensions(*dimensions) }
  scope :imported, -> { where.not(reference_name: nil) }
  scope :of_variant, ->(variant_id) { where(id: CatalogItem.where(variant_id: variant_id).pluck(:unit_id).uniq) }

  protect allow_update_on: %i[name work_code description symbol updated_at], form_reachable: true do
    reference_name.present? || associated?
  end

  before_validation do
    self.dimension = base_unit.dimension if base_unit
  end

  def format_coefficient
    coefficient.to_f.l(precision: 0)
  end

  def of_dimension?(dim)
    dim.to_sym == dimension.to_sym
  end

  def associated?
    catalog_items.any? || sale_items.any? || purchase_items.any? || reception_items.any? || shipment_items.any? || products.any? || derivative_units.any?
  end

  class << self
    def import_from_nomenclature(reference_name)
      unless item = Onoma::Unit.find(reference_name)
        raise ArgumentError.new("The unit #{reference_name.inspect} is unknown")
      end

      attributes = {
        name: item.human_name,
        reference_name: item.name,
        symbol: item.symbol,
        coefficient: item.dimension == :volume ? item.a * 1_000 : item.a.to_d,
        base_unit: import_from_nomenclature(BASE_UNIT_PER_DIMENSION[item.dimension]),
        dimension: item.dimension,
        type: 'ReferenceUnit'
      }
      create!(attributes)
    end

    def import_from_lexicon(ref_or_symbol)
      if unit = Unit.find_by_reference_name(ref_or_symbol) || Unit.find_by_symbol(ref_or_symbol)
        return unit
      end
      unless item = MasterPackaging.find_by_reference_name(ref_or_symbol) || MasterUnit.find_by_reference_name(ref_or_symbol) || MasterUnit.find_by_symbol(ref_or_symbol)
        raise ArgumentError.new("The unit #{ref_or_symbol.inspect} is not present in Lexicon Unit or Packaging")
      end

      attributes = send("#{item.class.name.downcase}_attributes", item)
      create!(attributes)
    end

    def load_defaults(**_options)
      BASE_UNIT_PER_DIMENSION.keys.each do |dim|
        MasterUnit.of_dimension(dim).each do |unit|
          import_from_lexicon(unit.reference_name)
        end
      end
    end

    def import_all_from_nomenclature
      Onoma::Unit.list.select { |u| BASE_UNIT_PER_DIMENSION.keys.include?(u.dimension) && u.dimension == u.base_dimension.to_sym && u.d == 1 }.each do |unit|
        import_from_nomenclature(unit.name)
      end
    end

    private

      # unit MasterUnit
      def masterunit_attributes(unit)
        normalized_language = ((Preference[:language].include?('fra') || Preference[:language].include?('eng') ) ? Preference[:language] : 'eng' )
        base_unit_name = BASE_UNIT_PER_DIMENSION[unit.dimension.to_sym]
        base_unit = base_unit_name == unit.reference_name ? nil : import_from_lexicon(base_unit_name)

        { name: unit.translation&.send(normalized_language) || unit.reference_name,
          reference_name: unit.reference_name,
          symbol: unit.symbol,
          base_unit: base_unit,
          coefficient: unit.a,
          dimension: unit.dimension,
          type: 'ReferenceUnit' }
      end

      # unit MasterPackaging
      def masterpackaging_attributes(unit)
        normalized_language = ((Preference[:language].include?('fra') || Preference[:language].include?('eng') ) ? Preference[:language] : 'eng' )
        { name: unit.translation&.send(normalized_language) || unit.reference_name,
          reference_name: unit.reference_name,
          # uniqueness of symbol
          # symbol: unit.capacity_unit.symbol,
          base_unit: import_from_lexicon(unit.capacity_unit),
          coefficient: unit.capacity,
          dimension: unit.capacity_unit.dimension,
          type: 'Conditioning' }
      end
  end
end
