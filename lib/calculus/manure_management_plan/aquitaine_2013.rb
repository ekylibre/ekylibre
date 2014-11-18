# -*- coding: utf-8 -*-
require 'calculus/manure_management_plan/poitou_charentes_2013'

module Calculus
  module ManureManagementPlan

    class Aquitaine2013 < PoitouCharentes2013

      # Estimate "y"
      def estimate_expected_yield
	require 'colored' unless defined? Colored
expected_yield = Calculus::ManureManagementPlan::External.new(@options).estimate_expected_yield
        cultivation_varieties = (@variety ? @variety.self_and_parents : :undefined)
        # puts "------------------------------------------------------".red
        # puts @options.inspect.yellow
        # puts cultivation_varieties.inspect.blue
        # puts soil_natures.inspect.white
        # FIXME for production_usage
        if items = Nomen::NmpFranceAbacusCultivationYield.where(cultivation_variety: cultivation_varieties, administrative_area: @options[:administrative_area] || :undefined) and items.any? #production_usage: @usage
          # puts items.inspect.green
          expected_yield = items.first.expected_yield.in_quintal_per_hectare
        end
        # puts "======================================================".red
        return expected_yield
      end


      # Estimate "Pf" see PoitouCharentes2013

      # Estimate Rf see PoitouCharentes2013

      # Estimate "Ri" see PoitouCharentes2013

      # Estimate "Mh"
      def estimate_humus_mineralization
        quantity = 30.in_kilogram_per_hectare
        return quantity
      end

      # Estimate "Mhp" see PoitouCharentes2013

      # Estimate "Mr"
      def estimate_previous_cultivation_residue_mineralization
        quantity = 0.in_kilogram_per_hectare
        # find previous variety
        previous_variety = nil
        for campaign in self.campaign.previous.reorder(harvest_year: :desc)
          for support in campaign.production_supports.where(storage_id: @support.storage.id)
            # if an implantation intervention exist, get the plant output
            if previous_implantation_intervention = support.interventions.of_nature(:implantation).where(state: :done).order(:started_at).last
              if previous_cultivation = previous_implantation_intervention.casts.of_generic_role(:output).actor
                previous_variety = previous_cultivation.variety
                previous_cultivation_dead_at = previous_cultivation.dead_at
                break
              end
              break if previous_variety
            # elsif get the production_variant
            elsif support.production_variant
              previous_variety = support.production_variant.variety
              break
            end
            break if previous_variety
          end
          break if previous_variety
        end
        # set value corresponding to previous variety
        if previous_variety
          if previous_variety <= :lupinus or previous_variety <= :vicia
            quantity = 20.in_kilogram_per_hectare
          elsif previous_variety <= :pisum or previous_variety <= :glycine_max
            quantity = 10.in_kilogram_per_hectare
          end
        end
        return quantity
      end

      # Estimate Xa see PoitouCharentes2013

      # Estimate "Mrci" see PoitouCharentes2013

      # Estimate "Xmax" see PoitouCharentes2013

      # Estimate Nirr
      def estimate_irrigation_water_nitrogen
        quantity = 0.in_kilogram_per_hectare
        if input_water = @support.get(:irrigation_water_input_area_density)
          if input_water.to_d(:liter_per_square_meter) >= 100.00
            # TODO find an analysis for nitrogen concentration of input water for irrigation 'c'
            c = 25
            v = input_water.to_d(:liter_per_square_meter)
            quantity = ((v / 100) * (c / 4.43)).in_kilogram_per_hectare
          end
        end
        return quantity
      end

      def compute

        values = {}

        # Pf
        values[:nitrogen_need]                  = estimate_nitrogen_need

        # Pi
        values[:absorbed_nitrogen_at_opening] = estimate_absorbed_nitrogen_at_opening

        # Ri
        values[:mineral_nitrogen_at_opening]  = estimate_mineral_nitrogen_at_opening

        # Mh
        values[:humus_mineralization]           = estimate_humus_mineralization

        # Mhp
        values[:meadow_humus_mineralization]    = estimate_meadow_humus_mineralization

        # Mr
        values[:previous_cultivation_residue_mineralization]         = estimate_previous_cultivation_residue_mineralization

        # Mrci
        values[:intermediate_cultivation_residue_mineralization] = estimate_intermediate_cultivation_residue_mineralization

        # Nirr
        values[:irrigation_water_nitrogen]      = estimate_irrigation_water_nitrogen

        # Xa
        values[:organic_fertilizer_mineral_fraction] = estimate_organic_fertilizer_mineral_fraction

        # Rf
        values[:nitrogen_at_closing]              = estimate_nitrogen_at_closing

        # Po
        values[:soil_production]       = estimate_soil_production

        # Xmax
        values[:maximum_nitrogen_input] = estimate_maximum_nitrogen_input

        # X
        values[:nitrogen_input] = 0.in_kilogram_per_hectare
        # get sets corresponding to @variety
        sets = crop_sets.map(&:name).map(&:to_s)
        # CEREALES A PAILLES : (((Pf + Rf) – (Ri + Mh + Mhp + Mr)) / CAU) - Xa = X
        if @variety and ( @variety <= :poaceae or @variety <= :brassicaceae or @variety <= :medicago or @variety <= :helianthus or @variety <= :nicotiana or @variety <= :linum )
          fertilizer_apparent_use_coeffient = 0.8.to_d
          values[:nitrogen_input] = (((values[:nitrogen_need] + values[:nitrogen_at_closing]) -
                                       (values[:mineral_nitrogen_at_opening] + values[:humus_mineralization] +
                                       values[:meadow_humus_mineralization] +
                                       values[:previous_cultivation_residue_mineralization])) /
                                       fertilizer_apparent_use_coeffient) -
                                       values[:organic_fertilizer_mineral_fraction]

        end
        # MAIS / TABAC / SORGHO : ((Pf + Rf) – (Ri + Mh + Mhp + Mr + MrCi + Nirr) - Xa ) / CAU = X
        if @variety <= :zea or @variety <= :nicotiana or @variety <= :sorghum
          fertilizer_apparent_use_coeffient = 0.8.to_d
          values[:nitrogen_input] = (((values[:nitrogen_need] + values[:nitrogen_at_closing]) -
                                       (values[:mineral_nitrogen_at_opening] + values[:humus_mineralization] +
                                       values[:meadow_humus_mineralization] +
                                       values[:previous_cultivation_residue_mineralization])) -
                                       values[:organic_fertilizer_mineral_fraction] ) /
                                       fertilizer_apparent_use_coeffient

        end

        # PRAIRIE : N exp – (Mh + N rest + FS) = Xa + (X * CAU)

        # NOYER : Xa + X = d * b

        # TOURNESOL

        # COLZA

        # SOJA : pas d'apport sauf échec de nodulation

        # LEGUMES / ARBO / VIGNES : Dose plafond à partir d'abaques
        # X ≤ nitrogen_input_max – Nirr – Xa
        if @variety and (@variety <= :vitis or @variety <= :solanum_tuberosum or @variety <= :cucumis or sets.include?("gardening_vegetables"))
          values[:nitrogen_input] = values[:maximum_nitrogen_input] - values[:irrigation_water_nitrogen] - values[:organic_fertilizer_mineral_fraction]
        end


        return values
      end



    end

  end
end
