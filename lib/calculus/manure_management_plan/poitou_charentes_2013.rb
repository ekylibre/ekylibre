module Calculus
  module ManureManagementPlan
    
    class PoitouCharentes2013 < Method
      
      # Estimate "y"
      def estimate_expected_yield
        expected_yield = Calculus::ManureManagementPlan::External.new(@options).estimate_expected_yield
        cultivation_varieties = (@variety ? @variety.self_and_parents : :undefined)
        puts "------------------------------------------------------".red
        puts @options.inspect.yellow
        puts cultivation_varieties.inspect.blue
        puts soil_natures.inspect.white
        if items = Nomen::NmpPoitouCharentesAbacusOne.where(cultivation_variety: cultivation_varieties, administrative_area: @options[:administrative_area] || :undefined) and items.any?
          puts items.inspect.green
          expected_yield = items.first.expected_yield.in_quintal_per_hectare
        elsif capacity = @options[:available_water_capacity].in_liter_per_square_meter and items = Nomen::NmpPoitouCharentesAbacusTwo.where(cultivation_variety: cultivation_varieties, soil_nature: soil_natures) and items = items.select{|i| i.minimum_available_water_capacity.in_liter_per_square_meter <= capacity and capacity < i.maximum_available_water_capacity.in_liter_per_square_meter} and items.any?
          puts items.inspect.green
          expected_yield = items.first.expected_yield.in_quintal_per_hectare
          # else
          #   expected_yield = 30.in_quintal_per_hectare
        end
        puts "======================================================".red
        return expected_yield
      end


      # Estimate "Pf"
      def estimate_nitrogen_need
        expected_yield = @expected_yield.to_f(:quintal_per_hectare)
        b = 3
        if @variety
          items = Nomen::NmpPoitouCharentesAbacusThree.list.select do |i|
            @variety <= i.cultivation_variety and
              i.usage.to_sym == @usage and
              i.minimum_yield_aim <= expected_yield and expected_yield <= i.maximum_yield_aim and
              (i.irrigated.blank? or (@options[:irrigated] and i.irrigated) or (!@options[:irrigated] and !i.irrigated))
          end
          if items.any?
            b = items.first.coefficient
          elsif @variety <= :zea
            b = 2.4
          end
        end
        # if @variety and items = Nomen::NmpPoitouCharentesAbacusThree.best_match(:cultivation_variety, @variety.name) and items.any?
        #   b = items.first.coefficient
        # end
        return @expected_yield.in_kilogram_per_hectare * b / 100.0.to_d
      end


      # Estimate "Pi"
      def estimate_absorbed_nitrogen_at_opening
        quantity = 10.in_kilogram_per_hectare
        if @cultivation.blank? and @variety and (@variety <= :zea or @variety <= :sorghum or @variety <= :helianthus or @variety <= :linum or @variety <= :cannabis or @variety <= :nicotiana)
          quantity = 0.in_kilogram_per_hectare
        elsif @cultivation 
          if count = @cultivation.leaf_count(at: @opened_at) and activity.nature.to_sym == :straw_cereal_crops
            items = Nomen::NmpPoitouCharentesAbacusFour.list.select do |item|
              item.minimum_leaf_count <= count and count <= item.minimum_leaf_count
            end
            if items.any?
              quantity = items.first.absorbed_nitrogen.in_kilogram_per_hectare
            end
          elsif @variety and @variety <= :brassica_napus and @cultivation.indicators_list.include?(:fresh_mass) and @cultivation.indicators_list.include?(:net_surface_area)
            items = Nomen::NmpPoitouCharentesAbacusTwelve.list.select do |item|
              @administrative_area <= item.administrative_area
            end
            if items.any?
              quantity = (items.first.coefficient * @cultivation.fresh_mass(at: @opened_at).to_f(:kilogram) / @cultivation.net_surface_area(at: @opened_at).to_f(:square_meter)).in_kilogram_per_hectare
            end
          end
        end
        return quantity
      end

      
      # Estimate "Ri"
      def estimate_mineral_nitrogen_at_opening
        @options[:mineral_nitrogen_at_opening] ||= 0.0
        quantity = @options[:mineral_nitrogen_at_opening].in_kilogram_per_hectare
        quantity ||= 15.in_kilogram_per_hectare
        if quantity < 5.in_kilogram_per_hectare
          quantity = 5.in_kilogram_per_hectare
        elsif quantity > 35.in_kilogram_per_hectare
          quantity = 35.in_kilogram_per_hectare
        end
        return quantity
      end

      # Estimate "Mh"
      def estimate_humus_mineralization
        quantity = 30.in_kilogram_per_hectare
        sets = crop_sets.map(&:name).map(&:to_s)
        if sets.any? and @soil_nature
          items = Nomen::NmpPoitouCharentesAbacusFive.list.select do |item|
            @soil_nature <= item.soil_nature and
              sets.include?(item.cereal_typology.to_s)
          end
          if items.any?
            # TODO How to determine exploitation typology ?
            typology = [:cereal_crop, :husbandry, :mixed_crop, :husbandry_with_mixed_crop].first
            quantity = items.first.send(typology).in_kilogram_per_hectare
          end
        end
        return quantity
      end

      # Estimate "Mhp"
      def estimate_meadow_humus_mineralization
        quantity = 0.in_kilogram_per_hectare
        rank, found = 1, nil
        for campaign in self.campaign.previous.reorder(harvest_year: :desc)
          for support in campaign.production_supports.where(storage_id: storage.id)
            if support.production.variant_variety < sdsd
              found = support
              break
            end
          end
          break if found
          rank += 1
        end
        if rank > 0 and found and cultivation = found.cultivation
          age = (cultivation.dead_at - cultivation.born_at) / 1.month
          season = ([9, 10, 11, 12].include?(cultivation.dead_at.month) ? :autumn : [3, 4, 5, 6].include?(cultivation.dead_at.month) ? :spring : nil)
          items = Nomen::NmpPoitouCharentesAbacusSix.list.select do |item|
            item.minimum_age <= age and age <= item.maximum_age and
              item.rank == rank
          end
          if items.any?
            items.first.quantity.in_kilogram_per_hectare
          end
        end
        return quantity
      end

      # Estimate "Mr"
      def estimate_previous_cultivation_residue_mineralization
        quantity = 0.in_kilogram_per_hectare
        # TODO
        return quantity
      end


      # Estimate "Mrci"
      def estimate_intermediate_cultivation_residue_mineralization
        quantity = 0.in_kilogram_per_hectare
        sets = crop_sets.map(&:name).map(&:to_s)
        if sets.any? and sets.include?('spring_crop')
          if storage
            # TODO
            # return the last plant on the storage
            
            # check if this plant is linked to a production with a nature <> "main"
            
          end
        end
        return quantity
      end


      # Estimate Nirr
      def estimate_irrigation_water_nitrogen
        quantity = 0.in_kilogram_per_hectare
        if input_water = @support.get(:input_water) 
          if input_water.to_d(:liter_per_square_meter) >= 100.00
            # TODO find an analysis for nitrogen concentration of input water for irrigation 'c'
            c = 40
            v = input_water.to_d(:liter_per_square_meter)
            quantity = ((v / 100) * (c / 4.43)).in_kilogram_per_hectare
          end
        end
        return quantity        
      end


      # Estimate Xa
      def estimate_organic_fertilizer_mineral_fraction
        quantity = 0.in_kilogram_per_hectare
        # TODO
        started_at = Time.new(campaign.harvest_year-1,7,15)
        stopped_at = @opened_at
        if interventions = @support.interventions.real.where(state: 'done').of_nature(:soil_enrichment).between(started_at,stopped_at).with_cast(:'soil_enrichment-target', storage)
          # TODO
        end
        return quantity        
      end


      # Estimate Rf
      def estimate_nitrogen_at_closing
        quantity = 0.in_kilogram_per_hectare
        # TODO
        return quantity        
      end

      # Estimate Po
      def estimate_soil_production
        quantity = 0.in_kilogram_per_hectare
        # TODO
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

        # X
        values[:nitrogen_input] = nil
        if soil_natures.include?(Nomen::SoilNatures[:clay_limestone_soil]) or soil_natures.include?(Nomen::SoilNatures[:chesnut_red_soil])
          # CAU = 0.8
          # X = [(Pf - Po - Mr - MrCi - Nirr) / CAU] - Xa
          fertilizer_apparent_use_coeffient = 0.8.to_d
          values[:nitrogen_input] = (((values[:nitrogen_need] -
                                       values[:soil_production] -
                                       values[:previous_cultivation_residue_mineralization] -
                                       values[:intermediate_cultivation_residue_mineralization] -
                                       values[:irrigation_water_nitrogen]) / fertilizer_apparent_use_coeffient) -
                                     values[:organic_fertilizer_mineral_fraction])
        else
          # X = Pf - Pi - Ri - Mh - Mhp - Mr - MrCi - Nirr - Xa + Rf
          values[:nitrogen_input] = (values[:nitrogen_need] -
                                     values[:absorbed_nitrogen_at_opening] -
                                     values[:mineral_nitrogen_at_opening] -
                                     values[:humus_mineralization] -
                                     values[:meadow_humus_mineralization] -
                                     values[:previous_cultivation_residue_mineralization] -
                                     values[:intermediate_cultivation_residue_mineralization] -
                                     values[:irrigation_water_nitrogen] -
                                     values[:organic_fertilizer_mineral_fraction] +
                                     values[:nitrogen_at_closing])
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

        return values
      end

      

    end

  end
end
