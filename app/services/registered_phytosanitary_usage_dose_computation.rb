# frozen_string_literal: true

class RegisteredPhytosanitaryUsageDoseComputation

  # @param [RegisteredPhytosanitaryUsage] usage
  # @param [RegisteredPhytosanitaryProduct] product
  # @param [Float] quantity
  # @param [String] dimension {@see Nomen::Indicator}
  # @param [Hash<Charta::GeometryCollection>] targets_data
  # @param [BigDecimal, nil] spray_colume
  def validate_dose(usage, product, quantity, dimension, targets_data, spray_volume = nil)
    if dimension == 'population' && !check_indicators(product, usage)
      { none: :provide_metrics_for_this_article.tl }
    else
      reference_measure = Measure.new((usage.dose_quantity * usage.dose_unit_factor).to_f, usage.dose_unit)
      user_measure = compute_user_measure(quantity, usage, product, targets_data, dimension, spray_volume)

      if user_measure.present? && reference_measure.dimension == user_measure.dimension
        compute_dose_message(user_measure, reference_measure)
      else
        { none: :max_dose_unit_not_handled.tl }
      end
    end
  rescue FloatDomainError
    { none: "" }
  end

  def validate_intervention_input(input)
    # targets_data wants a hash of "k" => {shape: }
    targets_data = input.intervention.targets.map.with_index { |v, i| [i.to_s, { shape: v.working_zone }] }.to_h

    validate_dose(input.relevant_usage, input.product, input.quantity_value, input.quantity_indicator_name, targets_data)
  end

  private
    # @return [Boolean]
    #   True if the amount can be computed from population (the product has a net_mass or net_volume)
    def check_indicators(product, usage)
      %i[mass volume].none? do |el|
        usage.among_dimensions?(el, "#{el}_area_density".to_sym) && (!product.has_indicator?("net_#{el}".to_sym) || product.send("net_#{el}".to_sym).to_f == 0)
      end
    end

    def handle_volume_area_density(quantity, usage, product, targets)
      return Measure.new(quantity, :liter_per_hectare) if usage.of_dimension?(:volume_area_density)
      return nil if usage.among_dimensions?(:mass, :mass_area_density) && (!product.has_indicator?(:net_mass) || product.net_mass.to_f == 0)
      return nil if usage.among_dimensions?(:volume_concentration, :mass_concentration)

      coeff = product.net_mass.to_f / product.net_volume.to_f
      if usage.of_dimension?(:mass)
        convert_from_area_density(Measure.new(quantity * coeff, :kilogram_per_hectare), targets)
      elsif usage.of_dimension?(:volume)
        convert_from_area_density(Measure.new(quantity, :liter_per_hectare), targets)
      elsif usage.of_dimension?(:mass_area_density)
        Measure.new(quantity * coeff, :kilogram_per_hectare)
      end
    end

    def handle_mass_area_density(quantity, usage, product, targets)
      return Measure.new(quantity, :kilogram_per_hectare) if usage.of_dimension?(:mass_area_density)
      return nil if usage.among_dimensions?(:volume, :volume_area_density) && (!product.has_indicator?(:net_volume) || product.net_volume.to_f == 0)
      return nil if usage.among_dimensions?(:volume_concentration, :mass_concentration)

      coeff = product.net_volume.to_f / product.net_mass.to_f
      if usage.of_dimension?(:volume)
        convert_from_area_density(Measure.new(quantity * coeff, :liter_per_hectare), targets)
      elsif usage.of_dimension?(:mass)
        convert_from_area_density(Measure.new(quantity, :kilogram_per_hectare), targets)
      elsif usage.of_dimension?(:volume_area_density)
        Measure.new(quantity * coeff, :liter_per_hectare)
      end
    end

    def handle_volume(quantity, usage, product, targets)
      return Measure.new(quantity, :liter) if usage.of_dimension?(:volume)
      return nil if usage.among_dimensions?(:mass, :mass_area_density) && (!product.has_indicator?(:net_mass) || product.net_mass.to_f == 0)
      return nil if usage.among_dimensions?(:volume_concentration, :mass_concentration)

      coeff = product.net_mass.to_f / product.net_volume.to_f
      if usage.of_dimension?(:mass)
        Measure.new(quantity * coeff, :kilogram)
      elsif usage.of_dimension?(:volume_area_density)
        convert_into_area_density(Measure.new(quantity, :liter), targets)
      elsif usage.of_dimension?(:mass_area_density)
        convert_into_area_density(Measure.new(quantity * coeff, :kilogram), targets)
      end
    end

    def handle_mass(quantity, usage, product, targets)
      return Measure.new(quantity, :kilogram) if usage.of_dimension?(:mass)
      return nil if usage.among_dimensions?(:volume, :volume_area_density) && (!product.has_indicator?(:net_volume) || product.net_volume.to_f == 0)
      return nil if usage.among_dimensions?(:volume_concentration, :mass_concentration)

      coeff = product.net_volume.to_f / product.net_mass.to_f
      if usage.of_dimension?(:volume)
        Measure.new(quantity * coeff, :liter)
      elsif usage.of_dimension?(:mass_area_density)
        convert_into_area_density(Measure.new(quantity, :kilogram), targets)
      elsif usage.of_dimension?(:volume_area_density)
        convert_into_area_density(Measure.new(quantity * coeff, :liter), targets)
      end
    end

    # @param [Float] quantity
    # @param [RegisteredPhytosanitaryUsage] usage
    # @param [Matter] product
    # @param [Hash<Charta::GeometryCollection>] targets
    # @param [BigDecimal, nil] spray_volume
    # @return [Measure, nil]
    def handle_mass_concentration(quantity, usage, product, targets, spray_volume)
      return Measure.new(quantity, :kilogram_per_hectoliter) if usage.of_dimension?(:mass_concentration)
      return nil if spray_volume.nil?
      return nil if usage.among_dimensions?(:volume, :volume_area_density, :volume_concentration) && (!product.has_indicator?(:net_volume) || product.net_volume.to_f == 0)

      targets_area = compute_area(targets)
      coeff = product.net_volume.to_f / product.net_mass.to_f
      if usage.of_dimension?(:mass)
        convert_mass_concentration_into_mass(spray_volume, targets_area, quantity)
      elsif usage.of_dimension?(:volume)
        convert_mass_concentration_into_volume(spray_volume, targets_area, quantity, coeff)
      elsif usage.of_dimension?(:mass_area_density)
        convert_mass_concentration_into_mass_area_density(spray_volume, quantity)
      elsif usage.of_dimension?(:volume_area_density)
        convert_mass_concentration_into_volume_area_density(spray_volume, quantity, coeff)
      elsif usage.among_dimensions?(:volume_concentration)
        Measure.new(quantity * coeff, :liter_per_hectoliter)
      end
    end

    # @param [Float] quantity
    # @param [RegisteredPhytosanitaryUsage] usage
    # @param [Matter] product
    # @param [Hash<Charta::GeometryCollection>] targets
    # @param [BigDecimal, nil] spray_volume
    # @return [Measure, nil]
    def handle_volume_concentration(quantity, usage, product, targets, spray_volume)
      return Measure.new(quantity, :liter_per_hectoliter) if usage.of_dimension?(:volume_concentration)
      return nil if spray_volume.nil?
      return nil if usage.among_dimensions?(:mass, :mass_area_density, :mass_concentration) && (!product.has_indicator?(:net_mass) || product.net_volume.to_f == 0)

      targets_area = compute_area(targets)
      coeff = product.net_mass.to_f / product.net_volume.to_f
      if usage.of_dimension?(:volume)
        convert_volume_concentration_into_volume(spray_volume, targets_area, quantity)
      elsif usage.of_dimension?(:mass)
        convert_volume_concentration_into_mass(spray_volume, targets_area, quantity, coeff)
      elsif usage.of_dimension?(:mass_area_density)
        convert_volume_concentration_into_mass_area_density(spray_volume, quantity, coeff)
      elsif usage.of_dimension?(:volume_area_density)
        convert_volume_concentration_into_volume_area_density(spray_volume, quantity)
      elsif usage.among_dimension?(:mass_concentration)
        Measure.new(quantity * coeff, :kilogram_per_hectoliter)
      end
    end

    # Tries to convert the user input to a Measure of the same dimension of the usage max dose
    #
    # param [Number] quantity
    # param [RegisteredPhytosanitaryUsage, InterventionParameter::LoggedPhytosanitaryUsage] usage
    # param [Product] product
    # param [Hash] targets_data
    # param [String] indicator
    # @param [BigDecimal] spray_volume
    # @return [Measure, nil]
    #   Returns nil either when the dimension is not handled or the computation fails
    def compute_user_measure(quantity, usage, product, targets_data, indicator, spray_volume)
      case indicator
        when 'population'
          handle_population(quantity, usage, product, targets_data)
        when 'net_mass'
          handle_mass(quantity, usage, product, targets_data)
        when 'net_volume'
          handle_volume(quantity, usage, product, targets_data)
        when 'mass_area_density'
          handle_mass_area_density(quantity, usage, product, targets_data)
        when 'volume_area_density'
          handle_volume_area_density(quantity, usage, product, targets_data)
        when 'specific_weight'
          handle_mass_concentration(quantity, usage, product, targets_data, spray_volume)
        when 'volume_density'
          handle_volume_concentration(quantity, usage, product, targets_data, spray_volume)
        else
          nil
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

    def convert_into_area_density(measure, targets)
      targets_area = compute_area(targets)
      coeff = Measure.new(targets_area, :square_meter).in(:hectare).to_f

      Measure.new(measure.to_f / coeff, "#{measure.unit}_per_hectare")
    end

    def convert_from_area_density(measure, targets)
      targets_area = compute_area(targets)
      coeff = Measure.new(targets_area, :square_meter).in(:hectare).to_f

      Measure.new(measure.to_f * coeff, measure.unit.match(/([a-zA-Z]+)_per_hectare/)[1])
    end

    def handle_population(quantity, usage, product, targets)
      converted_population = convert_population_into_mass_or_volume(quantity, usage, product)

      if converted_population.nil? || usage.among_dimensions?(:mass, :volume)
        converted_population
      else
        convert_into_area_density(converted_population, targets)
      end
    end

    def convert_population_into_mass_or_volume(quantity, usage, product)
      if usage.among_dimensions?(:mass, :mass_area_density)
        product.net_mass.in(:kilogram) * quantity
      elsif usage.among_dimensions?(:volume, :volume_area_density)
        product.net_volume.in(:liter) * quantity
      else
        nil
      end
    end

    # @param [BigDecimal] spray_volume in l/ha
    # @param [Float] targets_area in m2
    # @param [Float] quantity in kg/hl
    # @return [Measure] in kg
    def convert_mass_concentration_into_mass(spray_volume, targets_area, quantity)
      area_hectare = targets_area.in(:square_meter).in(:hectare)
      total_sprayed = spray_volume * area_hectare.value
      product_sprayed = quantity * total_sprayed / 100
      Measure.new(product_sprayed, :kilogram)
    end

    # @param [BigDecimal] spray_volume in l/ha
    # @param [Float] targets_area in m2
    # @param [Float] quantity in l/hl
    # @return [Measure] in l
    def convert_volume_concentration_into_volume(spray_volume, targets_area, quantity)
      area_hectare = targets_area.in(:square_meter).in(:hectare)
      total_sprayed = spray_volume * area_hectare.value
      product_sprayed = quantity * total_sprayed / 100

      Measure.new(product_sprayed, :liter)
    end

    def convert_mass_concentration_into_volume(spray_volume, targets_area, quantity, coeff)
      value = convert_mass_concentration_into_mass(spray_volume, targets_area, quantity).value * coeff
      Measure.new(value, :liter)
    end

    def convert_volume_concentration_into_mass(spray_volume, targets_area, quantity, coeff)
      value = convert_volume_concentration_into_volume(spray_volume, targets_area, quantity).value * coeff
      Measure.new(value, :kilogram)
    end

    # @param [BigDecimal] spray_volume in l/ha
    # @param [Float] quantity in kg/hl
    # @return [Measure] in kg/ha
    def convert_mass_concentration_into_mass_area_density(spray_volume, quantity)
      Measure.new(quantity * spray_volume / 100, :kilogram_per_hectare)
    end

    # @param [BigDecimal] spray_volume in l/ha
    # @param [Float] quantity in l/hl
    # @return [Measure] in kg/ha
    def convert_volume_concentration_into_mass_area_density(spray_volume, quantity, coeff)
      Measure.new(quantity * coeff * spray_volume / 100, :kilogram_per_hectare)
    end

    # @param [BigDecimal] spray_volume in l/ha
    # @param [Float] quantity in kg/hl
    # @return [Measure] in l/ha
    def convert_mass_concentration_into_volume_area_density(spray_volume, quantity, coeff)
      Measure.new(quantity * coeff * spray_volume / 100, :liter_per_hectare)
    end

    # @param [BigDecimal] spray_volume in l/ha
    # @param [Float] quantity in l/hl
    # @return [Measure] in l/ha
    def convert_volume_concentration_into_volume_area_density(spray_volume, quantity)
      Measure.new(quantity * spray_volume / 100, :liter_per_hectare)
    end

    # @return [Float] the area of given targets in SQUARE METERS
    def compute_area(targets)
      targets.values.sum do |target_info|
        Charta.new_geometry(target_info[:shape]).area
      end
    end
end
