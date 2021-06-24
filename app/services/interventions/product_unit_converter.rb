# frozen_string_literal: true

module Interventions
  class ProductUnitConverter
    # @param [Measure] measure
    # @param [Onoma::Item<Unit>] into
    # @param [Maybe<Measure<area>>] area
    # @param [Maybe<Measure<mass>>] net_mass
    # @param [Maybe<Measure<volume>>] net_volume
    # @param [Maybe<Measure<volume_concentration>>] spray_volume
    # @return [Maybe<Measure>] The result if the computation is successful, None otherwise.
    def convert(measure, into:, area:, net_mass:, net_volume:, spray_volume:)
      # Population <=> any
      if population_dimension?(measure.nomenclature_unit)
        convert_population_into_mass_or_volume(measure, into: Onoma::Unit.find(into.base_unit), net_mass: net_mass, net_volume: net_volume)
          .fmap do |net_measure|
            convert(net_measure, into: into, area: area, net_mass: net_mass, net_volume: net_volume, spray_volume: spray_volume)
          end
      elsif population_dimension?(into)
        convert(measure, into: Onoma::Unit.find(measure.base_unit), area: area, net_mass: net_mass, net_volume: net_volume, spray_volume: spray_volume)
          .fmap do |net_unit|
            convert_mass_or_volume_into_population(net_unit, net_mass: net_mass, net_volume: net_volume)
          end
      # passthrough
      elsif measure.dimension == into.dimension
        Maybe(measure.in(into))
      # Base dimensions are different
      elsif measure.base_dimension != into.base_dimension
        if net_dimension?(measure.dimension.to_sym)
          convert_net_into_other(measure, into: Onoma::Unit.find(into.base_unit), net_mass: net_mass, net_volume: net_volume)
            .fmap do |new_measure|
              convert(new_measure, into: into, area: area, net_mass: net_mass, net_volume: net_volume, spray_volume: spray_volume)
            end
        else
          convert_base_unit(measure, into: into, net_mass: net_mass, net_volume: net_volume)
            .fmap do |new_measure|
              convert(new_measure, into: into, area: area, net_mass: net_mass, net_volume: net_volume, spray_volume: spray_volume)
            end
        end
      # Surface_area <=> Net
      elsif net_dimension?(measure.dimension) && into.repartition_dimension == :surface_area
        convert_net_into_area_density(measure, into: into, area: area)
      elsif measure.repartition_dimension == :surface_area && net_dimension?(into.dimension)
        convert_area_density_into_net(measure, into: into, area: area)
      # concentration => Net
      elsif measure.repartition_dimension == :volume && net_dimension?(into.dimension)
        convert_concentration_into_net(measure, into: into, area: area, net_mass: net_mass, net_volume: net_volume, spray_volume: spray_volume)
      # Concentration => area_density
      elsif measure.repartition_dimension == :volume && into.repartition_dimension == :surface_area
        into_base_unit = Onoma::Unit.find(into.base_unit)

        convert(measure, into: into_base_unit, net_mass: net_mass, net_volume: net_volume, area: area, spray_volume: spray_volume)
          .fmap do |new_measure|
            convert(new_measure, into: into, net_mass: net_mass, net_volume: net_volume, area: area, spray_volume: spray_volume)
          end
      # any => concentration
      else
        None()
      end
    end

    # @param [Measure] measure
    # @param [Maybe<Measure<U>>] net_unit_value
    # @return [Maybe<Measure<U>>]
    def convert_population_into_net(measure, net_unit_value:)
      net_unit_value.fmap do |unit_value|
        unit_value * measure.value
      end
    end

    # @param [Measure<U>] measure
    # @param [Maybe<Measure<U>>] net_unit_value
    # @return [Maybe<Measure<population>>]
    def convert_net_into_population(measure, net_unit_value:)
      net_unit_value.fmap do |unit_value|
        if measure.dimension != unit_value.dimension
          None()
        else
          Measure.new(measure.in(unit_value.unit).value / unit_value.value, :population)
        end
      end
    end

    # @param [Measure] measure
    # @param [Onoma::Item<Unit>] into
    # @param [Maybe<Measure<mass>>] net_mass
    # @param [Maybe<Measure<volume>>] net_volume
    def convert_population_into_mass_or_volume(measure, into:, net_mass:, net_volume:)
      reference = case into.dimension
                  when :mass
                    net_mass
                  when :volume
                    net_volume
                  else
                    None()
                  end

      convert_population_into_net(measure, net_unit_value: reference)
    end

    # @param [Measure] measure
    # @param [Maybe<Measure<mass>>] net_mass
    # @param [Maybe<Measure<volume>>] net_volume
    def convert_mass_or_volume_into_population(measure, net_mass:, net_volume:)
      case measure.dimension
      when :mass
        convert_net_into_population(measure, net_unit_value: net_mass)
      when :volume
        convert_net_into_population(measure, net_unit_value: net_volume)
      else
        None()
      end
    end

    # @param [Onoma::Item<Unit>] from
    # @param [Onoma::Item<Unit>] to
    # @param [Maybe<Measure<mass>>] net_mass
    # @param [Maybe<Measure<volume>>] net_volume
    # @return [Maybe<Float>] ratio between from and to in :from/
    def compute_ratio_between_net_units(from:, to:, net_mass:, net_volume:)
      net_mass.fmap do |mass|
        net_volume.fmap do |volume|
          if from.dimension == to.dimension
            1.0
          elsif from.dimension == :mass && to.dimension == :volume
            volume.in(to).value.to_f / mass.in(from).value.to_f
          elsif from.dimension == :volume && to.dimension == :mass
            mass.in(to).value.to_f / volume.in(from).value.to_f
          else
            None()
          end
        end
      end
    end

    # @param [Measure] measure
    # @param [Onoma::Item<Unit>] into
    # @param [Maybe<Measure<mass>>] net_mass
    # @param [Maybe<Measure<volume>>] net_volume
    def convert_net_into_other(measure, into:, net_mass:, net_volume:)
      from = Onoma::Unit.find(measure.unit.to_sym)

      if from.nil?
        None()
      else
        compute_ratio_between_net_units(from: from, to: into, net_mass: net_mass, net_volume: net_volume)
          .fmap do |ratio|
            Measure.new(measure.value * ratio, into)
          end
      end
    end

    # @param [Measure] measure
    # @param [Onoma::Item<Unit>] into
    # @param [Maybe<Measure<area>>] area
    def convert_net_into_area_density(measure, into:, area:)
      if into.dimension.to_s.include?(measure.dimension.to_s)
        area.fmap do |area|
          Measure.new((measure.value.to_f / area.value.to_f), into)
        end
      else
        None()
      end
    end

    # @param [Measure] measure
    # @param [Onoma::Item<Unit>] into
    # @param [Maybe<Measure<area>>] area
    def convert_area_density_into_net(measure, into:, area:)
      area.fmap do |area|
        Measure.new(measure.value.to_f * area.value.to_f, into)
      end
    end

    def convert_base_unit(measure, into:, net_mass:, net_volume:)
      compute_ratio_between_net_units(from: Onoma::Unit.find(measure.base_unit), to: Onoma::Unit.find(into.base_unit), net_mass: net_mass, net_volume: net_volume)
        .fmap do |ratio|
          new_unit = "#{into.base_unit}_per_#{measure.repartition_unit}"

          Measure.new(measure.value.to_f * ratio, new_unit)
        end
    end

    # @param [Measure] measure
    # @param [Onoma::Item<Unit>] into
    # @param [Maybe<Measure<mass>>] net_mass
    # @param [Maybe<Measure<volume>>] net_volume
    def convert_area_density_into_other(measure, into:, net_mass:, net_volume:)
      if measure.repartition_dimension != :surface_area || into.repartition_dimension != :surface_area
        None()
      elsif measure.base_dimension == into.base_dimension
        Maybe(measure.in(into))
      else
        compute_ratio_between_net_units(from: Onoma::Unit.find(measure.base_unit), to: Onoma::Unit.find(into.base_unit), net_mass: net_mass, net_volume: net_volume)
          .fmap do |ratio|
            new_unit = "#{into.base_unit}_per_#{measure.repartition_unit}"
            Measure.new(measure.value.to_f * ratio, new_unit).in(into)
          end
      end
    end

    # @param [Measure] measure
    # @param [Onoma::Item<Unit>] into
    # @param [Maybe<Measure<area>>] area
    # @param [Maybe<Measure<mass>>] net_mass
    # @param [Maybe<Measure<volume>>] net_volume
    # @param [Maybe<Measure<volume_concentration>>] spray_volume
    def convert_concentration_into_net(measure, into:, area:, net_mass:, net_volume:, spray_volume:)
      spray_volume.fmap do |spray_volume|
        if spray_volume.unit.to_sym != :liter_per_hectare || (measure.unit.to_sym != :liter_per_hectoliter && measure.unit.to_sym != :kilogram_per_hectoliter)
          None()
        else
          area.fmap do |area|
            compute_ratio_between_net_units(from: Onoma::Unit.find(measure.base_unit), to: into, net_mass: net_mass, net_volume: net_volume)
              .fmap do |ratio|
                total_sprayed = spray_volume.value.to_f * area.in(:hectare).value.to_f
                product_sprayed = measure.value.to_f * total_sprayed / 100.0 * ratio
                Measure.new(product_sprayed, into)
              end
          end
        end
      end
    end

    # @param[Symbol] dimension
    def net_dimension?(dimension)
      dimension == :mass || dimension == :volume
    end

    # @param [Onoma::Item<Unit>] unit
    # @return [Boolean]
    def population_dimension?(unit)
      unit.dimension.to_sym == :none
    end
  end
end
