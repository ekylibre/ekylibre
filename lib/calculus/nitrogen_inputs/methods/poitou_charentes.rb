module Calculus
  module NitrogenInputs
    module Methods


      class PoitouCharentes < Calculus::NitrogenInputs::Method

        def self.global_options
          {beginning: :date}
        end


        # Calculate or get crop yield and saves it into markers
        def set_crop_yield!
          @crop_yield = @options.delete(:crop_yield)
          @crop_yield = @crop_yield[:value].to_d.in(@crop_yield[:unit]) rescue nil
          if @crop_yield.nil? or @crop_yield.zero?
            if items = Nomen::NmpPoitouCharentesAbacusOne.where(cultivation_variety: @zone.cultivation_varieties, administrative_area: @zone.administrative_area || :undefined) and items.any?
              @crop_yield = items.first.crop_yield.in_quintal_per_hectare
            elsif capacity = @zone.available_water_capacity and items = Nomen::NmpPoitouCharentesAbacusTwo.where(cultivation_variety: @zone.cultivation_varieties, soil_nature: @zone.soil_natures) and items = items.select{|i| i.minimum_available_water_capacity.in_liter_per_square_meter <= capacity and capacity < i.maximum_available_water_capacity.in_liter_per_square_meter} and items.any?
              @crop_yield = items.first.crop_yield.in_quintal_per_hectare
            else
              @crop_yield = 30.in_quintal_per_hectare
            end
          end
          if @crop_yield.zero?
            marker = @zone.crop_yield_marker
            marker.destroy if marker
          else
            @zone.mark(:mass_area_yield, @crop_yield)
          end
          return @crop_yield
        end


        def calculate!
          # Pf
          b = 3
          if items = Nomen::NmpPoitouCharentesAbacusThree.best_match(:cultivation_variety, zone.cultivation_variety) and items.any?
            b = items.first.coefficient
          end
          nitrogen_need = crop_yield.in_kilogram_per_hectare * b / 100.0.to_d
          # @zone.mark(:nitrogen_need_density, nitrogen_need)

          # Pi
          absorbed_nitrogen_at_beginning = 10.in_kilogram_per_hectare
          if zone.cultivation and count = zone.cultivation.leaf_count(at: Date.civil(zone.campaign.harvest_year, 2, 1)) and zone.activity.nature.to_s == :straw_cereal_crops

            if items = Nomen::NmpPoitouCharentesAbacusFour.list.select do |item|
                (item.minimum_leaf_count || 0) <= count and count <= (item.minimum_leaf_count || count)
              end.first
              absorbed_nitrogen_at_beginning = items.first.absorbed_nitrogen.in_kilogram_per_hectare
            end
          end
          # @zone.mark(:absorbed_nitrogen_at_beginning_density, absorbed_nitrogen_at_beginning)

          # Ri
          # @TODO between 0 and 35
          mineral_nitrogen_at_beginning = 15.in_kilogram_per_hectare

          # Mh
          humus_mineralization = 35.in_kilogram_per_hectare
          if false
            # TODO
          end

          # Mhp
          prairie_humus_mineralization = 0.in_kilogram_per_hectare
          if false
          end

          # Mr
          residue_mineralization = 20.in_kilogram_per_hectare

          # Mrci
          intermediate_cultivation_residue_mineralization = 0.in_kilogram_per_hectare

          # Nirr
          irrigation_water_nitrogen = 5.in_kilogram_per_hectare

          # Xa
          organic_fertilizer_mineral_fraction = 20.in_kilogram_per_hectare

          # Rf
          post_harvest_rest = 15.in_kilogram_per_hectare

          # Po
          soil_nitrogen_production = 45.in_kilogram_per_hectare

          # X
          nitrogen_input = nil
          if zone.soil_natures.include?(:clay_limestone_soil) or zone.soil_natures.include?(:chesnut_red_soil)
            # CAU = 0.8
            # X = [(Pf - Po - Mr - MrCi - Nirr) / CAU] - Xa
            fertilizer_apparent_use_coeffient = 0.8.to_d
            nitrogen_input = (((nitrogen_need -
                                soil_nitrogen_production -
                                residue_mineralization -
                                intermediate_cultivation_residue_mineralization -
                                irrigation_water_nitrogen) / fertilizer_apparent_use_coeffient) -
                              organic_fertilizer_mineral_fraction)
          else
            # X = Pf - Pi - Ri - Mh - Mhp - Mr - MrCi - Nirr - Xa + Rf
            nitrogen_input = (nitrogen_need -
                              absorbed_nitrogen_at_beginning -
                              mineral_nitrogen_at_beginning -
                              humus_mineralization -
                              prairie_humus_mineralization -
                              residue_mineralization -
                              intermediate_cultivation_residue_mineralization -
                              irrigation_water_nitrogen -
                              organic_fertilizer_mineral_fraction +
                              post_harvest_rest)
          end

          if zone.soil_natures.include?(:clay_limestone_soil)
            nitrogen_input *= 1.15.to_d
          else
            nitrogen_input *= 1.10.to_d
          end

          @zone.mark(:nitrogen_area_density, nitrogen_input.round(3), subject: :support)

          puts "-" * 80
          puts "crop_yield:     " + crop_yield.inspect
          puts "-" * 80
          puts "nitrogen_input: " + nitrogen_input.inspect
          puts "-" * 80

        end


      end


    end
  end
end
