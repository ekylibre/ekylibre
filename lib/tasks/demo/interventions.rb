demo :interventions do

  class Booker

    cattr_accessor :production

    def self.daytime_duration(on)
      12.0 - 4.0 * Math.cos((on + 11.days).yday.to_f / (365.25 / Math::PI / 2))
    end

    def self.sunrise(on, shift = 1.5)
      return shift + (24.0 - self.daytime_duration(on)) / 2.0
    end

    def self.sunset(on, shift = 1.5)
      self.daytime_duration(on) + self.sunrise(on, shift)
    end


    # <<<<<<< HEAD
    def self.intervene(procedure, year, month, day, duration, options = {}, &block)
      # =======
      #     def self.intervene(procedure, year, month, day, duration, options = {})
      #       #options = options.extract_options!
      # >>>>>>> c23a36b6714fc4b124ed35113576fba11fc9f33c
      day_range = options[:range] || 30

      # Find actors
      booker = new
      yield booker
      actors = booker.casts.collect{|c| c[:actor]}.compact
      if actors.empty?
        raise ArgumentError.new("What's the fuck ? No actors ? ")
      end

      # Estimate number of days to work
      duration_days = (duration / 8.0).ceil

      # Find a slot for all actors for given number of day
      on = nil
      begin
        on = Date.civil(year, month, day) + rand(day_range - duration_days).days
      end while InterventionCast.joins(:intervention).where(actor_id: actors.map(&:id)).where("? BETWEEN started_at AND stopped_at OR ? BETWEEN started_at AND stopped_at", on, on + duration_days).count > 0

      # Compute real number of day
      # 11 days shifting is here respect solstice shifting with 1st day of year
      daytime_duration = self.daytime_duration(on) - 2.0
      if duration > daytime_duration
        duration_days = (duration.to_f / daytime_duration).ceil
      end

      # Split into many interventions
      periods = []
      total = duration * 1.0
      duration_days.times do
        started_at = on.to_time + self.sunset(on).hours + 1.hour
        d = self.daytime_duration(on) - 2.0
        d = total if d > total
        periods << {started_at: started_at, duration: d} if d > 0
        total -= d
        on += 1
      end

      # Run interventions
      int = nil
      for period in periods
        int = Intervention.run!({procedure: procedure, production: Booker.production}, period, &block)
      end
      return int
    end

    attr_reader :casts

    def initialize
      @casts = []
    end

    def add_cast(options = {})
      @casts << options
    end

  end


  nature = ProductNature.find_or_create_by!(name: "Travailleur", variety: "worker")
  variant = nature.variants.find_or_create_by!(name: "Technicien", unit_name: "Personne")
  Worker.find_or_create_by!(number: 'ALICEALI', name: 'Alice', variant: variant)
  Worker.find_or_create_by!(number: 'BOBOBOBO', name: 'Bob', variant: variant)
  Worker.find_or_create_by!(number: 'CHARLENE', name: 'Charlene', variant: variant)


  # <<<<<<< HEAD

  Ekylibre::fixturize :interventions do |w|
    for production in Production.all
      variety = production.product_nature.variety
      if Nomen::Varieties[variety].self_and_parents.include?(Nomen::Varieties[:poaceae])
        # =======
        #     for production in Production.where("name LIKE 'Culture%'")
        #       variety = production.product_nature.variety
        #       #if Nomen::Varieties[variety].is_a?(:poaceae)
        
        #       fertilizer_product_prev = MineralMatter.of_variety("mineral_matter").can("fertilize").first
        
        #         product_nature = ProductNature.find_by_nomen("chemical_fertilizer")
        #         product_nature ||= ProductNature.import_from_nomenclature("chemical_fertilizer")
        #         product_nature_variant = product_nature.variants.create!(:name => "Ammo 33", :active => true, :unit_name => "big bag", :frozen_indicators => "net_weight")
        #         product_nature_variant.is_measured!(:net_weight, 500.in_kilogram)
        
        #       fertilizer_product_prev ||= MineralMatter.create!(:name => "Ammo 1", :born_at => Time.now, :variant_id => product_nature_variant.id, :owner => Entity.of_company, :identification_number => "FR25896")
        #         fertilizer_product_prev.is_measured!(:population, 50.in_unity)      
        #         fertilizer_product_prev.is_measured!(:nitrogen_concentration, 27.00.in_kilogram_per_hectogram, :at => Time.now)
        #         fertilizer_product_prev.is_measured!(:potassium_concentration, 33.00.in_kilogram_per_hectogram, :at => Time.now)
        #         fertilizer_product_prev.is_measured!(:phosphorus_concentration, 33.00.in_kilogram_per_hectogram, :at => Time.now)
        
        # >>>>>>> c23a36b6714fc4b124ed35113576fba11fc9f33c
        year = production.campaign.name.to_i
        Booker.production = production
        for support in production.supports
          land_parcel = support.storage
          # <<<<<<< HEAD
          if area = land_parcel.shape_area
            coeff = (area / 10000) / 6

            # Plowing 15-09-N -> 15-10-N
            Booker.intervene(:plowing, year - 1, 9, 15, 9.78 * coeff) do |i|
              i.add_cast(variable: 'driver', actor: Worker.all.sample)
              i.add_cast(variable: 'tractor', actor: Product.can("tow(equipment)").all.sample)
              i.add_cast(variable: 'plower', actor: Product.can("plow").all.sample)
              i.add_cast(variable: 'land_parcel', actor: land_parcel)
            end

            # Sowing 15-10-N -> 30-10-N
            int = Booker.intervene(:sowing, year - 1, 10, 15, 6.92 * coeff, :range => 15) do |i|
              i.add_cast(variable: 'seeds', actor: Product.of_variety("seed").derivative_of(variety).all.sample)
              i.add_cast(variable: 'seeds_to_sow', quantity: 20)
              i.add_cast(variable: 'sower', actor: Product.can("sow").all.sample)
              i.add_cast(variable: 'driver', actor: Worker.all.sample)
              i.add_cast(variable: 'tractor', actor: Product.can("tow(equipment)").all.sample)
              i.add_cast(variable: 'land_parcel', actor: land_parcel)
              i.add_cast(variable: 'culture')
            end

            culture = int.casts.find_by(variable: 'culture').actor

            # Fertilizing  01-03-M -> 31-03-M
            Booker.intervene(:mineral_fertilizing, year, 3, 1, 0.96 * coeff) do |i|
              i.add_cast(variable: 'fertilizer', actor: Product.of_variety(:mineral_matter).all.sample)
              i.add_cast(variable: 'fertilizer_to_spread', quantity: 20)
              i.add_cast(variable: 'spreader', actor: Product.can("spread(mineral_matter)").all.sample)
              i.add_cast(variable: 'driver', actor: Worker.all.sample)
              i.add_cast(variable: 'tractor', actor: Product.can("tow(equipment)").all.sample)
              i.add_cast(variable: 'land_parcel', actor: land_parcel)
            end

            if w.count.modulo(3).zero? # AND NOT prairie
              # Treatment herbicide 01-04 30-04
              Booker.intervene(:chemical_treatment, year, 4, 1, 1.07 * coeff) do |i|
                i.add_cast(variable: 'molecule', actor: Product.can("kill(plant)").all.sample)
                i.add_cast(variable: 'molecule_to_spread', quantity: 20)
                i.add_cast(variable: 'spreader', actor: Product.can("spread").all.sample)
                i.add_cast(variable: 'driver', actor: Worker.all.sample)
                i.add_cast(variable: 'tractor', actor: Product.can("tow(equipment)").all.sample)
                i.add_cast(variable: 'land_parcel', actor: land_parcel)
              end
            end

            # Harvest 01-07-M 30-07-M
            bob = Worker.all.sample
            other = Worker.where("id != ?", bob.id).all.sample
            Booker.intervene(:seed_harvest, year, 7, 1, 3.13 * coeff) do |i|
              i.add_cast(variable: 'silo', actor: Product.can("store(grain)").all.sample)
              i.add_cast(variable: 'driver', actor: bob)
              i.add_cast(variable: 'tractor', actor: Product.can("tow(equipment)").all.sample)
              i.add_cast(variable: 'trailer', actor: Product.can("store_fluid").all.sample)
              i.add_cast(variable: 'cropper', actor: Product.can("spread(mineral_matter)").all.sample)
              i.add_cast(variable: 'cropper_driver', actor: other)
              i.add_cast(variable: 'culture',  actor: culture)
              i.add_cast(variable: 'grains')
              i.add_cast(variable: 'straw')
            end
            # =======
            #           coeff = (land_parcel.shape_area / 10000) / 6
            
            #           # Plowing 15-09-N -> 15-10-N
            #           Booker.intervene(:plowing, year - 1, 9, 15, 9.78 * coeff) do |i|
            #             i.cast(variable: 'driver', actor: Worker.all.sample)
            #             i.cast(variable: 'tractor', actor: Product.can("tow").all.sample) # tow(plower)
            #             i.cast(variable: 'plower', actor: Product.can("plow").all.sample)
            #             i.cast(variable: 'land_parcel', actor: land_parcel)
            #           end

            #           # Sowing 15-10-N -> 30-10-N
            #           Booker.intervene(:sowing, year - 1, 10, 15, 6.92 * coeff, :range => 15) do |i|
            #             i.cast(variable: 'seeds', actor: Product.of_variety("seed").derivative_of(production.product_nature).all.sample)
            #             i.cast(variable: 'seeds_to_sow', quantity: 20)
            #             i.cast(variable: 'sower', actor: Product.can("sow").all.sample)
            #             i.cast(variable: 'driver', actor: Worker.all.sample)
            #             i.cast(variable: 'tractor', actor: Product.can("tow").all.sample) #tow(sower)
            #             i.cast(variable: 'land_parcel', actor: land_parcel)
            #             i.cast(variable: 'culture')
            #           end

            #           # Fertilizing  01-03-M -> 31-03-M
            #           Booker.intervene(:mineral_fertilizing, year, 3, 1, 0.96 * coeff) do |i|
            #             i.cast(variable: 'fertilizer', actor: fertilizer_product_prev)
            #             i.cast(variable: 'fertilizer_to_spread', quantity: 20)
            #             i.cast(variable: 'spreader', actor: Product.can("spread").all.sample) #spread(mineral_matter)
            #             i.cast(variable: 'driver', actor: Worker.all.sample)
            #             i.cast(variable: 'tractor', actor: Product.can("tow").all.sample) #tow(spreader)
            #             i.cast(variable: 'land_parcel', roles: 'soil_enrichment-target', actor: land_parcel)
            #           end

            #           #if w.count.mod(3).zero? # AND NOT prairie
            #             # Treatment herbicide 01-04 30-04
            #             Booker.intervene(:chemical_treatment, year, 4, 1, 1.07 * coeff) do |i|
            #               i.cast(variable: 'fertilizer', actor: fertilizer_product_prev)
            #               i.cast(variable: 'fertilizer_to_spread', roles: 'soil_enrichment-input', quantity: 20)
            #               i.cast(variable: 'spreader', actor: Product.can("spread").all.sample) # spread(mineral_matter)
            #               i.cast(variable: 'driver', actor: Worker.all.sample)
            #               i.cast(variable: 'tractor', actor: Product.can("tow").all.sample) # tow(spreader)
            #               i.cast(variable: 'land_parcel', roles: 'soil_enrichment-target', actor: land_parcel)
            #             end
            #           #end

            #           # Harvest 01-07-M 30-07-M
            #           Booker.intervene(:harvest, year, 7, 1, 3.13 * coeff) do |i|
            #             i.cast(variable: 'fertilizer', actor: fertilizer_product_prev)
            #             i.cast(variable: 'fertilizer_to_spread', roles: 'soil_enrichment-input', quantity: 20)
            #             i.cast(variable: 'spreader', actor: Product.can("spread").all.sample) # spread(mineral_matter)
            #             i.cast(variable: 'driver', actor: Worker.all.sample)
            #             i.cast(variable: 'tractor', actor: Product.can("tow").all.sample) # tow(spreader)
            #             i.cast(variable: 'land_parcel', roles: 'soil_enrichment-target', actor: land_parcel)
            # >>>>>>> c23a36b6714fc4b124ed35113576fba11fc9f33c
          end
          w.check_point
        end
      end
    end
  end
  
end
