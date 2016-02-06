require 'ffaker'

module Ekylibre
  module FirstRun
    class Booker
      cattr_accessor :production

      class << self
        # Find a product with given options
        #  - started_at
        #  - work_number
        #  - can
        #  - variety
        #  - derivative_of
        #  - filter: WSQL expression
        # Options for product creation only:
        #  - default_storage
        # Special options for worker creation only:
        #  - first_name
        #  - last_name
        #  - born_at
        #  - default_storage
        def find(model, options = {})
          relation = model
          relation = relation.where('COALESCE(born_at, ?) <= ? ', options[:started_at], options[:started_at]) if options[:started_at]
          relation = relation.of_expression(options[:filter]) if options[:filter]
          relation = relation.of_work_numbers(options[:work_number]) if options[:work_number]
          relation = relation.can(options[:can]) if options[:can]
          relation = relation.of_variety(options[:variety]) if options[:variety]
          relation = relation.derivative_of(options[:derivative_of]) if options[:derivative_of]
          return relation.all.sample if relation.any?
          # Create product with given elements
          attributes = {}
          unless options[:default_storage].is_a?(FalseClass)
            attributes[:default_storage] = find(BuildingDivision, default_storage: find(Building, default_storage: false))
          end
          if model == Worker
            options[:first_name] ||= ::FFaker::Name.first_name
            options[:last_name] ||= ::FFaker::Name.last_name
            options[:born_at] ||= Date.new(1970 + rand(20), 1 + rand(12), 1 + rand(28))
            unless person = Contact.find_by(first_name: options[:first_name], last_name: options[:last_name])
              person = Contact.create!(first_name: options[:first_name], last_name: options[:last_name], born_at: options[:born_at])
            end
            attributes[:person] = person
          end
          variants = ProductNatureVariant.find_or_import!(options[:variety] || model.name.underscore, derivative_of: options[:derivative_of])
          variants.can(options[:can]) if options[:can]
          unless attributes[:variant] = variants.first
            raise StandardError, "Cannot find product variant with options #{options.inspect}"
          end
          model.create!(attributes)
        end

        # Compute approximately day time duration in France at given date
        def daytime_duration(on)
          12.0 - 4.0 * Math.cos((on + 11.days).yday.to_f / (365.25 / Math::PI / 2))
        end

        # Compute approximately sunrise hour in France at given date
        def sunrise(on, shift = 1.5)
          shift + (24.0 - daytime_duration(on)) / 2.0
        end

        # Compute approximately sunset hour in France at given date
        def sunset(on, shift = 1.5)
          daytime_duration(on) + sunrise(on, shift)
        end

        # Duration is expected to be in hours
        def intervene(procedure_name, year, month, day, duration, options = {})
          day_range = options[:range] || 30

          duration += 1.5 - rand(0.5)

          # Find procedure
          procedure = Procedo[procedure_name]
          unless procedure
            raise ArgumentError, "Unknown procedure: #{procedure_name.inspect}"
          end

          # Find actors
          booker = new(procedure, Time.new(year, month, day), duration)
          yield booker
          actors = booker.product_parameters.collect { |c| c[:actor] }.compact
          raise ArgumentError, "What's the fuck ? No actors ? " if actors.empty?

          # Adds fixed durations to given time
          fixed_duration = procedure.fixed_duration / 3600
          duration += fixed_duration

          # Estimate number of days to work
          duration_days = (duration / 8.0).ceil

          # Find a slot for all actors for given number of day
          on = nil
          begin
            on = Date.civil(year, month, day) + rand(day_range - duration_days).days
          end while InterventionProductParameter.joins(:intervention).where(actor_id: actors.map(&:id)).where('? BETWEEN started_at AND stopped_at OR ? BETWEEN started_at AND stopped_at', on, on + duration_days).any?

          # Compute real number of day
          # 11 days shifting is here respect solstice shifting with 1st day of year
          daytime_duration = self.daytime_duration(on) - 2.0
          if duration > daytime_duration
            duration_days = (duration.to_f / daytime_duration).ceil
          end

          # Split into many interventions
          periods = []
          total = duration * 1.0 - fixed_duration
          duration_days.times do
            started_at = on.to_time + sunrise(on).hours + 1.hour
            d = self.daytime_duration(on) - 2.0 - fixed_duration
            d = total if d > total
            periods << { started_at: started_at, duration: (d + fixed_duration) * 3600 } if d > 0
            total -= d
            on += 1
          end

          # Run interventions
          intervention = nil
          for period in periods
            stopped_at = period[:started_at] + period[:duration]
            next unless stopped_at < Time.zone.now
            intervention = Intervention.create!(procedure_name: procedure_name, production: Booker.production, production_support: options[:support], started_at: period[:started_at], stopped_at: stopped_at)
            for cast in booker.product_parameters
              intervention.add_cast!(cast)
            end
            intervention.run!(period, options[:parameters])
          end
          intervention
        end

        # Used for importing intervention from others editors
        # procedure_code symbol (from procedure)
        # started_at datetime
        # duration integer (hours)
        def force(procedure_name, started_at, duration, options = {}, &_block)
          # Find procedure
          procedure = Procedo[procedure_name]
          unless procedure
            raise ArgumentError, "Unknown procedure: #{procedure_name.inspect}"
          end

          # Adds fixed durations to given time
          fixed_duration = procedure.fixed_duration / 3600
          duration += fixed_duration

          # Find actors
          booker = new(procedure, started_at, duration)
          yield booker
          actors = booker.product_parameters.collect { |c| c[:actor] }.compact
          raise ArgumentError, "What's the fuck ? No actors ? " if actors.empty?

          # Find a slot for all actors for given day and given duration
          at = nil
          9.times do |p|
            at = started_at + p
            break unless InterventionProductParameter.joins(:intervention).where(actor_id: actors.map(&:id)).where('? BETWEEN started_at AND stopped_at OR ? BETWEEN started_at AND stopped_at', at, at + duration.hours).any?
          end

          # Run interventions
          intervention = nil
          stopped_at = at + duration.hours
          if stopped_at < Time.zone.now
            intervention = Intervention.create!(procedure_name: procedure_name, production: Booker.production, production_support: options[:support], started_at: at, stopped_at: stopped_at, description: options[:description])
            booker.product_parameters.each do |cast|
              intervention.add_cast!(cast)
            end
            intervention.run!({ started_at: at, duration: duration.hours }, options[:parameters])
          end
          intervention
        end
      end

      attr_reader :product_parameters, :duration, :started_at, :procedure

      def initialize(procedure, started_at, duration)
        @procedure = procedure
        @duration = duration
        @started_at = started_at
        @product_parameters = []
      end

      def add_cast(options = {})
        unless procedure.parameter[options[:parameter_name]]
          raise "Invalid parameter: #{options[:parameter_name]} in procedure #{procedure.name}"
        end
        @product_parameters << options
      end

      # Find a valid actor in the given period
      def find(model, options = {})
        options[:started_at] = @started_at
        options[:stopped_at] = @started_at
        self.class.find(model, options)
      end
    end
  end
end
