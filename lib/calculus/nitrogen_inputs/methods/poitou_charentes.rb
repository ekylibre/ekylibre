# -*- coding: utf-8 -*-
module Calculus
  module NitrogenInputs
    module Methods


      class PoitouCharentes < Calculus::NitrogenInputs::Method

        def self.global_options
          {beginning: :date}
        end

        def crop_yield
          if @crop_yield.nil? or @crop_yield.zero?
            if items = Nomen::NmpPoitouCharentesAbacusOne.where(cultivation_variety: @zone.cultivation_varieties, administrative_area: @zone.administrative_area || :undefined) and items.any?
              @crop_yield = items.first.crop_yield.in_quintal_per_hectare
            elsif capacity = @zone.available_water_capacity and items = Nomen::NmpPoitouCharentesAbacusTwo.where(cultivation_variety: @zone.cultivation_varieties, soil_variety: @zone.soil_varieties) and items = items.select{|i| i.minimum_available_water_capacity.in_liter_per_square_meter <= capacity and capacity < i.maximum_available_water_capacity.in_liter_per_square_meter} and items.any?
              @crop_yield = items.first.crop_yield.in_quintal_per_hectare
            else
              @crop_yield = 40.in_quintal_per_hectare
            end
          end
          return @crop_yield
        end


        def apply!
          # Pf
          b = 3
          if items = Nomen::NmpPoitouCharentesAbacusThree.best_match(:cultivation_variety, zone.cultivation_variety) and items.any?
            b = items.first.coefficient
          end
          nitrogen_need = crop_yield * b

          # Pi
          absorbed_nitrogen_at_beginning = 10.in_kilogram_per_hectare
          if zone.cultivation and count = zone.cultivation.leaf_count(at: Date.civil(zone.campaign.harvest_year, 2, 1)) and zone.activity.nature.to_s == :straw_cereal_crops

            if items = Nomen::NmpPoitouCharentesAbacusFour.list.select do |item|
                (item.minimum_leaf_count || 0) <= count and count <= (item.minimum_leaf_count || count)
              end.first
              absorbed_nitrogen_at_beginning = items.first.absorbed_nitrogen.in_kilogram_per_hectare
            end
          end

          # Ri
          mineral_nitrogen_at_beginning = 20.in_kilogram_per_hectare

          # Mh
          humus_mineralization = 30.in_kilogram_per_hectare
          if false
            # TODO
          end

          # Mhp
          prairie_humus_mineralization = 0.in_kilogram_per_hectare
          if false
          end

          # Mr
          residue_mineralization = 0.in_kilogram_per_hectare

          # Mrci
          intermediate_cultivation_residue_mineralization = 0.in_kilogram_per_hectare

          # Nirr
          irrigation_water_nitrogen = 0.in_kilogram_per_hectare

          # Xa
          organic_fertilizer_mineral_fraction = 0.in_kilogram_per_hectare

          # Rf
          post_harvest_rest = 0.in_kilogram_per_hectare

          # Po
          soil_nitrogen_production = 0.in_kilogram_per_hectare

          # X
          real_nitrogen_need = nil
          if zone.soil_varieties.include?(:clay_limestone_soil) or zone.soil_varieties.include?(:chesnut_red_soil)
            # CAU = 0.8
            # X = [(Pf - Po - Mr - MrCi - Nirr) / CAU] – Xa
            fertilizer_apparent_use_coeffient = 0.8.to_d
            real_nitrogen_need = (((nitrogen_need -
                                    soil_nitrogen_production -
                                    residue_mineralization -
                                    intermediate_cultivation_residue_mineralization -
                                    irrigation_water_nitrogen) / fertilizer_apparent_use_coeffient) -
                                  organic_fertilizer_mineral_fraction)
          else
            # X = Pf - Pi - Ri - Mh - Mhp - Mr - MrCi - Nirr - Xa + Rf
            real_nitrogen_need = (nitrogen_need -
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

          if zone.soil_varieties.include?(:clay_limestone_soil)
            real_nitrogen_need *= 1.15.to_d
          else
            real_nitrogen_need *= 1.10.to_d
          end

          puts "---" * 80
          puts real_nitrogen_need.inspect

        end


      end


    end
  end
end
