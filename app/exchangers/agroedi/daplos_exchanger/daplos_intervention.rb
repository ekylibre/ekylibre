module Agroedi
  class DaplosExchanger < ActiveExchanger::Base
    class DaplosIntervention < DaplosNode
      daplos_parent :crop

      attr_accessor :record, :engine, :collections

      delegate :production_support, :activity_production, :production, :exchanger, to: :crop

      class << self
        alias_method :new_without_cast, :new
        # Autocasts to proper class
        def new(*args)
          int = super
          if int.unique?
            UniqueIntervention.new_without_cast(*args)
          else
            MergeableIntervention.new_without_cast(*args)
          end
        end

        def regroup(collection)
          collection.group_by(&:class).each { |klass, ints| klass.regroup(ints) }
        end
      end

      def initialize(*args)
        super
        return if self.class == DaplosIntervention
        DaplosExchanger::WorkingPeriod.new(self, daplos).register
        DaplosExchanger::Target.new(self, daplos).register
        register_parameters(self.inputs_to_register)
      end

      def import
        return if already_imported?

        align_activity_production_dates!
        record!
      end

      def working_zone_area
        production_support.shape.area.in(:square_meter).convert(:hectare)
      end

      def unique?
        %i[sowing_without_plant_output harvesting_with_plant_or_land_parcel].any? do |code|
          agroedi_code == code
        end
      end

      def mergeable?
        !unique?
      end

      def guids
        @guids ||= [guid]
      end

      def guid
        daplos.intervention_guid + daplos.intervention_started_at
      end

      def register_guid!
        existing_providers = record.providers || {}
        existing_guids = existing_providers['daplos_intervention_guid'] || []
        existing_guids << self.guid
        existing_guids.uniq!
        existing_providers.merge!('daplos_intervention_guid' => existing_guids)
        record.update!(providers: existing_providers)
      end

      def procedure
        procedure = Procedo.find(agroedi_code)
        raise "No procedure for #{agroedi_code}" unless procedure
        procedure
      end

      def agroedi_code
        return @memo_agroedi_code if @memo_agroedi_code

        code = daplos.intervention_nature_edicode
        match_record = RegisteredAgroediCode.find_by(
          repository_id: 14,
          reference_code: code)
        ekylibre_agroedi = match_record&.ekylibre_value&.to_sym
        unless ekylibre_agroedi
          raise "Intervention nature #{code.inspect} has no equivalent in Ekylibre reference"
        end
        @memo_agroedi_code = ekylibre_agroedi
      end

      def started_at
        DateTime.soft_parse(daplos.intervention_started_at)
      end

      def stopped_at
        DateTime.soft_parse(daplos.intervention_stopped_at)
      end

      def already_imported?
        return true if self.record
        records = guids.map { |g| ::Intervention.find_by(%(providers @> '{ "daplos_intervention_guid": ["#{g}"]}')) }
        return false unless records.all?(&:present?)
        self.record ||= records.first
      end

      def general_attributes
        {
          procedure_name: procedure.name,
          actions: procedure.mandatory_actions.map(&:name),
          providers: { "daplos_intervention_guid" => guids }
        }
      end

      def to_attributes
        collection_attributes = children.map do |key, values|
            keyed_values = values.map do |val|
              [val.uid.to_s, val.to_attributes]
            end
            ["#{key}_attributes", keyed_values.to_h]
          end.to_h.with_indifferent_access

          procedo_consistent(collection_attributes.merge(general_attributes))
      end

      private

        def record!
          create_and_set_record!
          register_guid!
        end

        def create_and_set_record!
          ::Intervention.new(to_attributes)
                        .tap(&:save!)
                        .tap { |rec| self.record = rec }
        end

        def register_parameters(parameter_kind)
          parameter_kind = parameter_kind.to_s.singularize
          collection = parameter_kind.pluralize.to_sym
          daplos.send(collection).each do |param|
            parameter = DaplosExchanger::DaplosInterventionParameter.new(self, param, parameter_kind)
            parameter.register if parameter.coherent?
          end
        end

        def updaters
          children.slice(:inputs, :outputs).flat_map do |collection_name, values|
            values.map { |value| "#{collection_name}[#{value.uid}]quantity_value" }
          end
        end

        def align_activity_production_dates!
          return unless children[:working_periods].any?(&:started_at)

          started_ats = children[:working_periods].map(&:started_at)
          stopped_ats = children[:working_periods].map(&:stopped_at)
          productions = children[:targets].map(&:target_production)

          productions.each do |production|
            production.reload
            production.started_on = [*started_ats,
                                     *stopped_ats,
                                     production.started_on].compact.min - 1.day
            production.stopped_on = [*started_ats,
                                     *stopped_ats,
                                     production.stopped_on].compact.max + 1.day

            production.tap(&:save!).tap(&:reload)
          end
        end

        def procedo_consistent(attributes)
          engine_intervention = Procedo::Engine.new_intervention(attributes)
          updaters.each do |change|
            engine_intervention.impact_with!(change)
          end
          attributes.merge(engine_intervention.to_attributes)
        end
    end
  end
end
