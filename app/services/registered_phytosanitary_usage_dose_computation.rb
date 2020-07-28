class RegisteredPhytosanitaryUsageDoseComputation

  def validate_dose(usage, product, quantity, dimension, targets_data)
    return { none: :max_dose_unit_not_handled.tl } unless usage.among_dimensions?(:volume_area_density, :mass_area_density, :mass, :volume)

    reference_measure = Measure.new((usage.dose_quantity * usage.dose_unit_factor).to_f, usage.dose_unit)
    return { none: :provide_metrics_for_this_article.tl } if dimension == 'population' && !check_indicators(product, usage)

    user_measure = compute_user_measure(quantity, usage, product, targets_data, dimension)
    return { none: :provide_metrics_for_this_article.tl } unless user_measure

    compute_dose_message(user_measure, reference_measure)
  rescue FloatDomainError
    {none: ""}
  end

  def validate_intervention_input(input)
    #targets_data wants a hash of "k" => {shape: }
    targets_data = input.intervention.targets.map.with_index { |v, i| [i.to_s, { shape: v.working_zone }] }.to_h

    validate_dose(input.relevant_usage, input.product, input.quantity_value, input.quantity_indicator_name, targets_data)
  end

  private

    def check_indicators(product, usage)
      %i[mass volume].each do |el|
        return false if usage.among_dimensions?(el, "#{el}_area_density".to_sym) && (!product.has_indicator?("net_#{el}".to_sym) || product.send("net_#{el}".to_sym).to_f == 0)
      end

      true
    end

    def handle_volume_area_density(quantity, usage, product, targets)
      return Measure.new(quantity, :liter_per_hectare) if usage.of_dimension?(:volume_area_density)
      return nil if usage.among_dimensions?(:mass, :mass_area_density) && (!product.has_indicator?(:net_mass) || product.net_mass.to_f == 0)

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

      coeff = product.net_volume.to_f / product.net_mass.to_f
      if usage.of_dimension?(:volume)
        Measure.new(quantity * coeff, :liter)
      elsif usage.of_dimension?(:mass_area_density)
        convert_into_area_density(Measure.new(quantity, :kilogram), targets)
      elsif usage.of_dimension?(:volume_area_density)
        convert_into_area_density(Measure.new(quantity * coeff, :liter), targets)
      end
    end

    def compute_user_measure(quantity, usage, product, targets_data, dimension)
      case dimension
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
      targets_area = targets.values.sum do |target_info|
        Charta.new_geometry(target_info[:shape]).area
      end
      coeff = Measure.new(targets_area, :square_meter).in(:hectare).to_f

      Measure.new(measure.to_f / coeff, "#{measure.unit}_per_hectare")
    end

    def convert_from_area_density(measure, targets)
      targets_area = targets.values.sum do |target_info|
        Charta.new_geometry(target_info[:shape]).area
      end
      coeff = Measure.new(targets_area, :square_meter).in(:hectare).to_f

      Measure.new(measure.to_f * coeff, measure.unit.match(/([a-zA-Z]+)_per_hectare/)[1])
    end

    def handle_population(quantity, usage, product, targets)
      converted_population = convert_population_into_mass_or_volume(quantity, usage, product)

      if usage.among_dimensions?(:mass, :volume)
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
      end
    end
end
