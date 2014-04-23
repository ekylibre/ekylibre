module Calculus
  module ManureManagementPlan
    
    module PoitouCharentes2013
      
      class << self

        def estimate_expected_yield(options = {})
          expected_yield = Calculus::ManureManagementPlan::External.estimate_expected_yield(options)
          cultivation_varieties = (options[:variety] ? options[:variety].self_and_parents : :undefined)
          soil_natures =  (options[:soil_nature] ? options[:soil_nature].self_and_parents : :undefined)
          puts "------------------------------------------------------".red
          puts options.inspect.yellow
          puts cultivation_varieties.inspect.blue
          puts soil_natures.inspect.white
          if items = Nomen::NmpPoitouCharentesAbacusOne.where(cultivation_variety: cultivation_varieties, administrative_area: options[:administrative_area] || :undefined) and items.any?
            puts items.inspect.green
            expected_yield = items.first.expected_yield.in_quintal_per_hectare
          elsif capacity = options[:available_water_capacity].in_liter_per_square_meter and items = Nomen::NmpPoitouCharentesAbacusTwo.where(cultivation_variety: cultivation_varieties, soil_nature: soil_natures) and items = items.select{|i| i.minimum_available_water_capacity.in_liter_per_square_meter <= capacity and capacity < i.maximum_available_water_capacity.in_liter_per_square_meter} and items.any?
            puts items.inspect.green
            expected_yield = items.first.expected_yield.in_quintal_per_hectare
          # else
          #   expected_yield = 30.in_quintal_per_hectare
          end
          puts "======================================================".red
          return expected_yield
        end


        def compute(options = {})
          values = {}
          soil_natures =  (options[:soil_nature] ? options[:soil_nature].self_and_parents : :undefined)
          cultivation = options[:cultivation]

          # Pf
          b = 3
          if options[:variety] and items = Nomen::NmpPoitouCharentesAbacusThree.best_match(:cultivation_variety, options[:variety].name) and items.any?
            b = items.first.coefficient
          end
          values[:nitrogen_need] = options[:expected_yield].in_kilogram_per_hectare * b / 100.0.to_d

          # Pi
          values[:absorbed_nitrogen_at_beginning] = 10.in_kilogram_per_hectare
          if options[:cultivation] and count = options[:cultivation].leaf_count(at: options[:opened_at]) and zone.activity.nature.to_s == :straw_cereal_crops

            if items = Nomen::NmpPoitouCharentesAbacusFour.list.select do |item|
                (item.minimum_leaf_count || 0) <= count and count <= (item.minimum_leaf_count || count)
              end.first
              values[:absorbed_nitrogen_at_beginning] = items.first.absorbed_nitrogen.in_kilogram_per_hectare
            end
          end
          # @zone.mark(:absorbed_nitrogen_at_beginning_density, absorbed_nitrogen_at_beginning)

          # Ri
          quantity = options[:mineral_nitrogen_at_beginning].in_kilogram_per_hectare
          quantity ||= 15.in_kilogram_per_hectare
          if quantity < 5.in_kilogram_per_hectare
            quantity = 5.in_kilogram_per_hectare
          elsif quantity > 35.in_kilogram_per_hectare
            quantity = 35.in_kilogram_per_hectare
          end
          values[:mineral_nitrogen_at_beginning] = quantity

          # Mh
          values[:humus_mineralization] = 35.in_kilogram_per_hectare
          if false
            # TODO
          end

          # Mhp
          values[:meadow_humus_mineralization] = 0.in_kilogram_per_hectare
          if false
          end

          # Mr
          values[:residue_mineralization] = 20.in_kilogram_per_hectare

          # Mrci
          values[:intermediate_cultivation_residue_mineralization] = 0.in_kilogram_per_hectare

          # Nirr
          values[:irrigation_water_nitrogen] = 5.in_kilogram_per_hectare

          # Xa
          values[:organic_fertilizer_mineral_fraction] = 20.in_kilogram_per_hectare

          # Rf
          values[:post_harvest_rest] = 15.in_kilogram_per_hectare

          # Po
          values[:soil_nitrogen_production] = 45.in_kilogram_per_hectare

          # X
          values[:nitrogen_input] = nil
          if soil_natures.include?(Nomen::SoilNatures[:clay_limestone_soil]) or soil_natures.include?(Nomen::SoilNatures[:chesnut_red_soil])
            # CAU = 0.8
            # X = [(Pf - Po - Mr - MrCi - Nirr) / CAU] - Xa
            fertilizer_apparent_use_coeffient = 0.8.to_d
            values[:nitrogen_input] = (((values[:nitrogen_need] -
                                         values[:soil_nitrogen_production] -
                                         values[:residue_mineralization] -
                                         values[:intermediate_cultivation_residue_mineralization] -
                                         values[:irrigation_water_nitrogen]) / fertilizer_apparent_use_coeffient) -
                                       values[:organic_fertilizer_mineral_fraction])
          else
            # X = Pf - Pi - Ri - Mh - Mhp - Mr - MrCi - Nirr - Xa + Rf
            values[:nitrogen_input] = (values[:nitrogen_need] -
                                       values[:absorbed_nitrogen_at_beginning] -
                                       values[:mineral_nitrogen_at_beginning] -
                                       values[:humus_mineralization] -
                                       values[:meadow_humus_mineralization] -
                                       values[:residue_mineralization] -
                                       values[:intermediate_cultivation_residue_mineralization] -
                                       values[:irrigation_water_nitrogen] -
                                       values[:organic_fertilizer_mineral_fraction] +
                                       values[:post_harvest_rest])
          end

          if soil_natures.include?(Nomen::SoilNatures[:clay_limestone_soil])
            values[:nitrogen_input] *= 1.15.to_d
          else
            values[:nitrogen_input] *= 1.10.to_d
          end

          # @zone.mark(:nitrogen_area_density, nitrogen_input.round(3), subject: :support)
          # puts "-" * 80
          # puts "crop_yield:     " + crop_yield.inspect
          # puts "-" * 80
          # puts "nitrogen_input: " + nitrogen_input.inspect
          # puts "-" * 80
        end

        
      end

    end

  end
end
