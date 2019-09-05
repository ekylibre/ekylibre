module Agroedi
  class DaplosExchanger < ActiveExchanger::Base
    class DaplosInterventionParameter < DaplosNode
      daplos_parent :intervention

      class << self
        alias_method :new_without_cast, :new

        def new(*args)
          kind = args.last
          klass_name = "agroedi/daplos_exchanger/#{kind}".classify
          klass = klass_name.constantize
          klass.new_without_cast(*args[0...-1]).tap do |param|
            param.procedure_parameter = param.matching_procedure_parameter
          end
        rescue NameError
          return raise $! unless $!.message =~ /^uninitialized constant Agroedi::DaplosExchanger::/
          raise "Could not find #{klass_name}"
        end
      end

      delegate :output_specie_edicode, :output_nature_edicode, :output_name,
                to: :daplos_output

      def procedure_parameter=(parameter)
        clear_memoization!
        @procedure_parameter = parameter
      end

      def procedure_parameter
        @procedure_parameter ||
          raise("Method #{caller(1).first} tried calling #procedure_parameter but it isn't set")
      end

      def handler(based_on)
        @memo_handler ||= Array(procedure_parameter.best_handler_for(based_on)).first
      end

      def uid
        [procedure_parameter, daplos].hash
      end

      def daplos_unit
        @daplos_unit ||= (RegisteredAgroediCode.of_reference_code(unit_edicode)
                                               .first
                                               &.ekylibre_value ||
                          raise("No way to find unit of #{unit_edicode}"))
      end

      def nature
        self.class.name.split('::').last.underscore.to_sym
      end

      def matching_procedure_parameter
        intervention.procedure.parameters_of_type(nature).find do |procedure_param|
          coherent?(with: procedure_param)
        end
      end

      def clear_memoization!
        instance_variables.each do |ivar_name|
          instance_variable_set(ivar_name, nil) if ivar_name.to_s =~ /^@memo_/
        end
      end
    end
  end
end
