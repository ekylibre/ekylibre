require 'test_helper'

module Interventions
  class ProductUnitConverterTest < Ekylibre::Testing::ApplicationTestCase
    setup do
      @converter = ProductUnitConverter.new
    end

    test 'convert_population_into_net returns None if net reference is none' do
      assert_equal None(), @converter.convert_population_into_net(1.in(:population), net_unit_value: None())
    end

    test 'convert_population_into_net computes value if net reference is provided' do
      assert_equal 2.in(:liter), @converter.convert_population_into_net(1.in(:population), net_unit_value: Maybe(2.0.in(:liter))).or_raise
    end

    test 'convert_population_into_mass_or_volume returns None if into is neither mass or volume' do
      assert_equal None(), @converter.convert_population_into_mass_or_volume(1.in(:population), into: unit(:milliequivalent_per_hundred_gram), net_mass: Maybe(1.0.in(:kilogram)), net_volume: Maybe(2.0.in(:liter)))
    end

    test 'convert_population_into_mass_or_volume computes value if the unit is handled (mass/volume)' do
      assert_equal 50.in(:kilogram), @converter.convert_population_into_mass_or_volume(2.in(:population), into: unit(:kilogram), net_mass: Maybe(25.0.in(:kilogram)), net_volume: Maybe(30.0.in(:liter))).or_raise
      assert_equal 50.in(:kilogram), @converter.convert_population_into_mass_or_volume(2.in(:population), into: unit(:kilogram), net_mass: Maybe(25.0.in(:kilogram)), net_volume: Maybe(30.0.in(:liter))).or_raise
    end

    test 'convert_net_into_population returns None if net reference is none' do
      assert_equal None(), @converter.convert_net_into_population(2.in(:kilogram), net_unit_value: None())
    end

    test 'convert_net_into_population computes value if net reference is provided' do
      assert_measure_equal 25.in(:population), @converter.convert_net_into_population(50.in(:kilogram), net_unit_value: Maybe(2.in(:kilogram))).or_raise
      assert_measure_equal 25_000.in(:population), @converter.convert_net_into_population(50.in(:kilogram), net_unit_value: Maybe(2.in(:gram))).or_raise
    end

    test 'convert_net_into_population returns None if net reference is not in the same dimension as the measure to convert' do
      assert_equal None(), @converter.convert_net_into_population(50.in(:kilogram), net_unit_value: Maybe(2.in(:liter)))
    end

    test 'convert_mass_or_volume_into_population return none if unit is not handled' do
      assert_equal None(), @converter.convert_mass_or_volume_into_population(50.in(:kourak), net_mass: Maybe(2.in(:kilogram)), net_volume: Maybe(3.in(:liter)))
    end

    test 'convert_mass_or_volume_into_population computes value if unit handled' do
      assert_measure_equal 25.in(:population), @converter.convert_mass_or_volume_into_population(50_000.in(:gram), net_mass: Maybe(2.in(:kilogram)), net_volume: Maybe(3.in(:liter))).or_raise
      assert_measure_equal 25.in(:population), @converter.convert_mass_or_volume_into_population(50.in(:kilogram), net_mass: Maybe(2.in(:kilogram)), net_volume: Maybe(3.in(:liter))).or_raise
      assert_measure_equal 20.in(:population), @converter.convert_mass_or_volume_into_population(60.in(:liter), net_mass: Maybe(2.in(:kilogram)), net_volume: Maybe(3.in(:liter))).or_raise
    end

    test 'compute_ratio_between_net_units computes the ratio' do
      assert_equal 2.0, @converter.compute_ratio_between_net_units(from: unit(:kilogram), to: unit(:liter), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter))).or_raise
      assert_equal 0.5, @converter.compute_ratio_between_net_units(from: unit(:liter), to: unit(:kilogram), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter))).or_raise
      assert_equal 0.5, @converter.compute_ratio_between_net_units(from: unit(:liter), to: unit(:kilogram), net_mass: Maybe(1_000.in(:gram)), net_volume: Maybe(2.in(:liter))).or_raise
      assert_equal 0.5, @converter.compute_ratio_between_net_units(from: unit(:liter), to: unit(:kilogram), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2_000.in(:milliliter))).or_raise
      assert_equal 1.0, @converter.compute_ratio_between_net_units(from: unit(:liter), to: unit(:liter), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2_000.in(:milliliter))).or_raise
      assert_equal 0.005, @converter.compute_ratio_between_net_units(from: unit(:centiliter), to: unit(:kilogram), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter))).or_raise
      assert_equal None(), @converter.compute_ratio_between_net_units(from: unit(:kilogram_per_liter), to: unit(:liter), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)))
      assert_equal None(), @converter.compute_ratio_between_net_units(from: unit(:kilogram), to: unit(:kilogram_per_liter), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)))
      assert_equal None(), @converter.compute_ratio_between_net_units(from: unit(:kilogram), to: unit(:liter), net_mass: None(), net_volume: Maybe(2.in(:liter)))
    end

    test 'convert_net_into_other returns None if unable to compute the ratio' do
      stub_many @converter, compute_ratio_between_net_units: None() do
        assert_equal None(), @converter.convert_net_into_other(1.0.in(:kilogram), into: unit(:liter), net_mass: None(), net_volume: Maybe(2.in(:liter)))
      end
    end

    test 'convert_net_into_other returns do the correct computation' do
      assert_equal 2.0.in(:liter), @converter.convert_net_into_other(1.0.in(:kilogram), into: unit(:liter), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter))).or_raise
      assert_equal 25.0.in(:kilogram), @converter.convert_net_into_other(50.0.in(:liter), into: unit(:kilogram), net_mass: Maybe(1000.in(:gram)), net_volume: Maybe(2.in(:liter))).or_raise
    end

    test 'convert returns the value if the units are the same' do
      assert_measure_equal 1.in(:kilogram), @converter.convert(1.in(:kilogram), into: unit(:kilogram), area: None(), net_mass: None(), net_volume: None(), spray_volume: None()).or_raise
      assert_measure_equal 1.in(:liter), @converter.convert(1.in(:liter), into: unit(:liter), area: None(), net_mass: None(), net_volume: None(), spray_volume: None()).or_raise
    end

    test 'convert works if measure and asked units have the same dimension' do
      assert_measure_equal 1.in(:kilogram), @converter.convert(1_000.in(:gram), into: unit(:kilogram), area: None(), net_mass: None(), net_volume: None(), spray_volume: None()).or_raise
      assert_measure_equal 1.in(:liter), @converter.convert(1_000.in(:milliliter), into: unit(:liter), area: None(), net_mass: None(), net_volume: None(), spray_volume: None()).or_raise
      assert_measure_equal 1.in(:liter_per_hectare), @converter.convert(0.0001.in(:liter_per_square_meter), into: unit(:liter_per_hectare), area: None(), net_mass: None(), net_volume: None(), spray_volume: None()).or_raise
    end

    test 'convert handles conversion between net dimensions' do
      assert_measure_equal 2.0.in(:liter), @converter.convert(1.0.in(:kilogram), into: unit(:liter), area: None(), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: None()).or_raise
      assert_measure_equal 0.5.in(:kilogram), @converter.convert(100.0.in(:centiliter), into: unit(:kilogram), area: None(), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: None()).or_raise
    end

    test 'net_dimension? returns true if mass or volume are given, false otherwise' do
      assert @converter.net_dimension?(:mass)
      assert @converter.net_dimension?(:volume)
      assert_not @converter.net_dimension?(:volume_concentration)
    end

    test 'convert is able to convert population into net units' do
      assert_measure_equal 2.0.in(:kilogram), @converter.convert(2.in(:population), into: unit(:kilogram), area: None(), net_mass: Maybe(1.in(:kilogram)), net_volume: None(), spray_volume: None()).or_raise
      assert_measure_equal 4.0.in(:liter), @converter.convert(2.in(:population), into: unit(:liter), area: None(), net_mass: None(), net_volume: Maybe(2.in(:liter)), spray_volume: None()).or_raise
    end

    test 'convert is able to convert net units into population' do
      assert_measure_equal 1.0.in(:population), @converter.convert(2.in(:liter), into: unit(:unity), area: None(), net_mass: None(), net_volume: Maybe(2.in(:liter)), spray_volume: None()).or_raise
      assert_measure_equal 2.0.in(:population), @converter.convert(2.in(:kilogram), into: unit(:unity), area: None(), net_mass: Maybe(1.in(:kilogram)), net_volume: None(), spray_volume: None()).or_raise
    end

    test 'convert_net_into_area_density handles conversion from net to net_area_density' do
      assert_measure_equal 1.in(:liter_per_hectare), @converter.convert_net_into_area_density(5.in(:liter), into: unit(:liter_per_hectare), area: Maybe(5.in(:hectare))).or_raise
      assert_measure_equal 100.in(:gram_per_square_meter), @converter.convert_net_into_area_density(5_000.in(:kilogram), into: unit(:gram_per_square_meter), area: Maybe(50_000.in(:square_meter))).or_raise
    end

    test 'convert_net_into_area_density handles conversion from net to net_area_density even even if units are of the same dimension but differents' do
      assert_measure_equal 1000.in(:liter_per_hectare), @converter.convert_net_into_area_density(5.in(:cubic_meter), into: unit(:liter_per_hectare), area: Maybe(5.in(:hectare))).or_raise
      assert_measure_equal 1000.in(:liter_per_hectare), @converter.convert_net_into_area_density(5000.in(:liter), into: unit(:liter_per_hectare), area: Maybe(50_000.in(:square_meter))).or_raise
    end

    test 'convert_net_into_area_density does not handle net unit conversion' do
      assert_equal None(), @converter.convert_net_into_area_density(5.in(:liter), into: unit(:kilogram_per_hectare), area: Maybe(5.in(:hectare)))
    end

    test 'convert_area_density_into_net handles conversion from area density units into net' do
      assert_measure_equal 25.in(:kilogram), @converter.convert_area_density_into_net(5.in(:kilogram_per_hectare), into: unit(:kilogram), area: Maybe(5.in(:hectare))).or_raise
      assert_measure_equal 25.in(:liter), @converter.convert_area_density_into_net(5.in(:liter_per_hectare), into: unit(:liter), area: Maybe(5.in(:hectare))).or_raise
    end

    test 'convert_area_density_into_other handles conversion from area_density units to other' do
      assert_measure_equal 50.in(:liter_per_hectare), @converter.convert_area_density_into_other(25.in(:kilogram_per_hectare), into: unit(:liter_per_hectare), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter))).or_raise
      assert_measure_equal 0.005.in(:liter_per_square_meter), @converter.convert_area_density_into_other(50.in(:liter_per_hectare), into: unit(:liter_per_square_meter), net_mass: None(), net_volume: None()).or_raise
      assert_measure_equal 25.in(:kilogram_per_hectare), @converter.convert_area_density_into_other(50.in(:liter_per_hectare), into: unit(:kilogram_per_hectare), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter))).or_raise
      assert_measure_equal 25.in(:kilogram_per_hectare), @converter.convert_area_density_into_other(0.005.in(:liter_per_square_meter), into: unit(:kilogram_per_hectare), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter))).or_raise
    end

    test 'convert_area_density_into_other returns none if the repartition dimension is not area' do
      assert_equal None(), @converter.convert_area_density_into_other(5.in(:liter_per_hectoliter), into: unit(:liter_per_hectare), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)))
    end

    test 'convert handles conversion from net to net_area_density and back' do
      assert_measure_equal 1.in(:liter_per_hectare), @converter.convert(5.in(:liter), into: unit(:liter_per_hectare), area: Maybe(5.in(:hectare)), net_mass: None(), net_volume: None(), spray_volume: None()).or_raise
      assert_measure_equal 5.in(:liter), @converter.convert(1.in(:liter_per_hectare), into: unit(:liter), area: Maybe(5.in(:hectare)), net_mass: None(), net_volume: None(), spray_volume: None()).or_raise
    end

    test 'convert handles conversion from population to net_area_density and back' do
      assert_measure_equal 0.4.in(:liter_per_hectare), @converter.convert(1.in(:population), into: unit(:liter_per_hectare), area: Maybe(5.in(:hectare)), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: None()).or_raise
      assert_measure_equal 0.2.in(:kilogram_per_hectare), @converter.convert(1.in(:population), into: unit(:kilogram_per_hectare), area: Maybe(5.in(:hectare)), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: None()).or_raise
      assert_measure_equal 1.in(:population), @converter.convert(0.4.in(:liter_per_hectare), into: unit(:unity), area: Maybe(5.in(:hectare)), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: None()).or_raise
      assert_measure_equal 1.in(:population), @converter.convert(0.2.in(:kilogram_per_hectare), into: unit(:unity), area: Maybe(5.in(:hectare)), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: None()).or_raise
    end

    test 'convert_concentration_into_net handles conversion from volume and mass concentration into net' do
      assert_measure_equal 1.in(:kilogram), @converter.convert_concentration_into_net(1.in(:kilogram_per_hectoliter), into: unit(:kilogram), area: Maybe(5.in(:hectare)), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: Maybe(20.in(:liter_per_hectare))).or_raise
      assert_measure_equal 2.in(:liter), @converter.convert_concentration_into_net(2.in(:liter_per_hectoliter), into: unit(:liter), area: Maybe(5.in(:hectare)), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: Maybe(20.in(:liter_per_hectare))).or_raise
      assert_measure_equal 2.in(:liter), @converter.convert_concentration_into_net(1.in(:kilogram_per_hectoliter), into: unit(:liter), area: Maybe(5.in(:hectare)), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: Maybe(20.in(:liter_per_hectare))).or_raise
      assert_measure_equal 1.in(:kilogram), @converter.convert_concentration_into_net(2.in(:liter_per_hectoliter), into: unit(:kilogram), area: Maybe(5.in(:hectare)), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: Maybe(20.in(:liter_per_hectare))).or_raise
      assert_measure_equal 1.in(:kilogram), @converter.convert_concentration_into_net(1.in(:kilogram_per_hectoliter), into: unit(:kilogram), area: Maybe(50_000.in(:square_meter)), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: Maybe(20.in(:liter_per_hectare))).or_raise
    end

    test 'convert handler conversion from mass to mass_concentration and back' do
      [
        [1.in(:kilogram), 1.in(:kilogram_per_hectoliter), unit(:kilogram)],
        [2.in(:liter), 2.in(:liter_per_hectoliter), unit(:liter)],
        [2.in(:liter), 1.in(:kilogram_per_hectoliter), unit(:liter)],
        [1.in(:kilogram), 2.in(:liter_per_hectoliter), unit(:kilogram)],

        [1.in(:kilogram_per_hectoliter), 1.in(:kilogram), unit(:kilogram_per_hectoliter)],
        [2.in(:liter_per_hectoliter), 2.in(:liter), unit(:liter_per_hectoliter)],
        [1.in(:kilogram_per_hectoliter), 2.in(:liter), unit(:kilogram_per_hectoliter)],
        [2.in(:liter_per_hectoliter), 1.in(:kilogram), unit(:liter_per_hectoliter)]

      ].each do |expected, measure, into|
        assert_measure_equal(expected,
                             @converter.convert(measure,
                                                into: into,
                                                area: Maybe(5.in(:hectare)),
                                                net_mass: Maybe(1.in(:kilogram)),
                                                net_volume: Maybe(2.in(:liter)),
                                                spray_volume: Maybe(20.in(:liter_per_hectare))).or_raise)
      end
    end

    test 'convert handler conversion from area_density to concentration and back' do
      [
        [10.in(:kilogram_per_hectoliter), 2.in(:kilogram_per_hectare), unit(:kilogram_per_hectoliter)],
        [2.in(:kilogram_per_hectare), 10.in(:kilogram_per_hectoliter), unit(:kilogram_per_hectare)],
        [10.in(:liter_per_hectoliter), 2.in(:liter_per_hectare), unit(:liter_per_hectoliter)],
        [2.in(:liter_per_hectare), 10.in(:liter_per_hectoliter), unit(:liter_per_hectare)],
      ].each do |expected, measure, into|
        assert_measure_equal(expected,
                             @converter.convert(measure,
                                                into: into,
                                                area: Maybe(50_000.in(:square_meter)),
                                                net_mass: Maybe(1.in(:kilogram)),
                                                net_volume: Maybe(2.in(:liter)),
                                                spray_volume: Maybe(20.in(:liter_per_hectare))).or_raise)
      end
    end

    test 'convert handles conversion from concentration to population' do
      assert_measure_equal 1.in(:population), @converter.convert(1.in(:kilogram_per_hectoliter), into: unit(:unity), area: Maybe(5.in(:hectare)), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: Maybe(20.in(:liter_per_hectare))).or_raise
      assert_measure_equal 1.in(:population), @converter.convert(2.in(:liter_per_hectoliter), into: unit(:unity), area: Maybe(5.in(:hectare)), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: Maybe(20.in(:liter_per_hectare))).or_raise
    end

    test 'convert handles conversion from concentration to area_density' do
      assert_measure_equal 0.2.in(:kilogram_per_hectare), @converter.convert(1.in(:kilogram_per_hectoliter), into: unit(:kilogram_per_hectare), area: Maybe(5.in(:hectare)), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: Maybe(20.in(:liter_per_hectare))).or_raise
      assert_measure_equal 0.4.in(:liter_per_hectare), @converter.convert(1.in(:kilogram_per_hectoliter), into: unit(:liter_per_hectare), area: Maybe(5.in(:hectare)), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: Maybe(20.in(:liter_per_hectare))).or_raise
      assert_measure_equal 0.1.in(:kilogram_per_hectare), @converter.convert(1.in(:liter_per_hectoliter), into: unit(:kilogram_per_hectare), area: Maybe(5.in(:hectare)), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: Maybe(20.in(:liter_per_hectare))).or_raise
      assert_measure_equal 0.2.in(:liter_per_hectare), @converter.convert(1.in(:liter_per_hectoliter), into: unit(:liter_per_hectare), area: Maybe(5.in(:hectare)), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: Maybe(20.in(:liter_per_hectare))).or_raise
    end

    test "convert handles conversion from X to Y_area_density" do
      assert_measure_equal 0.4.in(:liter_per_hectare), @converter.convert(1.in(:kilogram), into: unit(:liter_per_hectare), area: Maybe(5.in(:hectare)), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: None()).or_raise
    end

    test "convert handles conversion from Y_area_density to X" do
      assert_measure_equal 5.in(:kilogram), @converter.convert(2.in(:liter_per_hectare), into: unit(:kilogram), area: Maybe(5.in(:hectare)), net_mass: Maybe(1.in(:kilogram)), net_volume: Maybe(2.in(:liter)), spray_volume: None()).or_raise
    end

    def assert_measure_equal(expected, value)
      assert expected.is_a?(Measure), "Expected value is not a measure"
      assert value.is_a?(Measure), "Given value is not a measure"
      assert_equal expected.unit, value.unit, "Measures don't have the same unit"
      assert_equal expected.value, value.value, "Values are different"
    end

    def unit(name)
      u = Onoma::Unit.find(name)
      refute_nil u, "The unit #{name} does not exist"
      u
    end
  end
end
