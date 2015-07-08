class Intervention
  class Recorder

    class OperationTask
      def initialize(recorder, type, parameters = {}, options = {})
        @recorder = recorder
        @type = type
        @parameters = parameters
        @options = {}
      end


      def perform!(operation)
        operation.send("perform_#{@type}", nil, actors)
      end

      # FIXME Variant only not working
      def actors
        @parameters.inject({}) do |h, p|
          h[p.first] = if p.second.is_a?(Symbol)
                         intervention.casts.find_by!(reference_name: p.second)
                       elsif p.second.is_a?(Intervention::Recorder::Cast)
                         if p.second.variant?
                           intervention.casts.find_by!(variant_id: p.second.object.id)
                         else
                           intervention.casts.find_by!(actor_id: p.second.object.id)
                         end
                       else
                         p.second
                       end
          h
        end
      end

      def intervention
        @recorder.intervention
      end

    end


  end
end
