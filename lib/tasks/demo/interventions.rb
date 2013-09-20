demo :interventions do
  
  class Booker

    def self.daytime_duration(on)
      12.0 - 4.0 * Math.cos((on + 11.days).yday.to_f / (365.25 / Math::PI / 2))
    end

    def self.sunrise(on, shift = 1.5)
      return shift + (24.0 - self.daytime_duration(on)) / 2.0
    end

    def self.sunset(on, shift = 1.5)
      self.daytime_duration(on) + self.sunrise(on, shift)
    end


    def self.intervene(procedure, year, month, day, duration, &block)
      options = workers.extract_options!
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
      end while InterventionCast.joins(:interventions).where(actor_id: actors.map(&:id)).where("? BETWEEN started_at AND stopped_at OR ? BETWEEN started_at AND stopped_at", on, on + duration_day).count > 0

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
      for period in periods
        Intervention.run!(procedure, period, &block)
      end
    end

    attr_reader :casts

    def initialize
      @casts = []
    end

    def cast(options = {})
      @casts << options
    end

  end



  Ekylibre::fixturize :interventions do |w|

    for production in Production.all
      variety = production.product_nature.variety
      if Nomen::Varieties[variety].is_a?(:poaceae)
        year = production.campaign.name.to_i
        for support in production.supports
          land_parcel = support.storage
          coeff = (land_parcel.shape_area / 10000) / 6

          # Plowing 15-09-N -> 15-10-N
          Booker.intervene(:plowing, year - 1, 9, 15, 9.78 * coeff) do |i|
            i.cast(variable: 'driver', actor: Worker.all.sample)
            i.cast(variable: 'tractor', actor: Product.can("tow(plower)").all.sample)
            i.cast(variable: 'plower', actor: Product.can("plow").all.sample)
            i.cast(variable: 'land_parcel', actor: land_parcel)
          end          
          
          # Sowing 15-10-N -> 30-10-N
          Booker.intervene(:sowing, year - 1, 10, 15, 6.92 * coeff, :range => 15) do |i|
            i.cast(variable: 'seeds', actor: Product.of_variety("seed").derivative_of(production.product_nature).all.sample)
            i.cast(variable: 'seeds_to_sow', quantity: 20)
            i.cast(variable: 'sower', actor: Product.can("sow").all.sample)
            i.cast(variable: 'driver', actor: Worker.all.sample)
            i.cast(variable: 'tractor', actor: Product.can("tow(sower)").all.sample)
            i.cast(variable: 'land_parcel', actor: land_parcel)
            i.cast(variable: 'culture')
          end          
          
          # Fertilizing  01-03-M -> 31-03-M
          Booker.intervene(:mineral_fertilizing, year, 3, 1, 0.96 * coeff) do |i|
            i.cast(variable: 'fertilizer', actor: fertilizer_product_prev)
            i.cast(variable: 'fertilizer_to_spread', quantity: 20)
            i.cast(variable: 'spreader', actor: Product.can("spread(mineral_matter)").all.sample)
            i.cast(variable: 'driver', actor: Worker.all.sample)
            i.cast(variable: 'tractor', actor: Product.can("tow(spreader)").all.sample)
            i.cast(variable: 'land_parcel', roles: 'soil_enrichment-target', actor: land_parcel)
          end          

          if w.count.mod(3).zero? # AND NOT prairie
            # Treatment herbicide 01-04 30-04
            Booker.intervene(:chemical_treatment, year, 4, 1, 1.07 * coeff) do |i|
              i.cast(variable: 'fertilizer', actor: fertilizer_product_prev)
              i.cast(variable: 'fertilizer_to_spread', roles: 'soil_enrichment-input', quantity: 20)
              i.cast(variable: 'spreader', actor: Product.can("spread(mineral_matter)").all.sample)
              i.cast(variable: 'driver', actor: Worker.all.sample)
              i.cast(variable: 'tractor', actor: Product.can("tow(spreader)").all.sample)
              i.cast(variable: 'land_parcel', roles: 'soil_enrichment-target', actor: land_parcel_group_fert)
            end
          end
          
          # Harvest 01-07-M 30-07-M
          Booker.intervene(:harvest, year, 7, 1, 3.13 * coeff) do |i|
            i.cast(variable: 'fertilizer', actor: fertilizer_product_prev)
            i.cast(variable: 'fertilizer_to_spread', roles: 'soil_enrichment-input', quantity: 20)
            i.cast(variable: 'spreader', actor: Product.can("spread(mineral_matter)").all.sample)
            i.cast(variable: 'driver', actor: Worker.all.sample)
            i.cast(variable: 'tractor', actor: Product.can("tow(spreader)").all.sample)
            i.cast(variable: 'land_parcel', roles: 'soil_enrichment-target', actor: land_parcel_group_fert)
          end         
        end
        w.check_point
      end
    end
  end

end
