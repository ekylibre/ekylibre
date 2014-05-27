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
        if items = Nomen::NmpFranceAbacusCultivationYield.where(cultivation_variety: cultivation_varieties, administrative_area: @options[:administrative_area] || :undefined) and items.any? and (@variety <= :avena or @variety <= :secale)
          puts items.inspect.green
          expected_yield = items.first.expected_yield.in_quintal_per_hectare
        elsif capacity = @options[:available_water_capacity].in_liter_per_square_meter and items = Nomen::NmpPoitouCharentesAbacusTwo.where(cultivation_variety: cultivation_varieties, soil_nature: soil_natures) and items = items.select{|i| i.minimum_available_water_capacity.in_liter_per_square_meter <= capacity and capacity < i.maximum_available_water_capacity.in_liter_per_square_meter} and items.any?
          puts items.inspect.green
          expected_yield = items.first.expected_yield.in_quintal_per_hectare
        #else
          # TODO remove this when all factor could return a value
          #expected_yield = 30.in_quintal_per_hectare
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
        campaigns = self.campaign.previous.reorder(harvest_year: :desc)
        if sets.any? and @soil_nature
          items = Nomen::NmpPoitouCharentesAbacusFive.list.select do |item|
            @soil_nature <= item.soil_nature and
              sets.include?(item.cereal_typology.to_s)
          end
          if items.any?
            # if there are animal's activities on farm in campaign
            if Activity.of_campaign(campaigns).of_families(:animal_farming).any?
              # if animals moved on cultivable_zones in previous campaign then :husbandry_with_mixed_crop else :husbandry
              if Intervention.of_campaign(campaigns).of_nature(:pasturing).any?
                typology = :husbandry_with_mixed_crop
              else
                typology = :husbandry
              end
            # elsif all production on the campagin is link to a crop_set :cereals then :cereal_crop
            elsif Activity.of_campaign(campaigns).of_families(:straw_cereal_crops).count == Activity.of_campaign(campaigns).of_families(:vegetal_crops).count
              typology = :cereal_crop
            else 
              typology = :mixed_crop
            end
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
          for support in campaign.production_supports.where(storage_id: @support.storage.id)
            variety_support = Nomen::Varieties.find(support.production.variant_variety)
            if variety_support <= :poa
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
            quantity = items.first.quantity.in_kilogram_per_hectare
          end
        end
        return quantity
      end

      # Estimate "Mr"
      def estimate_previous_cultivation_residue_mineralization
        quantity = 0.in_kilogram_per_hectare
        # get the previous cultivation variety on the current support storage
        previous_variety = nil
        for campaign in self.campaign.previous.reorder(harvest_year: :desc)
          for support in campaign.production_supports.where(storage_id: @support.storage.id)
            # if an implantation intervention exist, get the plant output
            if previous_implantation_intervention = support.interventions.of_nature(:implantation).where(state: :done).order(:started_at).last
              if previous_cultivation = previous_implantation_intervention.casts.of_role(:output).actor
                previous_variety = previous_cultivation.variety
                previous_cultivation_dead_at = previous_cultivation.dead_at
                break
              end
              break if previous_variety
            # elsif get the production_variant
            elsif support.production_variant
              previous_variety = Nomen::Varieties.find(support.production_variant.variety)
              break
            end
            break if previous_variety
          end
          break if previous_variety
        end
        
        if previous_variety
          # find corresponding crop_sets to previous_variety
          previous_crop_sets = Nomen::CropSets.list.select do |i|
            i.varieties.detect do |v|
              previous_variety <= v
            end
          end
          previous_sets = previous_crop_sets.map(&:name).map(&:to_s)
        end
        # build variables for abacus 7
        # find the previous crop age in months
        if previous_cultivation and previous_cultivation.dead_at and previous_cultivation.born_at
          previous_crop_age = ((previous_cultivation.dead_at - previous_cultivation.born_at)/(3600*24*30)).to_i
        else
          previous_crop_age = 1
        end
        # find the previous crop destruction period date in format MMDD
        if previous_cultivation and previous_cultivation.dead_at
          previous_crop_destruction_period = previous_cultivation.dead_at.strftime("%m%d")
        else
          previous_crop_destruction_period = '0831'
        end
        # find the current crop implantation period date in format MMDD
        if @cultivation
          current_crop_implantation_period = @cultivation.born_at.strftime("%m%d")
        else
          current_crop_implantation_period = '0315'
        end
        # find items in abacus 7
        if previous_sets and previous_crop_age and previous_crop_destruction_period and current_crop_implantation_period
          items = Nomen::NmpPoitouCharentesAbacusSeven.list.select do |item|
            previous_sets.include?(item.previous_crop.to_s) and (item.previous_crop_minimum_age.to_i <= previous_crop_age.to_i and previous_crop_age.to_i < item.previous_crop_maximum_age.to_i) and (item.previous_crop_destruction_period_start.to_i <= previous_crop_destruction_period.to_i and previous_crop_destruction_period.to_i < item.previous_crop_destruction_period_stop.to_i) and current_crop_implantation_period.to_i >= item.current_crop_implantation_period_start.to_i
          end
          if items.any?
            quantity = items.first.quantity.in_kilogram_per_hectare
          end
        end
        return quantity
      end


      # Estimate "Mrci"
      def estimate_intermediate_cultivation_residue_mineralization
        quantity = 0.in_kilogram_per_hectare
        sets = crop_sets.map(&:name).map(&:to_s)
        if sets.any? and sets.include?('spring_crop')
          if @support.storage
            previous_variety = nil
            for campaign in self.campaign.previous.reorder(harvest_year: :desc)
              for support in campaign.production_supports.where(storage_id: @support.storage.id)
                # if an implantation intervention exist, get the plant output
                if previous_implantation_intervention = support.interventions.of_nature(:implantation).where(state: :done).order(:started_at).last
                  if previous_cultivation = previous_implantation_intervention.casts.of_role(:output).actor
                    previous_variety = previous_cultivation.variety
                    previous_cultivation_dead_at = previous_cultivation.dead_at
                    break
                  end
                  break if previous_variety
                # elsif get the production_variant
                elsif support.production_variant
                  previous_variety = Nomen::Varieties.find(support.production_variant.variety)
                  break
                end
                break if previous_variety
              end
              break if previous_variety
            end

            if previous_variety
              # find corresponding crop_sets to previous_variety
              previous_crop_sets = Nomen::CropSets.list.select do |i|
                i.varieties.detect do |v|
                  previous_variety <= v
                end
              end
              previous_sets = previous_crop_sets.map(&:name).map(&:to_s)
            end
            
            # build variables for abacus 11
            previous_crop_destruction_period = '0831'
            previous_crop_plants_growth_level = "hight"
            if previous_cultivation and previous_cultivation.dead_at
              previous_crop_destruction_period = previous_cultivation.dead_at.strftime("%m%d")
              if previous_cultivation.get(:plant_growth_level)
                previous_crop_plants_growth_level = previous_cultivation.get(:plant_growth_level)
              end
            end
            if previous_sets and previous_crop_destruction_period and previous_crop_plants_growth_level
              # get value from abacus 11
              items = Nomen::NmpPoitouCharentesAbacusEleven.list.select do |item|
            previous_sets.include?(item.intermediate_crop_variety.to_s) and (item.intermediate_crop_destruction_period_start.to_i <= previous_crop_destruction_period.to_i and previous_crop_destruction_period.to_i < item.intermediate_crop_destruction_period_stop.to_i) and previous_crop_plants_growth_level.to_s == item.growth_level.to_s
              end
              if items.any?
                quantity = items.first.mrci.in_kilogram_per_hectare
              end
            end
          end
        end
        return quantity
      end


      # Estimate Nirr
      def estimate_irrigation_water_nitrogen
        quantity = 0.in_kilogram_per_hectare
        if input_water = @support.get(:irrigation_water_input_area_density) 
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
        # FIXME be careful : started_at forced to 15/07/N-1
        started_at = Time.new(campaign.harvest_year-1,7,15)
        stopped_at = @opened_at
        global_xa = []
        if interventions = @support.interventions.real.where(state: 'done').of_nature(:soil_enrichment).between(started_at, stopped_at).with_cast('soil_enrichment-target', @support.storage)
          for intervention in interventions
            # get the working area (hectare)
            working_area = intervention.casts.of_role('soil_enrichment-target').first.population
            # get the population of each intrant
            for input in intervention.casts.of_role('soil_enrichment-input')
              if i = input.actor
                # get nitrogen concentration (t) in percent
                t = i.nitrogen_concentration.to_d(:percent)
                # get the keq coefficient from abacus_8
                  # get the variant reference_name
                  variant = i.variant_reference_name
                  # get the period (month of intervention)
                  month = intervention.started_at.strftime("%m")
                  # get the input method
                  input_method = 'on_top'
                  # get the crop_set
                  sets = crop_sets.map(&:name).map(&:to_s)
                # get keq
                items = Nomen::NmpPoitouCharentesAbacusEight.list.select do |item|
                  variant.to_s == item.variant.to_s and sets.include?(item.crop.to_s) and month.to_i >= item.input_period_start.to_i
                end
                if items.any?
                  keq = items.first.keq.to_d
                end
                # get net_mass (n) and working area for input density
                n = i.net_mass(input).to_d(:ton)
                if working_area != 0
                  q = (n / working_area).to_d
                end
                if t and keq and q
                  xa = (t / 10) * keq * q
                end
                global_xa << xa
              end
            end
          end
        end
        quantity = global_xa.compact.sum.in_kilogram_per_hectare
        return quantity        
      end


      # Estimate Rf
      def estimate_nitrogen_at_closing
        quantity = 0.in_kilogram_per_hectare
        if @variety and @variety <= :nicotiana
          quantity = 50.in_kilogram_per_hectare
        end
        if @soil_nature and capacity = @options[:available_water_capacity].in_liter_per_square_meter
          items = Nomen::NmpPoitouCharentesAbacusNine.list.select do |item|
            @soil_nature <= item.soil_nature and item.minimum_available_water_capacity.in_liter_per_square_meter <= capacity and capacity < item.maximum_available_water_capacity.in_liter_per_square_meter
          end
          if items.any?
            quantity = items.first.rf.in_kilogram_per_hectare
          end
        end
        return quantity        
      end

      # Estimate Po
      def estimate_soil_production
        quantity = 0.in_kilogram_per_hectare
        sets = crop_sets.map(&:name).map(&:to_s)
        # TODO find a way to retrieve water falls
        water_falls = 380.in_liter_per_square_meter
        
        if capacity = @options[:available_water_capacity].in_liter_per_square_meter and sets = crop_sets.map(&:name).map(&:to_s) 
          if @variety and @variety <= :brassica_napus and  plant_growth_indicator = @cultivation.density(:fresh_mass, :net_surface_area).to_d(:kilogram_per_hectare)
            
            if plant_growth_indicator <= 0.4
              plant_growth = 'low'
            elsif plant_growth_indicator > 0.4 and plant_growth_indicator <= 1.6
              plant_growth = 'medium'
            elsif plant_growth_indicator > 1.6
              plant_growth = 'high'
            else
              plant_growth = 'low'
            end
            
            items = Nomen::NmpPoitouCharentesAbacusTen.list.select do |item|
            item.plant_developpment == plant_growth.to_s and sets.include?(item.crop.to_s) and (item.precipitations_min.in_liter_per_square_meter <= water_falls and water_falls < item.precipitations_max.in_liter_per_square_meter)
            end
            
            
          elsif @variety
            
            items = Nomen::NmpPoitouCharentesAbacusTen.list.select do |item|
            (item.minimum_available_water_capacity.in_liter_per_square_meter <= capacity and capacity < item.maximum_available_water_capacity.in_liter_per_square_meter) and sets.include?(item.crop.to_s) and (item.precipitations_min.in_liter_per_square_meter <= water_falls and water_falls < item.precipitations_max.in_liter_per_square_meter)
            end
          else
            items = {}
          end
          if items.any?
            quantity = items.first.po.in_kilogram_per_hectare
          end
        end
        return quantity        
      end


      def estimate_maximum_nitrogen_input
        quantity = 170.in_kilogram_per_hectare
        if department_item = @options[:administrative_area] and @variety
          cultivation_varieties = @variety.self_and_parents
          items = Nomen::NmpFranceAbacusMaximumNitrogenInputPerCultivation.list.select do |i|
              @variety <= i.cultivation_variety  and i.administrative_area.to_s == department_item.parent_area.to_s
          end
          if items.any?
            quantity = items.first.maximum_nitrogen_input.in_kilogram_per_hectare
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
        
        sets = crop_sets.map(&:name).map(&:to_s)
        
        if @variety and ( @variety <= :poaceae or @variety <= :brassicaceae or @variety <= :medicago or @variety <= :helianthus or @variety <= :nicotiana or @variety <= :linum )
          if soil_natures.include?(Nomen::SoilNatures[:clay_limestone_soil]) or soil_natures.include?(Nomen::SoilNatures[:chesnut_red_soil]) and @variety and @variety > :nicotiana
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
        end
        
        # LEGUMES / ARBO / VIGNES : Dose plafond à partir d'abaques    
        # X ≤ nitrogen_input_max – Nirr – Xa
        if @variety and (@variety <= :vitis or @variety <= :solanum_tuberosum or @variety <= :cucumis or sets.include?("gardening_vegetables"))
          values[:nitrogen_input] = values[:maximum_nitrogen_input] - values[:irrigation_water_nitrogen] - values[:organic_fertilizer_mineral_fraction]
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
