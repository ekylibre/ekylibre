class RegisteredPhytosanitaryUsageDoseComputation
  class << self
    def build
      new(converter: Interventions::ProductUnitConverter.new)
    end
  end

  attr_reader :converter

  def initialize(converter:)
    @converter = converter
  end

  # MINCH pour les tests: changer les appels a cette methode pour lui passer une measure
  # @param [RegisteredPhytosanitaryUsage] usage
  # @param [RegisteredPhytosanitaryProduct] product
  # @param [Measure] measure
  # @param [Hash<Charta::GeometryCollection>] targets_data
  # @param [BigDecimal, nil] spray_volume
  def validate_dose(usage, product, measure, targets_data, spray_volume = nil)
    if measure.dimension == 'none' && !check_indicators(product, usage)
      { none: :provide_metrics_for_this_article.tl }
    else
      reference_measure = Measure.new((usage.dose_quantity * usage.dose_unit_factor).to_f, usage.dose_unit)
      user_measure = compute_user_measure(measure, usage, product, targets_data, spray_volume)

      if user_measure.present? && reference_measure.dimension == user_measure.dimension
        compute_dose_message(user_measure, reference_measure)
      else
        { none: :max_dose_unit_not_handled.tl }
      end
    end
  rescue FloatDomainError
    { none: "" }
  end

  # @param [InterventionInput] input
  def validate_intervention_input(input)
    # targets_data wants a hash of "k" => {shape: }
    targets_data = input.intervention.targets.map.with_index { |v, i| [i.to_s, { shape: v.working_zone }] }.to_h

    pu = ProductWithUsage.from_intervention_input(input)

    validate_dose(pu.relevant_usage, pu.product, pu.measure, targets_data)
  end

  private
    # @return [Boolean]
    #   True if the amount can be computed from population (the product has a net_mass or net_volume)
    def check_indicators(product, usage)
      %i[mass volume].none? do |el|
        usage.among_dimensions?(el, "#{el}_area_density".to_sym) && (!product.has_indicator?("net_#{el}".to_sym) || product.send("net_#{el}".to_sym).to_f == 0)
      end
    end

    # Tries to convert the user input to a Measure of the same dimension of the usage max dose
    #
    # param [Measure] quantity
    # param [RegisteredPhytosanitaryUsage, InterventionParameter::LoggedPhytosanitaryUsage] usage
    # param [Product] product
    # param [Hash] targets_data
    # @param [BigDecimal] spray_volume
    # @return [Measure, nil]
    #   Returns nil either when the dimension is not handled or the computation fails
    def compute_user_measure(measure, usage, product, targets_data, spray_volume)
      usage_unit = Onoma::Unit.find(usage.dose_unit)

      if usage_unit.nil?
        nil
      else
        zero_as_nil = ->(value) { value.zero? ? None() : value }

        params = {
          into: usage_unit,
          area: Maybe(compute_area(targets_data)).fmap(&zero_as_nil),
          net_mass: Maybe(product.net_mass).fmap(&zero_as_nil),
          net_volume: Maybe(product.net_volume).fmap(&zero_as_nil),
          spray_volume: Maybe(spray_volume).fmap(&zero_as_nil).in(:liter_per_hectare)
        }

        converter.convert(measure, **params).or_nil
      end
    end

    def compute_dose_message(user_measure, reference_measure)
      if user_measure < reference_measure
        { go: :dose_less_than_max.tl }
      elsif user_measure == reference_measure
        { caution: :dose_equal_to_max.tl }
      else
        { stop: :dose_bigger_than_max.tl }
      end
    end

    # @return [Measure<area>] the area of given targets
    def compute_area(targets)
      targets.values.sum do |target_info|
        Charta.new_geometry(target_info[:shape]).area
      end.in(:square_meter)
    end
end
